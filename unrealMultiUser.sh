#!/bin/zsh
# Michael Oliver
# Unreal MultiUserServer on Linux with Tailscale

# Setup the second drive
datadev="/dev/nvme1n1"
sudo mkfs -t xfs $datadev
sudo file -s $datadev
sudo mkdir /data
sudo chmod 777 /data
devUUID=`sudo blkid $datadev | awk '{print $2}' | /bin/sed 's/\"//g' | cut -c 6-`
echo $devUUID
echo "UUID=$devUUID  /data  xfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab
sudo mount -a

# Grab Unreal https://github.com/EpicGames/UnrealEngine
mkdir /data/git && cd /data/git
git clone https://github.com/EpicGames/UnrealEngine.git
cd UnrealEngine
./Setup.sh && ./GenerateProjectFiles.sh && make UnrealMultiUserServer
# Go get a coffee

# Install Tailscale
# https://tailscale.com/download/linux
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
sudo tailscale ip -4

# Configure the multiuser server
mkdir -p /data/git/UnrealEngine/Engine/Programs/UnrealMultiUserServer/Saved/Config/LinuxNoEditor
cat << 'EOF' | tee /data/git/UnrealEngine/Engine/Programs/UnrealMultiUserServer/Saved/Config/LinuxNoEditor/Engine.ini
[/Script/UdpMessaging.UdpMessagingSettings]
EnableTransport=True
UnicastEndpoint=100.X.X.X:7000
MulticastEndpoint=230.0.0.1:6666
MulticastTimeToLive=1
EnableTunnel=False
TunnelUnicastEndpoint=
TunnelMulticastEndpoint=
EOF

# Create the launcher
# -ConcertClean will clean out saved sessions
cat << 'EOF' | tee /home/ubuntu/launchMultiUserServer.sh
#!/bin/sh
/data/git/UnrealEngine/Engine/Binaries/Linux/UnrealMultiUserServer -ConcertIgnore
EOF

# Setup Service
cat << 'EOF' | sudo tee /etc/systemd/system/ue4server.service
[Unit]
Description=Unreal Engine Multi User Server

[Service]
Type=forking
User=ubuntu
WorkingDirectory=/home/ubuntu/ue4srvr
ExecStart=/home/ubuntu/ue4srvr/launchMultiUserServer.sh
SuccessExitStatus=143
TimeoutStopSec=10
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Launch the MultiUser Editor
sudo systemctl daemon-reload
sudo systemctl enable ue4server.service
sudo systemctl start ue4server
sudo systemctl status ue4server

# Check the logs
# sudo journalctl -f -n 1000 -u ue4server
