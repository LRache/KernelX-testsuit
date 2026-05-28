#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

QEMU="${QEMU:-qemu-system-riscv64}"
LINUX_SRC="${LINUX_SRC:-$REPO_ROOT/linux-6.18}"
DEFAULT_KERNEL_IMAGE="$LINUX_SRC/arch/riscv/boot/Image"
KERNEL_IMAGE="${KERNEL_IMAGE:-$DEFAULT_KERNEL_IMAGE}"
SDCARD_IMG="${SDCARD_IMG:-$REPO_ROOT/testsuit-for-oskernel/sdcard-rv.img}"
GUEST_INIT="${GUEST_INIT:-$SCRIPT_DIR/linux.sh}"
GUEST_INIT_PATH="${GUEST_INIT_PATH:-/linux.sh}"
TESTCODE_DIR="${TESTCODE_DIR:-$REPO_ROOT/testsuit-for-oskernel/testcode-rv}"
INSTALL_LTP_SCRIPTS="${INSTALL_LTP_SCRIPTS:-1}"
GUEST_LTP_TIMEOUT="${GUEST_LTP_TIMEOUT:-${LTP_TIMEOUT:-30}}"
RUN_MUSL="${RUN_MUSL:-0}"
MEMORY="${MEMORY:-1024M}"
SMP="${SMP:-2}"
TIMEOUT="${TIMEOUT:-0}"
QEMU_LOG="${QEMU_LOG:-$REPO_ROOT/log.log}"
AUTO_BUILD_KERNEL="${AUTO_BUILD_KERNEL:-1}"
FILTER_LTP_OUTPUT="${FILTER_LTP_OUTPUT:-1}"
if [ -z "${STOP_AFTER_LTP_SUMMARY+x}" ]; then
    if [ "$RUN_MUSL" = "1" ]; then
        STOP_AFTER_LTP_SUMMARY=0
    else
        STOP_AFTER_LTP_SUMMARY=1
    fi
fi

usage() {
    cat <<USAGE
Usage: $(basename "$0") [--no-build] [--no-install-init] [--install-only] [--dry-run] [--help]

Environment:
  KERNEL_IMAGE   Linux Image to boot. Default: $KERNEL_IMAGE
  LINUX_SRC      Linux source tree. Default: $LINUX_SRC
  SDCARD_IMG     Rootfs image. Default: $SDCARD_IMG
  QEMU           QEMU binary. Default: $QEMU
  TESTCODE_DIR   RISC-V testcode directory. Default: $TESTCODE_DIR
  INSTALL_LTP_SCRIPTS  Sync ltp_testcode_*.sh into image. Default: $INSTALL_LTP_SCRIPTS
  GUEST_LTP_TIMEOUT  Per-test timeout inside guest. Default: $GUEST_LTP_TIMEOUT
  RUN_MUSL       Continue with musl LTP after glibc. Default: $RUN_MUSL
  MEMORY         Guest memory. Default: $MEMORY
  SMP            Guest CPUs. Default: $SMP
  TIMEOUT        Seconds before host timeout, 0 disables. Default: $TIMEOUT
  QEMU_LOG       Console log path. Default: $QEMU_LOG
  AUTO_BUILD_KERNEL  Build missing kernel image first. Default: $AUTO_BUILD_KERNEL
  FILTER_LTP_OUTPUT  Keep only LTP test output in QEMU_LOG. Default: $FILTER_LTP_OUTPUT
  STOP_AFTER_LTP_SUMMARY  Stop the output filter after first summary. Default: $STOP_AFTER_LTP_SUMMARY
USAGE
}

install_init=1
install_only=0
dry_run=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --no-build)
            AUTO_BUILD_KERNEL=0
            ;;
        --no-install-init)
            install_init=0
            ;;
        --install-only)
            install_only=1
            ;;
        --dry-run)
            dry_run=1
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

need_file() {
    if [ ! -e "$1" ]; then
        echo "missing $2: $1" >&2
        exit 1
    fi
}

