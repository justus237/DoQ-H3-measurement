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



echo "experiment_type=4g" >> vars



#errant
#https://github.com/marty90/errant/blob/94d1aee77290abf246bcbfbaac22bd04b8596032/profiles.csv
#operator,country,rat,signal_quality,download_kbps,upload_kbps,latency_ms_avg,latency_ms_stdev
#best 4g operator
#telia,sweden,4G,medium,28648.29771023976,4224.282864079301,104.5041425140391,56.76313884877055
rtt_half="52.252071257ms"
rtt="104.5041425140391ms"
rtt_stdev="56.76313884877055ms"

download="28.64829771023976Mbit"
upload="4.224282864079301Mbit"







#client -> server
ip netns exec $namespace3 tc qdisc add dev $interface12 root netem delay $rtt $rtt_stdev rate $upload

#server -> client
ip netns exec $namespace3 tc qdisc add dev $interface21 root netem rate $download
