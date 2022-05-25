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

if [[ $experiment_type != "default" ]]; then
    ip netns pids $namespace1 | xargs kill
    ip netns pids $namespace2 | xargs kill
    ip netns exec $namespace1 tc qdisc delete dev ptp-$interface1 root
    ip netns exec $namespace2 tc qdisc delete dev ptp-$interface2 root
fi



echo "experiment_type=4g" >> vars



#errant
#operator,country,rat,signal_quality,download_kbps,upload_kbps,latency_ms_avg,latency_ms_stdev
#best 4g operator
#telia,sweden,4G,good,53954.87190708256,21181.03261207894,91.85231065904635,45.93133354604078
rtt_half="45.9261553295ms"
rtt_var="45.93133354604078ms"
packetloss="0%"
packetloss_half="0%"
#half of packet loss
packetloss_dec="0"
download="53954.87190708256kbit"
upload="21181.03261207894kbit"

upload_burst="256kb"
download_burst="256kb"


rtt_half="23.6ms"
packetloss_dec="0.0007"




#ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 root netem delay $rtt_half $rtt_var loss $packetloss_half rate $upload
#upload speed
ip netns exec $namespace1 tc qdisc add dev $interface1 root handle 1: tbf rate $upload burst $upload_burst latency 1000ms
#latency to server
ip netns exec $namespace1 tc qdisc add dev $interface1 parent 1: netem delay $rtt_half $rtt_var
#packet loss simulation of netem is kinda broken, use iptables instead?
#packet loss incoming from client on server
ip netns exec $namespace2 iptables -s $ip_address1 -A INPUT -m statistic --mode random --probability $packetloss_dec -j DROP

#ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 root netem delay $rtt_half $rtt_var loss $packetloss_half rate $download
#download speed
ip netns exec $namespace2 tc qdisc add dev $interface2 root handle 1: tbf rate $download burst $download_burst latency 1000ms
#latency to client
ip netns exec $namespace2 tc qdisc add dev $interface2 parent 1: netem delay $rtt_half $rtt_var
#packet loss incoming from server on client
ip netns exec $namespace1 iptables -s $ip_address2 -A INPUT -m statistic --mode random --probability $packetloss_dec -j DROP