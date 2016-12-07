#!/bin/bash
# Copyright 2016, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# (c) 2016, Kevin Carter <kevin.carter@rackspace.com>

set -eouv


function _vxlan_mesh_create {
    # Define our variables
    DEV_NAME="vxlan-$1"
    PAD_OCTET="$2"
    VID="$3"
    VGID="$4"
    PIF="$5"

    # Compute the VXLAN ID
    VXLAN_ID="$(( ${PAD_OCTET} + ${VID} ))"

    # Cleanup the interface if found
    (ip link del "$(ip -o l | awk '{print $2}' | grep -wo "^${DEV_NAME}")") || true

    # Create the tunnel interface
    ip link add ${DEV_NAME} type vxlan id ${VXLAN_ID} group ${VGID} ttl 4 dev ${PIF}

    # Enable arp notify on the interface and set it up
    sysctl -w net.ipv4.conf.${DEV_NAME}.arp_notify=1
    sysctl -w net.ipv6.conf.${DEV_NAME}.disable_ipv6=1
    ip link set ${DEV_NAME} up || true
}


function _bridge_create {
    # Define our variables
    DEV_NAME="br-$1"
    PAD_OCTET="$2"
    IP_ADDR="$3"
    BRIDGE_INTERFACE="$4"

    # Cleanup the interface if found
    (ip link del "$(ip -o l | awk '{print $2}' | grep -wo "^${DEV_NAME}")") || true

    # Create a bridge and add the tunnel interface to it
    brctl addbr ${DEV_NAME}
    brctl stp ${DEV_NAME} off
    brctl addif ${DEV_NAME} ${BRIDGE_INTERFACE}

    # IP the bridge, enable ARP notify, and set it up
    ip address add ${IP_ADDR}/22 dev ${DEV_NAME}
    sysctl -w net.ipv4.conf.${DEV_NAME}.arp_notify=1
    sysctl -w net.ipv6.conf.${DEV_NAME}.disable_ipv6=1
    ip link set ${DEV_NAME} up

    # Rebroadcast the mac address
    BRIDGE_MAC="${BRIDGE_MAC:-$(cat /sys/class/net/${DEV_NAME}/address)}"
    ip link set ${DEV_NAME} address "${BRIDGE_MAC}"
}


