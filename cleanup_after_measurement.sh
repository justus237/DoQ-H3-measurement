#!/bin/bash
#network namespaces require sudo
if [[ $EUID -ne 0 ]]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
fi

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