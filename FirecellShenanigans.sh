cd ~/Documents
git clone https://gitlab.com/firecell/r-d/firecellrd.git

cd ~/Documents/firecellrd
export PATHTOREPO=$(pwd)
export PATHTORAN=$PATHTOREPO/components/RAN
export PATHTO5GCN=$PATHTOREPO/components/CN
export PATHTOEPC=$PATHTOREPO/components/CN/openair-5gcn
export PATHTOFRD=$PATHTOREPO/fc-ue-Proxy

##################3 PROXY for L2 SIM #######################
cd $PATHTOREPO
git clone https://gitlab.com/firecell/r-d/fc-ue-proxy.git
make
sudo ifconfig lo: 127.0.0.2 netmask 255.0.0.0 up

# Start proxy whenever
./proxy_testscript.py --num-ues 1 --mode=nr

# CONFIGURATIONS TO DO AT THE BS
<PATHTORAN>/ci-scripts/conf_files/episci/proxy_gnb.band78.sa.fr1.106PRB.usrpn310.conf

AMF parameters:
amf_ip_address
ipv4 = "192.168.70.132"
ipv6 = "192:168:30::17";
active = "yes";
preference = "ipv4";


NETWORK_INTERFACES:
NOTE: Assuming BOND0 as the physical interface name & CI_GNB_IP_ADDR the IP Address of this
interface. Keep these according to the ifconfig output of your gNB server.

GNB_INTERFACE_NAME_FOR_NG_AMF = "BOND0";
GNB_IPV4_ADDRESS_FOR_NG_AMF = "CI_GNB_IP_ADDR";
GNB_INTERFACE_NAME_FOR_NGU = "BOND0";
GNB_IPV4_ADDRESS_FOR_NGU = "CI_GNB_IP_ADDR";
GNB_PORT_FOR_NGU = 2152; # Spec 2152

PLMN and Tracking Area Code:
tracking_area_code = 0xa000;
mcc = 208;
mnc = 95;

# CONFIGURATIONS TO DO AT THE UE
<PATHTORAN>/ ci-scripts/conf_files/episci/proxy_nr-ue.nfapi.conf

imsi = "208950000000031";
key = "0C0A34601D4F07677303652C0462535B";
opc= "63bfa50ee6523365ff14c1f45f88737d";
dnn= "default";

# CONFIGURATIOS FOR SYSTEM SIMULATION (paste the following in the config file)
<PATHTORAN>/ci-scripts/conf_files/episci/proxy_gnb.band78.sa.fr1.106PRB.usrpn310.conf
# IP Address, port numbers and Mode for System Simulator
SSConfig = ({
hostIp = "127.0.0.1"; #Host IP for System Simulator
Sys_port = 7777; #Port Number for System Simulator Sys Port
Srb_port = 7778; #Port Number for System Simulator Srb Port
Vng_port = 7779; #Port Number for System Simulator
Vng Port
SSMode = 2; #SSMode: 0 - gNB ,
1- SYS_PORT test ,
2- Only SRB_PORT test
});
############################################################


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
(in SMF)
● DEFAULT_DNS_IPV4_ADDRESS: 192.168.253.1 or 8.8.8.8
(in AMF)
● SST_0=1
● SD_0=1
● OPERATOR_KEY=1006020f0a478bf6b699f15c062e42b3

# Deploy 5G CN
cd $PATHTO5GCN/docker-compose
sudo python3 ./core-network.py --type start-basic --fqdn no --scenario 2

# Check running containers
docker ps

# You should see something like this:
CONTAINER ID   IMAGE                   COMMAND                  CREATED         STATUS                   PORTS                          NAMES
8987279ed67d   ubuntu:bionic           "/bin/bash -c ' apt …"   2 minutes ago   Up 2 minutes                                            oai-ext-dn
8885f5f47b53   oai-spgwu-tiny:latest   "/openair-spgwu-tiny…"   2 minutes ago   Up 2 minutes (healthy)   2152/udp, 8805/udp             oai-spgwu
ed64d7fcc50b   oai-smf:latest          "/bin/bash /openair-…"   2 minutes ago   Up 2 minutes (healthy)   80/tcp, 9090/tcp, 8805/udp     oai-smf
af653fb8e9cf   oai-amf:latest          "/bin/bash /openair-…"   2 minutes ago   Up 2 minutes (healthy)   80/tcp, 9090/tcp, 38412/sctp   oai-amf
9f0327194872   oai-ausf:latest         "/bin/bash /openair-…"   2 minutes ago   Up 2 minutes (healthy)   80/tcp                         oai-ausf
0a3d46c5d231   oai-udm:latest          "/bin/bash /openair-…"   2 minutes ago   Up 2 minutes (healthy)   80/tcp                         oai-udm
3834fa873ae6   oai-udr:latest          "/bin/bash /openair-…"   2 minutes ago   Up 2 minutes (healthy)   80/tcp                         oai-udr
4aef2e5b9ebc   mysql:5.7               "docker-entrypoint.s…"   2 minutes ago   Up 2 minutes (healthy)   3306/tcp, 33060/tcp            mysql



