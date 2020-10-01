# backup_llvm_luks.sh

If you have encrypted your Linux operating system, you might find that there is no efficient way to backup and restore your system. You can use 'dd' or any other raw backup tool but you will have to copy the entire disk each time, which is a problem. I made this script to solve this.

A dd backup of a 500Go luks disk will use 500Go to store the disk image. This script allows you to only backup the used data inside this disk. For example I managed to backup a 500Go luks disk inside a 50Go encrypted and compressed backup (will vary according to your real disk usage).

Here are the steps for the backup (on a mounted and decrypted system only) :
- Backup the GPT partition table with 'sgdisk' (for safety)
- Backup every decrypted / non-encrypted partitions with 'fsarchiver'

The restoration is a bit trickier :
- Create a new GTP partition table and 3 partitions on the destination disk
  - 1 FAT16 200Mo for EFI (non-encrypted)
  - 2 ext4 1Go for /boot (non-encrypted)
  - 3 LUKS encrypted volume
- Restore partitions 1 & 2 with 'fsarchiver'
- Encrypt and mount partition 3 with 'cryptsetup'
- Create 1 physical volume (pv), 1 volume group (vg) and 2 logical volume (lv) (or 3 if you want to add swap)
- Restore logical volumes 'root' and 'home' with 'fsarchiver'
- Create new UUID for the destination partitions in order to avoid conflicts
- Mount the necessary things in /mnt/luks and chroot it
- Edit /etc/crypttab /etc/fstab and /etc/default/grub and replace the old UUID
- execute 'dracut -f' to regenerate the initramfs images
- execute grub2-mkconfig to update the bootloader
- Exit and reboot. You can now boot a clone of your encrypted system backup

Linux now uses UUID to identify disk (The probability to have same UUID is very low). So if you just duplicate your disk, you will end up with different disks having the same UUIDs (which is not gonna work). That is why you need to create new UUIDs (and therefore it implies to regenerate any files using those identifiers).

**!!! BEWARE !!!**

This is highly untested. You should read and understand this script before using it. If you don't understand it, DON'T USE IT