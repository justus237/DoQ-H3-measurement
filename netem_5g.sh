#!/bin/bash
#some values taken from https://github.com/noise-lab/dns-measurement-suite/blob/cdf17805271918a5b6d06121a74bf9fb430684d7/src/measure/tc.4g.sh
if [[ $EUID -ne 0 ]]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
fi
if [ ! -f vars ]; then
    echo "Could not find environment variables to use"
    exit 2
fi
source vars
if [ ! -e /var/run/netns/${namespace1} ]; then
    echo "Could not find network namespace ${namespace1}"
    exit 2
fi
if [ ! -e /var/run/netns/${namespace2} ]; then
    echo "Could not find network namespace ${namespace2}"
    exit 2
fi

rtt_half="19ms"
rtt_var="0.3ms"
packetloss="0.4%"
download="150.0mbit"
upload="17.9mbit"


sudo ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 root netem delay $rtt_half $rtt_var loss $packetloss rate $upload

sudo ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 root netem delay $rtt_half $rtt_var loss $packetloss rate $download