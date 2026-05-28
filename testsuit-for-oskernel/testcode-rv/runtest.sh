#!/glibc/busybox sh

export PATH=/bin:$PATH

/glibc/busybox mkdir -p /bin /lib /tmp /var/tmp

busybox_tools="
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
chmod 755 /glibc/busybox

cd /glibc

rm -f /lib/ld-linux-riscv64-lp64d.so.1 /lib/libc.so.6 /lib/libm.so.6
ln /glibc/lib/ld-linux-riscv64-lp64d.so.1 /lib/ld-linux-riscv64-lp64d.so.1
ln /glibc/lib/libc.so.6 /lib/libc.so.6
ln /glibc/lib/libm.so.6 /lib/libm.so.6

set -ex

/testcode/basic_testcode.sh
/testcode/busybox_testcode.sh
/testcode/lua_testcode.sh
/testcode/libcbench_testcode.sh
/testcode/lmbench_testcode.sh
/testcode/iozone_testcode.sh
/testcode/ltp_testcode_glibc.sh

set +ex

cd /musl

rm -f /lib/ld-musl-riscv64-sf.so.1 /lib/ld-linux-riscv64-lp64d.so.1 /lib/ld-musl-riscv64.so.1
ln /musl/lib/libc.so /lib/ld-musl-riscv64-sf.so.1
ln /musl/lib/libc.so /lib/ld-linux-riscv64-lp64d.so.1
ln /musl/lib/libc.so /lib/ld-musl-riscv64.so.1

set -ex

/testcode/basic_testcode.sh
/testcode/busybox_testcode.sh
/testcode/lua_testcode.sh
/testcode/libctest_static_testcode.sh
/testcode/libctest_dynamic_testcode.sh
/testcode/libcbench_testcode.sh
/testcode/lmbench_testcode.sh
/testcode/iozone_testcode.sh
/testcode/ltp_testcode_musl.sh

set +ex

rm -rf /lib
