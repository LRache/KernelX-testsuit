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
    xz -dk "$XZ"
fi

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
fi

MOUNT_DIR="$SCRIPT_DIR/sdcard-rv"
mkdir -p "$MOUNT_DIR"
echo "Mounting $IMG to $MOUNT_DIR..."
$SUDO mount -o loop "$IMG" "$MOUNT_DIR"

$SUDO chown -R $USER:$USER "$MOUNT_DIR"

echo "Copying testcode to image..."
$SUDO cp -r "$TESTCODE" "$MOUNT_DIR/"
$SUDO chown -R root:root "$MOUNT_DIR/testcode"

$SUDO find "$MOUNT_DIR" -type f -executable -exec chmod o-x {} +

$SUDO mkdir -p "$MOUNT_DIR/etc"
$SUDO cp ./data/passwd "$MOUNT_DIR/etc/"

echo "=== sdcard-rv/ ==="
ls "$MOUNT_DIR" -al
echo "=== sdcard-rv/testcode/ ==="
ls "$MOUNT_DIR/testcode" -al

$SUDO umount "$MOUNT_DIR"

echo "Done. testcode has been written to $IMG."
