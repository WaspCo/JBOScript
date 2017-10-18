#!/bin/bash
#Purpose = Backup of NVME SSD
#To modify the scheduling => crontab -e
#Version 1.0
#Next phase is to backup LUKS LVM partitions as encrypted filesystem without unused data.
#START

START_TIME=$SECONDS
DATE=`date +%d%m%y`

SRC=/dev/nvme0n1
DST=/run/media/WaspCo/0f348a9b-bf55-459c-835e-0396e5648795/backup/laptop_backup

echo " "
echo "---------------------------------------"
echo "---------- NVME laptop backup ---------"
echo "---------------------------------------"
echo " "

echo "Source -> $SRC"
echo "Location -> $DST"
echo " "
mkdir $DST/laptop_backup_$DATE
sgdisk --backup=$DST/laptop_backup_$DATE/partition_table_$DATE.txt /dev/nvme0n1
dd if=/dev/nvme0n1p1 of=$DST/laptop_backup_$DATE/nvme0n1p1.img status=progress bs=4096
echo " "
dd if=/dev/nvme0n1p2 of=$DST/laptop_backup_$DATE/nvme0n1p2.img status=progress bs=4096
echo " "
dd if=/dev/nvme0n1p3 of=$DST/laptop_backup_$DATE/nvme0n1p3.img status=progress bs=4096
echo " "

ELAPSED_TIME=&(($SECONDS - $START_TIME))
echo "Backup of NVME laptop ssd took $ELAPSED_TIME seconds"
echo " "
echo "---------------------------------------"
echo "-------- End of NVME laptop ssd -------"
echo "---------------------------------------"
