#!/glibc/busybox sh

set -e

cd /glibc

# /testcode/busybox_testcode.sh
# /testcode/lua_testcode.sh
# /testcode/libcbench_testcode.sh

cd /musl

./entry-static.exe pthread_cond

# /glibc/busybox mkdir -p /lib
# /glibc/busybox ln /musl/lib/libc.so /lib/ld-musl-riscv64-sf.so.1

# /testcode/libctest_dynamic_testcode.sh

# /glibc/busybox rm -rf /lib
