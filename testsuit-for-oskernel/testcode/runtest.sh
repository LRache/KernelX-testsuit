#!/glibc/busybox sh

/glibc/busybox mkdir -p /lib
/glibc/busybox rm -rf /lib/*

cd /glibc

/glibc/busybox ln /glibc/lib/ld-linux-riscv64-lp64d.so.1 /lib/ld-linux-riscv64-lp64d.so.1
/glibc/busybox ln /glibc/lib/libc.so.6 /lib/libc.so.6
/glibc/busybox ln /glibc/lib/libm.so.6 /lib/libm.so.6

set -ex

/testcode/basic_testcode.sh
/testcode/busybox_testcode.sh
/testcode/lua_testcode.sh
/testcode/libcbench_testcode.sh
/testcode/lmbench_testcode.sh
/testcode/unixbench_testcode.sh
/testcode/iozone_testcode.sh

/glibc/busybox rm -rf /lib/ld-linux-riscv64-lp64d.so.1

cd /musl

set +ex

/glibc/busybox ln /musl/lib/libc.so /lib/ld-musl-riscv64-sf.so.1
/glibc/busybox ln /musl/lib/libc.so /lib/ld-linux-riscv64-lp64d.so.1

set -ex

/testcode/basic_testcode.sh
/testcode/busybox_testcode.sh
/testcode/lua_testcode.sh
/testcode/libctest_static_testcode.sh
/testcode/libctest_dynamic_testcode.sh
/testcode/libcbench_testcode.sh
/testcode/lmbench_testcode.sh
/testcode/unixbench_testcode.sh
/testcode/iozone_testcode.sh

set +ex

/glibc/busybox rm -rf /lib
