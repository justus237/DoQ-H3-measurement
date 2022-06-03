#!/bin/bash
#set -ex
#network namespaces require sudo
if [[ $EUID -ne 0 ]]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
fi
# increase UDP receive buffer size
sysctl -w net.core.rmem_max=25000000

# disable ipv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1

# https://www.redhat.com/sysadmin/net-namespaces
echo "cleaning up any old leftover data, setting up new vars"
if [[ -f vars ]]; then
  echo "found old vars file, killing any processes running in old namespaces and deleting the namsepaces themselves"
  source vars
  if [[ -e /var/run/netns/${namespace1} ]]; then
    echo "Removing network namespace ${namespace1}"
    ip netns pids $namespace1 | xargs -r kill
    ip netns del $namespace1
  fi
  if [[ -e /var/run/netns/${namespace2} ]]; then
    echo "Removing network namespace ${namespace2}"
    ip netns pids $namespace2 | xargs -r kill
    ip netns del $namespace2
  fi
  if [[ -e /var/run/netns/${namespace3} ]]; then
    echo "Removing network namespace ${namespace3}"
    ip netns pids $namespace3 | xargs -r kill
    ip netns del $namespace3
  fi
  
  if [[ -e /var/run/netns/${namespace11} ]]; then
    echo "Removing network namespace ${namespace11}"
    ip netns del $namespace11
  fi
  if [[ -e /var/run/netns/${namespace22} ]]; then
    echo "Removing network namespace ${namespace22}"
    ip netns del $namespace22
  fi
  #ip link del ptp-$interface1
  #ip link del ptp-$interface2
  rm vars
fi


if [[ -f /tmp/chrome_session_cache.txt ]]; then
  echo "removing old chrome client session cache file"
  rm /tmp/chrome_session_cache.txt
fi



coredns_path="../coredns"
dnsproxy_path="../dnsproxy"
chrome_path="../chromium"

cat << EOF >> vars
namespace1=client
namespace2=server
namespace11=netembridgeclient
namespace22=netembridgeserver
namespace3=netem-bridge
ip_address1="10.0.0.1/24"
ip_address2='10.0.0.2/24'
ip_address11="10.0.0.10/24"
ip_address22='10.0.0.20/24'
interface1=veth-client
interface2=veth-server
interface11=br-veth-client
interface22=br-veth-server
interface12=br-veth-cs
interface21=br-veth-sc
br1=bridge-client
br2=bridge-server
br0=bridge
experiment_type=default
EOF

if [[ ! -f website-under-test ]]; then
  echo "website_under_test=www.localdomain.com" > website-under-test
fi


#get website_under_test
source website-under-test

echo "generating coredns certificates and keys"
openssl req -x509 -out localhost.crt -keyout localhost.key \
  -newkey rsa:2048 -nodes -sha256 \
  -subj '/CN=DNS-over-QUIC-and-HTTP\/3-measurement-setup-TUM' -extensions EXT -config <( \
   printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=IP:10.0.0.2, IP:10.0.0.20, IP:10.0.0.3, IP:10.0.0.4, IP:10.0.0.5, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, DNS:localhost, IP:'::1', DNS:www.example.org, DNS:*.example.org, DNS:example.org\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
cert_fingerprint=$(openssl x509 -pubkey -noout -in localhost.crt | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | base64)
echo $cert_fingerprint > cert_fingerprint.txt

openssl rand -out session_ticket.key 48

mv localhost.crt "${coredns_path}/localhost.crt"
mv localhost.key "${coredns_path}/localhost.key"
mv session_ticket.key "${coredns_path}/session_ticket.key"



source vars

echo "generating Corefile"
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
}" | tee "${coredns_path}/Corefile"


echo "setting up network namespaces"
ip netns add $namespace1
ip netns add $namespace2
#for two bridge setup
ip netns add $namespace11
ip netns add $namespace22

#for one bridge setup
#ip netns add $namespace3
ip netns list

#single cable setup
ip link add $interface1 type veth peer name $interface2
ip link set $interface1 netns $namespace1
ip link set $interface2 netns $namespace2
ip netns exec $namespace1 ip addr add $ip_address1 dev $interface1
ip netns exec $namespace2 ip addr add $ip_address2 dev $interface2
ip netns exec $namespace1 ip link set dev $interface1 up
ip netns exec $namespace2 ip link set dev $interface2 up
#ip netns exec $namespace1 ip addr add 127.0.0.1/8 dev lo
ip netns exec $namespace1 ip link set lo up

