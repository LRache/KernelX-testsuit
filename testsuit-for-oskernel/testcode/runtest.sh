#!/glibc/busybox sh

set -ex

cd /glibc

./busybox sh -c 'sleep 5' & ./busybox kill $!

# /testcode/busybox_testcode.sh
# /testcode/lua_testcode.sh
/testcode/libcbench_testcode.sh

cd /musl

# i=1
# while [ "$i" -le 100 ]; do
# 	./entry-static.exe pthread_cond
# 	i=$((i + 1))
# done

# /glibc/busybox mkdir -p /lib
# /glibc/busybox ln /musl/lib/libc.so /lib/ld-musl-riscv64-sf.so.1

/testcode/libctest_static_testcode.sh
/testcode/libctest_dynamic_testcode.sh

# ./entry-static.exe pthread_cancel

# /glibc/busybox rm -rf /lib
