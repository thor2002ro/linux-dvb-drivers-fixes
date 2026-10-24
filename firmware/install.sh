#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
set -eu

[ "$#" -le 1 ] || { echo "Usage: $0 [--check|kernel-release]" >&2; exit 2; }
firmware_source=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Check every image before creating a directory or replacing installed files.
(cd "$firmware_source" && sha256sum --check --strict SHA256SUMS)
[ "${1:-}" != --check ] || exit 0

kernel_release=${1:-${KERNELRELEASE:-$(uname -r)}}
case "$kernel_release" in
    ''|.|..|*/*|-*) echo "Invalid kernel release: $kernel_release" >&2; exit 2 ;;
esac
destination="${INSTALL_MOD_PATH:-}/lib/firmware/updates/$kernel_release"
sudo_cmd=
[ "$(id -u)" -eq 0 ] || [ -n "${INSTALL_MOD_PATH:-}" ] || sudo_cmd=sudo

$sudo_cmd install -d "$destination"
while read -r checksum name; do
    $sudo_cmd install -m644 -- "$firmware_source/$name" "$destination/$name"
done < "$firmware_source/SHA256SUMS"
printf 'Installed DVB firmware overrides in %s\n' "$destination"
