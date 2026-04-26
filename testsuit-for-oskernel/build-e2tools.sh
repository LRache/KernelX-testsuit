#!/usr/bin/env bash

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
    xz -dk -T 0 "$XZ"
fi

for tool in e2cp e2mkdir e2ls e2ln e2rm e2chmod; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: e2tools is not fully installed. Missing: $tool"
        echo "Install with: apt install e2tools"
        exit 1
    fi
done

ensure_dir() {
    e2mkdir "$IMG:$1" 2>/dev/null || true
}

remove_path() {
    e2rm "$IMG:$1" 2>/dev/null || true
}

path_exists() {
    e2ls "$IMG:$1" >/dev/null 2>&1
}

copy_file() {
    local src="$1"
    local dest_dir="$2"
    local dest_path="$dest_dir/$(basename "$src")"

    remove_path "$dest_path"
    e2cp -p "$src" "$IMG:$dest_dir/"
}

make_hardlink() {
    local source_path="$1"
    local link_path="$2"

    if path_exists "$link_path"; then
        remove_path "$link_path"
    fi

    if path_exists "$link_path"; then
        echo "Keeping existing $link_path"
        return 0
    fi

    e2ln -f "$IMG:$source_path" "$link_path"
}

echo "Writing testcode to $IMG using e2tools..."

ensure_dir "/testcode"

find "$TESTCODE" -type d | while read -r dir; do
    rel="${dir#$TESTCODE}"
    if [ -n "$rel" ]; then
        ensure_dir "/testcode$rel"
    fi
done

find "$TESTCODE" -type f | while read -r file; do
    rel="${file#$TESTCODE}"
    dest_dir="/testcode$(dirname "$rel")"
    copy_file "$file" "$dest_dir"
done

echo "Preparing /bin busybox links in image..."
ensure_dir "/bin"
for tool in sh cp ls mkdir ln rm chmod; do
    make_hardlink "/glibc/busybox" "/bin/$tool"
done

echo "Adding execute permission for all users on /bin files..."
for tool in sh cp ls mkdir ln rm chmod; do
    e2chmod 755 "$IMG:/bin/$tool"
done

echo "Preparing runtime library links in image..."
ensure_dir "/lib"
make_hardlink "/glibc/lib/ld-linux-riscv64-lp64d.so.1" \
    "/lib/ld-linux-riscv64-lp64d.so.1"
make_hardlink "/glibc/lib/libc.so.6" "/lib/libc.so.6"
make_hardlink "/glibc/lib/libm.so.6" "/lib/libm.so.6"
make_hardlink "/musl/lib/libc.so" "/lib/ld-musl-riscv64-sf.so.1"
make_hardlink "/musl/lib/libc.so" "/lib/.ld-linux-riscv64-lp64d.so.1.musl"

echo "Copying config files to image..."
ensure_dir "/etc"
copy_file "$DATA_DIR/passwd" "/etc"
copy_file "$DATA_DIR/group" "/etc"

ensure_dir "/lib/modules"
ensure_dir "/lib/modules/5.0.0"
remove_path "/lib/modules/5.0.0/config"
e2cp -p "$DATA_DIR/config" "$IMG:/lib/modules/5.0.0/config"

echo "=== / ==="
e2ls -la "$IMG:/"
echo "=== /testcode/ ==="
e2ls -la "$IMG:/testcode/"

echo "Done. testcode has been written to $IMG."
