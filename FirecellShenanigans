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
./build_oai --eNB --UE --gNB --nrUE -w SIMU

# To compile just the rfsim
# cd $PATHTORAN/cmake_targets/ran_build/build
# make rfsimulator

# To compile just the UE or eNB
# cd $PATHTORAN/cmake_targets/ran_build/build
# make lte-uesoftmodem
# make lte-softmodem
