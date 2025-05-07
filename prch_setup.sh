#!/bin/bash
sudo mv /etc/netplan/1-network-manager-all.yaml /etc/netplan/1-network-manager-all.yaml.copy

read -p "Enter pricechecker IP: " ip_address
read -p "Enter gateway IP: " gateway

echo "
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp2s0:
      dhcp4: no
      addresses: [${ip_address}/24]
      gateway4: ${gateway}
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]" | tee /etc/netplan/1-network-manager-all.yaml

sudo netplan apply


echo "Please select ACR server from the list:"
echo "1) 65st"
echo "2) E16st"
echo "3) Philly 1"
echo "4) 18th ave"
echo "5) Staten Iland"
echo "6) Queens"
echo "7) Brighton"
echo "8) Philly2"
echo "9) Manalapan"
echo "10) Paramus"
echo "11) Ocean"
echo "12) Neptune"
echo "13) Florida(Oakwood)"
echo "14) exit"
read -p "Enter your choice [1-14]: " choice
case $choice in
    1)
        pricecheckersrv="10.0.1.5"
        ;;
    2)
        pricecheckersrv="10.0.2.5"
        ;;
    3)
        pricecheckersrv="10.0.4.5"
        ;;
    4)
        pricecheckersrv="10.0.5.5"
        ;;
    5)
        pricecheckersrv="10.0.6.5"
        ;;
    6)
        pricecheckersrv="10.0.7.5"
        ;;
    7)
        pricecheckersrv="10.0.8.5"
        ;;
    8)
        pricecheckersrv="10.0.9.5"
        ;;
    9)
        pricecheckersrv="10.0.10.5"
        ;;
    10)
        pricecheckersrv="10.0.11.5"
        ;;
    11)
        pricecheckersrv="10.0.12.5"
        ;;
    12)
        pricecheckersrv="10.0.14.5"
        ;;
    13)
        pricecheckersrv="10.0.15.5"
        ;;
    14)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid selection."
        exit 1
        ;;
esac
echo "You selected: $pricecheckersrv"

# Write X.org startup script to /opt/kiosk/kiosk.sh
sudo mkdir /opt/kiosk
echo "xset s off
xset -dpms
xset -s noblank
openbox-session &
while true;
do
  /usr/bin/firefox -kiosk -private-window -width=1280 -height=800 http://${pricecheckersrv}:4322/access/PriceChecker.html
done" | sudo tee /opt/kiosk/kiosk.sh

# Write service file to /etc/systemd/system/kiosk.service
echo "[Unit]
Description=Start kiosk
[Service]
Type=simple
ExecStartPre=/bin/sleep 30
ExecStart=sudo startx /etc/X11/Xsession /opt/kiosk/kiosk.sh
[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/kiosk.service

# Add permissions to the files
sudo chmod 644 /etc/systemd/system/kiosk.service
sudo chmod +x /opt/kiosk/kiosk.sh

# Enable the service on startup
sudo systemctl daemon-reload
sudo systemctl enable kiosk
sudo systemctl set-default multi-user.target
# Finish
sudo systemctl stop kiosk
sudo systemctl start kiosk
sudo reboot

