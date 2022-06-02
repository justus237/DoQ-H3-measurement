#!/bin/bash
#set -ex
if [[ $EUID -ne 0 ]]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
fi
if [ ! -f vars ]; then
    echo "###Could not find environment variables to use"
    exit 2
fi
source vars
if [[ ! -e /var/run/netns/${namespace1} ]]; then
    echo "###Could not find network namespace ${namespace1}"
    exit 2
fi
if [[ ! -e /var/run/netns/${namespace2} ]]; then
    echo "###Could not find network namespace ${namespace2}"
    exit 2
fi


dns_server_ip=`echo $ip_address2 |awk -F '/' '{print $1}'`

#from web-performance measurement script by Luca
ip netns exec $namespace1 ping -c 1 $dns_server_ip 2>&1 >/dev/null ;
ping_code=$?
if [ $ping_code -ne 0 ]
then
  echo "###pinging server from client failed"
  exit 2
fi
sleep 1

client_ip=`echo $ip_address1 |awk -F '/' '{print $1}'`
ip netns exec $namespace2 ping -c 1 $client_ip 2>&1 >/dev/null ;
ping_code=$?
if [ $ping_code -ne 0 ]
then
  echo "###pinging client from server failed"
  exit 2
fi
sleep 1

msmID=$(uuidgen)
timestamp="`date "+%Y-%m-%d_%H_%M_%S"`"
server_ip=`echo $ip_address2 |awk -F '/' '{print $1}'`
error=""
echo $experiment_type
# stop systemd-resolved
#systemctl stop systemd-resolved
#systemctl disable systemd-resolved
root_dir=$(pwd)
coredns_path="../coredns"
dnsproxy_path="../dnsproxy"
chrome_path="../chromium"

#ip netns exec $namespace1 tcpdump -G 3600 -i any -w $root_dir/client-${timestamp}-${experiment_type}-${msmID}.pcap &
#tcpdumpclientPID=$!
#ip netns exec $namespace2 tcpdump -G 3600 -i any -w $root_dir/server-${timestamp}-${experiment_type}-${msmID}.pcap &
#tcpdumpserverPID=$!
#sleep 5

cd $root_dir && cd $coredns_path
#echo "starting coredns for DoQ udp:8853, DoUDP udp:53 and DoH tcp:443"
ip netns exec $namespace2 ./coredns >& $root_dir/coredns.log &
corednsPID=$!

sleep 5

#echo "starting dnsproxy with DoQ upstream"
cd $root_dir && cd $dnsproxy_path
ip netns exec $namespace1 ./dnsproxy -u "quic://${dns_server_ip}:8853" -v --insecure --ipv6-disabled -l 127.0.0.2 >& $root_dir/dnsproxy.log &
dnsproxyPID=$!
#echo "DoQ: running dig"
h3_server_ip=$(ip netns exec $namespace1 dig @127.0.0.2 +short www.localdomain.com | tail -n1)
#echo "dig result: www.localdomain.com. IN A ${h3_server_ip}"
if [[ $h3_server_ip != $server_ip ]]; then
  error="${error},DoQ: ${h3_server_ip}"
fi


#echo "killing dnsproxy ${dnsproxyPID}"
kill -SIGTERM $dnsproxyPID
sleep 2
cp $root_dir/dnsproxy.log $root_dir/dnsproxy-doq.log
echo -n > $root_dir/dnsproxy.log
sleep 1

#echo "DoQ metrics"
#grep --text '^metrics:DoQ exchange' $root_dir/dnsproxy-doq.log


cd $root_dir && cd $dnsproxy_path
#echo "starting dnsproxy with DoH upstream"
ip netns exec $namespace1 ./dnsproxy -u "https://${dns_server_ip}:443/dns-query" -v --insecure --ipv6-disabled -l 127.0.0.2 >& $root_dir/dnsproxy.log &
dnsproxyPID=$!
#echo "DoH: running dig"
h3_server_ip=$(ip netns exec $namespace1 dig @127.0.0.2 +short www.localdomain.com | tail -n1)
#echo "dig result: www.localdomain.com. IN A ${h3_server_ip}"
if [[ $h3_server_ip != $server_ip ]]; then
  error="${error},DoH: ${h3_server_ip}"
fi


#echo "killing dnsproxy ${dnsproxyPID}"
kill -SIGTERM $dnsproxyPID
sleep 2
cp $root_dir/dnsproxy.log $root_dir/dnsproxy-doh.log
echo -n > $root_dir/dnsproxy.log
sleep 1

#echo "DoH metrics"
#grep '^metrics:DoH exchange' $root_dir/dnsproxy-doh.log


#echo "starting dnsproxy with DoUDP upstream"
ip netns exec $namespace1 ./dnsproxy -u "${dns_server_ip}:53" -v --insecure --ipv6-disabled -l 127.0.0.2 >& $root_dir/dnsproxy.log &
dnsproxyPID=$!
#echo "DoUDP: running dig"
h3_server_ip=$(ip netns exec $namespace1 dig @127.0.0.2 +short www.localdomain.com | tail -n1)
#echo "dig result: www.localdomain.com. IN A ${h3_server_ip}"
if [[ $h3_server_ip != $server_ip ]]; then
  error="${error},DoUDP: ${h3_server_ip}"
fi

#echo "killing dnsproxy ${dnsproxyPID}"
kill -SIGTERM $dnsproxyPID
sleep 2
cp $root_dir/dnsproxy.log $root_dir/dnsproxy-doudp.log
echo -n > $root_dir/dnsproxy.log
sleep 1

#echo "DoUDP metrics"
#grep '^metrics:DoUDP exchange' $root_dir/dnsproxy-doudp.log


if [[ $error != "" ]]; then
  error="${error:1}"
else
  error="none"
fi

# remove dnsproxy session cache
if [[ -f /tmp/chrome_session_cache.txt ]]; then
  echo "removing old chrome client session cache file"
  rm /tmp/chrome_session_cache.txt
fi


cd $root_dir
source website-under-test
echo "running web performance measurement"
ip netns exec $namespace1 /home/quic_net01/.pyenv/shims/python3 chromium_measurement.py $h3_server_ip $msmID $timestamp $experiment_type $website_under_test $error


kill -SIGTERM $corednsPID

#kill -SIGINT $tcpdumpclientPID
#kill -SIGINT $tcpdumpserverPID
# restart systemd-resolved
#systemctl enable systemd-resolved
#systemctl start systemd-resolved