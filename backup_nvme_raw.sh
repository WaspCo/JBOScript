#!/bin/bash
#Purpose = RAW backup of NVME
#To modify the scheduling => 'crontab -e' as root
#Version 1.0
#START

START_TIME=$SECONDS
DATE=`date +%d%m%y`

SRC=/dev/nvme0n1
DST=/run/media/WaspCo/18FE619713130F48/laptop_backup

echo " "
echo "---------------------------------------"
echo "----------- NVME RAW backup -----------"
echo "---------------------------------------"
echo " "

echo "Source -> $SRC"
echo "Location -> $DST"
echo " "
mkdir $DST/laptop_backup_$DATE
sgdisk --backup=$DST/laptop_backup_$DATE/partition_table_$DATE.txt /dev/nvme0n1
dd if=/dev/nvme0n1p1 of=$DST/laptop_backup_$DATE/nvme0n1p1.img status=progress bs=8092
echo " "
dd if=/dev/nvme0n1p2 of=$DST/laptop_backup_$DATE/nvme0n1p2.img status=progress bs=8092
echo " "
dd if=/dev/nvme0n1p3 of=$DST/laptop_backup_$DATE/nvme0n1p3.img status=progress bs=8092
echo " "

ELAPSED_TIME=&(($SECONDS - $START_TIME))
echo "Backup took $ELAPSED_TIME seconds"
echo " "
echo "---------------------------------------"
echo "-------- End of NVME RAW backup -------"
echo "---------------------------------------"
