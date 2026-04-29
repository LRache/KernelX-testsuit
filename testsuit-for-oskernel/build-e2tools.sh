#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG="${IMG:-$SCRIPT_DIR/sdcard-rv.img}"
XZ="${XZ:-$SCRIPT_DIR/sdcard-rv.img.xz}"
URL="https://github.com/oscomp/testsuits-for-oskernel/releases/download/pre-20250615/sdcard-rv.img.xz"
TESTCODE="$SCRIPT_DIR/testcode"
DATA="$SCRIPT_DIR/data"

if [ ! -f "$IMG" ]; then
    if [ ! -f "$XZ" ]; then
        echo "Downloading sdcard-rv.img.xz..."
        wget -O "$XZ" "$URL"
    fi
    echo "Extracting sdcard-rv.img.xz..."
    mkdir -p "$(dirname "$IMG")"
    xz -dc "$XZ" > "$IMG"
fi

check_e2tools() {
    for cmd in e2cp e2ln e2ls e2mkdir e2rm; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: $cmd is not installed. Install with: apt install e2tools"
            exit 1
        fi
    done
}

e2_exists() {
    e2ls "$IMG:$1" >/dev/null 2>&1
}

e2mkdir_p() {
    local dir="$1"
    local mode="${2:-0755}"
    local current=""
    local part
    local -a parts

    dir="${dir#/}"
    IFS='/' read -r -a parts <<< "$dir"
    for part in "${parts[@]}"; do
        [ -n "$part" ] || continue
        current="$current/$part"
        if ! e2_exists "$current"; then
            e2mkdir -O 0 -G 0 -P "$mode" "$IMG:$current"
        fi
    done
}

e2rm_if_exists() {
    local path="$1"

    if e2_exists "$path"; then
        e2rm -r "$IMG:$path"
    fi
}

e2cp_file() {
    local src="$1"
    local dest_dir="$2"
    local mode="$3"
    local dest_path="${dest_dir%/}/$(basename "$src")"

    e2mkdir_p "$dest_dir"
    e2rm_if_exists "$dest_path"
    e2cp -O 0 -G 0 -P "$mode" "$src" "$IMG:$dest_dir/"
}

check_e2tools

for file in "$DATA/passwd" "$DATA/group" "$DATA/config"; do
    if [ ! -f "$file" ]; then
        echo "Error: missing required file: $file"
        exit 1
    fi
done

echo "Writing testcode to $IMG using e2tools..."

e2rm_if_exists /testcode
e2mkdir_p /testcode

find "$TESTCODE" -type d -print | sort | while read -r dir; do
    rel="${dir#$TESTCODE}"
    [ -n "$rel" ] || continue
    e2mkdir_p "/testcode$rel"
done

find "$TESTCODE" -type f | while read -r file; do
    rel="${file#$TESTCODE}"
    dest_dir="/testcode$(dirname "$rel")"
    mode=0644
    if [ "${file##*.}" = "sh" ]; then
        mode=0755
    fi
    e2cp_file "$file" "$dest_dir" "$mode"
done

e2mkdir_p /etc
e2cp_file "$DATA/passwd" /etc 0644
e2cp_file "$DATA/group" /etc 0644

e2mkdir_p /lib/modules/5.0.0
e2cp_file "$DATA/config" /lib/modules/5.0.0 0644

echo "=== sdcard-rv/ ==="
e2ls -la "$IMG:/"
echo "=== sdcard-rv/testcode/ ==="
e2ls -la "$IMG:/testcode/"

echo "Done. testcode has been written to $IMG."
