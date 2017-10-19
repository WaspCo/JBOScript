#!/bin/bash
#Purpose = Backup of NVME SSD
#To modify the scheduling => crontab -e
#Version 1.0
#Use image files and rsync the filesystem into it
#START

START_TIME=$SECONDS
DATE=`date +%d%m%y`

S0=/dev/mmcblk0
S1=/dev/mmcblk0p1
S2=/dev/mmcblk0p2
DST=/mnt/ssd/backup

echo " "
echo "---------------------------------------"
echo "------------ BananaPi backup ----------"
echo "---------------------------------------"
echo " "

if [ -n "$S0" ]; then
  echo "S0 -> $S0 (main device)"
fi
if [ -n "$S1" ]; then
  echo "S1 -> $S1"
fi
if [ -n "$S2" ]; then
  echo "S2 -> $S2"
fi
if [ -n "$S3" ]; then
  echo "S3 -> $S3"
fi
echo " "

if [ ! -d "$DST" ]; then
  mkdir /mnt/ssd/backup
fi

#backup the partition table
sgdisk --backup=$DST/partition_table.txt $S0

################################################################################
#First partition, mount img and rsync ##########################################
if [ ! -f "$DST/backup_bananapi_p1.img" ]; then
  dd if=$S1 of=$DST/backup_bananapi_p1.img status=progress bs=4096
fi

mkdir /mnt/d1
mount $DST/backup_bananapi_p1.img /mnt/d1
rsync -a --stats --force --progress --delete $S1 $DST/backup_bananapi_p1.img
umount /mnt/d1
rm /mnt/d1

################################################################################
#Second partition, mount img and rsync #########################################
if [ ! -f "$DST/backup_bananapi_p2.img" ]; then
  dd if=$S2 of=$DST/backup_bananapi_p2.img status=progress bs=4096
fi

mkdir /mnt/d2
mount $DST/backup_bananapi_p2.img /mnt/d2
rsync -a --stats --force --progress --delete $S2 $DST/backup_bananapi_p2.img
umount /mnt/d2
rm /mnt/d2

ELAPSED_TIME=&(($SECONDS - $START_TIME))
echo "Backup of NVME laptop ssd took $ELAPSED_TIME seconds"
echo " "
echo "---------------------------------------"
echo "-------- End of NVME laptop ssd -------"
echo "---------------------------------------"
