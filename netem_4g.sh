#!/bin/bash
set -ex
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

# #https://www.opensignal.com/reports/2020/01/usa/mobile-network-experience -> best of all
# # down is ATT, up is TM, latency is ATT
# rtt_half="23.6ms"
# rtt_full="47.2ms"
# rtt_var="0.5ms"
# packetloss="0.5%"
# download="29.1Mbit"
# peak_download="50Mbit"
# upload="8.8Mbit"
# peak_upload="10Mbit"
# # following https://unix.stackexchange.com/a/100797, upload burst should be 4_400B, and download 14_550B
# upload_burst="10000b"
# download_burst="30000b"

#~network link conditioner in macOS
rtt_half="55ms"
rtt_var="0.5ms"
packetloss="0.5%"
packetloss_half="0.25%"
packetloss_dec="0.005"
download="50Mbit"
peak_download="50Mbit"
upload="10Mbit"
peak_upload="10Mbit"

upload_burst="10kb"
download_burst="50kb"



#ip netns exec $namespace1 tc qdisc delete dev ptp-$interface1 root
#ip netns exec $namespace2 tc qdisc delete dev ptp-$interface2 root


#ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 root netem delay $rtt_half $rtt_var loss $packetloss rate $upload
ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 root handle 1: tbf rate $upload burst $upload_burst latency 1000ms
ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 parent 1: netem delay $rtt_half $rtt_var loss $packetloss_half


#ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 root netem delay $rtt_half $rtt_var loss $packetloss rate $download
ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 root handle 1: tbf rate $download burst $download_burst latency 1000ms
ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 parent 1: netem delay $rtt_half $rtt_var
#packet loss simulation of netem is kinda broken, use iptables instead?
#ip netns exec $namespace2 iptables -s $ip_address1 -A INPUT -m statistic --mode random --probability $packetloss_dec -j DROP