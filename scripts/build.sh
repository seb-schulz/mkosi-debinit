#!/usr/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --no-install-recommends -y build-essential devscripts debhelper pandoc

dpkg-buildpackage -us -uc
mkdir -p dist
cp ../mkosi-debinit*.deb dist
cp ../mkosi-debinit*.buildinfo dist
cp ../mkosi-debinit*.changes dist
cp ../mkosi-debinit*.tar* dist
cp ../mkosi-debinit*.dsc dist
