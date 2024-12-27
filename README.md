# Scripts to make xpass based ISPs work with UDM

This is heavily insipired by an article on the Japanese website zinntikumugai - https://www.zinntikumugai.com/2024/11/03/-6725-/#toc7

However, the examples there have some issues.  For instance, they do not handle the fact that the tunnel loose the interface binding if the network goes down and up again (pull the WAN cable, restart a switch on the WAN etc). 

These updated scripts will handle that.
They are only tested with Rakuten Hikari but seems to work stable there

I have tried to downgrade one release and upgrade again and this setup survived a basic down/upgrade between 4.1.9 and 4.1.11 but it may very well be wiped by a larger fw change. 

I was thinking to make a .deb package, but I decided against it for now as the script may need adoptation depending on controller model and which port is used for WAN.

## Installation
### Change Settings on the UDM
- Enable SSH on the console
- Go to Settings -> Internet

Please notice that if you currently use pppoe connection, the settings here will make you loose ipv4 connection to the internet until you finish the process.

Set IPv4 to DS-Lite and input dgw.xpass.jp for gateway

Set IPv6 to SLAAC and single network. 
![alt text](https://github.com/terjenm/xpass-start/blob/main/Images/InternetSettings.png?raw=true)
Zinntikumugai state that "single network" did not work for them and they had to use prefix delegation with a 64 bit prefix. I tested this with Rakuten Hikari and for me "single network" worked as expected. 

### Adopt the script as needed.
I only have a UDM to test with in Japan, but port numbers on WAN interface will differ depending on UDM model

Please adjust the variables at the start of the xpasssetup.sh script according to your device
```
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
```
- scp xpasssetup.sh to /root/ folder on the UDM
- chmod +x xpasssetup.sh
- scp xpass-start.service to /etc/systemd/system/xpass-start.service
- systemctl enable xpass-start

To check that things works as expected try:
- ping www.rakuten.co.jp
- ping6 www.google.com

Check that everything still work if you pull WAN and insert again as well as after reboot.



