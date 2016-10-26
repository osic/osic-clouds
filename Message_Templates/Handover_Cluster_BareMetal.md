# Bare Metal Allocation

Greetings,

We have finished deploying your bare metal server allocation of <#_of_servers> servers.  These servers will be available to you until <Month, Day, Year>.  Below is detailed information about the servers, including access information, hardware details, and cable/switchport configuration with VLANS trunked.

## Accessing the OSIC Servers

You are required to install an F5's SSL VPN to access the OSIC servers. The SSL VPN is a browser plugin.

Open URL <insert-URL> in your browser and follow the instructions.
You can login with the following credentials:
Username: <osic-cloud-username>
Password: <insert-one-time-click-link>

Your VPN account has been setup to allow communication to all routed networks shown in the diagram below.

Server Cabling and Switch Port Configuration

Every server you have been allocated has its cables and switchports configured as indicated by the attached diagram.

## Servers

The following 66 servers have been allocated to you. Each server has the following specs:
 - Model: HP DL380 Gen9
 - Processor: 2x 12-core Intel E5-2680 v3 @ 2.50GHz
 - RAM: 256GB RAM
 - Disk: 12x 600GB 15K SAS - RAID10
 - NICS: 2x Intel X710 Dual Port 10 GbE

All servers contain two Intel X710 10 GbE NICs. This is a relatively new NIC that has caused us a lot of problems during the setup of the OSIC environment. 

> If you will be installing Ubuntu Server 14.04 on these servers, we highly recommend you use an i40e driver no older than 1.3.47.

The server hostnames (as we identify them in our internal systems) are below as well as the iLO IP address for each server. Please use the iLO IP addresses, and not the hostnames, to access the servers via iLO. The iLO username is root and the iLO password is <INSERT_PASSWORD>.

 > < DEVICE LIST WITH NODE NAMES AND ILO IP'S >

 > < INSERT DEVICE LIST HERE >

 > < / DEVICE LIST WITH NODE NAMES AND ILO IP'S >
 
## Gathering MAC Addresses for PXE Booting

The switchport networking has been configured in a way that allows you to PXE boot from p1p1. Pick one of those network interfaces to PXE boot from for every server.
Depending on which network interface you pick, you can get its MAC address from the server's iLO using the following method.
If you run command 

```
sshpass -p <iLO password> ssh -o StrictHostKeyChecking=no root@ILO_IP show /system1/network1/Integrated_NICs
```

from your workstation while connected to the VPN, you will get the following output from the iLO (the MAC addresses will of course be different for each server):

```
show /system1/network1/Integrated_NICs
status=0
status_tag=COMMAND COMPLETED
Mon Jan 25 16:55:35 2016
/system1/network1/Integrated_NICs
  Targets
  Properties
    iLO4_MACAddress=ec:b1:d7:7a:3d:fc
    Port1NIC_MACAddress=3c:a8:2a:23:e1:f4
    Port2NIC_MACAddress=3c:a8:2a:23:e1:f5
    Port3NIC_MACAddress=3c:a8:2a:23:e1:f6
    Port4NIC_MACAddress=3c:a8:2a:23:e1:f7
    Port5NIC_MACAddress=3c:fd:fe:9c:67:20
    Port6NIC_MACAddress=3c:fd:fe:9c:67:21
    Port7NIC_MACAddress=3c:fd:fe:9c:64:3c
    Port8NIC_MACAddress=3c:fd:fe:9c:64:3d
  Verbs
    cd version exit show
```
Every server you have been allocated has the same number of NICs. The MAC addresses map to their corresponding network interfaces in the operating system in the following way:
```
  Properties
    iLO4_MACAddress=ec:b1:d7:7a:3d:fc
    Port1NIC_MACAddress=3c:a8:2a:23:e1:f4 --> em1
    Port2NIC_MACAddress=3c:a8:2a:23:e1:f5 --> em2
    Port3NIC_MACAddress=3c:a8:2a:23:e1:f6 --> em3
    Port4NIC_MACAddress=3c:a8:2a:23:e1:f7 --> em4
    Port5NIC_MACAddress=3c:fd:fe:9c:67:20 --> p1p1
    Port6NIC_MACAddress=3c:fd:fe:9c:67:21 --> p1p2
    Port7NIC_MACAddress=3c:fd:fe:9c:64:3c --> p4p1
    Port8NIC_MACAddress=3c:fd:fe:9c:64:3d --> p4p2
```
 
You can loop through all iLO's and parse the output as needed to get the MAC address for p1p1 to PXE boot with.
Troubleshooting iLO Connectivity
 
If for some reason you lose connectivity to the server(s) iLO, try to reset it using the following ipmitool command:
```
ipmitool -I lanplus -U root -p <iLO password> -H <iLO IP> mc reset warm
```
If you still have connectivity problems, please submit open a ticket with Rackspace identifying the problematic servers.
 
---

Thank you,

OSIC Cluster Team