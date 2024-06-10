#!/usr/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later

set -euxo pipefail

[[ $(id -u) != 0 ]] && SUDO=sudo || SUDO=

export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update
$SUDO apt-get install --no-install-recommends -y build-essential devscripts debhelper pandoc fakeroot

dpkg-buildpackage -us -uc
mkdir -p dist
cp ../mkosi-debinit*.deb dist
cp ../mkosi-debinit*.buildinfo dist
cp ../mkosi-debinit*.changes dist
cp ../mkosi-debinit*.tar* dist
cp ../mkosi-debinit*.dsc dist
