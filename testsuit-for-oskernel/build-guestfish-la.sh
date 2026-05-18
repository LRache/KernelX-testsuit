#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG="${IMG:-$SCRIPT_DIR/sdcard-la.img}"
XZ="${XZ:-$SCRIPT_DIR/sdcard-la.img.xz}"
URL="https://github.com/oscomp/testsuits-for-oskernel/releases/download/pre-20250615/sdcard-la.img.xz"
TESTCODE="${TESTCODE:-$SCRIPT_DIR/testcode-la}"
DATA="$SCRIPT_DIR/data"
MKE2FS="${MKE2FS:-$SCRIPT_DIR/bin/loongarch64-mke2fs.static}"
ROOT_DEV="${ROOT_DEV:-/dev/sda}"

if [ "$MKE2FS" = "$SCRIPT_DIR/bin/loongarch64-mke2fs.static" ]; then
    "$SCRIPT_DIR/ensure-mke2fs-tools.sh" loongarch64
fi

has_supermin_kernel() {
    local kernel

    if [ -n "${SUPERMIN_KERNEL:-}" ]; then
        [ -f "$SUPERMIN_KERNEL" ] || return 1
        if [ -n "${SUPERMIN_MODULES:-}" ]; then
            [ -d "$SUPERMIN_MODULES" ] || return 1
        fi
        return 0
    fi

    for kernel in /boot/vmlinuz* /boot/bzImage* /lib/modules/*/vmlinuz; do
        [ -e "$kernel" ] && return 0
    done

    return 1
}

check_guestfish() {
    if ! command -v guestfish >/dev/null 2>&1; then
        echo "Error: guestfish is not installed. Install with: apt install libguestfs-tools"
        exit 1
    fi

    if ! command -v supermin >/dev/null 2>&1; then
        echo "Error: supermin is not installed. Install with: apt install supermin"
        exit 1
    fi

    if ! has_supermin_kernel; then
        cat >&2 <<'EOF'
Error: libguestfs/supermin cannot find a host kernel for guestfish.

Install a kernel package for the host environment, for example on Ubuntu:
  sudo apt install linux-image-generic

Alternatively, point supermin at a custom kernel and modules directory:
  export SUPERMIN_KERNEL=/boot/vmlinuz-...
  export SUPERMIN_MODULES=/lib/modules/...
EOF
        exit 1
    fi
}

check_guestfish

if [ ! -d "$TESTCODE" ]; then
    echo "Error: missing required directory: $TESTCODE"
    exit 1
fi

for file in "$DATA/passwd" "$DATA/group" "$DATA/config" "$MKE2FS"; do
    if [ ! -f "$file" ]; then
        echo "Error: missing required file: $file"
        exit 1
    fi
done

if [ ! -f "$IMG" ]; then
    if [ ! -f "$XZ" ]; then
        echo "Downloading sdcard-la.img.xz..."
        wget -O "$XZ" "$URL"
    fi
    echo "Extracting sdcard-la.img.xz..."
    mkdir -p "$(dirname "$IMG")"
    xz -dc "$XZ" > "$IMG"
fi

export LIBGUESTFS_BACKEND="${LIBGUESTFS_BACKEND:-direct}"
export TMPDIR="${TMPDIR:-/tmp}"

gf_quote() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '"%s"' "$value"
}

file_mode() {
    local file="$1"
    local mode

    if ! mode="$(stat -c '%a' "$file" 2>/dev/null)"; then
        mode="$(stat -f '%Lp' "$file")"
    fi

    if [ -x "$file" ]; then
        printf '%03o' "$((8#$mode & 0777 & ~1))"
    else
        printf '%03o' "$((8#$mode & 0777))"
    fi
}

set_guest_metadata() {
    local guest_path="$1"
    local mode="$2"

    echo "chown 0 0 $(gf_quote "$guest_path")"
    echo "chmod 0$mode $(gf_quote "$guest_path")"
}

commands="$(mktemp)"
cleanup() {
    rm -f "$commands"
}
trap cleanup EXIT

{
    echo "run"
    echo "mount $(gf_quote "$ROOT_DEV") /"
    echo "umask 0"

    echo "rm-rf /testcode"
    echo "mkdir-p /testcode"
    set_guest_metadata "/testcode" "755"

    find "$TESTCODE" -type d -print | sort | while IFS= read -r dir; do
        rel="${dir#$TESTCODE}"
        [ -n "$rel" ] || continue

        guest_path="/testcode$rel"
        echo "mkdir-p $(gf_quote "$guest_path")"
        set_guest_metadata "$guest_path" "755"
    done

    find "$TESTCODE" -type f -print | sort | while IFS= read -r file; do
        rel="${file#$TESTCODE}"
        guest_path="/testcode$rel"
        echo "upload $(gf_quote "$file") $(gf_quote "$guest_path")"
        set_guest_metadata "$guest_path" "$(file_mode "$file")"
    done

    echo "mkdir-p /bin"
    set_guest_metadata "/bin" "755"
    echo "upload $(gf_quote "$MKE2FS") /bin/mke2fs.static"
    set_guest_metadata "/bin/mke2fs.static" "755"

    echo "mkdir-p /etc"
    set_guest_metadata "/etc" "755"
    echo "upload $(gf_quote "$DATA/passwd") /etc/passwd"
    echo "upload $(gf_quote "$DATA/group") /etc/group"
    set_guest_metadata "/etc/passwd" "644"
    set_guest_metadata "/etc/group" "644"

    echo "mkdir-p /lib/modules/6.0.0"
    set_guest_metadata "/lib" "755"
    set_guest_metadata "/lib/modules" "755"
    set_guest_metadata "/lib/modules/6.0.0" "755"
    echo "upload $(gf_quote "$DATA/config") /lib/modules/6.0.0/config"
    set_guest_metadata "/lib/modules/6.0.0/config" "644"

    echo "echo === sdcard-la/ ==="
    echo "ll /"
    echo "echo === sdcard-la/testcode/ ==="
    echo "ll /testcode"
    echo "echo === sdcard-la/bin/ ==="
    echo "ll /bin"
} > "$commands"

echo "Writing testcode to $IMG using guestfish..."
guestfish --rw --format=raw -a "$IMG" -f "$commands"

echo "Done. testcode has been written to $IMG."
