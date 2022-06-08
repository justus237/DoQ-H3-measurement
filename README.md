# DoQ-H3-measurement

run ```get_websites.sh```, then ```measure.sh```, requires ```../coredns/``` and ```../dnsproxy/``` as well as chromdriver and selenium.

Mainly developed for Ubuntu but would probably work on other distributions.

Network namespaces may not work on all VMs, e.g. Ubuntu 16.04 in VirtualBox did not support virtual ethernet pairs for some reason.

Requires selenium to be installed under sudo's pip or alternatively calling a normal user's Python installation using sudo (currently set to a pyenv managed installation)

Check ```$no_proxy``` environment variable and make sure the domain used by Chrome is in there, otherwise the measurement likely won't run on TUM Machines/VMs (they are all proxied by default). We use the 10.0.0.0/24 IP range for the experiment, so in case proxy environment settings are not managed by Ansible or something else, it would probably work by just putting the IP address range in there.

Initial version was based on this tutorial: https://www.redhat.com/sysadmin/net-namespaces, however it was extended to move the netem limitations away from the network interfaces used by the applications, because the network stack will generally be aware of netem and not behave properly. Introduced third namespace with a bridge to solve this.

4G network performance values taken from https://github.com/marty90/errant
Trevisan, Martino, Ali Safari Khatouni, and Danilo Giordano. "ERRANT: Realistic emulation of radio access networks." Computer Networks 176 (2020): 107289.

Fixed broaband data taken from https://www.fcc.gov/oet/mba/raw-data-releases (2019)