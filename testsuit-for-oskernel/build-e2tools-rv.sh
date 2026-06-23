#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG="$SCRIPT_DIR/sdcard-rv.img"
XZ="$SCRIPT_DIR/sdcard-rv.img.xz"
URL="https://github.com/oscomp/testsuits-for-oskernel/releases/download/pre-20250615/sdcard-rv.img.xz"
TESTCODE="$SCRIPT_DIR/testcode-rv"
DATA="$SCRIPT_DIR/data"
MKE2FS="$SCRIPT_DIR/bin/riscv64-mke2fs.static"
FAT32_IMAGE_NAME="${FAT32_IMAGE_NAME:-empty-fat32.img}"
FAT32_IMAGE="$(mktemp "${TMPDIR:-/tmp}/kernelx-empty-fat32.XXXXXX.img")"
trap 'rm -f "$FAT32_IMAGE"' EXIT

"$SCRIPT_DIR/ensure-mke2fs-tools.sh" riscv64
"$SCRIPT_DIR/prepare-fat32-image.sh" "$FAT32_IMAGE"

for file in "$DATA/passwd" "$DATA/group" "$DATA/config" "$MKE2FS"; do
    if [ ! -f "$file" ]; then
        echo "Error: missing required file: $file"
        exit 1
    fi
done

# Always start fresh to avoid leftover corruption
rm -f "$IMG"
if [ ! -f "$XZ" ]; then
    echo "Downloading sdcard-rv.img.xz..."
    wget -O "$XZ" "$URL"
fi
echo "Extracting sdcard-rv.img.xz..."
xz -dk -T 0 "$XZ"

# Prefer debugfs from Homebrew (macOS) or system PATH
DEBUGFS="${DEBUGFS:-debugfs}"
if ! command -v "$DEBUGFS" &> /dev/null; then
    DEBUGFS="/opt/homebrew/opt/e2fsprogs/sbin/debugfs"
fi
E2FSCK="${E2FSCK:-e2fsck}"
if ! command -v "$E2FSCK" &> /dev/null; then
    E2FSCK="/opt/homebrew/opt/e2fsprogs/sbin/e2fsck"
fi

echo "Writing testcode to $IMG using debugfs..."

# Build a debugfs command script
CMDS=$(mktemp)
trap 'rm -f "$CMDS" "$FAT32_IMAGE"' EXIT

file_mode() {
    local file="$1"
    local mode

    if ! mode="$(stat -c '%a' "$file" 2>/dev/null)"; then
        mode="$(stat -f '%Lp' "$file")"
    fi

    if [ -x "$file" ]; then
        printf '%03o' "$((8#$mode & ~1))"
    else
        printf '%03o' "$((8#$mode))"
    fi
}

set_file_metadata() {
    local image_path="$1"
    local mode="$2"

    echo "sif $image_path mode 0100$mode" >> "$CMDS"
    echo "sif $image_path uid 0" >> "$CMDS"
    echo "sif $image_path gid 0" >> "$CMDS"
}

# Create directory structure
echo "mkdir /testcode" >> "$CMDS"
echo "mkdir /bin"      >> "$CMDS"
echo "mkdir /etc"      >> "$CMDS"
echo "mkdir /lib"      >> "$CMDS"
echo "mkdir /lib/modules" >> "$CMDS"
echo "mkdir /lib/modules/6.0.0" >> "$CMDS"
echo "mkdir /lib64"    >> "$CMDS"
echo "mkdir /usr"      >> "$CMDS"
echo "mkdir /usr/lib64" >> "$CMDS"
echo "mkdir /dev"      >> "$CMDS"
echo "mkdir /dev/shm"  >> "$CMDS"

# Create subdirectories under /testcode
find "$TESTCODE" -type d | sort | while read -r dir; do
    rel="${dir#$TESTCODE}"
    if [ -n "$rel" ]; then
        echo "mkdir /testcode$rel" >> "$CMDS"
    fi
done

# Copy testcode files
find "$TESTCODE" -type f | sort | while read -r file; do
    rel="${file#$TESTCODE}"
    image_path="/testcode$rel"
    echo "write $file $image_path" >> "$CMDS"
    set_file_metadata "$image_path" "$(file_mode "$file")"
done

echo "write $FAT32_IMAGE /testcode/$FAT32_IMAGE_NAME" >> "$CMDS"
set_file_metadata "/testcode/$FAT32_IMAGE_NAME" "644"

# Copy tools and data files
echo "write $MKE2FS /bin/mke2fs.static" >> "$CMDS"
set_file_metadata "/bin/mke2fs.static" "755"

echo "write $DATA/passwd /etc/passwd" >> "$CMDS"
set_file_metadata "/etc/passwd" "644"
echo "write $DATA/group /etc/group" >> "$CMDS"
set_file_metadata "/etc/group" "644"
echo "write $DATA/config /lib/modules/6.0.0/config" >> "$CMDS"
set_file_metadata "/lib/modules/6.0.0/config" "644"

# Hard-link /bin/sh -> /glibc/busybox so shebang scripts work
echo "ln /glibc/busybox /bin/sh" >> "$CMDS"

echo "--- debugfs commands ---"
cat "$CMDS"
echo "--- end ---"

"$DEBUGFS" -w "$IMG" < "$CMDS" 2>&1

# Fix any checksum issues
"$E2FSCK" -y -f "$IMG" 2>&1 || true

# Verify
echo ""
echo "=== / ==="
"$DEBUGFS" -R 'ls -l /' "$IMG" 2>&1
echo "=== /testcode/ ==="
"$DEBUGFS" -R 'ls -l /testcode' "$IMG" 2>&1
echo "=== /bin/ ==="
"$DEBUGFS" -R 'ls -l /bin' "$IMG" 2>&1
echo "=== /bin/mke2fs.static ==="
"$DEBUGFS" -R 'stat /bin/mke2fs.static' "$IMG" 2>&1 | grep -E "Mode|User|Group|Size"
echo "=== /glibc/busybox ==="
"$DEBUGFS" -R 'stat /glibc/busybox' "$IMG" 2>&1 | grep -E "Size|Links"

echo ""
echo "Done. Image ready: $IMG"