function _run_network_setup {
    if [[ ! -f "/var/run/mesh-active" ]]; then
      for script in $(ls /opt/network-mesh/scripts/*); do
        [ -f "$script" ] && [ -x "$script" ] && "$script"
      done
      touch /var/run/mesh-active
    fi
}


function setup_host {
    # If something already exists which overlaps with the network config
    #  this next line will remove it.
    (ip -o link | grep -v control | egrep '(vxlan-|br-)' | awk '{print $2}' | sed 's|:||g' | xargs -n 1 ip link del) || true

    # Create the network mesh path
    mkdir -p /opt/network-mesh/scripts

    # This package needs to be installed before bridging will work.
    case ${DISTRO_ID} in
        centos|rhel)
            yum install -y bridge-utils python2 python-requests
            ;;
        ubuntu|debian)
            apt-get update && apt-get install -y bridge-utils python python-requests
            ;;
    esac

    # The VLAN ID is derived from the openssh-key provided to the instances
    #  as set in cloudinit. If, for some reason, cloud-init is not
    #  available a random number will be used. This value is hashed and
    #  converted to an integer. The return integer is the modulo of "16776216"
    #  which is "1000" less than the maximum number of vxlan id's available.
    VLAN_ID=$(python <<EOC
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
EOC
)

    cat > /opt/network-mesh/defaults <<EOF
# The VLAN ID is derived from the openssh-key provided to the instances
#  as set in cloudinit. If, for some reason, cloud-init is not
#  available a random number will be used. This value is hashed and
#  converted to an integer. The return integer is the modulo of "16776216"
#  which is 1000 less than the maximum number of vxlan id's available.
VLAN_ID="\${VLAN_ID:-${VLAN_ID}}"

# Define the primary network interface. This is determined by the Gateway interface
#  should it not be defined elsewhere. In many cases this interface should NOT be
#  the gateway device. If you're building this in an environment like the Rackspace
#  Public cloud you likley want this to be the internal network interface on SNET or
#  a tenant specific network.
PRIMARY_INTERFACE="\${PRIMARY_INTERFACE:=$(ip -o r g 1 | awk '{print $5}')}"

# Compute the GROUP membership address. This address is used to to isolate the network broadcast.
read -n 3 FRN_OCT <<< \${VLAN_ID}
FRN_OCT=\$(( \${FRN_OCT} % 254 ))
MID_OCT="\$(( \${VLAN_ID} % 254 ))"
END_OCT="\$(( \${VLAN_ID:\${#VLAN_ID}<3?0:-3} % 254 ))"

# The multi-cast group will be unique to the user. This provides the isolation needed between users.
GROUP_ADDR="\${GROUP_ADDR:-230.\$FRN_OCT.\$MID_OCT.\$END_OCT}"
EOF

    cat > /opt/network-mesh/scripts/00-bond-mtu <<EOF
if [[ -d "/sys/class/net/bond0" ]];then
  # Ensure the bonds slaves are using an MTU of 9000
  for i in $(cat /sys/class/net/bond0/bonding/slaves); do
    ip link set \$i mtu 9000
  done

  # Ensure bond0 is using an MTU of 9000
  ip link set bond0 mtu 9000
fi
EOF
    chmod +x /opt/network-mesh/scripts/00-bond-mtu

    # Generate functions script
    FUNCTIONS_SCRIPT="/opt/network-mesh/functions"
    echo '#!/usr/bin/env bash' > ${FUNCTIONS_SCRIPT}
    for i in "_vxlan_mesh_create" "_bridge_create" "_run_network_setup"; do
      echo "function $(declare -f $i)" >> ${FUNCTIONS_SCRIPT}
    done

    touch /opt/network-mesh/setup-complete
}


function get_ip {
    # This function ensures that a given IP address is available.
    #  Should an IP address not be available it will retry until it
    #  discovers one.
    set +e
    RETURN_IP=false
    proposed_addr="$1.$(ip -o r g 1 | awk '{print $7}' | awk -F'.' '{print $4}')"
    while [ ${RETURN_IP} = false ]; do
      if ! ping -c 1 -w 1 "${proposed_addr}" 2>&1 > /dev/null; then
        RETURN_IP="${proposed_addr}"
      else
        proposed_addr="$1.$(( ( RANDOM % 254 ) + 1 ))"
      fi
    done
    set -e
    echo "${proposed_addr}"
}


# Do basic OS detection
source /etc/os-release
export DISTRO_ID="${ID}"
export DISTRO_NAME="${NAME}"
export DISTRO_VERSION_ID="${VERSION_ID}"

# Run basic host setup. This is only run once.
if [[ ! -f "/opt/network-mesh/setup-complete" ]]; then
  setup_host
fi

# Run the network generation setup
PAD_OCTET=0
for i in {1..10}; do
  INTERFACE_SCRIPT="/opt/network-mesh/scripts/10-vxlan-$i"
  PAD_OCTET="$(( PAD_OCTET + 4 ))"
  if [[ ! -f "${INTERFACE_SCRIPT}" ]]; then
    echo '#!/usr/bin/env bash' > ${INTERFACE_SCRIPT}
    echo '. /opt/network-mesh/defaults' >> ${INTERFACE_SCRIPT}
    echo '. /opt/network-mesh/functions' >> ${INTERFACE_SCRIPT}
    echo "_vxlan_mesh_create \"$i\" \"${PAD_OCTET}\" \"\${VLAN_ID}\" \"\${GROUP_ADDR}\" \"\${PRIMARY_INTERFACE}\"" >> ${INTERFACE_SCRIPT}
    chmod +x ${INTERFACE_SCRIPT}
  fi
done

COUNT=0
PAD_OCTET=0
for i in "mgmt" "storage" "repl" "flat" "vlan" "tunnel"; do
  PAD_OCTET="$(( PAD_OCTET + 4 ))"
  let COUNT=COUNT+1
  INTERFACE_SCRIPT="/opt/network-mesh/scripts/20-br-$i"
  if [[ ! -f "${INTERFACE_SCRIPT}" ]]; then
    IP_ADDR="$(get_ip 172.16.${PAD_OCTET})"
    echo '#!/usr/bin/env bash' > ${INTERFACE_SCRIPT}
    echo '. /opt/network-mesh/defaults' >> ${INTERFACE_SCRIPT}
    echo '. /opt/network-mesh/functions' >> ${INTERFACE_SCRIPT}
    echo "_bridge_create \"$i\" \"${PAD_OCTET}\" \"${IP_ADDR}\" \"vxlan-${COUNT}\"" >> ${INTERFACE_SCRIPT}
    chmod +x ${INTERFACE_SCRIPT}
  fi
done

NETWORK_SETUP_SCRIPT="/opt/network-mesh/run_network_setup.sh"
if [[ ! -f "${NETWORK_SETUP_SCRIPT}" ]]; then
  echo '#!/bin/bash' > "${NETWORK_SETUP_SCRIPT}"
  echo ". /opt/network-mesh/functions" >> "${NETWORK_SETUP_SCRIPT}"
  echo "_run_network_setup" >> "${NETWORK_SETUP_SCRIPT}"
  chmod +x "${NETWORK_SETUP_SCRIPT}"
fi

# Run OS persistence
case ${DISTRO_ID} in
    centos|rhel)
        sed -i "/exit\s0/i ${NETWORK_SETUP_SCRIPT}\n" /etc/sysconfig/network-scripts/ifup-post
        ;;
    ubuntu|debian)
        ln -sf ${NETWORK_SETUP_SCRIPT} /etc/network/if-up.d/mesh-network
        chmod +x /etc/network/if-up.d/mesh-network
        ;;
esac

# Run network setup
eval "${NETWORK_SETUP_SCRIPT}"
