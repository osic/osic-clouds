#### Creating Isolated Networks within Ironic Hosts

###### Preventing VXLAN Collisions at Scale
While creating a VXLAN network with a random ID and a random multicast address is decent at preventing collisions we want to be more consistent and programmatic about it. 

###### Generating the magic numbers
In OpenStack we can consume metadata and consistently generate variables on a per-user basis which will be used to intelligently isolate traffic from other users within the cloud. To be able to programmatically isolate networks we're going to be generating an ``integer`` from the user provided public key as found in the OpenStack metadata service. To get "magic number" the public key will be ``hash`` using **sha256** which will then be converted to a **base36** ``integer`` and the returned value will be the modulo of "16776216" which is "1000" less than the maximum number of VXLAN IDs available. ==This little python script will do everything needed==.

``` python
import requests
import hashlib
import random
try:
    key = requests.get('http://169.254.169.254/1.0/meta-data/public-keys/0/openssh-key')
except Exception:
    string = str(random.randrange(1, 16776216))
else:
    string = key.content.encode('utf-8')
finally:
    string = hashlib.sha256(string).hexdigest()
    print(int(string, 36) % 16776216)
```

After executing this script, or running the commands by hand, the output will be used as the VXLAN ID tag and with that we can generate all of the rest of the data we'll need isolate a specific users internal traffic. Set the output as a variable known as ``VLAN_ID``.

Now grab the primary network interface. If you know it, just set the ``PIF`` variable accordingly otherwise running the following bash commands will get the interface providing the default route.

``` shell
PIF=$(ip -o r g 1 | awk '{print $5}')
```

Now set the following variables to define the multicast group.

``` shell
read -n 3 FRN_OCT <<< ${VLAN_ID}
FRN_OCT=$(( ${FRN_OCT} % 254 ))
MID_OCT="$(( ${VLAN_ID} % 254 ))"
END_OCT="$(( ${VLAN_ID:${#VLAN_ID}<3?0:-3} % 254 ))"
GROUP_ADDR="${GROUP_ADDR:-230.$FRN_OCT.$MID_OCT.$END_OCT}"
```

Name the VXLAN network

``` shell
DEVICE_NAME="vxlan-0"
```

Now string it all together to create a specific vxlan network.

``` shell
ip link add ${DEVICE_NAME} type vxlan id ${VXLAN_ID} group ${GROUP_ADDR} ttl 4 dev ${PIF}
ip link set ${DEVICE_NAME} up  
```

----

#### Network Setup Script
This is [the mesh creation script](scripts/vxlan-mesh-create.sh) (easy button). The script will generate everything needed to isolated a users traffic between hosts, create 10 vxlan type networks, and 6 bridges with unique IP addresses on them. Once run, the script will drop all of the persistent configs in ``/opt/network-mesh``. 

###### Rerunning the network config
If you ever need to rerun anything to recreate an interface or reset a value you can execute the scripts directly as found in the scripts directory which will create various parts of the stack or you can remove the file ``/var/run/mesh-active`` and rerunning ``/opt/network-mesh/run_network_setup.sh`` which will rerun the entire setup. 

> **NOTICE**: If you force rerun ``/opt/network-mesh/run_network_setup.sh`` the bridges will be re-created and any ephemeral devices plugged into those bridges may be broken (Container and VMs can be greatly effected by this).

###### Joining another user's network
If you find yourself in a situation where you need to join another user's deployment you can by simply changing the network-mesh defaults as found here ``/opt/network-mesh/defaults``. In order to join another user's deployment you will need to copy over the defaults file and rerun the network setup. Rerruning the network setup can be done by rebooting the host or by [executing the following](#rerunningthenetworkconfig).
