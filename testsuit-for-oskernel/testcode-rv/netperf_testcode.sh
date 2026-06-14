#!/glibc/busybox sh

ip="127.0.0.1"
port=12865

echo "------ NETPERF TEST START ------"

set -ex

./netserver -D -L $ip -p $port &
server_pid=$!

sleep 1

./netperf -H $ip -p $port -t UDP_STREAM -l 1 -- -s 16k -S 16k -m 1k -M 1k
./netperf -H $ip -p $port -t TCP_STREAM -l 1 -- -s 16k -S 16k -m 1k -M 1k
./netperf -H $ip -p $port -t UDP_RR     -l 1 -- -s 16k -S 16k -m 1k -M 1k -r 64,64 -R 1
./netperf -H $ip -p $port -t TCP_RR     -l 1 -- -s 16k -S 16k -m 1k -M 1k -r 64,64 -R 1
./netperf -H $ip -p $port -t TCP_CRR    -l 1 -- -s 16k -S 16k -m 1k -M 1k -r 64,64 -R 1

kill -9 $server_pid
wait $server_pid 2>/dev/null || true

set +ex

echo "------ NETPERF TEST END ------"
