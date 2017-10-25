#!/bin/bash
#Purpose = Backup of system ssd
#Created on 181017
#Pour modifier le scheduling, => 'crontab -e' as root
#TODO => restore option
#FIRST backup the filesystem with fsarchiver
#THEN rsync the 'pseudo' RAID10
#Version 1.0
#START

clear
USER=waspco
START_TIME=$SECONDS
DATE=`date +%d%m%y` #Add date to backup
DST=/run/media/waspco/Raid-Backup/backup #Destination of backup file.

#System partition for fsarchiver
P0=/dev/sda
P1=/dev/sda1
P2=/dev/sda2
P3=/dev/sda3
P4=/dev/sda6

#Disk locations for rsync
S1=/run/media/waspco/Raid-Backup/
S2=/run/media/waspco/Raid-Data/
D1=/run/media/waspco/Raidon-Back/
D2=/run/media/waspco/Raidon-Data/

echo " "
echo "--------------------------------------"
echo "--------- Workstation backup ---------"
echo "--------------------------------------"
echo " "
echo "System partitions for fsarchiver:"
if [ -n "$P1" ]; then
  echo "P1 -> $P1"
fi
if [ -n "$P2" ]; then
  echo "P2 -> $P2"
fi
if [ -n "$P3" ]; then
  echo "P3 -> $P3"
fi
if [ -n "$P4" ]; then
  echo "P4 -> $P4"
fi
if [ -n "$P5" ]; then
  echo "P5 -> $P5"
fi

echo " "
echo "Disk for rsync:"
if [ -n "$S1" ]; then
  echo "S1 -> $S1"
fi
if [ -n "$S2" ]; then
  echo "S2 -> $S2"
fi
if [ -n "$D1" ]; then
  echo "D1 -> $D1"
fi
if [ -n "$D2" ]; then
  echo "D2 -> $D2"
fi
echo " "

if [ ! -d "$DST" ]; then
  mkdir /run/media/waspco/Raid-Backup/backup
fi

if [ ! -d "$DST/backup_ssd_$DATE" ]; then
  mkdir /run/media/waspco/Raid-Backup/backup/backup_ssd_$DATE
fi

#Backup of the partition table onto the backup disk
echo "Backup of the partition table:"
sudo sgdisk --backup=$DST/backup_ssd_$DATE/partition_table_$DATE.txt $P0
echo " "

#Backup the filesystem onto the backup disk
fsarchiver savefs -z 1 -o $DST/backup_ssd_$DATE/backup_ssd_$DATE.fsa $P1 $P2 $P3 $P4 -j3 -A

# Then we synchronise the content of the raid
if [ ! -d "$S1" ]
then
  echo "S1 -> $S1 is not accessible !"
  ERR=1
elif [ ! -d "$D1" ]
then
  echo "D1 -> $D1 is not accessible !"
  ERR=1
else
  echo "Syncing S1 -> $S1"
  rsync -a --no-links --stats --force --progress --delete $S1 $D1
fi
echo " "
if [ ! -d "$S2" ]
then
  echo "S2 -> $S2 is not accessible !"
  ERR=1
elif [ ! -d "$D2" ]
then
  echo "D2 -> $D2 is not accessible !"
  ERR=1
else
  echo "Syncing S2 -> $S2"
  rsync -a --no-links --stats --force --progress --delete $S2 $D2
fi


ELAPSED_TIME=$(($SECONDS - $START_TIME))

#Send notifications to gnome (as regular user)
if [ ! -n "$ERR" ]
then
  DISPLAY=:0.0 su $USER -c "notify-send 'System successfully backed up in $ELAPSED_TIME seconds' -t 0 -u critical -i /usr/share/icons/Paper/24x24/apps/zen-icon.png"
  echo "System successfully backed up in $ELAPSED_TIME seconds"
else
  DISPLAY=:0.0 su $USER -c "notify-send 'There was an error while backing up the system' -t 0 -u critical -i /usr/share/icons/Paper/24x24/apps/abrt.png"
  echo "There was an error while backing up the system, check up needed"
fi

echo " "
echo "Execution en $ELAPSED_TIME secondes."
echo "--------------------------------------"
echo "----- End of workstation backup ------"
echo "--------------------------------------"
echo " "
#END
