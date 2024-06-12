#!/usr/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later

set -euxo pipefail

[[ $(id -u) != 0 ]] && SUDO=sudo || SUDO=
$SUDO apt-get update

lint_packages=(lintian shellcheck)
build_packages=(build-essential devscripts debhelper pandoc fakeroot)
tests_packages=(mkosi qemu-system-x86 kmod jq systemd-boot cpio zstd systemd-ukify dosfstools mtools file linux-image-amd64)

$SUDO apt-get install --no-install-recommends -y "${lint_packages[@]}" "${build_packages[@]}" "${tests_packages[@]}"
