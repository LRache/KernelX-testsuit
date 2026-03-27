#!/glibc/busybox sh

set -ex

echo "lua test"

./lua date.lua
./lua file_io.lua
./lua max_min.lua
./lua random.lua
./lua remove.lua
./lua round_num.lua
./lua sin30.lua
./lua sort.lua
./lua strings.lua

echo "lua test done"
