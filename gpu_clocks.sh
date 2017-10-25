#!/bin/bash
# Set clocks and start gpu mining
# Made for a Zotac GTX1060 6Go
#
# This script is a dirty trick
# The clocks are high but the card never gets into 'Performance Mode'
# ,or whatever NVIDIA calls it, when mining. That is an NVIDIA bug on Linux with
# this kind of card. So in fact, the card only gets half of this frequency
# offsets when mining. OC has to be switch ON/OFF very quicky otherwise the
# card will get into 'Performance Mode' briefly before / after mining
# (silly drivers) therefore getting the full frequency offset ... and crash.
#
# If you want to mine I strongly advise you to change my public keys, otherwise
# you would be mining for me ; ]


echo " "
echo "---------------------------------------"
echo "-------- Ethereum Mining GOGOGO -------"
echo "---------------------------------------"
echo " "
START_TIME=$SECONDS

# Switching OC ON
sudo nvidia-smi -pm 1
sudo nvidia-smi -pl 140
nvidia-settings -a [gpu:0]/GPUFanControlState=1
nvidia-settings -a [fan:0]/GPUTargetFanSpeed=75
nvidia-settings -a [gpu:0]/GPUGraphicsClockOffset[3]=100
nvidia-settings -a [gpu:0]/GPUMemoryTransferRateOffset[3]=1000

# Starting miner
cd /opt/claymore/
./ethdcrminer64_patched -dcri 35 -epool eth-eu1.nanopool.org:9999 -mport 0 -ewal 0x5eF269666ad34eC7c03f49C20739f34FDc964356/waspco/swrm@gmx.com -epsw x -dpool stratum+tcp://eu.siamining.com:7777 -dwal 7a602c5521a7195dbb2396edaa8fbf586826b4cea4bc326d84529cd62ff5631358ff8811aa29.waspco -dcoin sia

# Switching OC OFF
nvidia-settings -a [gpu:0]/GPUMemoryTransferRateOffset[3]=0
nvidia-settings -a [gpu:0]/GPUGraphicsClockOffset[3]=0
sudo nvidia-smi -pl 120

ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo " "
echo "Uptime of $ELAPSED_TIME seconds"
echo "Mining has stopped ... clocks and fans returning to normal."
echo " "
