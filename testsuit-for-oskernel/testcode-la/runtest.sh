#!/glibc/busybox sh

export PATH=/bin:$PATH

# Prepare the basic tools
/glibc/busybox mkdir -p /bin
/glibc/busybox rm -f /bin/sh /bin/cp /bin/ls /bin/mkdir /bin/ln /bin/rm /bin/chmod /bin/mkfs.ext2 /bin/mkfs.ext3 /bin/mkfs.ext4

/glibc/busybox ln /glibc/busybox /bin/ln
/musl/busybox chmod 0755 /glibc/busybox
ln /glibc/busybox /bin/sh
ln /glibc/busybox /bin/cp
ln /glibc/busybox /bin/rm
ln /glibc/busybox /bin/ls
ln /glibc/busybox /bin/echo
ln /glibc/busybox /bin/mkdir
ln /glibc/busybox /bin/chmod
ln /bin/mke2fs.static /bin/mkfs.ext2
ln /bin/mke2fs.static /bin/mkfs.ext3
ln /bin/mke2fs.static /bin/mkfs.ext4

mkdir -p /lib /lib64 /usr/lib64
mkdir -p /dev/shm

cd /glibc

# glibc dynamic linker — LoongArch uses /lib64/ for interpreter
rm -f /lib64/ld-linux-loongarch-lp64d.so.1
ln /glibc/lib/ld-linux-loongarch-lp64d.so.1 /lib64/ld-linux-loongarch-lp64d.so.1
rm -f /lib/libc.so.6 /lib/libm.so.6
ln /glibc/lib/libc.so.6 /lib/libc.so.6
ln /glibc/lib/libm.so.6 /lib/libm.so.6
rm -f /usr/lib64/libc.so.6 /usr/lib64/libm.so.6 /usr/lib64/ld-linux-loongarch-lp64d.so.1
ln /glibc/lib/libc.so.6 /usr/lib64/libc.so.6
ln /glibc/lib/libm.so.6 /usr/lib64/libm.so.6
ln /glibc/lib/ld-linux-loongarch-lp64d.so.1 /usr/lib64/ld-linux-loongarch-lp64d.so.1

set -e

/testcode/basic_testcode.sh
/testcode/busybox_testcode.sh
/testcode/lua_testcode.sh
/testcode/libcbench_testcode.sh
/testcode/lmbench_testcode.sh
# /testcode/unixbench_testcode.sh
/testcode/iozone_testcode.sh
# /testcode/cyclictest_testcode.sh
/testcode/ltp_testcode_glibc.sh

cd /musl

# musl dynamic linker
rm -f /lib64/ld-musl-loongarch-lp64d.so.1 /lib64/ld-linux-loongarch-lp64d.so.1
ln /musl/lib/libc.so /lib64/ld-musl-loongarch-lp64d.so.1
ln /musl/lib/libc.so /lib64/ld-linux-loongarch-lp64d.so.1

/testcode/basic_testcode.sh
/testcode/busybox_testcode.sh
/testcode/lua_testcode.sh
/testcode/libctest_static_testcode.sh
/testcode/libctest_dynamic_testcode.sh
/testcode/libcbench_testcode.sh
/testcode/lmbench_testcode.sh
# /testcode/unixbench_testcode.sh
/testcode/iozone_testcode.sh
# /testcode/cyclictest_testcode.sh
/testcode/ltp_testcode_musl.sh

set +e
