#!/usr/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later

echo "::group::Prepare testsuite"
set -euxo pipefail

MKOSI_CACHE=${MKOSI_CACHE:-"/var/tmp/mkosi-debinit.$(</etc/machine-id).cache"}
mkdir -p "$MKOSI_CACHE"

# shellcheck disable=SC2206
PHASES=(${@:-DEPS INITRD_BASIC})
SYSTEMD_LOG_OPTS="systemd.log_target=console udev.log_level=info systemd.default_standard_output=journal+console systemd.status_unit_format=name"

CLEANUP=()

function finish {
    next-group "Clean up"
    [[ ${#CLEANUP[@]} -gt 0 ]] && rm -rf "${CLEANUP[@]}" 2> /dev/null
    set +x
    echo "::endgroup::"
}
trap finish EXIT ERR

function next-group() {
    set +x
    echo "::endgroup::"
    echo "::group::$*"
    set -x
}

for phase in "${PHASES[@]}"; do
    case "$phase" in
        DEPS)
            next-group "Installing necessary dependencies"
            apt-get update
            apt-get install --no-install-recommends -y mkosi qemu-system-x86 kmod jq systemd-boot cpio zstd systemd-ukify dosfstools mtools file
            ;;
        INITRD_BASIC)
            next-group "Prepare initrd basic testsuite"
            command -v mkosi >/dev/null 2>&1 || exit 1
            command -v kvm >/dev/null 2>&1 || exit 1
            mkosi --version

            TESTDIR=$(mktemp -d)
            CLEANUP+=("$TESTDIR")
            INITRD=$TESTDIR/initrd.img

            next-group "Build initrd file"
            ./update-mkosi-debinit "$INITRD"

            stat "$INITRD"

            next-group "Build test image"
            ROOTFS=rootfs.img
            mkosi \
                --incremental=yes \
                --cache-dir="$MKOSI_CACHE" \
                --distribution=debian \
                --release=testing \
                --format=disk \
                --bootable \
                --package=linux-image-amd64,udev,systemd-boot \
                --extra-search-path=/usr/sbin \
                --output-dir="$TESTDIR" \
                --output="$ROOTFS" \
                build

            next-group "Sanity check if the initrd is bootable"
            timeout --foreground -k 10 3m \
                kvm -m 512 -smp "$(nproc)" -nographic \
                    -initrd "$INITRD" \
                    -kernel "$TESTDIR"/$ROOTFS.vmlinuz \
                    -append "rd.systemd.unit=systemd-poweroff.service rd.debug $SYSTEMD_LOG_OPTS console=ttyS0"

            next-group "Show all kernel modules"
            file "$INITRD"
            zstdcat "$INITRD" | cpio -t || true

            next-group "Get UUID for next test"
            UUID=$(/sbin/sfdisk -J "$TESTDIR"/$ROOTFS | jq -r '.partitiontable.partitions[1].uuid|ascii_downcase')
            /sbin/sfdisk -J "$TESTDIR"/$ROOTFS

            next-group "Boot the initrd with an OS image"
            timeout --foreground -k 10 2m \
                kvm -m 1024 -smp "$(nproc)" -nographic \
                    -initrd "$INITRD" \
                    -kernel "$TESTDIR"/$ROOTFS.vmlinuz \
                    -drive "if=virtio,index=0,format=raw,cache=unsafe,file=$TESTDIR/$ROOTFS" \
                    -append "root=PARTUUID=$UUID rd.debug $SYSTEMD_LOG_OPTS console=ttyS0 systemd.unit=systemd-poweroff.service systemd.default_timeout_start_sec=240"

            next-group "Info about built artifacts"
            ls -lah "$TESTDIR"
            stat "$INITRD"
            ;;
        DEBUG)
            next-group "Prepare initrd basic testsuite"
            command -v mkosi >/dev/null 2>&1 || exit 1
            command -v kvm >/dev/null 2>&1 || exit 1
            mkosi --version

            TESTDIR=$(mktemp -d)
            CLEANUP+=("$TESTDIR")

            next-group "Build test image"
            ROOTFS=rootfs.img
            mkosi \
                --incremental=yes \
                --cache-dir="$MKOSI_CACHE" \
                --distribution=debian \
                --release=testing \
                --format=disk \
                --bootable \
                --package=linux-image-amd64,udev,systemd-boot \
                --extra-search-path=/usr/sbin \
                --output-dir="$TESTDIR" \
                --output="$ROOTFS" \
                build

            next-group "Sanity check if the initrd is bootable"
            timeout --foreground -k 10 3m \
                kvm -m 512 -smp "$(nproc)" -nographic \
                    -initrd "$TESTDIR"/$ROOTFS.initrd \
                    -kernel "$TESTDIR"/$ROOTFS.vmlinuz \
                    -append "rd.systemd.unit=systemd-poweroff.service rd.debug $SYSTEMD_LOG_OPTS console=ttyS0"

            next-group "Show all kernel modules"
            file "$TESTDIR"/$ROOTFS.initrd
            zstdcat "$TESTDIR"/$ROOTFS.initrd | cpio -t || true

            next-group "Get UUID for next test"
            UUID=$(/sbin/sfdisk -J "$TESTDIR"/$ROOTFS | jq -r '.partitiontable.partitions[1].uuid|ascii_downcase')
            /sbin/sfdisk -J "$TESTDIR"/$ROOTFS

            next-group "Boot the initrd with an OS image"
            timeout --foreground -k 10 2m \
                kvm -m 1024 -smp "$(nproc)" -nographic \
                    -initrd "$TESTDIR"/$ROOTFS.initrd \
                    -kernel "$TESTDIR"/$ROOTFS.vmlinuz \
                    -drive "if=virtio,index=0,format=raw,cache=unsafe,file=$TESTDIR/$ROOTFS" \
                    -append "root=PARTUUID=$UUID rd.debug $SYSTEMD_LOG_OPTS console=ttyS0 systemd.unit=systemd-poweroff.service systemd.default_timeout_start_sec=240"

            next-group "Info about built artifacts"
            ls -lah "$TESTDIR"
            ;;
        *)
            echo >&2 "Unknown phase '$phase'"
            exit 1
    esac
done
