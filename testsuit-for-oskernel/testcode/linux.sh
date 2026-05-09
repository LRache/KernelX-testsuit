#!/glibc/busybox sh

export PATH=/bin:$PATH

/glibc/busybox mkdir -p /bin
/musl/busybox chmod 0755 /glibc/busybox

COMMON_CMDS="
sh
cat
chmod
chown
cp
cut
date
dd
df
dmesg
du
echo
env
false
find
free
grep
head
kill
ln
ls
mkdir
mknod
mount
mv
printf
ps
pwd
poweroff
rm
rmdir
sed
sleep
sort
stat
sync
tail
tar
test
touch
true
umount
uname
wc
which
xargs
"

for cmd in $COMMON_CMDS; do
    /glibc/busybox rm -f "/bin/$cmd"
    /glibc/busybox ln /glibc/busybox "/bin/$cmd"
done

mkdir -p /tmp /proc /dev /var/tmp
mount -t tmpfs tmpfs /tmp
mount -t tmpfs tmpfs /var/tmp
mount -t proc proc /proc || mount -t procfs procfs /proc
mount -t devtmpfs devtmpfs /dev || mount -t tmpfs tmpfs /dev || mount -t devfs devfs /dev

sh

poweroff -f
