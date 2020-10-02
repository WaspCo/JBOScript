#!/bin/bash

# backup all partitions of a disk in a backup folder

START_TIME=$SECONDS
DATE=`date +%d%m%y`

# those env variables must be set
SRC=$BACKUP_SOURCE_DISK
DST=$BACKUP_DESTINATION_DISK
PAR=$BACKUP_SOURCE_DISK_PARTICULE
IDX=$BACKUP_SOURCE_DISK_START_IDX

echo " "
echo "---------------------------------------"
echo "------------- RAW backup --------------"
echo "---------------------------------------"
echo " "

echo "Source      -> /dev/$SRC"
echo "Destination -> $DST"
echo " "

sudo mkdir $DST/backup_$DATE &> /dev/null
sudo sgdisk --backup=$DST/backup_$DATE/partition_table_$DATE.txt /dev/$SRC

for (( ; ; )) # loop over all partitions of the disk
do
    if [ -e "/dev/$SRC$PAR$IDX" ]
    then
        echo "Backup partition /dev/$SRC$PAR$IDX"
        sudo dd if=/dev/$SRC$PAR$IDX of=$DST/backup_$DATE/$SRC$PAR$IDX.img status=progress bs=8092
        IDX=$(($IDX+1))
        echo " "
    else
        break
    fi
done

ELAPSED_TIME=&(($SECONDS - $START_TIME))
echo " "
echo "Backup took $ELAPSED_TIME seconds"
echo " "
