#!/bin/bash
#Purpose = Backup of NVME SSD
#To modify the scheduling => crontab -e
#Version 1.0
#After restoration, you might need to edit your /etc/fstab
#START

#dmsetup remove vg0-root vg0-home vg0-swap fedora_crypt

START_TIME=$SECONDS
DATE=`date +%d%m%y`

SRC=/dev/nvme0n1
DST=/run/media/WaspCo/0f348a9b-bf55-459c-835e-0396e5648795/backup/laptop_backup

root_size=150G
home_size=150G
swap_size=16G

echo " "
echo "---------------------------------------"
echo "------------ LUKS LVM backup ----------"
echo "---------------------------------------"
echo " "
echo "WARNING: Please check this script configuration before using !"
echo "         It could break your system a thousand different ways !"
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

#All about restoring the LUKS drive backup #####################################
elif [ "$1" == "-restore" ]; then
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
    echo "Please enter the backup password:"
    pwd=0
    read -s pwd;
    if [ "$pwd" == 0 ]; then
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
    (echo "$pwd";) | fsarchiver archinfo $clean_source -c -



    #Basic device size verification
    disk_size=sudo fdisk -l /dev/$disk | sed -n 1p | awk '{print $3}'
    need_size=$(sudo du -k -h $clean_source | cut -f1)
    if [ $disk_size /< $need_size ]; then
      echo "ERROR: This backup file fit, the disk size is too small."
      exit
    fi
    echo " "

    #Last hope
    #echo "Do you really want to wipe /dev/$disk and restore this backup ? (Y/N)"
    #choice=0
    #read choice
    #if [ "$choice" != "Y" ]; then
    #  exit
    #fi

    #Restore EFI & boot partitions
    echo "Restoring GPT partition table..."
    parted /dev/$disk mklabel gpt
    (echo n; echo 1; echo " "; echo +200M; echo t; echo 1; echo w;) | fdisk /dev/${disk}
    mkfs.fat -F32 /dev/sda1
    (echo n; echo 2; echo " "; echo +1G; echo w) | fdisk /dev/${disk}
    #############################################Restore the backup !!
    #partprobe
    echo "GPT partition table OK"
    echo " "

    echo "Restoring EFI and boot partitions..."
    (echo "$pwd";) | fsarchiver restfs $clean_source id=0,dest=/dev/${disk}1 id=1,dest=/dev/${disk}2
    echo "EFI and boot partitions OK"
    echo " "

    echo "Creating partition for LUKS encrypted volume..."
    (echo n; echo 3; echo " "; echo " "; echo w;) | fdisk /dev/${disk}
    sudo partprobe
    echo "Partition for LUKS encrypted volume OK"
    echo " "

    echo "Creating LUKS encrypted volume..."
    cryptsetup luksFormat --hash=sha512 --key-size=512 --cipher=aes-xts-plain64 --verify-passphrase /dev/${disk}3
    #It will ask for password
    echo "LUKS encrypted volume OK"
    echo " "

    disk_crypt=fedora_crypt
    echo "Opening LUKS encrypted volume..."
    (echo "$pwd";) | cryptsetup luksOpen /dev/${disk}3 $disk_crypt
    echo "LUKS encrypted volume opened"
    echo " "

    #Get logical volumes names
    #lvdisplay -v /dev/vg00/lvol2

    #Now we need to take care of the LVM
    echo "Creating a physical LVM volume..."
    lvm pvcreate -ff /dev/mapper/$disk_crypt  #Use device as physical volume
    echo "Physical LVM volume OK"
    echo " "

    echo "Creating a LVM volume group inside the physical volume..."
    vgcreate vg0 /dev/mapper/$disk_crypt  #Create volume group containing the physical volume
    echo "LVM volume group OK"
    echo " "

    #Create the different logical volumes
    echo "Creating LVM logical volumes..."
    lvcreate -n root -L $root_size vg0
    lvcreate -n home -L $home_size vg0
    #lvcreate -n swap -L $swap_size vg0
    echo "LVM logical volumes OK"
    echo " "
    #lvcreate -n data -l +100%FREE vg0   #If you want to have a data partition encrypted as well


    #Now we have to recreate the LUKS partition and its content
    #
    echo "Restoring LUKS partitions from backup..."
    fsarchiver -c - -j3 restfs $clean_source id=2,dest=/dev/mapper/vg0-root id=3,dest=/dev/mapper/vg0-home #id=4,dest=/dev/mapper/vg0-swap
    echo "LUKS partitions from backup OK"
    echo " "

    umount /dev/mapper/vg0-root
    umount /dev/mapper/vg0-home
    umount /dev/mapper/vg0-swap
    #And finally we close the encrypted volume
    echo "Closing the LUKS encrypted volume..."
    cryptsetup luksClose $disk_crypt
    echo "LUKS encrypted volume successfully closed"
    echo " "

    echo "Restoration of your LUKS LVM encrypted system is successfull !"
    echo " "

else
    echo "Use the '-backup' argument to enter the backup mode"
    echo "Use the '-restore' argument to enter the restore mode"
fi

echo " "
echo "---------------------------------------"
echo "-------- End of LUKS LVM backup -------"
echo "---------------------------------------"
echo " "
