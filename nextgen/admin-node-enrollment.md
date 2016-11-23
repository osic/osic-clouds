#### Enrolling new nodes into Ironic

The OSIC has a diverse set of hardware specifications that we provide to our users. Because of the hardware profile diversity enrolling nodes within Ironic requires a little bit of tender love and care to get them all happy.

To ease the enrollment process a playbook was created which allows for the rapid enrollment of nodes into the cloud. The playbook will enroll a node into Ironic, set all of the required capabilities and properties, define the RAID configuration, and force the node through an initial cleaning.

``` yaml
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
---
- name: Setup the utility location(s)
  hosts: "{{ ironic_node_group }}"
  user: root
  gather_facts: false
  tasks:
    - name: create ironic nodes
      shell: |
        . ~/openrc
        KERNEL_IMAGE=$(glance image-list | awk '/baremetal-ubuntu-xenial.vmlinuz/ {print $2}')
        INITRAMFS_IMAGE=$(glance image-list | awk '/baremetal-ubuntu-xenial.initrd/ {print $2}')
        DEPLOY_RAMDISK=$(glance image-list | awk '/ironic-deploy.initramfs/ {print $2}')
        DEPLOY_KERNEL=$(glance image-list | awk '/ironic-deploy.kernel/ {print $2}')
        if ironic node-list | grep "{{ inventory_hostname }}"; then
            NODE_UUID=$(ironic node-list | awk '/{{ inventory_hostname }}/ {print $2}')
            FIRST_ENROLL=false
        else
            NODE_UUID=$(ironic node-create \
              -d agent_ipmitool \
              -i ipmi_address="{{ ilo_address }}" \
              -i ipmi_password="{{ ilo_password }}" \
              -i ipmi_username="{{ ilo_user }}" \
              -i deploy_ramdisk="${DEPLOY_RAMDISK}" \
              -i deploy_kernel="${DEPLOY_KERNEL}" \
              -n {{ inventory_hostname }} | awk '/ uuid / {print $4}')
            FIRST_ENROLL=true
            ironic port-create -n "$NODE_UUID" \
                               -a {{ Port1NIC_MACAddress }}
        fi
        ironic node-update "$NODE_UUID" add \
                driver_info/deploy_kernel=$DEPLOY_KERNEL \
                driver_info/deploy_ramdisk=$DEPLOY_RAMDISK \
                instance_info/deploy_kernel=$KERNEL_IMAGE \
                instance_info/deploy_ramdisk=$INITRAMFS_IMAGE \
                instance_info/root_gb=744 \
                properties/cpus=48 \
                properties/memory_mb=254802 \
                properties/local_gb=744 \
                properties/size=3600 \
                properties/cpu_arch=x86_64 \
                properties/capabilities=memory_mb:254802,local_gb:744,cpu_arch:x86_64,cpus:48,boot_option:local,disk_label:gpt,system_type:{{ raid_type }}
        echo '{{ raid_configs[raid_type] | to_json }}' | ironic --ironic-api-version 1.15 node-set-target-raid-config "$NODE_UUID" -
        if [ "${FIRST_ENROLL}" = true ];then
          ironic --ironic-api-version 1.15 node-set-provision-state "$NODE_UUID" manage
          ironic --ironic-api-version 1.15 node-set-provision-state "$NODE_UUID" clean \
                  --clean-steps \
                  '[{"interface": "raid", "step": "delete_configuration"}, {"interface": "raid", "step": "create_configuration"}]'
        fi
      delegate_to: "{{ utility_address }}"
  vars:
    raid_configs:
      comp:
        logical_disks:
          - controller: "Smart Array P840 in Slot 3"
            is_root_volume: true
            physical_disks:
              - "1I:1:1"
              - "1I:1:2"
            raid_level: '1'
            size_gb: "MAX"
            volume_name: "root_volume"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "1I:1:3"
              - "1I:1:4"
            raid_level: '1'
            size_gb: "MAX"
            volume_name: "app_volume"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "1I:1:5"
              - "1I:1:6"
              - "1I:1:7"
              - "1I:1:8"
              - "2I:2:1"
              - "2I:2:2"
              - "2I:2:3"
              - "2I:2:4"
            raid_level: '1+0'
            size_gb: "MAX"
            volume_name: "data_volume"
      object:
        logical_disks:
          - controller: "Smart Array P840 in Slot 3"
            is_root_volume: true
            physical_disks:
              - "1I:1:1"
              - "1I:1:2"
            raid_level: '1'
            size_gb: "MAX"
            volume_name: "root_volume"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "1I:1:3"
            raid_level: '0'
            size_gb: "MAX"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "1I:1:4"
            raid_level: '0'
            size_gb: "MAX"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "1I:1:5"
            raid_level: '0'
            size_gb: "MAX"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "1I:1:6"
            raid_level: '0'
            size_gb: "MAX"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "1I:1:7"
            raid_level: '0'
            size_gb: "MAX"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "1I:1:8"
            raid_level: '0'
            size_gb: "MAX"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "2I:2:1"
            raid_level: '0'
            size_gb: "MAX"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "2I:2:2"
            raid_level: '0'
            size_gb: "MAX"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "2I:2:3"
            raid_level: '0'
            size_gb: "MAX"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "2I:2:4"
            raid_level: '0'
            size_gb: "MAX"
      block:
        logical_disks:
          - controller: "Smart Array P840 in Slot 3"
            is_root_volume: true
            physical_disks:
              - "1I:1:1"
              - "1I:1:2"
            raid_level: '1'
            size_gb: "MAX"
            volume_name: "root_volume"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "1I:1:3"
              - "1I:1:4"
            raid_level: '0'
            size_gb: "MAX"
            volume_name: "app_volume"
          - controller: "Smart Array P840 in Slot 3"
            physical_disks:
              - "1I:1:5"
              - "1I:1:6"
              - "1I:1:7"
              - "1I:1:8"
              - "2I:2:1"
              - "2I:2:2"
              - "2I:2:3"
              - "2I:2:4"
            raid_level: '1+0'
            size_gb: "MAX"
            volume_name: "data_volume"
```

This playbook requires an inventory with the following data:

``` ini
[group_name]
ServerID ansible_hostname=ServerHostname ilo_address=x.x.x.x ilo_user=root ilo_password=IloPassword Port1NIC_MACAddress=YY:YY:YY:YY:YY:YY raid_type=comp

ServerID ansible_hostname=ServerHostname ilo_address=x.x.x.x ilo_user=root ilo_password=IloPassword Port1NIC_MACAddress=YY:YY:YY:YY:YY:YY raid_type=object

ServerID ansible_hostname=ServerHostname ilo_address=x.x.x.x ilo_user=root ilo_password=IloPassword Port1NIC_MACAddress=YY:YY:YY:YY:YY:YY raid_type=block
```

The inventory has three entries in it to illustrate the three types of RAID configurations being used within the OSIC hardware.

----

Once the nodes have been enrolled and the initial cleaning has completed the nods will be left in a "managed" state. You will need to cycle through the nodes to promote them into "available" using the "provide" state. The following loop will look for nodes in the "managed" state and promote them.

``` bash
for i in $(ironic node-list | awk '/manage/ {print $2}'); do
  ironic --ironic-api-version 1.15 node-set-provision-state $i provide
done
```

Transitioning a node from "managed" to "available" will trigger another cleaning run. If automated cleaning is enabled node available may take some time.
