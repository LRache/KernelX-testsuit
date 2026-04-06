set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG="$SCRIPT_DIR/sdcard-rv.img"
XZ="$SCRIPT_DIR/sdcard-rv.img.xz"
URL="https://github.com/oscomp/testsuits-for-oskernel/releases/download/pre-20250615/sdcard-rv.img.xz"
TESTCODE="$SCRIPT_DIR/testcode"

if [ ! -f "$IMG" ]; then
    if [ ! -f "$XZ" ]; then
        echo "Downloading sdcard-rv.img.xz..."
        wget -O "$XZ" "$URL"
    fi
    echo "Extracting sdcard-rv.img.xz..."
    xz -dk -T 0 "$XZ"
fi

# Check e2tools availability
if ! command -v e2cp &> /dev/null; then
    echo "Error: e2tools is not installed. Install with: apt install e2tools"
    exit 1
fi

echo "Writing testcode to $IMG using e2tools..."

# Create /testcode directory in image
e2mkdir "$IMG:/testcode"

# Copy testcode files into image
find "$TESTCODE" -type d | while read -r dir; do
    rel="${dir#$TESTCODE}"
    if [ -n "$rel" ]; then
        e2mkdir "$IMG:/testcode$rel"
    fi
done

find "$TESTCODE" -type f | while read -r file; do
    rel="${file#$TESTCODE}"
    dest_dir="/testcode$(dirname "$rel")"
    e2cp -p "$file" "$IMG:$dest_dir/"
done

# Create /etc and copy passwd
e2mkdir "$IMG:/etc"
e2cp -p "./data/passwd" "$IMG:/etc/"

# List contents to verify
echo "=== / ==="
e2ls -la "$IMG:/"
echo "=== /testcode/ ==="
e2ls -la "$IMG:/testcode/"

echo "Done. testcode has been written to $IMG."
