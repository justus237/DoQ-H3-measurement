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

root_dir=$(pwd)
coredns_path="../coredns"
dnsproxy_path="../dnsproxy"
chrome_path="../chromium"
source website-under-test

server_ip=`echo $ip_address2 |awk -F '/' '{print $1}'`
echo "quic://.:8853 {
  bind ${server_ip}
  tls localhost.crt localhost.key {
    session_ticket_key session_ticket.key
  }
  hosts {
    ${server_ip} www.localdomain.com
    reload 1h
  }
  h3server ${website_under_test}/ ${server_ip}:6121
  errors
  log
  debug
}

.:53 {
  bind ${server_ip}
  hosts {
    ${server_ip} www.localdomain.com
    reload 1h
  }
  errors
  log
  debug
}

tcp://.:80 {
  bind ${server_ip}
  hosts {
    ${server_ip} www.localdomain.com
    reload 1h
  }
  errors
  log
  debug
}

https://.:443 {
  bind ${server_ip}
  tls localhost.crt localhost.key {
    session_ticket_key session_ticket.key
  }
  hosts {
    ${server_ip} www.localdomain.com
    reload 1h
  }
  errors
  log
  debug
}" > ${coredns_path}/Corefile

cd $root_dir && cd $coredns_path
#echo "starting coredns for DoQ udp:8853, DoUDP udp:53 and DoH tcp:443"
ip netns exec $namespace2 ./coredns >& $root_dir/coredns.log &
corednsPID=$!

sleep 5
#while [[$(tac coredns.log |egrep -m 1 .) != "[INFO] plugin/DoQ: ServePacket()"]]
while ! grep -Fxq "[INFO] plugin/DoQ: ServePacket()" $root_dir/coredns.log
do
  sleep 1
done


dns_server_ip=`echo $ip_address2 |awk -F '/' '{print $1}'`

client_ip=`echo $ip_address1 |awk -F '/' '{print $1}'`
cd $root_dir
#echo "traceroutes from client to server with first ttl 30"
#echo "TCP"
#ip netns exec $namespace1 traceroute -T -f 30 -p 80 $dns_server_ip
#echo "UDP"
#ip netns exec $namespace1 traceroute -U -f 30 -p 53 $dns_server_ip
# echo "hping3"
# echo "TCP"
ip netns exec $namespace1 hping3 -S -c 20 -p 443 $dns_server_ip 
#echo "UDP"
#ip netns exec $namespace1 hping3 --udp -c 1 -p 53 $dns_server_ip

kill -SIGTERM $corednsPID