#!/usr/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later

echo "::group::Prepare testsuite"
set -euxo pipefail

command -v mkosi >/dev/null 2>&1 || exit 1
command -v kvm >/dev/null 2>&1 || exit 1

MKOSI_CACHE=${MKOSI_CACHE:-"/var/tmp/mkosi-debinit.$(</etc/machine-id).cache"}
mkdir -p "$MKOSI_CACHE"

mkosi --version

# shellcheck disable=SC2206
PHASES=(${@:-DEPS INITRD_BASIC})
SYSTEMD_LOG_OPTS="systemd.log_target=console udev.log_level=info systemd.default_standard_output=journal+console systemd.status_unit_format=name"

CLEANUP=()

function finish {
    # find "${CLEANUP[@]}" -type f || true
    sudo rm -rf "${CLEANUP[@]}"
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

next-group "Start testsuite"
for phase in "${PHASES[@]}"; do
    case "$phase" in
        DEPS)
            echo "Installing necessary dependencies"
            ;;
        INITRD_BASIC)
            TESTDIR=$(mktemp -d)
            CLEANUP+=("$TESTDIR")
            INITRD=$TESTDIR/initrd.img

            next-group "Build tools image"
            mkosi \
                --incremental=yes \
                --cache-dir="$MKOSI_CACHE" \
                --distribution=debian \
                --release=testing \
                --include=mkosi-tools \
                --package=linux-image-amd64 \
                --extra-search-path=/usr/sbin \
                --directory='' \
                --format=directory \
                --output-dir="$TESTDIR" \
                --output=mkosi.tools \
                build

            next-group "Build initrd file"
            ROOTFS="$TESTDIR"/mkosi.tools ./update-mkosi-debinit "$INITRD"

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
                --package=linux-image-amd64 \
                --tools-tree="$TESTDIR"/mkosi.tools \
                --output-dir="$TESTDIR" \
                --output="$ROOTFS" \
                build

            next-group "Sanity check if the initrd is bootable"
            timeout --foreground -k 10 5m \
                kvm -m 512 -smp "$(nproc)" -nographic \
                    -initrd "$INITRD" \
                    -kernel "$TESTDIR"/$ROOTFS.vmlinuz \
                    -append "rd.systemd.unit=systemd-poweroff.service rd.debug $SYSTEMD_LOG_OPTS console=ttyS0"

            next-group "Boot the initrd with an OS image"
            timeout --foreground -k 10 5m \
                kvm -m 1024 -smp "$(nproc)" -nographic \
                    -initrd "$INITRD" \
                    -kernel "$TESTDIR"/$ROOTFS.vmlinuz \
                    -drive "format=raw,cache=unsafe,file=$TESTDIR/$ROOTFS" \
                    -append "root=LABEL=root-x86-64 rd.debug $SYSTEMD_LOG_OPTS console=ttyS0 systemd.unit=systemd-poweroff.service systemd.default_timeout_start_sec=240"

            next-group "Info about built artifacts"
            ls -lah "$TESTDIR"
            stat "$INITRD"
            ;;
        *)
            echo >&2 "Unknown phase '$phase'"
            exit 1
    esac
done
next-group "Clean up"
