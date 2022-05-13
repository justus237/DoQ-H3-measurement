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
#ATT dsl is 100/20, DTAG is 100/40 -> take middle ground for upload?
rtt_half="5ms"
rtt_var="0.1ms"
packetloss="0%"
download="100mbit"
upload="30mbit"

upload_burst="256kb"
download_burst="256kb"


#ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 root netem delay $rtt_half $rtt_var loss $packetloss rate $upload
#upload speed
ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 root handle 1: tbf rate $upload burst $upload_burst latency 1000ms
#latency to server
ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 parent 1: netem delay $rtt_half $rtt_var

#ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 root netem delay $rtt_half $rtt_var loss $packetloss rate $download
#download speed
ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 root handle 1: tbf rate $download burst $download_burst latency 1000ms
#latency to client
ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 parent 1: netem delay $rtt_half $rtt_var
