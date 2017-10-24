#!/bin/bash
#Set clocks for gpu mining

echo " "
echo "---------------------------------------"
echo "-------- Ethereum Mining GOGOGO -------"
echo "---------------------------------------"
echo " "
START_TIME=$SECONDS

sudo nvidia-smi -pm 1
sudo nvidia-smi -pl 140

nvidia-settings -a [gpu:0]/GPUFanControlState=1
nvidia-settings -a [fan:0]/GPUTargetFanSpeed=75
nvidia-settings -a [gpu:0]/GPUGraphicsClockOffset[3]=100
nvidia-settings -a [gpu:0]/GPUMemoryTransferRateOffset[3]=1000

cd /opt/claymore/
./ethdcrminer64_patched -dcri 35 -epool eth-eu1.nanopool.org:9999 -mport 0 -ewal 0x5eF269666ad34eC7c03f49C20739f34FDc964356/waspco/swrm@gmx.com -epsw x -dpool stratum+tcp://eu.siamining.com:7777 -dwal 7a602c5521a7195dbb2396edaa8fbf586826b4cea4bc326d84529cd62ff5631358ff8811aa29.waspco -dcoin sia

nvidia-settings -a [gpu:0]/GPUMemoryTransferRateOffset[3]=0
nvidia-settings -a [gpu:0]/GPUGraphicsClockOffset[3]=0
sudo nvidia-smi -pl 120

ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo " "
echo "Uptime of $ELAPSED_TIME seconds"
echo "Mining has stop ... clocks and fan returned to normal."
echo " "