if [ "$dry_run" -eq 0 ] && [ ! -e "$KERNEL_IMAGE" ] && [ "$AUTO_BUILD_KERNEL" = "1" ] && [ "$KERNEL_IMAGE" = "$DEFAULT_KERNEL_IMAGE" ]; then
    echo "kernel image missing, building Linux first: $KERNEL_IMAGE"
    LINUX_SRC="$LINUX_SRC" "$SCRIPT_DIR/build-linux.sh"
fi

if [ "$dry_run" -eq 0 ]; then
    need_file "$KERNEL_IMAGE" "kernel image"
    need_file "$SDCARD_IMG" "sdcard image"
    need_file "$GUEST_INIT" "guest init script"
    command -v "$QEMU" >/dev/null || {
        echo "missing qemu binary: $QEMU" >&2
        exit 1
    }
fi

install_guest_file() {
    local src="$1"
    local dst="$2"

    need_file "$src" "guest file"
    printf "rm %s\nwrite %s %s\nsif %s mode 0100755\nsif %s uid 0\nsif %s gid 0\n" \
        "$dst" \
        "$src" "$dst" \
        "$dst" \
        "$dst" \
        "$dst" |
        debugfs -w "$SDCARD_IMG" >/dev/null 2>&1
}

install_guest_files() {
    if command -v debugfs >/dev/null 2>&1; then
        install_guest_file "$GUEST_INIT" "$GUEST_INIT_PATH"
        if [ "$INSTALL_LTP_SCRIPTS" = "1" ]; then
            install_guest_file "$TESTCODE_DIR/ltp_testcode_glibc.sh" /testcode/ltp_testcode_glibc.sh
            install_guest_file "$TESTCODE_DIR/ltp_testcode_musl.sh" /testcode/ltp_testcode_musl.sh
        fi
        return
    fi

    echo "debugfs is required to install guest files into $SDCARD_IMG" >&2
    echo "Install e2fsprogs or copy $GUEST_INIT to the image manually." >&2
    exit 1
}

if [ "$dry_run" -eq 0 ] && [ "$install_init" -eq 1 ]; then
    install_guest_files
fi

if [ "$install_only" -eq 1 ]; then
    exit 0
fi

append_args=(
    "root=/dev/vda"
    "rw"
    "rootwait"
    "console=ttyS0"
    "quiet"
    "loglevel=0"
    "init=$GUEST_INIT_PATH"
    "LTP_TIMEOUT=$GUEST_LTP_TIMEOUT"
    "RUN_MUSL=$RUN_MUSL"
    "TMPFS_SIZE=${TMPFS_SIZE:-768m}"
    "loop.max_loop=64"
    "panic=-1"
)

qemu_cmd=(
    "$QEMU"
    -machine virt
    -m "$MEMORY"
    -smp "$SMP"
    -nographic
    -no-reboot
    -bios default
    -kernel "$KERNEL_IMAGE"
    -append "${append_args[*]}"
    -drive "file=$SDCARD_IMG,format=raw,if=none,id=hd0,cache=writeback"
    -device virtio-blk-device,drive=hd0
    -netdev user,id=net0
    -device virtio-net-device,netdev=net0
    -device virtio-rng-device
)

print_qemu_command() {
    printf 'qemu command:'
    printf ' %q' "${qemu_cmd[@]}"
    printf '\n'
}

if [ "$dry_run" -eq 1 ]; then
    print_qemu_command
    exit 0
fi

run_qemu() {
    if [ "$TIMEOUT" -gt 0 ]; then
        timeout "$TIMEOUT" "${qemu_cmd[@]}"
    else
        "${qemu_cmd[@]}"
    fi
}

filter_ltp_output() {
    if [ "$FILTER_LTP_OUTPUT" = "0" ]; then
        cat
        return
    fi

    awk -v stop_after_summary="$STOP_AFTER_LTP_SUMMARY" '
        done { next }
        /^== TEST / { started = 1 }
        started { print; fflush() }
        started && stop_after_summary == "1" && /^LTP_SUMMARY / { done = 1 }
    '
}

mkdir -p "$(dirname "$QEMU_LOG")"
run_qemu 2>&1 | filter_ltp_output | tee "$QEMU_LOG"
