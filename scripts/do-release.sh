#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later

set -euxo pipefail

command -v dpkg-parsechangelog >/dev/null 2>&1 || exit 1

[[ $(dpkg-parsechangelog -SDistribution) = 'UNRELEASED' ]] && exit 0
VERSION=$(dpkg-parsechangelog -SVersion)

command -v gh >/dev/null 2>&1 || exit 1

PACKAGES=(
    mkosi-debinit
    mkosi-debinit-core
)

files=()
for package in "${PACKAGES[@]}"; do
    [[ -f dist/${package}_"${VERSION}"_all.deb ]] || exit 1
    files+=("dist/${package}_${VERSION}_all.deb")
done

git tag v"${VERSION}"
git push origin v"${VERSION}"

dpkg-parsechangelog -SChanges | tail -n+4 | pandoc -s -o dist/release-notes.md

gh release create v"${VERSION}" \
    --generate-notes \
    --latest \
    --draft \
    --notes-file=dist/release-notes.md \
    "${files[@]}"
