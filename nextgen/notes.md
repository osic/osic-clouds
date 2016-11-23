#### Notes

  - For the socks proxy to work you will need to be SSH'd into one of your hosts which automatically creates the tunnel.

  - All Ironic nodes will come with both an IPv4 and an IPv6 address. If you wish to use IPv6 the host will need to have port 0 and 2 bonded. This requirement is due to a known bug in the Nexus 3k switches which drop multicast traffic when bonding is enabled and a node has an interface in standalone mode.

  - Only one jumpbox is required per project tenant. If you wish to provide access to your environment to multiple users you can do so by simply logging into the jump box as the "ubuntu" user and adding an ssh key to the "authroized_keys" file found at ``/home/ubuntu/.ssh/authorized_keys``. You will also need to add that key to any physical node you wish to share.

  - When provisioning a new baremetal node the time it takes to become active can take nearly 30 minutes, assuming there were no issues or delays in scheduling.

  - If a node is active but unreachable try hard rebooting the instance. There have been occasions where cloud-init does not do everything perfectly on the first boot which requires a reboot to finish.
