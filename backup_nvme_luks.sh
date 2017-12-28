#!/bin/bash
#Purpose = Backup of LUKS LVM encrypted linux system
#To modify the scheduling => crontab -e
#Version 1.1
#START

#dmsetup remove vg0-root vg0-home vg0-swap fedora_crypt

START_TIME=$SECONDS
DATE=`date +%d%m%y`

root_size=150G
home_size=150G
swap_size=16G

clear
echo " "
echo "---------------------------------------"
echo "------------ LUKS LVM backup ----------"
echo "---------------------------------------"
echo " "
echo "WARNING: Please check this script configuration before using !"
echo "         It could break your system a thousand different ways !"
echo " "

################################################################################
################################################################################
#All about up the LUKS drive ###################################################
if [ "$1" == "-backup" ]; then
    echo "------------- Backup Mode -------------"
    echo " "

    echo "Enter the source LUKS LVM drive to backup (/dev/xxx):"
    read SRC;
    echo " "

    echo "Enter the destination directory :"
    read DST;
    echo " "

    echo "Source -> $SRC"
    echo "Location -> $DST"

    mkdir $DST/backup_nvme_luks_$DATE
    echo "Backup of the partition table ..."
    sgdisk --backup=$DST/backup_nvme_luks_$DATE/partition_table_$DATE.txt $SRC
    echo "Backup of the partition table ------------------------------------- OK"
    echo " "

    #Backup p1 & p2 and the mouted encrypted volumes in /dev/mapper
    echo "Backup of the partitions ..."
    echo "Please enter a password for the backup encryption. It is gonna take some time."
    fsarchiver savefs -z 7 -c - -o $DST/backup_nvme_luks_$DATE/backup_nvme_luks_$DATE.fsa ${SRC}p1 ${SRC}p2 /dev/mapper/fedora-root /dev/mapper/fedora-home  -j3 -A
    echo "Backup of the partitions ------------------------------------------ OK"
    echo " "

    ELAPSED_TIME=&(($SECONDS - $START_TIME))
    echo "Backup of NVME laptop ssd took $ELAPSED_TIME seconds"

