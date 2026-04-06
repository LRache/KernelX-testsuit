#!/glibc/busybox sh

echo "------ UNIXBENCH TEST START ------"

set -ex

./dhry2reg 10
./whetstone-double 10
./syscall 10
./context1 10
./pipe 10
./spawn 10
UB_BINDIR=./ ./execl 10

#./fstime
./fstime -w -t 20 -b 256 -m 500
./fstime -r -t 20 -b 256 -m 500
./fstime -c -t 20 -b 256 -m 500

./fstime -w -t 20 -b 1024 -m 2000
./fstime -r -t 20 -b 1024 -m 2000
./fstime -c -t 20 -b 1024 -m 2000

./fstime -w -t 20 -b 4096 -m 8000
./fstime -r -t 20 -b 4096 -m 8000
./fstime -c -t 20 -b 4096 -m 8000

./looper 20 /testcode/unixbench/multi.sh 1
./looper 20 /testcode/unixbench/multi.sh 8
./looper 20 /testcode/unixbench/multi.sh 16

./arithoh 10
./short 10
./int 10
./long 10
./float 10
./double 10
./hanoi 10
# ./syscall 10 exec /bin/true not found

set +ex

echo "------ UNIXBENCH TEST END ------"
