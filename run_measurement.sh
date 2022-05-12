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
msmID=$(uuidgen)
# stop systemd-resolved
#systemctl stop systemd-resolved
#systemctl disable systemd-resolved
root_dir=$(pwd)
coredns_path="../coredns"
dnsproxy_path="../dnsproxy"
chrome_path="../chromium"

#coredns
cd $coredns_path
echo "starting coredns for DoQ udp:8853, DoUDP udp:53 and DoH tcp:443"
ip netns exec $namespace2 ./coredns >& $root_dir/coredns.log &

#dnsproxy
cd $root_dir
cd $dnsproxy_path
dns_server_ip=`echo $ip_address2 |awk -F '/' '{print $1}'`

# echo "starting dnsproxy with DoQ upstream"
# ip netns exec $namespace1 ./dnsproxy -u "quic://${dns_server_ip}:8853" -v --insecure --ipv6-disabled -l 127.0.0.2 >& $root_dir/dnsproxy.log &
# cd $root_dir
# echo "DoQ: running dig"
# h3_server_ip=$(ip netns exec $namespace1 dig @127.0.0.2 +short www.example.org | tail -n1)
# echo "dig result: www.example.org IN A ${h3_server_ip}"

# sleep 1
# echo "DoQ: moving log file and clearing it for session resumption"
# cp $root_dir/dnsproxy.log $root_dir/dnsproxy-doq-warmup.log
# echo -n > $root_dir/dnsproxy.log
# echo "DoQ: sending reset to dnsproxy for session resumption"
# dnsproxyPID=$(ps -e | pgrep dnsproxy)
# kill -SIGUSR1 $dnsproxyPID

# echo "DoQ: running dig with session resumption"
# h3_server_ip=$(ip netns exec $namespace1 dig @127.0.0.2 +short www.example.org | tail -n1)
# echo "dig result: www.example.org IN A ${h3_server_ip}"

# cp $root_dir/dnsproxy.log $root_dir/dnsproxy-doq.log
# echo -n > $root_dir/dnsproxy.log
# echo "killing dnsproxy"
# kill -SIGTERM $dnsproxyPID




echo "starting dnsproxy with DoH upstream"
ip netns exec $namespace1 ./dnsproxy -u "https://${dns_server_ip}:443/dns-query" -v --insecure --ipv6-disabled -l 127.0.0.2 >& $root_dir/dnsproxy.log &
dnsproxyPID=$!
cd $root_dir
echo "DoH: running dig"
h3_server_ip=$(ip netns exec $namespace1 dig @127.0.0.2 +short www.example.org | tail -n1)
echo "dig result: www.example.org IN A ${h3_server_ip}"

#dnsproxyPID=$(ps -e | pgrep dnsproxy)
cp $root_dir/dnsproxy.log $root_dir/dnsproxy-doh.log
echo -n > $root_dir/dnsproxy.log
echo "killing dnsproxy"
kill -SIGTERM $dnsproxyPID


echo "starting dnsproxy with DoUDP upstream"
ip netns exec $namespace1 ./dnsproxy -u "${dns_server_ip}:53" -v --insecure --ipv6-disabled -l 127.0.0.2 >& $root_dir/dnsproxy.log &
dnsproxyPID=$!
cd $root_dir
echo "DoUDP: running dig"
h3_server_ip=$(ip netns exec $namespace1 dig @127.0.0.2 +short www.example.org | tail -n1)
echo "dig result: www.example.org IN A ${h3_server_ip}"

#dnsproxyPID=$(ps -e | pgrep dnsproxy)
cp $root_dir/dnsproxy.log $root_dir/dnsproxy-doudp.log
echo -n > $root_dir/dnsproxy.log
echo "killing dnsproxy"
kill -SIGTERM $dnsproxyPID



echo "running web performance measurement"
ip netns exec $namespace1 python3 chromium_measurement.py $h3_server_ip $msmID

# restart systemd-resolved
#systemctl enable systemd-resolved
#systemctl start systemd-resolved