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
if [[ ! -e /var/run/netns/${namespace3} ]]; then
    echo "Could not find network namespace ${namespace11}"
    exit 2
fi

if [[ $experiment_type != "default" ]]; then
    ip netns pids $namespace1 | xargs kill
    ip netns pids $namespace2 | xargs kill
    ip netns exec $namespace11 tc qdisc delete dev $interface12 root
    ip netns exec $namespace22 tc qdisc delete dev $interface21 root
fi



echo "experiment_type=cable" >> vars


#fcc mba 2019
#down mean: 184.116545Mbps median: 165.046798Mbps
#up mean: 16.410990Mbps median: 11.634674Mbps
#latency mean: 25.17665ms median: 18.441ms
#latency stdev: 48.24348ms

rtt_half="12.588325ms"
rtt="25.17665ms"
rtt_stdev="48.24348ms"

download="165.046798Mbit"
upload="11.634674Mbit"







#client -> server
ip netns exec $namespace3 tc qdisc add dev $interface12 root netem delay $rtt $rtt_stdev rate $upload

#server -> client
ip netns exec $namespace3 tc qdisc add dev $interface21 root netem rate $download
