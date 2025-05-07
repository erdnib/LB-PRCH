#!/bin/bash
# Back up the current netplan configuration
sudo cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.copy
# Prompt for static IP and gateway
read -p "Enter pricechecker IP (e.g., 10.0.10.50/24): " ip_address
read -p "Enter gateway IP: " gateway
# Automatically detect the first active non-loopback interface
interface=$(ip -o link show | awk -F': ' '{print $2}' | grep -vE '^lo$' | head -n 1)
# Generate new netplan configuration
sudo tee /etc/netplan/00-installer-config.yaml > /dev/null <<EOF
network:
  version: 2
  ethernets:
    ${interface}:
      dhcp4: false
      addresses:
        ${ip_address}
      routes:
          to: 0.0.0.0/0
          via: ${gateway}
EOF
# Apply new network configuration
sudo netplan apply
# Select the ACR server from the list
echo "Please select ACR server from the list:"
PS3="Enter your choice [1-14]: "
select opt in \
    "65st" "E16st" "Philly 1" "18th ave" "Staten Island" "Queens" "Brighton" \
    "Philly2" "Manalapan" "Paramus" "Ocean" "Neptune" "Florida(Oakwood)" "Exit"
do
    case $REPLY in
        1) pricecheckersrv="10.0.1.5"; break ;;
        2) pricecheckersrv="10.0.2.5"; break ;;
        3) pricecheckersrv="10.0.4.5"; break ;;
        4) pricecheckersrv="10.0.5.5"; break ;;
        5) pricecheckersrv="10.0.6.5"; break ;;
        6) pricecheckersrv="10.0.7.5"; break ;;
        7) pricecheckersrv="10.0.8.5"; break ;;
        8) pricecheckersrv="10.0.9.5"; break ;;
        9) pricecheckersrv="10.0.10.5"; break ;;
        10) pricecheckersrv="10.0.11.5"; break ;;
        11) pricecheckersrv="10.0.12.5"; break ;;
        12) pricecheckersrv="10.0.14.5"; break ;;
        13) pricecheckersrv="10.0.15.5"; break ;;
        14) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option"; continue ;;
    esac
done
echo "Selected server: $pricecheckersrv"
# Install X server, Openbox, and Firefox
sudo apt update
sudo apt install --no-install-recommends -y xorg openbox firefox
# Create a script to launch Firefox in kiosk mode
sudo mkdir -p /opt/kiosk
sudo tee /opt/kiosk/kiosk.sh > /dev/null <<EOF
#!/bin/bash
xset s off
xset -dpms
xset s noblank
openbox-session &
sleep 3
while true; do
  /usr/bin/firefox --kiosk --private-window --width=1280 --height=800 http://${pricecheckersrv}:4322/access/PriceChecker.html 
done 
EOF

sudo chmod +x /opt/kiosk/kiosk.sh
# Create a systemd unit for kiosk service
sudo tee /etc/systemd/system/kiosk.service > /dev/null <<EOF
[Unit]
Description=Start Firefox Kiosk
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
ExecStart=/usr/bin/startx /opt/kiosk/kiosk.sh
User=ubuntu
Environment=DISPLAY=:0
[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 /etc/systemd/system/kiosk.service
# Reload systemd and enable the kiosk service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable kiosk.service
sudo systemctl restart kiosk.service
