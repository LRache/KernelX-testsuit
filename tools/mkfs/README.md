# mke2fs.static

`mke2fs.static` is built from the `e2fsprogs` submodule.

```sh
CROSS_COMPILE=loongarch64-linux-gnu- ./tools/mkfs/build-mke2fs.sh
CROSS_COMPILE=riscv64-unknown-linux-gnu- ./tools/mkfs/build-mke2fs.sh
```

The script requires `CROSS_COMPILE` from the caller, builds a statically linked
binary, and writes it to `tools/mkfs/out/<host>/mke2fs.static`.

Useful overrides:

- `HOST`: configure host triplet, defaults to `CROSS_COMPILE` without the trailing dash.
- `BUILD_CC`: native compiler for build-time helper tools, defaults to `cc`.
- `JOBS`: parallel build jobs.
- `OUT_DIR`: output directory.
- `BUILD_ROOT`: build directory root.
