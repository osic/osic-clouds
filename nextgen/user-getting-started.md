#### Getting started

1. Login to the OSIC at "https://cloud1.osic.org":

  ![OSIC Login](images/create-new-vm-1.png)

2. Access Cloud1 **"RegionOne"** to build your jump box:

  ![Switch to RegionOne](images/create-new-vm-2.png)

3. Create a VM:

  ![Create a VM](images/create-new-vm0.png)

4. Name the VM:

  ![Name VM](images/create-new-vm1.png)

5. Select the baremetal appliance image: *Note that the image used for accessing baremetal is an "Instance Snapshot".*

  ![Image Select](images/create-new-vm2.png)

6. Select the flavor: *The flavor used does not need many resources. I recommend simply using ``m1.small``.*

  ![Flavor Select](images/create-new-vm3.png)

7. Add networks to the VM: *The VM will need to use 2 networks. **GATEWAY\_NET** will be the first network and **BAREMETAL\_NET** will be the second. This combination will allow for public access using an IPv4 network and pass through for baremetal.*

  ![Add Networks](images/create-new-vm4.png)

8. Add your key to the VM: *If you fail to add an SSH key to the node you will not have access and will need to start over.*

  ![Add an SSH key](images/create-new-vm5.png)
