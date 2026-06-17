#!/glibc/busybox sh

export PATH=/bin:$PATH

/glibc/busybox mkdir -p /bin /lib /tmp /var/tmp

busybox_tools="
awk
setsid
sh
cp
rm
ls
echo
chmod
basename
cat
grep
cut
mkdir
mktemp
touch
seq
diff
ln
du
dd
sed
stat
wc
which
id
blkid
df
mount
umount
"

for tool in $busybox_tools; do
    /glibc/busybox rm -f "/bin/$tool"
done

for tool in $busybox_tools; do
    /glibc/busybox ln /glibc/busybox "/bin/$tool"
done

mount -t tmpfs none /tmp
mount -t tmpfs none /var/tmp

mkfs_tools="
mkfs
mkfs.ext2
mkfs.ext3
mkfs.ext4
"

for tool in $mkfs_tools; do
    rm -f "/bin/$tool"
    ln /bin/mke2fs.static "/bin/$tool"
done

mkdir -p /lib64 /usr/lib64
mkdir -p /dev/shm

cp /testcode/tst_test_busybox_compatible.sh /glibc/ltp/testcases/bin/tst_test.sh
cp /testcode/tst_test_busybox_compatible.sh /musl/ltp/testcases/bin/tst_test.sh

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
/testcode/iperf_testcode.sh
/testcode/netperf_testcode.sh
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
/testcode/iperf_testcode.sh
/testcode/netperf_testcode.sh
# /testcode/cyclictest_testcode.sh
/testcode/ltp_testcode_musl.sh

set +e
