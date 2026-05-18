#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
BASE_URL="https://github.com/LRache/KernelX-testsuit/releases/download/mkfs.ext-tools"

download_file() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fL -o "$output" "$url"
        return
    fi

    if command -v wget >/dev/null 2>&1; then
        wget -O "$output" "$url"
        return
    fi

    echo "Error: curl or wget is required to download mke2fs tools" >&2
    return 1
}

ensure_tool() {
    local arch="$1"
    local tool="$arch-mke2fs.static"
    local dest="$BIN_DIR/$tool"
    local tmp

    if [ -s "$dest" ]; then
        chmod 755 "$dest"
        return
    fi

    mkdir -p "$BIN_DIR"
    tmp="$(mktemp "$BIN_DIR/$tool.XXXXXX")"

    echo "Downloading $tool..."
    if ! download_file "$BASE_URL/$tool" "$tmp"; then
        rm -f "$tmp"
        echo "Error: failed to download $tool" >&2
        exit 1
    fi

    chmod 755 "$tmp"
    mv "$tmp" "$dest"
}

if [ "$#" -eq 0 ]; then
    set -- riscv64 loongarch64
fi

for arch in "$@"; do
    case "$arch" in
        riscv64 | rv)
            ensure_tool riscv64
            ;;
        loongarch64 | la)
            ensure_tool loongarch64
            ;;
        *)
            echo "Error: unknown mke2fs tool arch: $arch" >&2
            exit 1
            ;;
    esac
done
