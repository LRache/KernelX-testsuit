#!/usr/bin/env bash
set -e

OUT="$1"
SIZE="${FAT32_IMAGE_SIZE:-64M}"
LABEL="${FAT32_IMAGE_LABEL:-KXFAT32}"

if [ -z "$OUT" ]; then
    echo "Usage: $0 <output-image>" >&2
    exit 1
fi

if ! command -v mkfs.vfat >/dev/null 2>&1; then
    cat >&2 <<'EOF'
Error: mkfs.vfat is required to create the empty FAT32 image.

Install dosfstools, for example:
  sudo apt install dosfstools
EOF
    exit 1
fi

mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
truncate -s "$SIZE" "$OUT"
mkfs.vfat -F 32 -n "$LABEL" "$OUT" >/dev/null
chmod 0644 "$OUT"
