#!/glibc/busybox sh

export PATH=/bin:$PATH

# The /bin tools and runtime library links are prepared during image build.

cd /glibc

# /testcode/basic_testcode.sh
# /testcode/busybox_testcode.sh
# /testcode/lua_testcode.sh
# /testcode/libcbench_testcode.sh
# /testcode/lmbench_testcode.sh
/testcode/unixbench_testcode.sh
# /testcode/iozone_testcode.sh
# /testcode/cyclictest_testcode.sh
# /testcode/ltp_testcode.sh

cd /musl

# if [ -e /lib/.ld-linux-riscv64-lp64d.so.1.musl ]; then
#     /glibc/busybox rm -f /lib/ld-linux-riscv64-lp64d.so.1
#     /glibc/busybox mv /lib/.ld-linux-riscv64-lp64d.so.1.musl /lib/ld-linux-riscv64-lp64d.so.1
# fi

# /glibc/busybox rm -f /lib/ld-linux-riscv64-lp64d.so.1
# /glibc/busybox mv /lib/.ld-linux-riscv64-lp64d.so.1.musl /lib/ld-linux-riscv64-lp64d.so.1
# /glibc/busybox mv /lib/.ld-linux-riscv64-lp64d.so.1.musl /lib/ld-musl-riscv64.so.1

set -ex

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
# /testcode/ltp_testcode.sh

# set +ex
