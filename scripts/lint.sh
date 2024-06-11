#!/usr/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later

set -euxo pipefail

# shellcheck disable=SC2206
PHASES=(${@:-SHELL DPKG})

for phase in "${PHASES[@]}"; do
    case "$phase" in
        SHELL)
            shellcheck update-mkosi-debinit scripts/*.sh
            ;;
        DPKG)
            # XXX: Allow running as root in rootless container and CI
            # XXX: pandoc >= 3.2 fixes 'groff-message' tag on man pages
            lintian \
                --allow-root \
                --suppress-tags groff-message \
                ./dist/*.deb
            ;;
        *)
            echo >&2 "Unknown phase '$phase'"
            exit 1
    esac
done
