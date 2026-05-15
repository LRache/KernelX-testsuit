set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG="$SCRIPT_DIR/sdcard-la.img"
XZ="$SCRIPT_DIR/sdcard-la.img.xz"
URL="https://github.com/oscomp/testsuits-for-oskernel/releases/download/pre-20250615/sdcard-la.img.xz"
TESTCODE="$SCRIPT_DIR/testcode-la"

# Always start fresh to avoid leftover corruption
rm -f "$IMG"
if [ ! -f "$XZ" ]; then
    echo "Downloading sdcard-la.img.xz..."
    wget -O "$XZ" "$URL"
fi
echo "Extracting sdcard-la.img.xz..."
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

# Create directory structure
echo "mkdir /testcode" >> "$CMDS"
echo "mkdir /bin"      >> "$CMDS"
echo "mkdir /etc"      >> "$CMDS"
echo "mkdir /lib"      >> "$CMDS"
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
    echo "write $file /testcode$rel" >> "$CMDS"
done

# Copy /etc/passwd
echo "write $SCRIPT_DIR/data/passwd /etc/passwd" >> "$CMDS"

# Hard-link /bin/sh -> /glibc/busybox so shebang scripts work
echo "ln /glibc/busybox /bin/sh" >> "$CMDS"

echo "--- debugfs commands ---"
cat "$CMDS"
echo "--- end ---"

"$DEBUGFS" -w "$IMG" < "$CMDS" 2>&1
rm -f "$CMDS"

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
echo "=== /glibc/busybox ==="
"$DEBUGFS" -R 'stat /glibc/busybox' "$IMG" 2>&1 | grep -E "Size|Links"

echo ""
echo "Done. Image ready: $IMG"
