#!/usr/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later

echo "::group::Prepare testsuite"
set -euxo pipefail

[[ -f /etc/machine-id ]] && MKOSI_CACHE=${MKOSI_CACHE:-"/var/tmp/mkosi-debinit.$(</etc/machine-id).cache"} || MKOSI_CACHE=${MKOSI_CACHE:-"/var/tmp/mkosi-debinit.cache"}
mkdir -p "$MKOSI_CACHE"

# shellcheck disable=SC2206
PHASES=(${@:-INITRD_BASIC})
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
        INITRD_BASIC)
            next-group "Prepare initrd basic testsuite"
            command -v mkosi >/dev/null 2>&1 || exit 1
            command -v kvm >/dev/null 2>&1 || exit 1
            mkosi --version

            TESTDIR=$(mktemp -d)
            CLEANUP+=("$TESTDIR")
            INITRD=$TESTDIR/initrd.img

            next-group "Build initrd file"

            # shellcheck disable=SC2012
            ./update-mkosi-debinit "$INITRD" "$(ls /usr/lib/modules/ | sort | tail -n1)"

            [[ -n "${GITHUB_STEP_SUMMARY:-}" ]] && echo "# Details about created initrd file" | tee -a "$GITHUB_STEP_SUMMARY"
            stat "$INITRD" | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"

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
                --repart-dir=tests/fixtures/test-image-definitions \
                --extra-search-path=/usr/sbin \
                --output-dir="$TESTDIR" \
                --output="$ROOTFS" \
                build

            next-group "Sanity check if the initrd is bootable"
            timeout --foreground -k 10 5m \
                kvm -m 512 -smp "$(nproc)" -nographic \
                    -initrd "$INITRD" \
                    -kernel "$TESTDIR"/$ROOTFS.vmlinuz \
                    -append "rd.systemd.unit=systemd-poweroff.service rd.debug $SYSTEMD_LOG_OPTS console=ttyS0"

            next-group "Get UUID for next test"
            UUID=$(/sbin/sfdisk -J "$TESTDIR"/$ROOTFS | jq -r '.partitiontable.partitions[1].uuid|ascii_downcase')
            /sbin/sfdisk -J "$TESTDIR"/$ROOTFS

            next-group "Boot the initrd with an OS image"
            timeout --foreground -k 10 5m \
                kvm -m 1024 -smp "$(nproc)" -nographic \
                    -initrd "$INITRD" \
                    -kernel "$TESTDIR"/$ROOTFS.vmlinuz \
                    -drive "if=virtio,index=0,format=raw,cache=unsafe,file=$TESTDIR/$ROOTFS" \
                    -append "root=PARTUUID=$UUID rd.debug $SYSTEMD_LOG_OPTS console=ttyS0 systemd.unit=systemd-poweroff.service systemd.default_timeout_start_sec=240"

            [[ -n "${GITHUB_STEP_SUMMARY:-}" ]] && echo "# List all files" | tee -a "$GITHUB_STEP_SUMMARY"

            # shellcheck disable=SC2012
            ls -lh "$TESTDIR" | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
            ;;
        MKOSI_AND_KVM_CHECK)
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
                --repart-dir=tests/fixtures/test-image-definitions \
                --output-dir="$TESTDIR" \
                --output="$ROOTFS" \
                build

            next-group "Sanity check if the initrd is bootable"
            timeout --foreground -k 10 5m \
                kvm -m 512 -smp "$(nproc)" -nographic \
                    -initrd "$TESTDIR"/$ROOTFS.initrd \
                    -kernel "$TESTDIR"/$ROOTFS.vmlinuz \
                    -append "rd.systemd.unit=systemd-poweroff.service rd.debug $SYSTEMD_LOG_OPTS console=ttyS0"

            next-group "Show all kernel modules"
            file "$TESTDIR"/$ROOTFS.initrd
            zstdcat "$TESTDIR"/$ROOTFS.initrd | cpio -t || true
            sleep 1

            next-group "Get UUID for next test"
            UUID=$(/sbin/sfdisk -J "$TESTDIR"/$ROOTFS | jq -r '.partitiontable.partitions[1].uuid|ascii_downcase')
            /sbin/sfdisk -J "$TESTDIR"/$ROOTFS

            next-group "Boot the initrd with an OS image"
            timeout --foreground -k 10 5m \
                kvm -m 1024 -smp "$(nproc)" -nographic \
                    -initrd "$TESTDIR"/$ROOTFS.initrd \
                    -kernel "$TESTDIR"/$ROOTFS.vmlinuz \
                    -drive "if=virtio,index=0,format=raw,cache=unsafe,file=$TESTDIR/$ROOTFS" \
                    -append "root=PARTUUID=$UUID rd.debug $SYSTEMD_LOG_OPTS console=ttyS0 systemd.unit=systemd-poweroff.service systemd.default_timeout_start_sec=240"

            [[ -n "${GITHUB_STEP_SUMMARY:-}" ]] && echo "# List all files" | tee -a "$GITHUB_STEP_SUMMARY"

            # shellcheck disable=SC2012
            ls -lh "$TESTDIR" | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
            ;;
        *)
            echo >&2 "Unknown phase '$phase'"
            exit 1
    esac
done
