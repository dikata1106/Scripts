# PC_IFACE=enx000ec6889de1
# RPI4B_IFACE=eth0
# LAN=192.168.1.0
# PC_IFACE_IP=192.168.1.1
# RPI4B_IFACE_IP=192.168.1.100
# BCAST=192.168.1.255
# MASK=255.255.255.0

# step 1 - PC
sudo ifconfig enx000ec6889de1 up
sudo ifconfig enx000ec6889de1 192.168.1.1 netmask 255.255.255.0
route

# step 2 - RPI4B
sudo ifconfig eth0 up
sudo ifconfig eth0 192.168.1.100 netmask 255.255.255.0
sudo route add default gw 192.168.1.1
route
#or edit in file
#sudo nano /etc/network/interfaces
#auto lo
#iface lo inet loopback
#auto eth0
#iface eth0 inet static
#        address 192.168.1.100
#        netmask 255.255.255.0
#        broadcast 192.168.1.255
#        gateway 192.168.1.1

# step 3 - PC
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null
sudo iptables -P FORWARD ACCEPT
sudo iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.1.0/24
sudo ifconfig enx000ec6889de1 up
sudo ifconfig enx000ec6889de1 192.168.1.1 netmask 255.255.255.0
route

# step 4 - RPI4B
ping -c 5 192.168.1.1
ping -c 5 8.8.8.8

#step 5 - PC
ssh pi@192.168.1.100

