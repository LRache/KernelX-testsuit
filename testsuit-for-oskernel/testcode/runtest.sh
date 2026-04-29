#!/glibc/busybox sh

export PATH=/bin:$PATH

cd /glibc

rm -f /lib/ld-linux-riscv64-lp64d.so.1 /lib/libc.so.6 /lib/libm.so.6
ln /glibc/lib/ld-linux-riscv64-lp64d.so.1 /lib/ld-linux-riscv64-lp64d.so.1
ln /glibc/lib/libc.so.6 /lib/libc.so.6
ln /glibc/lib/libm.so.6 /lib/libm.so.6

set -ex

# /testcode/basic_testcode.sh
# /testcode/busybox_testcode.sh
# /testcode/lua_testcode.sh
# /testcode/libcbench_testcode.sh
# /testcode/lmbench_testcode.sh
# /testcode/unixbench_testcode.sh
# /testcode/iozone_testcode.sh
# /testcode/cyclictest_testcode.sh
/testcode/ltp_testcode.sh

set +ex

# cd /musl

# rm -f /lib/ld-musl-riscv64-sf.so.1 /lib/ld-linux-riscv64-lp64d.so.1 /lib/ld-musl-riscv64.so.1
# ln /musl/lib/libc.so /lib/ld-musl-riscv64-sf.so.1
# ln /musl/lib/libc.so /lib/ld-linux-riscv64-lp64d.so.1
# ln /musl/lib/libc.so /lib/ld-musl-riscv64.so.1

# set -ex

# /testcode/basic_testcode.sh
# /testcode/busybox_testcode.sh
# /testcode/lua_testcode.sh
# /testcode/libctest_static_testcode.sh
# /testcode/libctest_dynamic_testcode.sh
# /testcode/libcbench_testcode.sh
# /testcode/lmbench_testcode.sh
# /testcode/unixbench_testcode.sh
# /testcode/iozone_testcode.sh
# /testcode/cyclictest_testcode.sh

# set +ex
