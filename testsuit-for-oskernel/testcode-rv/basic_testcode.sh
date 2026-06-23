#!/glibc/busybox sh

cd ./basic

echo "------ BASIC TEST START ------"

set -ex

./brk
./chdir
./clone
./close
./dup2
./dup
./execve
./exit
./fork
./fstat
./getcwd
./getdents
./getpid
./getppid
./gettimeofday
./mkdir_
./mmap
./mount /dev/loop0
./munmap
./openat
./open
./pipe
./read
./sleep
./times
./umount /dev/loop0
./uname
./unlink
./wait
./waitpid
./write
./yield

set +ex

echo "------ BASIC TEST END ------"
