#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later

set -euxo pipefail

command -v dpkg-parsechangelog >/dev/null 2>&1 || exit 1

[[ $(dpkg-parsechangelog -SDistribution) = 'UNRELEASED' ]] && exit 0
VERSION=$(dpkg-parsechangelog -SVersion)

command -v gh >/dev/null 2>&1 || exit 1

PACKAGES=(
    dist/mkosi-debinit_"${VERSION}"_all.deb
    dist/mkosi-debinit-core_"${VERSION}"_all.deb
)

for package in "${PACKAGES[@]}"; do
    [[ -f $package ]] || exit 1
done

git tag v"${VERSION}"
git push orgin v"${VERSION}"

dpkg-parsechangelog -SChanges | tail -n+4 | pandoc -s -o dist/release-notes.md

gh release create v"${VERSION}" \
    --generate-notes \
    --latest \
    --draft \
    --notes-file=dist/release-notes.md \
    "${PACKAGES[@]}"
