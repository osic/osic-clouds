#### Getting SSH Access

``` bash
PUBLICIP_OF_ACCESS_NODE="<IP_ADDRESS_FROM_NODE_YOU_CREATED>"
```

Now create an ssh config that will allow you to proxy your connections through the access appliance.

``` conf
cat > ${HOME}/.ssh/osic-proxy-ssh <<EOF
host osic-proxy-bastion
  HostName $PUBLICIP_OF_ACCESS_NODE
  User ubuntu
  ProxyCommand none
  ForwardAgent yes
  ControlPath none

Host *
  ForwardAgent yes
  Compression yes
  CompressionLevel 7
  TCPKeepAlive yes
  ServerAliveInterval 60
  ControlPersist 10h
  StrictHostKeyChecking no
  VerifyHostKeyDNS no
  HashKnownHosts no
  ProxyCommand ssh -F ${HOME}/.ssh/osic-proxy-ssh -A osic-proxy-bastion 'nc %h %p'
EOF
```

With the ssh config in place access is quite simple using the following command after you've provisioned your baremetal resources.

``` bash
ssh -o StrictHostKeyChecking=no -F ${HOME}/.ssh/osic-proxy-ssh <USER>@$TARGETNODE
```

###### *Optional*
You may also wish to create an alias in your user's profile giving you simple command line access.

``` bash
# On Apple MacOS
echo "alias osicssh='ssh -o StrictHostKeyChecking=no -F ${HOME}/.ssh/osic-proxy-ssh'" >> ~/.profile

# On most Linux Distro's
echo "alias osicssh='ssh -o StrictHostKeyChecking=no -F ${HOME}/.ssh/osic-proxy-ssh'" >> ~/.bashrc
```

If you create the alias you will need to reload your profile before using it. That can be done by simply logging out and back into the terminal session.

One the alias is loaded you can access your target nodes using the following command.

``` bash
osicssh <USER>@$TARGETNODE
```
