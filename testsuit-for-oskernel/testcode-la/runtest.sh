#!/glibc/busybox sh

# Prepare the basic tools

export PATH=/bin:$PATH

/glibc/busybox mkdir -p /bin
/glibc/busybox rm -f /bin/*
/glibc/busybox ln /glibc/busybox /bin/sh
/glibc/busybox ln /glibc/busybox /bin/cp
/glibc/busybox ln /glibc/busybox /bin/ls
/glibc/busybox ln /glibc/busybox /bin/mkdir
/glibc/busybox ln /glibc/busybox /bin/ln
/glibc/busybox ln /glibc/busybox /bin/rm

mkdir -p /lib
mkdir -p /lib64
mkdir -p /usr/lib64
mkdir -p /dev/shm
rm -rf /lib/*
rm -rf /lib64/*
rm -rf /usr/lib64/*

cd /glibc

# glibc dynamic linker — LoongArch uses /lib64/ for interpreter
/glibc/busybox ln /glibc/lib/ld-linux-loongarch-lp64d.so.1 /lib64/ld-linux-loongarch-lp64d.so.1
/glibc/busybox ln /glibc/lib/libc.so.6 /lib/libc.so.6
/glibc/busybox ln /glibc/lib/libm.so.6 /lib/libm.so.6
# glibc ld.so searches /usr/lib64/ by default on LoongArch
/glibc/busybox ln /glibc/lib/libc.so.6 /usr/lib64/libc.so.6
/glibc/busybox ln /glibc/lib/libm.so.6 /usr/lib64/libm.so.6
/glibc/busybox ln /glibc/lib/ld-linux-loongarch-lp64d.so.1 /usr/lib64/ld-linux-loongarch-lp64d.so.1

set -ex

/testcode/basic_testcode.sh
/testcode/busybox_testcode.sh
/testcode/lua_testcode.sh
/testcode/libcbench_testcode.sh
/testcode/lmbench_testcode.sh
/testcode/unixbench_testcode.sh
/testcode/iozone_testcode.sh
/testcode/cyclictest_testcode.sh

set +ex

/glibc/busybox rm -rf /lib64/ld-linux-loongarch-lp64d.so.1

cd /musl

# musl dynamic linker
/glibc/busybox ln /musl/lib/libc.so /lib64/ld-musl-loongarch-lp64d.so.1
/glibc/busybox ln /musl/lib/libc.so /lib64/ld-linux-loongarch-lp64d.so.1

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
/testcode/cyclictest_testcode.sh

set +ex

/glibc/busybox rm -rf /lib
/glibc/busybox rm -rf /lib64
/glibc/busybox rm -rf /usr/lib64
