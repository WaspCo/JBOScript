#!/bin/bash

START_TIME=$SECONDS
DATE=`date +%d%m%y`

SRC=$SOURCE_DISK
DST=$BACKUP_DISK

echo " "
echo "---------------------------------------"
echo "------------- RAW backup --------------"
echo "---------------------------------------"
echo " "

echo "Source      -> $SRC"
echo "Destination -> $DST"
echo " "
mkdir $DST/backup_$DATE
sgdisk --backup=$DST/backup_$DATE/partition_table_$DATE.txt $SRC
dd if=/dev/nvme0n1p1 of=$DST/backup_$DATE/nvme0n1p1.img status=progress bs=8092
echo " "
dd if=/dev/nvme0n1p2 of=$DST/backup_$DATE/nvme0n1p2.img status=progress bs=8092
echo " "
dd if=/dev/nvme0n1p3 of=$DST/backup_$DATE/nvme0n1p3.img status=progress bs=8092
echo " "

ELAPSED_TIME=&(($SECONDS - $START_TIME))
echo "Backup took $ELAPSED_TIME seconds"
echo " "