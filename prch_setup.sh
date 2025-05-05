read -p "Enter pricechecker IP: " pricecheckerip

# Install X.org, OpenBox, Firefox
sudo apt install --no-install-recommends -y xorg openbox firefox

# Write X.org startup script to /opt/kiosk/kiosk.sh
sudo mkdir /opt/kiosk
echo "xset s off
xset -dpms
xset -s noblank
off openbox-session &
while true;
do
  /usr/bin/firefox -kiosk -private-window -width=1280 -height=800 http://${pricecheckerip}:4322/access/PriceChecker.html
done" | sudo tee /opt/kiosk/kiosk.sh

# Write service file to /etc/systemd/system/kiosk.service
echo "[Unit]
Description=Start kiosk
[Service]
Type=simple
ExecStart=sudo startx /etc/X11/Xsession /opt/kiosk/kiosk.sh
[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/kiosk.service

# Add permissions to the files
sudo chmod 644 /etc/systemd/system/kiosk.service
sudo chmod +x /opt/kiosk/kiosk.sh

# Enable the service on startup
sudo systemctl daemon-reload
sudo systemctl enable kiosk

# Finish
sudo systemctl start kiosk
