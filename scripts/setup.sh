#!/usr/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later

set -euxo pipefail

[[ $(id -u) != 0 ]] && SUDO=sudo || SUDO=
$SUDO apt-get update

lint_packages=(lintian shellcheck)
build_packages=(build-essential devscripts debhelper pandoc fakeroot)
tests_packages=(mkosi qemu-system-x86 kmod jq systemd-boot cpio zstd systemd-ukify dosfstools mtools file linux-image-amd64)

[[ ${ONLY_BUILD:-} = "1" ]] && $SUDO apt-get install --no-install-recommends -y "${build_packages[@]}"
[[ -z ${ONLY_BUILD:-} ]] && $SUDO apt-get install --no-install-recommends -y "${lint_packages[@]}" "${build_packages[@]}" "${tests_packages[@]}"

if [[ ${WITH_GH:-} = "1" ]]; then
    (type -p wget >/dev/null || (apt update && apt-get install wget -y))

    mkdir -p /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    apt update
    apt install gh -y
fi

exit 0
