#!/bin/bash
#set -ex
#some values taken from https://github.com/noise-lab/dns-measurement-suite/blob/cdf17805271918a5b6d06121a74bf9fb430684d7/src/measure/tc.4g.sh
if [[ $EUID -ne 0 ]]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
fi
if [[ ! -f vars ]]; then
    echo "Could not find environment variables to use"
    exit 2
fi
source vars
if [[ ! -e /var/run/netns/${namespace1} ]]; then
    echo "Could not find network namespace ${namespace1}"
    exit 2
fi
if [[ ! -e /var/run/netns/${namespace2} ]]; then
    echo "Could not find network namespace ${namespace2}"
    exit 2
fi
# if [[ ! -e /var/run/netns/${namespace3} ]]; then
#     echo "Could not find network namespace ${namespace3}"
#     exit 2
# fi
if [[ ! -e /var/run/netns/${namespace11} ]]; then
    echo "Could not find network namespace ${namespace11}"
    exit 2
fi
if [[ ! -e /var/run/netns/${namespace22} ]]; then
    echo "Could not find network namespace ${namespace22}"
    exit 2
fi

if [[ $experiment_type != "default" ]]; then
    ip netns pids $namespace1 | xargs kill
    ip netns pids $namespace2 | xargs kill
    ip netns exec $namespace11 tc qdisc delete dev $interface12 root
    ip netns exec $namespace22 tc qdisc delete dev $interface21 root
fi



echo "experiment_type=fixed" >> vars


#fcc mba 2019
#down mean: 108.7955Mbps median: 70.54765Mbps
#up mean: 43.96956Mbps median: 10.41276Mbps
#latency mean: 44.5534ms median: 22.52ms
#latency stdev: 107.4591ms

rtt_half="22.2767ms"
rtt="44.5534ms"
rtt_stdev="107.4591ms"

download="70.54765Mbit"
upload="10.41276Mbit"






#ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 root netem delay $rtt_half $rtt_var loss $packetloss_half rate $upload
#upload speed
ip netns exec $namespace11 tc qdisc add dev $interface12 root handle 1: tbf rate $upload burst $upload_burst latency 1000ms
#latency to server
ip netns exec $namespace11 tc qdisc add dev $interface12 parent 1: netem rate 1000mbit delay $rtt $rtt_stdev

#ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 root netem delay $rtt_half $rtt_var loss $packetloss_half rate $download
#download speed
ip netns exec $namespace22 tc qdisc add dev $interface21 root handle 1: tbf rate $download burst $download_burst latency 1000ms
#latency to client
#ip netns exec $namespace22 tc qdisc add dev $interface21 parent 1: netem delay $rtt_half $rtt_stdev
