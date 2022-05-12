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

rtt_half="23.6ms"
rtt_var="0.5ms"
packetloss="0.5%"
download="29.1mbit"
upload="8.8mbit"


ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 root netem delay $rtt_half $rtt_var loss $packetloss rate $upload

ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 root netem delay $rtt_half $rtt_var loss $packetloss rate $download