# #two bridge setup
# ip link add $interface1 type veth peer name $interface11
# ip link add $interface2 type veth peer name $interface22
# ip link add $interface12 type veth peer name $interface21

# ip link set $interface1 netns $namespace1
# ip link set $interface2 netns $namespace2
# ip netns exec $namespace1 ip addr add $ip_address1 dev $interface1
# ip netns exec $namespace2 ip addr add $ip_address2 dev $interface2
# ip netns exec $namespace1 ip link set dev $interface1 up
# ip netns exec $namespace2 ip link set dev $interface2 up
# ip netns exec $namespace1 ip link set lo up

# ip link set $interface11 netns $namespace11
# ip link set $interface22 netns $namespace22
# ip link set $interface12 netns $namespace11
# ip link set $interface21 netns $namespace22

# ip netns exec $namespace11 ip link set dev $interface11 up
# ip netns exec $namespace11 ip link set dev $interface12 up
# ip netns exec $namespace22 ip link set dev $interface22 up
# ip netns exec $namespace22 ip link set dev $interface21 up

# ip netns exec $namespace11 ip link add name $br1 type bridge
# ip netns exec $namespace22 ip link add name $br2 type bridge
# #ip link set $br1 netns $namespace11
# #ip link set $br2 netns $namespace22

# ip netns exec $namespace11 ip link set $br1 up
# ip netns exec $namespace22 ip link set $br2 up

# ip netns exec $namespace11 ip link set $interface11 master $br1
# ip netns exec $namespace11 ip link set $interface12 master $br1

# ip netns exec $namespace22 ip link set $interface22 master $br2
# ip netns exec $namespace22 ip link set $interface21 master $br2

# #ip netns exec $namespace11 ip addr add $ip_address11 dev $br1
# #ip netns exec $namespace22 ip addr add $ip_address22 dev $br2

# #ip netns exec $namespace1 ip route add default via $ip_address11
# #ip netns exec $namespace2 ip route add default via $ip_address22

# #single bridge setup
# ip link add $interface1 type veth peer name $interface12
# ip link add $interface2 type veth peer name $interface21
# ip link set $interface1 netns $namespace1
# ip link set $interface2 netns $namespace2
# ip netns exec $namespace1 ip addr add $ip_address1 dev $interface1
# ip netns exec $namespace2 ip addr add $ip_address2 dev $interface2
# ip netns exec $namespace1 ip link set dev $interface1 up
# ip netns exec $namespace2 ip link set dev $interface2 up
# ip netns exec $namespace1 ip link set lo up

# ip link set $interface12 netns $namespace3
# ip link set $interface21 netns $namespace3

# ip netns exec $namespace3 ip link set dev $interface12 up
# ip netns exec $namespace3 ip link set dev $interface21 up

# ip netns exec $namespace3 ip link add name $br0 type bridge
# ip netns exec $namespace3 ip link set $br0 up
# ip netns exec $namespace3 ip link set $interface12 master $br0
# ip netns exec $namespace3 ip link set $interface21 master $br0


echo "setting up netns rslv.conf"
mkdir -p /etc/netns/{$namespace1,$namespace2,$namespace11,$namespace22}
touch /etc/netns/$namespace{1,2,11,22}/resolv.conf
#echo "nameserver 127.0.0.2" | tee /etc/netns/${namespace1}/resolv.conf

server_ip=`echo $ip_address2 |awk -F '/' '{print $1}'`
ip netns exec $namespace1 ping -c1 ${server_ip} 2>&1 >/dev/null ; ping_code=$?
#https://unix.stackexchange.com/a/184273
while ! ip netns exec $namespace1 ping -c1 ${server_ip} &>/dev/null
do
  echo "###Pinging server from client failed - `date`"
done

client_ip=`echo $ip_address1 |awk -F '/' '{print $1}'`
ip netns exec $namespace2 ping -c1 ${client_ip} 2>&1 >/dev/null ; ping_code=$?
while ! ip netns exec $namespace2 ping -c1 ${client_ip} &>/dev/null
do
  echo "###Pinging client from server failed - `date`"
done