################################################################################
################################################################################
#All about restoring the LUKS drive backup #####################################
elif [ "$1" == "-restore" ]; then
    echo "------------- Restore Mode ------------"
    echo " "

    echo "Enter the device name (/dev/...):"
    read disk;
    echo " "

    echo "Trying to unmount any partitions from the destination disk ..."
    umount -f /dev/mapper/vgfedora*
    #cryptsetup luksClose /dev/mapper/$vgname*
    #lvchange -a n vgfedora
    umount -f /dev/${disk}*
    echo "Destination disk unmounted ---------------------------------------- OK"

    echo " "
    echo "Please enter the backup file location:"
    source=0
    read source;
    clean_source="$( echo $source 2>&1| sed "s/^\([\"']\)\(.*\)\1\$/\2/g")"
    if [ "$clean_source" == 0 ]; then
      exit
    fi
    echo " "

    #Basic device size verification
    disk_size=$(sudo fdisk -l /dev/$disk | sed -n 1p | cut -d " " -f3)
    need_size=$(sudo du -k -h $clean_source | cut -f1)
    # Round values
    need_size=$(echo ${need_size::-1} | awk '{print ($0-int($0)>0)?int($0)+1:int($0)}')
    disk_size=$(echo $disk_size | awk '{print ($0-int($0)>0)?int($0)+1:int($0)}')
    if [ "$disk_size" -le "${need_size::-1}" ]; then
      echo "ERROR: This backup file won't fit, the disk size is too small."
      echo " "
      exit
    fi

    #Restore EFI & boot partitions
    echo "Restoring GPT partition table..."
    partprobe
    parted -s /dev/$disk mklabel gpt
    (echo n; echo 1; echo " "; echo +200M; echo t; echo 1; echo w;) | fdisk /dev/${disk} &>/dev/null
    partprobe
    mkfs.fat -F16 /dev/${disk}1
    #mlabel -i /dev/${disk}1 :"EFI System Partition"
    (echo n; echo 2; echo " "; echo +1G; echo w) | fdisk /dev/${disk} &>/dev/null
    #############################################Restore the backup !!
    #partprobe
    echo "GPT partition table ----------------------------------------------- OK"
    echo " "

    echo "Creating partition for LUKS encrypted volume..."
    (echo n; echo 3; echo " "; echo " "; echo w;) | fdisk /dev/${disk} &>/dev/null
    sudo partprobe
    umount -f /dev/${disk}3
    echo "Partition for LUKS encrypted volume ------------------------------- OK"
    echo " "

    echo "Creating LUKS encrypted volume..."
    cryptsetup luksFormat --hash=sha512 --key-size=512 --cipher=aes-xts-plain64 --verify-passphrase -q /dev/${disk}3
    #It will ask for password
    echo "LUKS encrypted volume --------------------------------------------- OK"
    echo " "

    echo "Please enter a name for the new lvm group:"
    vgname=0
    read vgname;
    if [ "$vgname" == 0 ]; then
      exit
    fi
    echo " "

    old_uuid3=$(blkid /dev/${disk}3 | cut -d " " -f 2 | cut -c 7-42)
    disk_crypt=luks-${old_uuid3} #temporary name for the mounted luks

    echo "Opening LUKS encrypted volume..."
    cryptsetup luksOpen /dev/${disk}3 $disk_crypt
    echo "LUKS encrypted volume opening ------------------------------------- OK"
    echo " "

    #Now we need to take care of the LVM
    echo "Creating a physical LVM volume..."
    lvm pvcreate -ff -y /dev/mapper/$disk_crypt  #Use device as physical volume
    echo "Physical LVM volume creation -------------------------------------- OK"
    echo " "

    echo "Creating a LVM volume group inside the physical volume..."
    vgcreate vgfedora /dev/mapper/$disk_crypt  #Create volume group containing the physical volume
    echo "LVM volume group creation ----------------------------------------- OK"
    echo " "

    #Create the different logical volumes
    echo "Creating LVM logical volumes..."
    lvcreate -n lvroot -L $root_size $vgname
    lvcreate -n lvhome -L $home_size $vgname
    #lvcreate -n data -l +100%FREE vgfedora   #If you want to have a data partition encrypted as well
    #lvcreate -n swap -L $swap_size vgfedora
    echo "LVM logical volumes creation -------------------------------------- OK"
    echo " "

    #Now we have to restore the partitions from the backup
    echo "Restoring partitions from backup..."
    sudo fsarchiver -c - -j3 restfs $clean_source id=0,dest=/dev/${disk}1 id=1,dest=/dev/${disk}2 id=2,dest=/dev/mapper/$vgname-lvroot id=3,dest=/dev/mapper/$vgname-lvhome &>/dev/null #id=4,dest=/dev/mapper/fedora-swap
    echo "Restoring partitions from backup ---------------------------------- OK"
    echo " "

    cryptsetup luksClose /dev/mapper/$vgname*

################################################################################
################################################################################

    echo "Update partitions with new UUIDs ..."
    tmp1=$(blkid /dev/${disk}1 | cut -d " " -f 3 | cut -c 7-15)
    old_uuid1=${tmp1^^}
    old_uuid2=$(blkid /dev/${disk}2 | cut -d " " -f 2 | cut -c 7-42)
    old_uuid3=$(blkid /dev/${disk}3 | cut -d " " -f 2 | cut -c 7-42)
    tmp2=$(uuidgen | cut -d - -f 2,3)
    new_uuid1=$(echo ${tmp2^^} | cut -c 1,2,3,4,6,7,8,9)
    new_uuid2=$(uuidgen)
    new_uuid3=$(uuidgen)

    echo " "
    echo ${old_uuid1^^}
    echo $old_uuid2
    echo $old_uuid3
    echo ${new_uuid1^^}
    echo $new_uuid2
    echo $new_uuid3
    echo " "

    echo "Replacing /dev/${disk}1 UUID ..."
    mlabel -N $new_uuid1 -i /dev/${disk}1
    echo " "

    echo "Replacing /dev/${disk}2 UUID ..."
    e2fsck -f /dev/${disk}2
    tune2fs -U $new_uuid2 /dev/${disk}2
    echo " "

    echo "Replacing /dev/${disk}3 UUID ..."
    cryptsetup luksOpen /dev/${disk}3 $vgname
    cryptsetup luksUUID /dev/${disk}3 --uuid $new_uuid3 -q

    echo "Update partitions with new UUIDs -------------------------------------- OK"
    echo " "

################################################################################
################################################################################

    echo "Modifying crypttab, fstab & grub configuration files ..."
    lvchange -a y ${vgname}

    mkdir /mnt/luks &>/dev/null
    mount /dev/mapper/$vgname-lvroot /mnt/luks &>/dev/null
    mount /dev/${disk}2 /mnt/luks/boot &>/dev/null
    mount -t vfat /dev/${disk}1 /mnt/luks/boot/efi &>/dev/null

    echo "luks-$new_uuid3 UUID=$new_uuid3 none discard" > /mnt/luks/etc/crypttab

    sed -i ":a;N;\$!ba;s/UUID=[A-Fa-f0-9-]*/UUID="$new_uuid2"/1" /mnt/luks/etc/fstab
    sed -i ":a;N;\$!ba;s/UUID=[A-Fa-f0-9-]*/UUID="${tmp2^^}"/2" /mnt/luks/etc/fstab
    sed -i ":a;N;\$!ba;s/\/dev\/mapper\/[A-Fa-f0-9-]*fedora[A-Fa-f0-9-]*root[A-Fa-f0-9-]*/\/dev\/mapper\/"$vgname"-lvroot/1" /mnt/luks/etc/fstab
    sed -i ":a;N;\$!ba;s/\/dev\/mapper\/[A-Fa-f0-9-]*fedora[A-Fa-f0-9-]*home[A-Fa-f0-9-]*/\/dev\/mapper\/"$vgname"-lvhome/1" /mnt/luks/etc/fstab
    sed -i ":a;N;\$!ba;s/\/dev\/mapper\/[A-Fa-f0-9-]*fedora[A-Fa-f0-9-]*swap[A-Fa-f0-9-]*/#\/dev\/mapper\/"$vgname"-lvswap/1" /mnt/luks/etc/fstab #swap desactivated

    sed -i ":a;N;\$!ba;s/[A-Fa-f0-9-]*fedora[A-Fa-f0-9-]*\/[A-Fa-f0-9-]*root[A-Fa-f0-9-]*/"$vgname"\/lvroot/1" /mnt/luks/etc/default/grub
    sed -i ":a;N;\$!ba;s/rd.luks.uuid=luks-[A-Fa-f0-9-]*/rd.luks.uuid=luks-"$new_uuid3"/1" /mnt/luks/etc/default/grub
    sed -i ":a;N;\$!ba;s/rd.lvm.lv=[A-Fa-f0-9-]*fedora[A-Fa-f0-9-]*\/[A-Fa-f0-9-]*swap[A-Fa-f0-9-]*//1" /mnt/luks/etc/default/grub

    echo "Modifying crypttab, fstab & grub configuration files ------------------ OK"
    echo " "

################################################################################
################################################################################

    #Create environment and chroot
    echo "Create environment and chroot ..."

    #Mount special devices
    cd /mnt/luks
    mount -o bind /dev dev
    mount -o bind /proc proc
    mount -o bind /sys sys
    mount -t tmpfs tmpfs tmp

################################################################################
################################################################################

chroot /mnt/luks /usr/bin/env disk=$disk /bin/bash <<EOF
echo "Create environment and chroot ----------------------------------------- OK"
echo " "

echo "Updating initramfs files ..."
dracut -f &>/dev/null
echo "Updating initramfs files ---------------------------------------------- OK"
echo " "

echo "Updating GRUB bootloader ..."
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg &>/dev/null
echo "Updating GRUB bootloader ---------------------------------------------- OK"
echo " "

echo "Exit Chroot and umount ..."
exit
EOF

################################################################################
################################################################################

for d in sys dev tmp proc ; do umount -f /mnt/luks/"$d" ; done
#umount /mnt/luks/{proc,sys,dev,run}

umount -f /mnt/luks/boot/efi
umount -f /mnt/luks/boot
umount -f /mnt/luks
#rm -fr /mnt/luks

umount -f /dev/mapper/$vgname* &>/dev/null
lvchange -a n $vgname &>/dev/null
umount -f /dev/${disk}* &>/dev/null

cryptsetup luksClose /dev/mapper/$vgname*

echo "Exit Chroot and umount ------------------------------------------------ OK"
echo " "
#ELAPSED_TIME=&(($SECONDS - $START_TIME))
#echo "Backup of NVME laptop ssd took $ELAPSED_TIME seconds"
echo " "
echo "--------------------------------------------------------------------------"
echo "Restoration of the LUKS LVM encrypted system has successfully ended ------"
echo "--------------------------------------------------------------------------"
echo " "

################################################################################
################################################################################

else
    echo "Use the '-backup' argument to enter the backup mode"
    echo "Use the '-restore' argument to enter the restore mode"
fi