# if needed, get AMF and SP-GWU IPs (MAYBE THERES A SPACE BETWEEN RANGE and .NETWORK)
sudo docker inspect --format="{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}" oai-amf
sudo docker inspect --format="{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}" oai-spgwu

# Undeploy 5G CN
sudo python3 ./core-network.py --type stop-basic --fqdn no --scenario 2
#################################################






# MY last commands IN 4G, without namespaces
cd $PATHTORAN/cmake_targets/
sudo RFSIMULATOR=server ./ran_build/build/lte-softmodem -O ../ci-scripts/conf_files/enb.band7.tm1.25PRB.usrpb210.conf --noS1 --nokrnmod 1 --rfsim -d --telnetsrv --rfsimulator.options chanmod
sudo ./ran_build/build/lte-uesoftmodem -C 2680000000 -r 25 --ue-rxgain 120 --ue-txgain 0 --ue-max-power 0 --ue-scan-carrier --nokrnmod 1 --noS1 --rfsim --rfsimulator.serveraddr 10.0.1.1


# namespaces
ue_id=1
sudo ip netns add ue$ue_id
sudo ip link add v-eth$ue_id type veth peer name v-ue$ue_id
sudo ip link set v-ue$ue_id netns ue$ue_id

sudo ip addr add 10.201.1.1/24 dev v-eth$ue_id
sudo ip link set v-eth$ue_id up
export IFACE_NAME=enxa0cec8fd657b

sudo iptables -t nat -A POSTROUTING -s 10.201.1.0/255.255.255.0 -o $IFACE_NAME -j MASQUERADE
sudo iptables -A FORWARD -i $IFACE_NAME -o v-eth$ue_id -j ACCEPT
sudo iptables -A FORWARD -o $IFACE_NAME -i v-eth$ue_id -j ACCEPT
sudo ip netns exec ue$ue_id ip link set dev lo up
sudo ip netns exec ue$ue_id ip addr add 10.201.1.2/24 dev v-ue$ue_id
sudo ip netns exec ue$ue_id ip link set v-ue$ue_id up


# MY command (4G), but with network interfaces enabled:
sudo ip netns exec ue$ue_id sudo ./ran_build/build/lte-uesoftmodem -C 2680000000 -r 25 --ue-rxgain 120 --ue-txgain 0 --ue-max-power 0 --ue-scan-carrier --nokrnmod 1 --noS1 --rfsim --rfsimulator.serveraddr 10.201.1.1


# Final commands
sudo ip netns exec ue$ue_id sudo -E RFSIMULATOR=10.201.1.1 ./ran_build/build/nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --rfsim --sa --noS1 --nokrnmod -O ue.conf
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem --rfsim --sa --noS1 --nokrnmod -d -O gnb.sa.band78.fr1.106PRB.usrpb210.conf

# WORKING COMMANDS

sudo RFSIMULATOR=server ./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-LTE-EPC/CONF/gnb.band78.tm1.106PRB.usrpn300.conf --parallel-config PARALLEL_SINGLE_THREAD --rfsim --phy-test --nokrnmod 1
sudo RFSIMULATOR=127.0.0.1 ./nr-uesoftmodem --rfsim --phy-test --rrc_config_path .





sudo ip netns exec ue$ue_id bash
################3
ping -I oaitun_enb1 10.0.1.2  # (from eNB machine)
ping -I oaitun_ue1 10.0.1.1   # (from UE machine)
# Requires --nokrnmod, I think. 


############################ Validate L2 SIM in noS1 mode ##############
cd $PATHTOPROXY
./proxy_testscript.py --num-ues 1 --mode=nr
# Returns a few errors...


# or individually
cd $PATHTORAN/cmake_targets
sudo -E taskset --cpu-list 1 ./ran_build/build/nr-softmodem -O ../ci-scripts/conf_files/episci/proxy_gnb.band78.sa.fr1.106PRB.usrpn310.conf --nfapi 2 --noS1 --emulate-l1 --log_config.global_log_options level,nocolor,time,thread_id --sa
###### (libconfig couldnt be loaded!!)

cd $PATHTOPROXY
number_of_ues=1
sudo -E ./build/proxy $number_of_ues --nr

cd $PATHTORAN/cmake_targets
sudo -E taskset --cpu-list 2 ./ran_build/build/nr-uesoftmodem -O ../ci-scripts/conf_files/episci/proxy_nr-ue.nfapi.conf --nokrnmod 1 --nfapi 5 --node-number 2 --emulate-l1 --log_config.global_log_options level,nocolor,time,thread_id --sa

########################################################################




