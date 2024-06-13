#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later

set -euxo pipefail

REPO=repo
PACKAGES=(
    mkosi-debinit
    mkosi-debinit-core
)

mkdir -p "$REPO"/pool
for tag in $(gh release list --exclude-drafts --exclude-pre-releases --json name | jq -r '.[]|.name'); do
    for package in "${PACKAGES[@]}"; do
        package_path=${package}_${tag#v}_all.deb
        curl https://github.com/seb-schulz/mkosi-debinit/releases/download/$tag/"$package_path" -L -o "$REPO"/pool/"$package_path"
    done
done

cPWD=$PWD
function finish {
    cd "$cPWD"
}
trap finish EXIT ERR

cd "$REPO"/
mkdir -p dists/testing/main/binary-{all,amd64}

dpkg-scanpackages pool > dists/testing/main/binary-all/Packages
xz -9 <dists/testing/main/binary-all/Packages >dists/testing/main/binary-all/Packages.xz

touch dists/testing/main/binary-amd64/Packages
xz -9 <dists/testing/main/binary-amd64/Packages >dists/testing/main/binary-amd64/Packages.xz

do_hash() {
    HASH_NAME=$1
    HASH_CMD=$2
    echo "${HASH_NAME}:"
    # shellcheck disable=SC2044
    for f in $(find . -type f); do
        f=$(echo "$f" | cut -c3-) # remove ./ prefix
        if [ "$f" = "Release" ]; then
            continue
        fi
        echo " $(${HASH_CMD} "$f"  | cut -d" " -f1) $(wc -c "$f")"
    done
}

cd dists/testing/

tee Release <<EOF
Origin: mkosi-debinit Repository
Label: mkosi-debinit
Suite: testing
Codename: testing
Version: 1.0
Architectures: amd64 all
Components: main
Description: mkosi-debinit repository
Date: $(date -Ru)
EOF
do_hash "MD5Sum" "md5sum" | tee -a Release
do_hash "SHA1" "sha1sum" | tee -a Release
do_hash "SHA256" "sha256sum" | tee -a Release
