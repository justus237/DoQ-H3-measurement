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
packetloss="0.11%"
#half of packet loss
packetloss_dec="0.00055"
download="50Mbit"
upload="10Mbit"

upload_burst="256kb"
download_burst="256kb"



#ip netns exec $namespace1 tc qdisc delete dev ptp-$interface1 root
#ip netns exec $namespace2 tc qdisc delete dev ptp-$interface2 root


#ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 root netem delay $rtt_half $rtt_var loss $packetloss rate $upload
#upload speed
ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 root handle 1: tbf rate $upload burst $upload_burst latency 1000ms
#latency to server
ip netns exec $namespace1 tc qdisc add dev ptp-$interface1 parent 1: netem delay $rtt_half $rtt_var
#packet loss simulation of netem is kinda broken, use iptables instead?
#packet loss incoming from client on server
ip netns exec $namespace2 iptables -s $ip_address1 -A INPUT -m statistic --mode random --probability $packetloss_dec -j DROP

#ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 root netem delay $rtt_half $rtt_var loss $packetloss rate $download
#download speed
ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 root handle 1: tbf rate $download burst $download_burst latency 1000ms
#latency to client
ip netns exec $namespace2 tc qdisc add dev ptp-$interface2 parent 1: netem delay $rtt_half $rtt_var
#packet loss incoming from server on client
ip netns exec $namespace1 iptables -s $ip_address2 -A INPUT -m statistic --mode random --probability $packetloss_dec -j DROP