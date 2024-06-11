#!/usr/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later

set -euxo pipefail

[[ $(id -u) != 0 ]] && SUDO=sudo || SUDO=
$SUDO apt-get update

# shellcheck disable=SC2206
JOBS=(${@:-tests build lint})

for phase in "${JOBS[@]}"; do
    case "$phase" in
        lint)
            $SUDO apt-get install --no-install-recommends -y lintian shellcheck
            ;;
        build)
            $SUDO apt-get install --no-install-recommends -y build-essential devscripts debhelper pandoc fakeroot
            ;;
        tests)
            $SUDO apt-get install --no-install-recommends -y mkosi qemu-system-x86 kmod jq systemd-boot cpio zstd systemd-ukify dosfstools mtools file linux-image-amd64
            ;;
        *)
            echo >&2 "Unknown phase '$phase'"
            exit 1
    esac
done
