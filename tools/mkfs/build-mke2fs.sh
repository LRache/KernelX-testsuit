#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SRC_DIR="$SCRIPT_DIR/e2fsprogs"

if [ -z "${CROSS_COMPILE:-}" ]; then
    echo "error: CROSS_COMPILE must be set, for example:" >&2
    echo "  CROSS_COMPILE=loongarch64-linux-gnu- $0" >&2
    exit 1
fi

HOST="${HOST:-$(basename "$CROSS_COMPILE")}"
HOST="${HOST%-}"
BUILD_ROOT="${BUILD_ROOT:-$SCRIPT_DIR/build}"
BUILD_DIR="${BUILD_DIR:-$BUILD_ROOT/$HOST}"
OUT_DIR="${OUT_DIR:-$SCRIPT_DIR/out/$HOST}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}"

CC="${CC:-${CROSS_COMPILE}gcc}"
AR="${AR:-${CROSS_COMPILE}ar}"
RANLIB="${RANLIB:-${CROSS_COMPILE}ranlib}"
STRIP="${STRIP:-${CROSS_COMPILE}strip}"
BUILD_CC="${BUILD_CC:-cc}"
LDFLAGS_STATIC="${LDFLAGS_STATIC:--static}"

for tool in "$CC" "$AR" "$RANLIB" "$BUILD_CC"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "error: required tool not found: $tool" >&2
        exit 1
    fi
done

if [ ! -x "$SRC_DIR/configure" ]; then
    git -C "$REPO_ROOT" submodule update --init --depth 1 -- tools/mkfs/e2fsprogs
fi

mkdir -p "$BUILD_DIR" "$OUT_DIR"

CONFIGURE_ARGS=(
    "--host=$HOST"
    "--prefix=/usr"
    "--with-root-prefix="
    "--enable-libuuid"
    "--enable-libblkid"
    "--disable-elf-shlibs"
    "--disable-bsd-shlibs"
    "--disable-debugfs"
    "--disable-imager"
    "--disable-resizer"
    "--disable-defrag"
    "--disable-fuse2fs"
    "--disable-uuidd"
    "--disable-nls"
    "--disable-backtrace"
    "--disable-mmp"
    "--disable-tdb"
    "--disable-bmap-stats"
    "--without-libarchive"
)

(
    cd "$BUILD_DIR"
    CC="$CC" \
    AR="$AR" \
    RANLIB="$RANLIB" \
    STRIP="$STRIP" \
    BUILD_CC="$BUILD_CC" \
    LDFLAGS_STATIC="$LDFLAGS_STATIC" \
        "$SRC_DIR/configure" "${CONFIGURE_ARGS[@]}" "$@"

    make -j "$JOBS" libs
    make -C misc -j "$JOBS" mke2fs.static
)

cp "$BUILD_DIR/misc/mke2fs.static" "$OUT_DIR/mke2fs.static"
if command -v "$STRIP" >/dev/null 2>&1; then
    "$STRIP" "$OUT_DIR/mke2fs.static" || true
fi

echo "Built static mke2fs: $OUT_DIR/mke2fs.static"
