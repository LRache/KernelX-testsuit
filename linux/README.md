# Linux 6.18 RISC-V LTP Runner

This folder contains host and guest scripts for booting Linux 6.18 under
`qemu-system-riscv64` with `testsuit-for-oskernel/sdcard-rv.img` as the root
filesystem and running the LTP tests already stored in that image.

## Files

- `linux.sh`: guest init script. It creates BusyBox command links, mounts
  `/proc`, `/sys`, `/dev`, `/tmp`, and `/var/tmp`, then runs
  `/testcode/runtest.sh`.
- `run.sh`: host runner. It writes `linux.sh` into the ext4 image as
  `/linux.sh`, syncs `ltp_testcode_*.sh` into `/testcode/`, boots QEMU, and
  logs the serial console to `log.log`.
- `build-linux.sh`: helper for building `linux-6.18/arch/riscv/boot/Image`.
- `riscv64-ltp.config`: config fragment for Linux 6.18.

## Build

Run:

```sh
./linux/build-linux.sh
```

If `linux-6.18` is missing, the script downloads
`https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.tar.xz` into
`linux/downloads/`, extracts it at the repository root, merges
`linux/riscv64-ltp.config`, and builds `arch/riscv/boot/Image`.

Use `--no-fetch` when you want the script to fail instead of downloading.

The script detects `riscv64-unknown-linux-gnu-` or `riscv64-linux-gnu-`.
Override paths when needed:

```sh
LINUX_SRC=/path/to/linux-6.18 CROSS_COMPILE=riscv64-unknown-linux-gnu- ./linux/build-linux.sh --no-fetch
```

## Run

```sh
./linux/run.sh
```

When the kernel image is missing, `run.sh` invokes `build-linux.sh` first. Use
`--no-build` to make it fail instead.

Useful overrides:

```sh
KERNEL_IMAGE=/path/to/Image SDCARD_IMG=/path/to/sdcard-rv.img TIMEOUT=600 ./linux/run.sh
```

## Kernel Options

The current RISC-V LTP script inside the image is:

```text
/testcode/runtest.sh
  -> /testcode/ltp_testcode_glibc.sh
  -> /testcode/ltp_testcode_musl.sh
```

The generated glibc script currently selects SysV message queue tests:
`msgctl*`, `msgget*`, `msgrcv*`, and `msgsnd*`. The key options for those are
`CONFIG_SYSVIPC`, `CONFIG_SYSVIPC_SYSCTL`, and `CONFIG_IPC_NS`.

Booting the image also requires virtio block, ext4, proc/sysfs/devtmpfs/tmpfs,
ELF and script binary formats, and a serial console. The config fragment keeps
extra options enabled for the broader PASS/HALF list in `ltp_test_status.csv`,
including epoll, eventfd, fanotify, namespaces, cgroups, keys, and crypto user
APIs.
