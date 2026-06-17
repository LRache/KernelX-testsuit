#!/glibc/busybox sh

host="127.0.0.1"
port="5001"

echo "------ IPERF TEST START ------"

./iperf3 -s -p $port &
server_pid=$!

set -ex

./iperf3 -c $host -p $port -t 2 -i 0 -u -b 1000G
./iperf3 -c $host -p $port -t 2 -i 0
./iperf3 -c $host -p $port -t 2 -i 0 -u -P 5 -b 1000G
./iperf3 -c $host -p $port -t 2 -i 0 -P 5
./iperf3 -c $host -p $port -t 2 -i 0 -u -R -b 1000G
./iperf3 -c $host -p $port -t 2 -i 0 -R

set +ex

kill -9 $server_pid

echo "------ IPERF TEST END ------"
