#!/bin/bash
set -ex
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



echo "experiment_type=fiber" >> vars


#fcc mba 2019
#down mean: 138.480304Mbps median: 99.859576Mbps
#up mean: 106.422907Mbps median: 109.103380Mbps
#latency mean: 14.767147ms median: 11.476000ms
#latency stdev: 14.156490ms

rtt_half="7.3835735ms"
rtt="14.767147ms"
rtt_stdev="14.156490ms"

download="99.859576Mbit"
upload="109.103380Mbit"







#client -> server
ip netns exec $namespace11 tc qdisc add dev $interface12 root netem delay $rtt $rtt_stdev rate $upload

#server -> client
ip netns exec $namespace22 tc qdisc add dev $interface21 root netem rate $download
