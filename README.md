# DoQ-H3-measurement

Requires ```../coredns/``` (https://github.com/justus237/coredns) and ```../dnsproxy/``` (https://github.com/justus237/dnsproxy) as well as chromedriver and selenium.

Run ```get_websites.sh```, then ```measure.sh```.

`measure.sh` will run
  - `setup_measurement.sh`, which generates the configuration file, certificate and session ticket encryption key for `coredns` and sets up all the namespaces and connections between them,
  - `tc_netem_[access_tech].sh` to apply delay, download and upload limits to those connections,
  - `run_measurement.sh`, which will start `../coredns/coredns`, start `../dnsproxy/dnsproxy` three times, once for DoQ, once for DoH and once for DoUDP, and use `dig` to resolve `www.localdomain.com` with each of them, and lastly it will run 
    - `chromium_measurement.py` which runs `selenium` twice, once to measure HTTP/3 over QUIC 1-RTT and a second time for 0-RTT. This script will also create all databases (`sqlite3`) and write the data from `chromium` as well as the DNS performance data from `DNS proxy` into those databases

Mainly developed for Ubuntu but would probably work on other distributions.

Network namespaces may not work on all VMs, e.g. Ubuntu 16.04 in VirtualBox did not support virtual ethernet pairs for some reason.

Requires selenium to be installed under sudo's pip or alternatively calling a normal user's Python installation using sudo (currently set to a pyenv managed installation)

Hardcoded paths:
  - Python3 is assumed to be located at `/home/quic_net01/.pyenv/shims/python3` in `run_measurement.sh`
  - Chrome/chromium is assumed to be located at `/home/quic_net01/justus/chromium/src/out/Default/chrome` in `chromium_measurement.py`
  - Chromedriver is assumed to be located at `/home/quic_net01/justus/chromium/src/out/Default/chromedriver` in `chromium_measurement.py`

Check ```$no_proxy``` environment variable and make sure the domain used by Chrome is in there, otherwise the measurement likely won't run on TUM Machines/VMs (they are all proxied by default). We use the 10.0.0.0/24 IP range for the experiment, so in case proxy environment settings are not managed by Ansible or something else, it would probably work by just putting the IP address range in there.

4G network performance values taken from https://github.com/marty90/errant
Trevisan, Martino, Ali Safari Khatouni, and Danilo Giordano. "ERRANT: Realistic emulation of radio access networks." Computer Networks 176 (2020): 107289.

Fixed broaband data taken from https://www.fcc.gov/oet/mba/raw-data-releases (2019)
