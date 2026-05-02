#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG="${IMG:-$SCRIPT_DIR/sdcard-rv.img}"
XZ="${XZ:-$SCRIPT_DIR/sdcard-rv.img.xz}"
URL="https://github.com/oscomp/testsuits-for-oskernel/releases/download/pre-20250615/sdcard-rv.img.xz"
TESTCODE="$SCRIPT_DIR/testcode"
DATA="$SCRIPT_DIR/data"
ROOT_DEV="${ROOT_DEV:-/dev/sda}"

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
    echo "copy-in $(gf_quote "$TESTCODE") /"
    echo "chown 0 0 /testcode"
    echo "chmod 0755 /testcode"

    find "$TESTCODE" -print | sort | while read -r path; do
        rel="${path#$TESTCODE}"
        [ -n "$rel" ] || continue

        guest_path="/testcode$rel"
        echo "chown 0 0 $(gf_quote "$guest_path")"
        if [ -d "$path" ]; then
            echo "chmod 0755 $(gf_quote "$guest_path")"
        elif [ "${path##*.}" = "sh" ]; then
            echo "chmod 0755 $(gf_quote "$guest_path")"
        fi
    done

    echo "mkdir-p /bin"
    echo "chmod 0755 /bin"
    echo "chmod 0755 /glibc/busybox"
    for cmd in sh cp ls mkdir ln rm; do
        echo "rm-f /bin/$cmd"
        echo "ln /glibc/busybox /bin/$cmd"
    done
    for cmd in sh cp ls mkdir ln rm; do
        echo "chmod 0755 /bin/$cmd"
    done

    echo "mkdir-p /etc"
    echo "upload $(gf_quote "$DATA/passwd") /etc/passwd"
    echo "upload $(gf_quote "$DATA/group") /etc/group"
    echo "chown 0 0 /etc/passwd"
    echo "chown 0 0 /etc/group"
    echo "chmod 0644 /etc/passwd"
    echo "chmod 0644 /etc/group"

    echo "mkdir-p /lib/modules/6.0.0"
    echo "upload $(gf_quote "$DATA/config") /lib/modules/6.0.0/config"
    echo "chown 0 0 /lib/modules/6.0.0/config"
    echo "chmod 0644 /lib/modules/6.0.0/config"

    echo "echo === sdcard-rv/ ==="
    echo "ll /"
    echo "echo === sdcard-rv/testcode/ ==="
    echo "ll /testcode"
} > "$commands"

echo "Writing testcode to $IMG using guestfish..."
guestfish --rw --format=raw -a "$IMG" -f "$commands"

echo "Done. testcode has been written to $IMG."
