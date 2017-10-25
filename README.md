# JBOScript

~ Just a Bunch Of Script ~


## backup_nvme_luks.sh

If you have encrypted your Linux operating system (Fedora in my case), you might
find that there is no efficient way to backup and restore your system. You
can use 'dd' or any other raw backup tool but you will have to copy the entire
disk each time, which is a problem.

I made this script to solve this. Here are the steps for the backup (on
a mounted and decrypted system only) :
- Backup the GPT partition table with 'sgdisk' (for safety)
- Backup every mounted and decrypted / non-encrypted partitions with 'fsarchiver'

The restoration is a bit trickier :
- Create a new GTP partition table and 3 partitions on the destination disk
  - 1 FAT32 200Mo for EFI (non-encrypted)
  - 2 ext4 1Go for /boot (non-encrypted)
  - 3 LUKS encrypted volume
- Restore partitions 1 & 2 with 'fsarchiver'
- Encrypt and mount partition 3 with 'cryptsetup'
- Create 1 physical volume (pv), 1 volume group (vg) and 2 logical volume (lv)
- Restore logical volumes 'root' and 'home' with 'fsarchiver'
- Close the LUKS LVM restored on partition 3

You will probably have to edit /etc/fstab to make it work.

## backup_workstation.sh

A simple backup script in 3 steps:
- Backup system onto backup disk with 'fsarchiver'
- Backup gpt partition table with 'sgdisk' (for safety)
- Synchronize backup and data disks with 'rsync'


## backup_banana.sh

Another simple backup script. The system is 8Go, only a few things change over time
and I stock my backup on a SSD, so here the idea is to use 'dd' to make one full
raw backup of partitions 1 & 2 (/ and /boot), mount them and then use rsync each
time in the future to update the content of the backups without writing
everything again. In case of trouble just 'dd' everything back and voilà.


## gpu_clocks.sh

Overclock my NVIDIA GPU and start a mining software (claymore).
Made for a Zotac GTX1060 6Go. This script is kind of dirty.

The clocks are high but the card never gets into 'Performance Mode', or whatever
NVIDIA calls it, when mining. That is an NVIDIA bug on Linux with this kind of
card. So in fact, the card only gets half of this frequency offsets when mining.
OC has to be switched ON/OFF very quicky otherwise the card will get into
'Performance Mode' briefly before / after mining (silly drivers), therefore
getting the full frequency offset ... and crash.

Do not forget to change the public keys : ]
