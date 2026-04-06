#!/glibc/busybox sh

echo "------ LIBCBENCH TEST START ------"

set -ex

./libc-bench

set +ex

echo "------ LIBCBENCH TEST END ------"
