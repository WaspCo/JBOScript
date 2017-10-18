#!/bin/bash
#Purpose = Backup of NVME SSD
#To modify the scheduling => crontab -e
#Version 1.0
#Next phase is to backup LUKS LVM partitions as encrypted filesystem without unused data.
#After restoration, you might need to edit your /etc/fstab
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

#All about up the LUKS drive ###################################################
if [ "$1" == "-backup" ]; then
    echo "------------- Backup Mode -------------"
    echo " "
    echo "Source -> $SRC"
    echo "Location -> $DST"
    echo " "

    mkdir $DST/backup_nvme_luks_$DATE
    echo "Backup of the partition table:"
    sgdisk --backup=$DST/backup_nvme_luks_$DATE/partition_table_$DATE.txt /dev/nvme0n1
    #Backup p1 & p2
    #Also backup the mouted encrypted volumes in /dev/mapper
    echo " "
    fsarchiver savefs -z 7 -c - -o $DST/backup_nvme_luks_$DATE/backup_nvme_luks_$DATE.fsa /dev/nvme0n1p1 /dev/nvme0n1p2 /dev/mapper/fedora-home /dev/mapper/fedora-root -j3 -A


    echo " "
    ELAPSED_TIME=&(($SECONDS - $START_TIME))
    echo "Backup of NVME laptop ssd took $ELAPSED_TIME seconds"
fi

#All about restoring the LUKS drive backup #####################################
if [ "$1" == "-restore" ]; then
    echo "------------- Restore Mode ------------"
    echo " "

    echo "Enter the device name (/dev/...):"
    read disk;
    echo " "
    echo "WARNING: !!! The disk /dev/$disk will be irredeemably wiped out !!!"
    echo "I get it (Y/N):"
    read choice;
    if [ "$choice" != "Y" ]; then
      exit
    fi
    echo " "
    echo "Please enter the backup file location:"
    source=0
    read source;
    clean_source="$( echo $source 2>&1| sed "s/^\([\"']\)\(.*\)\1\$/\2/g")"

    if [ "$clean_source" == 0 ]; then
      exit
    fi
    echo " "
    fsarchiver archinfo $clean_source -c -

    #Basic device size verification
    disk_size=sudo fdisk -l /dev/$disk | sed -n 1p | awk '{print $3}'
    need_size=$(sudo du -k -h $clean_source | cut -f1)
    if [ $disk_size /< $need_size ]; then
      echo "ERROR: This backup file fit, the disk size is too small."
      exit
    fi
    echo " "

    #Last hope
    echo "Do you really want to wipe /dev/$disk and restore this backup ? (Y/N)"
    choice=0
    read choice
    if [ "$choice" != "Y" ]; then
      exit
    fi

    #Restore EFI & boot partitions
    parted /dev/$disk mklabel gpt
    fsarchiver restfs $clean_source id=0,dest=/dev/$disk1 id=1,dest=/dev/$disk2
    parted /dev/$disk mkpart primary 2048s 100%  #Create one big partition with the remaining space

    cryptsetup luksFormat --hash=sha512 --key-size=512 --cipher=aes-xts-plain64 --verify-passphrase /dev/$disk
    #It will ask for password
    cryptsetup luksOpen /dev/$disk $disk_crypt

    #Get logical volumes names
    lvdisplay -v /dev/vg00/lvol2

    #Now we need to take care of the LVM
    lvm pvcreate /dev/mapper/$disk_crypt  #Use device as physical volume
    vgcreate vg0 /dev/mapper/$disk_crypt  #Create volume group containing the physical volume
    #Create the different logical volumes
    lvcreate -n root -L $root_size vg0
    lvcreate -n home -L $home_size vg0
    lvcreate -n swap -L $swap_size vg0
    #lvcreate -n data -l +100%FREE vg0   #If you want to have a data partition encrypted as well


    #Now we have to recreate the LUKS partition and its content
    #
    fsarchiver restfs $clean_source id=2,dest=/dev/mapper/$? id=3,dest=/dev/mapper/$? id=4,dest=/dev/mapper/$?

    #And finally we close the encrypted volume
    cryptsetup luksClose $disk_crypt
fi

echo " "
echo "---------------------------------------"
echo "-------- End of NVME laptop ssd -------"
echo "---------------------------------------"
