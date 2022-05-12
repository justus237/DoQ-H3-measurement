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
if [ -f vars ]; then
  echo "found old vars file, killing any processes running in old namespaces and deleting the namsepaces themselves"
  source vars
  if [ -e /var/run/netns/${namespace1} ]; then
    echo "Removing network namespace ${namespace1}"
    ip netns pids $namespace1 | xargs kill
    ip netns del $namespace1
  fi
  if [ -e /var/run/netns/${namespace2} ]; then
    echo "Removing network namespace ${namespace2}"
    ip netns pids $namespace2 | xargs kill
    ip netns del $namespace2
  fi
  #ip link del ptp-$interface1
  #ip link del ptp-$interface2
  rm vars
fi


if [ -f /tmp/chrome_session_cache.txt ]; then
  echo "removing old chrome client session cache file"
  rm /tmp/chrome_session_cache.txt
fi



coredns_path="../coredns"
dnsproxy_path="../dnsproxy"
chrome_path="../chromium"

cat << EOF >> vars
namespace1=client
namespace2=server
ip_address1="10.0.0.1/24"
ip_address2='10.0.0.2/24'
interface1=veth-client
interface2=veth-server
EOF


echo "generating coredns certificates and keys"
openssl req -x509 -out localhost.crt -keyout localhost.key \
  -newkey rsa:2048 -nodes -sha256 \
  -subj '/CN=localhost' -extensions EXT -config <( \
   printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
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
    ${server_ip} www.example.org
    reload 1h
  }
  h3server /tmp/quic-data/www.example.org/ ${server_ip}:6121
  errors
  log
  debug
}
.:53 {
  bind ${server_ip}
	hosts {
    ${server_ip} www.example.org
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
    ${server_ip} www.example.org
    reload 1h
  }
	errors
	log
	debug
}" | tee "${coredns_path}/Corefile"


echo "setting up network namespaces"
ip netns add $namespace1
ip netns add $namespace2
ip netns list

ip link add ptp-$interface1 type veth peer name ptp-$interface2
ip link set ptp-$interface1 netns $namespace1
ip link set ptp-$interface2 netns $namespace2
ip netns exec $namespace1 ip addr add $ip_address1 dev ptp-$interface1
ip netns exec $namespace2 ip addr add $ip_address2 dev ptp-$interface2
ip netns exec $namespace1 ip link set dev ptp-$interface1 up
ip netns exec $namespace2 ip link set dev ptp-$interface2 up
#ip netns exec $namespace1 ip addr add 127.0.0.1/8 dev lo
ip netns exec $namespace1 ip link set lo up



echo "setting up netns rslv.conf"
mkdir -p /etc/netns/{$namespace1,$namespace2}
touch /etc/netns/$namespace{1,2}/resolv.conf
#echo "nameserver 127.0.0.2" | tee /etc/netns/${namespace1}/resolv.conf