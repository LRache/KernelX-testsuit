set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG="$SCRIPT_DIR/sdcard-rv.img"
XZ="$SCRIPT_DIR/sdcard-rv.img.xz"
URL="https://github.com/oscomp/testsuits-for-oskernel/releases/download/pre-20250615/sdcard-rv.img.xz"
TESTCODE="$SCRIPT_DIR/testcode"
DATA_DIR="$SCRIPT_DIR/data"

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

link_in_image() {
    local source_path="$1"
    local link_path="$2"

    if [ ! -e "$source_path" ]; then
        echo "Missing source for hard link: $source_path"
        exit 1
    fi

    $SUDO rm -f "$link_path"
    $SUDO ln "$source_path" "$link_path"
}

echo "Preparing /bin busybox links in image..."
$SUDO mkdir -p "$MOUNT_DIR/bin"
for tool in sh cp ls mkdir ln rm chmod; do
    link_in_image "$MOUNT_DIR/glibc/busybox" "$MOUNT_DIR/bin/$tool"
done

echo "Preparing runtime library links in image..."
$SUDO mkdir -p "$MOUNT_DIR/lib"
link_in_image "$MOUNT_DIR/glibc/lib/ld-linux-riscv64-lp64d.so.1" \
    "$MOUNT_DIR/lib/ld-linux-riscv64-lp64d.so.1"
link_in_image "$MOUNT_DIR/glibc/lib/libc.so.6" "$MOUNT_DIR/lib/libc.so.6"
link_in_image "$MOUNT_DIR/glibc/lib/libm.so.6" "$MOUNT_DIR/lib/libm.so.6"
link_in_image "$MOUNT_DIR/musl/lib/libc.so" "$MOUNT_DIR/lib/ld-musl-riscv64-sf.so.1"
link_in_image "$MOUNT_DIR/musl/lib/libc.so" \
    "$MOUNT_DIR/lib/.ld-linux-riscv64-lp64d.so.1.musl"

echo "Copying testcode to image..."
$SUDO cp -r "$TESTCODE" "$MOUNT_DIR/"
$SUDO chown -R root:root "$MOUNT_DIR/testcode"

$SUDO find "$MOUNT_DIR" -type f -executable -exec chmod o-x {} +
$SUDO find -L "$MOUNT_DIR/bin" -maxdepth 1 -mindepth 1 -type f -exec chmod a+x {} +

$SUDO mkdir -p "$MOUNT_DIR/etc"
$SUDO cp "$DATA_DIR/passwd" "$MOUNT_DIR/etc/"
$SUDO cp "$DATA_DIR/group" "$MOUNT_DIR/etc/"

$SUDO mkdir -p "$MOUNT_DIR/lib/modules/5.0.0"
$SUDO cp "$DATA_DIR/config" "$MOUNT_DIR/lib/modules/5.0.0/config"

$SUDO mkdir -p "$MOUNT_DIR/bin"
$SUDO cp "bin/mkfs.ext2" "$MOUNT_DIR/bin"

$SUDO chown -R $USER:$USER "$MOUNT_DIR"

echo "=== sdcard-rv/ ==="
ls "$MOUNT_DIR" -al
echo "=== sdcard-rv/testcode/ ==="
ls "$MOUNT_DIR/testcode" -al

$SUDO umount "$MOUNT_DIR"

echo "Done. testcode has been written to $IMG."
