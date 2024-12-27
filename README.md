Scripts to make xpass based ISPs work with UDM

Original fix from Japanese website zinntikumugai - https://www.zinntikumugai.com/2024/11/03/-6725-/#toc7
However, these scripts have some issues and specifically, they do not handle the fact that the tunnel loose the interface binding if the network goes down and up again (pull the WAN cable, restart a switch on the WAN etc). 

These updated scripts will handle that.

Installation
Enable SSH on the console

Go to Settings -> Internet
Set IPv4 to DS-Lite and input dgw.xpass.jp for gateway

Set IPv6 to SLAAC and single network. Zinntikumugai state that this did not work for them and they had to use prefix delegation with a 64 bit prefix. I tested this with Rakuten Hikari and for me "single network" worked as expected. 


I only have a UDM to test with in Japan, but port numbers on WAN interface will differ depending on UDM model

Please adjust the variables at the start of the xpasssetup.sh script according to your device
---
model=`ubnt-device-info model`
tun_interface=ip6tnl1
IPv6=""
heartbeat_addr=8.8.8.8

#I think port assignment for the SE is correct, but I can only verify the UDM. 
#If you add support for model devices, feel free to send me updates

if [[ $model == "UniFi Dream Machine SE" ]]
then
    ext_interface=eth8
elif [[ $model == "UniFi Dream Machine" ]]
then
    ext_interface=eth4
fi
----

Copy xpasssetup.sh to /root/ folder on the UDM
chmod +x xpasssetup.sh

Copy xpass-start.service to /etc/systemd/system/xpass-start.service
systemctl enable xpass-start

You should now be able to do ping www.rakuten.co.jp and ping6 www.google.com

Check that everything still work if you pull WAN and insert again as well as after reboot.
I have tried to downgrade one release and upgrade again and this setup survived a basic down/upgrade between 4.1.9 and 4.1.11 but it may very well be wiped by a larger fw change

