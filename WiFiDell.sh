# Fixes Wifi issues with using Ubuntu 18.04 on Dell 9520 (has AX211 card)

# Install dependencies
sudo apt install -y flex bison

# Clone Repo and Build wifi backport-driver
cd ~/Downloads
git clone https://github.com/intel/backport-iwlwifi.git
cd backport-iwlwifi/iwlwifi-stack-dev
sudo make defconfig-iwlwifi-public
sudo make
sudo make install

# Clone the original driver and ... i dunno, copy stuff around to take effect
cd ~/Downloads
git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
cd linux-firmware/
sudo cp iwlwifi-* /lib/firmware/

# Display warning
echo "REBOOT for changes to take effect"

