cd ~/Documents
git clone https://gitlab.com/firecell/r-d/firecellrd.git
cd firecellrd
export PATHTOREPO=$(pwd)
export PATHTORAN=$PATHTOREPO/components/RAN
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


# Run eNB
cd $PATHTORAN/cmake_targets/
sudo RFSIMULATOR=server ./ran_build/build/lte-softmodem -O ../ci- scripts/conf_files/enb.band7.tm1.25PRB.usrpb210.conf --noS1 -- nokrnmod 1 --rfsim

# Run UE
cd $PATHTORAN/cmake_targets/
sudo RFSIMULATOR=<SERVERIP> ./ran_build/build/lte-uesoftmodem -C 2680000000 -r 25 --ue-rxgain 120 --ue-txgain 0 --ue-max-power 0 --ue- scan-carrier --nokrnmod 1 --noS1 --rfsim


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

ping -I oaitun_enb1 10.0.1.2  # (from eNB machine)
ping -I oaitun_ue1 10.0.1.1   # (from UE machine)

