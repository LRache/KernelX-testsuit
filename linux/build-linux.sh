#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LINUX_VERSION="${LINUX_VERSION:-6.18}"
LINUX_SRC="${LINUX_SRC:-$REPO_ROOT/linux-$LINUX_VERSION}"
CONFIG_FRAGMENT="${CONFIG_FRAGMENT:-$SCRIPT_DIR/riscv64-ltp.config}"
ARCH="${ARCH:-riscv}"
JOBS="${JOBS:-$(nproc)}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$SCRIPT_DIR/downloads}"
KERNEL_MIRROR="${KERNEL_MIRROR:-https://cdn.kernel.org/pub/linux/kernel}"
TARBALL="${TARBALL:-$DOWNLOAD_DIR/linux-$LINUX_VERSION.tar.xz}"
TARBALL_URL="${TARBALL_URL:-$KERNEL_MIRROR/v${LINUX_VERSION%%.*}.x/linux-$LINUX_VERSION.tar.xz}"

if [ -z "${CROSS_COMPILE:-}" ]; then
    if command -v riscv64-unknown-linux-gnu-gcc >/dev/null 2>&1; then
        CROSS_COMPILE=riscv64-unknown-linux-gnu-
    elif command -v riscv64-linux-gnu-gcc >/dev/null 2>&1; then
        CROSS_COMPILE=riscv64-linux-gnu-
    else
        echo "set CROSS_COMPILE to a RISC-V Linux toolchain prefix" >&2
        exit 1
    fi
fi
export ARCH CROSS_COMPILE

usage() {
    cat <<USAGE
Usage: $(basename "$0") [--no-fetch] [--clean-config] [--help]

Build Linux $LINUX_VERSION for qemu-system-riscv64 and the LTP sdcard image.

Environment:
  LINUX_SRC        Source tree. Default: $LINUX_SRC
  LINUX_VERSION    Kernel version to download when missing. Default: $LINUX_VERSION
  CROSS_COMPILE    Toolchain prefix. Current: $CROSS_COMPILE
  CONFIG_FRAGMENT  Config fragment. Default: $CONFIG_FRAGMENT
  DOWNLOAD_DIR     Tarball cache directory. Default: $DOWNLOAD_DIR
  TARBALL_URL      Kernel tarball URL. Default: $TARBALL_URL
  JOBS             Parallel make jobs. Default: $JOBS
USAGE
}

fetch=1
clean_config=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --no-fetch)
            fetch=0
            ;;
        --clean-config)
            clean_config=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

download_linux() {
    local partial

    mkdir -p "$DOWNLOAD_DIR"

    if [ -s "$TARBALL" ]; then
        echo "using cached tarball: $TARBALL"
        return
    fi

    partial="$TARBALL.partial"
    rm -f "$partial"

    echo "downloading $TARBALL_URL"
    echo "to $TARBALL"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --retry-delay 2 "$TARBALL_URL" -o "$partial"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$partial" "$TARBALL_URL"
    else
        echo "missing downloader: install curl or wget" >&2
        exit 1
    fi

    mv "$partial" "$TARBALL"
}

extract_linux() {
    local extract_dir

    extract_dir="$REPO_ROOT/linux-$LINUX_VERSION"
    if [ "$LINUX_SRC" != "$extract_dir" ]; then
        echo "custom LINUX_SRC is missing: $LINUX_SRC" >&2
        echo "Set LINUX_SRC=$extract_dir or create the custom source tree yourself." >&2
        exit 1
    fi

    echo "extracting $TARBALL"
    tar -C "$REPO_ROOT" -xf "$TARBALL"

    if [ ! -f "$LINUX_SRC/Makefile" ] || [ ! -d "$LINUX_SRC/arch/riscv" ]; then
        echo "extracted tree does not look like Linux RISC-V source: $LINUX_SRC" >&2
        exit 1
    fi
}

if [ ! -d "$LINUX_SRC" ]; then
    if [ "$fetch" -ne 1 ]; then
        echo "missing Linux source tree: $LINUX_SRC" >&2
        echo "Place linux-$LINUX_VERSION there, or allow the default auto-download." >&2
        exit 1
    fi

    download_linux
    extract_linux
fi

if [ ! -f "$LINUX_SRC/Makefile" ] || [ ! -d "$LINUX_SRC/arch/riscv" ]; then
    echo "source tree does not look like Linux RISC-V source: $LINUX_SRC" >&2
    exit 1
fi

if [ ! -f "$CONFIG_FRAGMENT" ]; then
    echo "missing config fragment: $CONFIG_FRAGMENT" >&2
    exit 1
fi

if [ "$clean_config" -eq 1 ] || [ ! -f "$LINUX_SRC/.config" ]; then
    make -C "$LINUX_SRC" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" defconfig
fi
(
    cd "$LINUX_SRC"
    scripts/kconfig/merge_config.sh -m .config "$CONFIG_FRAGMENT"
)
make -C "$LINUX_SRC" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" olddefconfig
make -C "$LINUX_SRC" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" -j"$JOBS" Image

echo "built: $LINUX_SRC/arch/riscv/boot/Image"
