cd ~/Documents
git clone https://gitlab.com/firecell/r-d/firecellrd.git
cd ~/Documents/firecellrd
export PATHTOREPO=$(pwd)
export PATHTORAN=$PATHTOREPO/components/RAN
export PATHTO5GCN=$PATHTOREPO/components/CN
export PATHTOEPC=$PATHTOREPO/components/CN/openair-epc


cd $PATHTOREPO
chmod +x ./scripts/build
./scripts/clone_all

cd $PATHTORAN/cmake_targets
./build_oai --eNB --UE --gNB --nrUE -w SIMU --build-lib all

# To compile just the rfsim
# cd $PATHTORAN/cmake_targets/ran_build/build
# make rfsimulator

# To compile just the UE or eNB
# cd $PATHTORAN/cmake_targets/ran_build/build
# make lte-uesoftmodem
# make lte-softmodem


# ALWAYS RUN THIS FIRST:
cd $PATHTORAN
source oaienv

# Run eNB
cd $PATHTORAN/cmake_targets/
sudo RFSIMULATOR=server ./ran_build/build/lte-softmodem -O ../ci-scripts/conf_files/enb.band7.tm1.25PRB.usrpb210.conf --noS1 --nokrnmod 1 --rfsim
# -d --telnet_srv --rfsimulator.options chanmod


# Run UE
cd $PATHTORAN/cmake_targets/
sudo RFSIMULATOR=<SERVERIP> ./ran_build/build/lte-uesoftmodem -C 2680000000 -r 25 --ue-rxgain 120 --ue-txgain 0 --ue-max-power 0 --ue-scan-carrier --nokrnmod 1 --noS1 --rfsim

sudo RFSIMULATOR=10.0.1.1 ./ran_build/build/lte-uesoftmodem -C 2680000000 -r 25 --ue-rxgain 120 --ue-txgain 0 --ue-max-power 0 --ue-scan-carrier --nokrnmod 1 --noS1 --rfsim

# RUN DIFFERENT NAME SPACES!!!!

# Install wireshark
sudo add-apt-repository ppa:wireshark-dev/stable
sudo apt update
sudo apt install -y wireshark
sudo usermod -a -G wireshark $(whoami)
reboot


# Mark packets with heuristics
cd $PATHTORAN/common/utils/T/tracer
make
./macpdu2wireshark -d ../T_messages.txt -live -no-bind -ip 127.0.0.1

# COPY and ADD the channel model to the right path.
cp $PATHTORAN/ci-scripts/conf_files/channelmod_rfsimu.conf targets/PROJECTS/GENERIC-LTE-EPC/CONF/
@include "channelmod_rfsimu.conf"





# ######## Install 5G CN ########
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \ "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
sudo usermod -a -G docker "joao"
reboot
sudo groups
dpkg --list | grep docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo docker login

sudo sysctl net.ipv4.conf.all.forwarding=1
sudo iptables -P FORWARD ACCEPT

# Pull Docker components
sudo docker pull rdefosseoai/oai-amf:latest
sudo docker pull rdefosseoai/oai-nrf:latest
sudo docker pull rdefosseoai/oai-spgwu-tiny:latest
sudo docker pull rdefosseoai/oai-smf:latest
sudo docker pull rdefosseoai/oai-udr:latest
sudo docker pull rdefosseoai/oai-udm:latest
sudo docker pull rdefosseoai/oai-ausf:latest
sudo docker pull rdefosseoai/oai-upf-vpp:latest
sudo docker pull rdefosseoai/oai-nssf:latest
sudo docker pull rdefosseoai/trf-gen-cn5g:latest

sudo docker image tag rdefosseoai/oai-amf:latest oai-amf:latest
sudo docker image tag rdefosseoai/oai-nrf:latest oai-nrf:latest
sudo docker image tag rdefosseoai/oai-spgwu-tiny:latest oai-spgwu-tiny:latest
sudo docker image tag rdefosseoai/oai-smf:latest oai-smf:latest
sudo docker image tag rdefosseoai/oai-udr:latest oai-udr:latest
sudo docker image tag rdefosseoai/oai-udm:latest oai-udm:latest
sudo docker image tag rdefosseoai/oai-ausf:latest oai-ausf:latest
sudo docker image tag rdefosseoai/oai-upf-vpp:latest oai-upf-vpp:latest
sudo docker image tag rdefosseoai/oai-nssf:latest oai-nssf:latest
sudo docker image tag rdefosseoai/trf-gen-cn5g:latest trf-gen-cn5g:latest

sudo docker logout

# Configure DNS for SMF
route -n
cd $PATHTO5GCN/docker-compose
nano docker-compose-basic-nonrf.yaml

# modify: 
● DEFAULT_DNS_IPV4_ADDRESS: 192.168.253.1 or 8.8.8.8
● SST_0=1
● SD_0=1
● OPERATOR_KEY=1006020f0a478bf6b699f15c062e42b3

# Deploy 5G CN
cd $PATHTO5GCN/docker-compose
sudo python3 ./core-network.py --type start-basic --fqdn no --scenario 2

# if needed, get AMF and SP-GWU IPs (MAYBE THERES A SPACE BETWEEN RANGE and .NETWORK)
sudo docker inspect --format="{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}" oai-amf
sudo docker inspect --format="{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}" oai-spgwu

# Undeploy 5G CN
sudo python3 ./core-network.py --type stop-basic --fqdn no --scenario 2
#################################################







sudo RFSIMULATOR=server ./ran_build/build/lte-softmodem -O ../ci-scripts/conf_files/enb.band7.tm1.25PRB.usrpb210.conf --noS1 --nokrnmod 1 --rfsim -d --telnetsrv --rfsimulator.options chanmod
sudo ./ran_build/build/lte-uesoftmodem -C 2680000000 -r 25 --ue-rxgain 120 --ue-txgain 0 --ue-max-power 0 --ue-scan-carrier --nokrnmod 1 --noS1 --rfsim --rfsimulator.serveraddr 10.0.1.1

# namespaces
sudo ip netns add ue1
sudo ip netns exec u1 <command>


################3
ping -I oaitun_enb1 10.0.1.2  # (from eNB machine)
ping -I oaitun_ue1 10.0.1.1   # (from UE machine)

