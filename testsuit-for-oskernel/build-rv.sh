set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG="$SCRIPT_DIR/sdcard-rv.img"
XZ="$SCRIPT_DIR/sdcard-rv.img.xz"
URL="https://github.com/oscomp/testsuits-for-oskernel/releases/download/pre-20250615/sdcard-rv.img.xz"
TESTCODE="$SCRIPT_DIR/testcode-rv"
DATA="$SCRIPT_DIR/data"

for file in "$DATA/passwd" "$DATA/group" "$DATA/config"; do
    if [ ! -f "$file" ]; then
        echo "Error: missing required file: $file"
        exit 1
    fi
done

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
$SUDO mkdir -p "$MOUNT_DIR/testcode"
$SUDO cp -r $TESTCODE/* "$MOUNT_DIR/testcode/"
$SUDO chown -R root:root "$MOUNT_DIR/testcode"

$SUDO find "$MOUNT_DIR" -type f -executable -exec chmod o-x {} +

$SUDO mkdir -p "$MOUNT_DIR/bin"
$SUDO cp ./bin/riscv64-mke2fs.static "$MOUNT_DIR/bin/mke2fs.static"
$SUDO chmod 755 "$MOUNT_DIR/bin/mke2fs.static"

$SUDO mkdir -p "$MOUNT_DIR/etc"
$SUDO cp "$DATA/passwd" "$MOUNT_DIR/etc/passwd"
$SUDO cp "$DATA/group" "$MOUNT_DIR/etc/group"
$SUDO chown root:root "$MOUNT_DIR/etc/passwd" "$MOUNT_DIR/etc/group"
$SUDO chmod 0644 "$MOUNT_DIR/etc/passwd" "$MOUNT_DIR/etc/group"

$SUDO mkdir -p "$MOUNT_DIR/lib/modules/6.0.0"
$SUDO cp "$DATA/config" "$MOUNT_DIR/lib/modules/6.0.0/config"
$SUDO chown root:root "$MOUNT_DIR/lib/modules/6.0.0/config"
$SUDO chmod 0644 "$MOUNT_DIR/lib/modules/6.0.0/config"

echo "=== sdcard-rv/ ==="
ls "$MOUNT_DIR" -al
echo "=== sdcard-rv/testcode/ ==="
ls "$MOUNT_DIR/testcode" -al

$SUDO umount "$MOUNT_DIR"

echo "Done. testcode has been written to $IMG."
