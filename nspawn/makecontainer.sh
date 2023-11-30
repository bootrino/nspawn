#!/bin/bash
# Set the container name and directory
set -x
CONTAINER_NAME="treasurehuntauctions"
CONTAINER_DIR="/var/lib/machines/$CONTAINER_NAME"
UBUNTU_RELEASE="jammy"
UBUNTU_MIRROR="http://archive.ubuntu.com/ubuntu/"
mkdir -p "$CONTAINER_DIR"
#debootstrap --arch=amd64 --variant=minbase --include=systemd,dbus,ssh,iputils-ping,iproute2 "$UBUNTU_RELEASE" "$CONTAINER_DIR" "$UBUNTU_MIRROR"
debootstrap --arch=amd64 --include=systemd,dbus,ssh,iputils-ping,iproute2 "$UBUNTU_RELEASE" "$CONTAINER_DIR" "$UBUNTU_MIRROR"

# Enter the container and configure it
cd /var/lib/machines

# Create a temporary script file
temp_script=/var/lib/machines/treasurehuntauctions/setup.sh

# Write the heredoc to the temporary script file
cat <<EOF > "$temp_script"
#!/bin/bash
# Inside the container

# Create the 'ubuntu' user
useradd -m -s /bin/bash ubuntu
usermod -aG sudo ubuntu

# Set the password for the 'ubuntu' user
echo "ubuntu:SUPERSECRET" | chpasswd
# Check the exit status of the 'passwd' command for the 'ubuntu' user
if [ $? -eq 0 ]; then
    echo "Password for 'ubuntu' user has been set."
else
    echo "Failed to set the password for 'ubuntu' user."
fi

# Set the password for the 'root' user
echo "root:SUPERSECRET" | chpasswd

# Check the exit status of the 'passwd' command for the 'root' user
if [ $? -eq 0 ]; then
    echo "Password for 'root' user has been set."
else
    echo "Failed to set the password for 'root' user."
fi

# Configure network settings (if needed)
cat <<EOL > /etc/systemd/network/host0.network
[Match]
Name=host0
[Network]
DHCP=yes
# Address=192.168.5.100/24
# Gateway=192.168.5.254
# DNS=192.168.5.254
# DNS=8.8.8.8
EOL

systemctl enable --now systemd-networkd
#systemctl restart systemd-networkd

#apt-get update
#apt-get install -y openssh-server sudo vim wget
# Allow SSH password authentication (if needed)
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
#systemctl restart ssh

# Exit the container
exit
EOF

# Make the temporary script executable
chmod +x "$temp_script"

# Run the temporary script inside the container
sudo systemd-nspawn -D "$CONTAINER_DIR" -P /setup.sh
echo done
# Remove the temporary script
rm -f "$temp_script"
exit 0


