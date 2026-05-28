#!/glibc/busybox sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH

BB=/glibc/busybox
RESULT_LOG=${RESULT_LOG:-/ltp-linux.log}
RUN_MUSL=${RUN_MUSL:-0}
TMPFS_SIZE=${TMPFS_SIZE:-768m}

if [ ! -x "$BB" ]; then
    echo "missing busybox: $BB"
    exec sh
fi

"$BB" mkdir -p /bin /sbin /usr/bin /usr/sbin /tmp /var/tmp /proc /sys /dev /run
"$BB" chmod 0755 "$BB"

COMMON_CMDS="
sh
ash
[
basename
cat
chattr
chmod
chown
cpio
cp
cut
date
dd
df
dirname
dmesg
du
echo
env
false
find
free
grep
head
id
ifconfig
kill
ln
ls
mkdir
mountpoint
mkfifo
mkswap
mknod
mktemp
mount
mv
poweroff
printf
ps
pwd
readlink
reboot
rm
rmdir
sed
seq
setsid
sleep
sort
stat
swapoff
swapon
sync
tail
tar
tee
test
timeout
touch
tr
true
umount
uname
wc
which
xargs
awk
cmp
diff
expr
gzip
gunzip
hexdump
hostname
ip
killall
netstat
od
pgrep
ping
ping6
pkill
route
sysctl
top
uniq
usleep
yes
zcat
"

"$BB" --list >/tmp/busybox.applets 2>/dev/null || true
for cmd in $COMMON_CMDS; do
    if [ -s /tmp/busybox.applets ] && ! "$BB" grep -qx "$cmd" /tmp/busybox.applets 2>/dev/null; then
        continue
    fi
    "$BB" rm -f "/bin/$cmd"
    "$BB" ln "$BB" "/bin/$cmd" 2>/dev/null || "$BB" ln -s "$BB" "/bin/$cmd"
done

mountpoint() {
    grep -q " $1 " /proc/mounts 2>/dev/null
}

mount -t proc proc /proc 2>/dev/null || true
mountpoint /sys || mount -t sysfs sysfs /sys 2>/dev/null || true
mountpoint /dev || mount -t devtmpfs devtmpfs /dev 2>/dev/null || mount -t tmpfs tmpfs /dev 2>/dev/null || true
mountpoint /tmp || mount -t tmpfs -o "mode=1777,size=$TMPFS_SIZE" tmpfs /tmp 2>/dev/null || true
mountpoint /tmp && mount -o "remount,mode=1777,size=$TMPFS_SIZE" /tmp 2>/dev/null || true
mountpoint /var/tmp || mount -t tmpfs -o "mode=1777,size=$TMPFS_SIZE" tmpfs /var/tmp 2>/dev/null || true
mkdir -p /dev/shm /sys/fs/cgroup /sys/kernel/debug /sys/kernel/tracing /tmp/ltp
chmod 1777 /tmp /var/tmp /dev/shm /tmp/ltp 2>/dev/null || true
mountpoint /dev/shm || mount -t tmpfs -o "mode=1777,size=$TMPFS_SIZE" tmpfs /dev/shm 2>/dev/null || true
mountpoint /sys/fs/cgroup || mount -t cgroup2 none /sys/fs/cgroup 2>/dev/null || true
mountpoint /sys/kernel/debug || mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null || true
mountpoint /sys/kernel/tracing || mount -t tracefs tracefs /sys/kernel/tracing 2>/dev/null || true
ifconfig lo 127.0.0.1 up 2>/dev/null || true

for tool in mkfs mkfs.ext2 mkfs.ext3 mkfs.ext4; do
    rm -f "/bin/$tool"
    if [ -x /bin/mke2fs.static ]; then
        ln /bin/mke2fs.static "/bin/$tool"
    fi
done

run_ltp_script() {
    libc_name="$1"
    workdir="$2"
    script="$3"

    if [ ! -d "$workdir" ]; then
        echo "missing $libc_name workdir: $workdir"
        return 0
    fi
    if [ ! -x "$script" ]; then
        echo "missing executable $libc_name LTP script: $script"
        return 0
    fi

    cd "$workdir" || return 0
    "$script"
}

run_all_ltp() {
    mkdir -p /lib

    rm -f /lib/ld-linux-riscv64-lp64d.so.1 /lib/libc.so.6 /lib/libm.so.6
    ln /glibc/lib/ld-linux-riscv64-lp64d.so.1 /lib/ld-linux-riscv64-lp64d.so.1
    ln /glibc/lib/libc.so.6 /lib/libc.so.6
    ln /glibc/lib/libm.so.6 /lib/libm.so.6
    run_ltp_script glibc /glibc /testcode/ltp_testcode_glibc.sh

    if [ "$RUN_MUSL" = "1" ]; then
        rm -f /lib/ld-musl-riscv64-sf.so.1 /lib/ld-linux-riscv64-lp64d.so.1 /lib/ld-musl-riscv64.so.1
        ln /musl/lib/libc.so /lib/ld-musl-riscv64-sf.so.1
        ln /musl/lib/libc.so /lib/ld-linux-riscv64-lp64d.so.1
        ln /musl/lib/libc.so /lib/ld-musl-riscv64.so.1
        run_ltp_script musl /musl /testcode/ltp_testcode_musl.sh
    fi
}

run_all_ltp 2>&1 | tee "$RESULT_LOG"
status=0

sync

poweroff -f
reboot -f
exit "$status"
