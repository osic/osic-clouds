#### Building baremetal images

This is a quick rundown on the steps used to create the OSIC baremetal images. For a more detailed rundown on Ironic image building [please read the following post](https://cloudnull.io/2016/11/openstack-ironic-images-and-flavors/).

----

###### Install required apt packages

``` bash
apt-get install -y qemu uuid-runtime curl kpartx
```

Install the disk-image-builder (DIB)

``` bash
pip install diskimage-builder --isolated
```

Clone the OSIC diskimage-builder elements

``` bash
git clone https://github.com/osic/osic-elements /opt/osic-elements
```

##### Create the deploy image

The OSIC uses Gen9 proliant servers. The following set of commands will create a proper deploy image using the ``stable/newton`` release of IPA and ensure the deploy image has access to the proliant tools for node management.

``` bash
# Export a few variables used to provide debug access to the deploy image
DIB_DEV_USER_USERNAME=debug-user
DIB_DEV_USER_PASSWORD=secrete
DIB_DEV_USER_PWDLESS_SUDO=yes

# This URL is subject to change, in the after now
#  it may be different. Please set this accordingly.
export DIB_HPSSACLI_URL="http://downloads.hpe.com/pub/softlib2/software1/pubsw-linux/p1857046646/v109216/hpssacli-2.30-6.0.x86_64.rpm"

# If you're running Ironic ``<=newton`` you should use the
#  newton version of IPA.
export IRONIC_AGENT_VERSION="stable/newton"

# NOTE THIS IS USING "fedora" ON PURPOSE.
#  The proliant tools only have a pre-built RPM.
#  While you can provision other Linux Operating
#  systems the "deploy image" will NEED to be "fedora".
disk-image-create --install-type source -o ironic-deploy ironic-agent fedora devuser proliant-tools
```

###### Upload the deploy image into glance

``` bash
# Upload the deploy image kernel
glance image-create --name ironic-deploy.kernel \
                    --visibility public \
                    --disk-format aki \
                    --property hypervisor_type=baremetal \
                    --protected=True \
                    --container-format aki < ironic-deploy.kernel

# Upload the user image initramfs
glance image-create --name ironic-deploy.initramfs \
                    --visibility public \
                    --disk-format ari \
                    --property hypervisor_type=baremetal \
                    --protected=True \
                    --container-format ari < ironic-deploy.initramfs
```

##### Create a user image

The OSIC uses Ubuntu 14.04 and 16.04 as well as CentOS 7 images by default. The following two commands will illustrate how to build both Ubuntu and CentOS.

**Build the Ubuntu image** *You can configure the Ubuntu release by setting the "DIB_RELEASE" accordingly.*
``` bash
# Set the release
export DIB_RELEASE=xenial
export DISTRO_NAME=ubuntu

# Create the image
ELEMENTS_PATH="/opt/osic-elements" DIB_CLOUD_INIT_DATASOURCES="Ec2, ConfigDrive, OpenStack" disk-image-create -o baremetal-$DISTRO_NAME-$DIB_RELEASE $DISTRO_NAME baremetal bootloader osic-dfw
```

**Build the CentOS image**
``` bash
# Set the release
export DIB_RELEASE=centos
export DISTRO_NAME=7

# Create the image
ELEMENTS_PATH="/opt/osic-elements" DIB_CLOUD_INIT_DATASOURCES="Ec2, ConfigDrive, OpenStack" disk-image-create -o baremetal-$DISTRO_NAME-$DIB_RELEASE centos7 baremetal bootloader epel osic-dfw
```

###### Upload the user image into glance
``` bash
# Upload the user image vmlinuz and store uuid
VMLINUZ_UUID="$(glance image-create --name baremetal-$DISTRO_NAME-$DIB_RELEASE.vmlinuz \
                                    --visibility public \
                                    --disk-format aki \
                                    --property hypervisor_type=baremetal \
                                    --protected=True \
                                    --container-format aki < baremetal-$DISTRO_NAME-$DIB_RELEASE.vmlinuz | awk '/\| id/ {print $4}')"

# Upload the user image initrd and store uuid
INITRD_UUID="$(glance image-create --name baremetal-$DISTRO_NAME-$DIB_RELEASE.initrd \
                                   --visibility public \
                                   --disk-format ari \
                                   --property hypervisor_type=baremetal \
                                   --protected=True \
                                   --container-format ari < baremetal-$DISTRO_NAME-$DIB_RELEASE.initrd | awk '/\| id/ {print $4}')"

# Create image
glance image-create --name baremetal-$DISTRO_NAME-$DIB_RELEASE \
                    --visibility public \
                    --disk-format qcow2 \
                    --container-format bare \
                    --property hypervisor_type=baremetal \
                    --property kernel_id=${VMLINUZ_UUID} \
                    --protected=True \
                    --property ramdisk_id=${INITRD_UUID} < baremetal-$DISTRO_NAME-$DIB_RELEASE.qcow2
```

----

With that complete you will have a functional deploy image based on Fedora with all of the needed tools to manage HP proliant servers. You will also have a user image which will automatically come up with nics using the ``i40e`` driver and will be available for bonding.
