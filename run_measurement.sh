#!/bin/bash
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
# stop systemd-resolved
#systemctl stop systemd-resolved
#systemctl disable systemd-resolved
root_dir=$(pwd)
coredns_path="../coredns"
dnsproxy_path="../dnsproxy"
chrome_path="../chromium"

echo "starting coredns"
cd $coredns_path
ip netns exec $namespace2 ./coredns >& $root_dir/coredns.log &

echo "starting dnsproxy"
cd $root_dir
cd $dnsproxy_path
dns_server_ip=`echo $ip_address2 |awk -F '/' '{print $1}'`
ip netns exec $namespace1 ./dnsproxy -u "quic://${dns_server_ip}:784" -v --insecure --ipv6-disabled -l 127.0.0.2 >& $root_dir/dnsproxy.log &

echo "running dig"
h3_server_ip=$(dig @127.0.0.2 +short www.example.org | tail -n1)
echo "dig result: www.example.org IN A ${h3_server_ip}"
echo "running web performance measurement"
python3 chromium_measurement.py $h3_server_ip

# restart systemd-resolved
#systemctl enable systemd-resolved
#systemctl start systemd-resolved