set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG="$SCRIPT_DIR/sdcard-rv.img"
XZ="$SCRIPT_DIR/sdcard-rv.img.xz"
REPO="LRache/KernelX-testsuit"

if [ ! -f "$IMG" ]; then
    echo "Error: $IMG not found. Run build.sh first."
    exit 1
fi

TAG="${1:-$(date +%Y%m%d)}"

echo "Compressing $IMG..."
xz -fk "$IMG"
echo "Created $XZ"

echo "Creating release $TAG on $REPO..."
gh release create "$TAG" "$XZ" \
    --repo "$REPO" \
    --title "Release $TAG" \
    --notes "sdcard-rv.img with testcode (built on $(date +%Y-%m-%d))"

echo "Done. Release $TAG published."
