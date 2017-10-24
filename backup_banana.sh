#!/bin/bash
#Purpose = Backup of NVME SSD
#To modify the scheduling => crontab -e
#Version 1.0
#Use image files and rsync the filesystem into it
#START

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


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


if [ ! -f "$DST" ]; then
  mount /dev/sda1 /mnt/ssd
fi

if [ ! -d "$DST" ]; then
  mkdir /mnt/ssd/backup
fi

#backup the partition table
sgdisk --backup=$DST/partition_table.txt $S0

################################################################################
#First partition, mount img and rsync ##########################################
echo " "
echo "Backup of the first partition has started"
if [ ! -f "$DST/backup_bananapi_p1.img" ]; then
  dd if=$S1 of=$DST/backup_bananapi_p1.img bs=4096
fi

mkdir /mnt/d1
mount $DST/backup_bananapi_p1.img /mnt/d1
rsync -avxHAX --stats --force --progress --delete /boot/ /mnt/d1/
umount /mnt/d1
rm -fr /mnt/d1
echo "Backup of the first partition has ended"
echo " "

################################################################################
#Second partition, mount img and rsync #########################################
echo " "
echo "Backup of the second partition has started"
if [ ! -f "$DST/backup_bananapi_p2.img" ]; then
  dd if=$S2 of=$DST/backup_bananapi_p2.img bs=4096
fi

mkdir /mnt/d2
mount $DST/backup_bananapi_p2.img /mnt/d2
rsync -avxHAX --stats --force --progress --delete --exclude '/boot' --exclude '/var/log' --exclude '/mnt' / /mnt/d2
umount /mnt/d2
rm -fr /mnt/d2
echo "Backup of the second partition has ended"
echo " "

ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "Backup of NVME laptop ssd took $ELAPSED_TIME seconds"
echo " "
echo "---------------------------------------"
echo "-------- End of NVME laptop ssd -------"
echo "---------------------------------------"
