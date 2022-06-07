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
    ip netns pids $namespace1 | xargs -r kill
    ip netns pids $namespace2 | xargs -r kill
    ip netns exec $namespace11 tc qdisc delete dev $interface12 root
    ip netns exec $namespace22 tc qdisc delete dev $interface21 root
fi



echo "experiment_type=dsl" >> vars


#fcc mba 2019
#down mean: 14.38496Mbps median: 10.73476Mbps
#up mean: 1.674286Mbps median: 0.842152Mbps
#latency mean: 42.35979ms median: 31.8755ms
#latency stdev: 53.99053ms

rtt_half="21.179895ms"
rtt="42.35979ms"
rtt_stdev="53.99053ms"

download="10.73476Mbit"
upload="0.842152Mbit"







#client -> server
ip netns exec $namespace11 tc qdisc add dev $interface12 root netem delay $rtt_half rate $upload

#server -> client
ip netns exec $namespace22 tc qdisc add dev $interface21 root netem delay $rtt_half rate $download
