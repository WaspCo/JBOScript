# backup_regular.sh

In 2 steps:
- Backup all partitions using `dd`
- Backup gpt partition table with `sgdisk`

4 environment variables are expected to be set:

>$BACKUP_SOURCE_DISK

Name of the disk to backup, without /dev/

> $BACKUP_DESTINATION_DISK

Path of the destination folder.

> $BACKUP_SOURCE_DISK_PARTICULE

Optional particule before the partition index. For a disk nvme0n1, and a partition nvme0n1p1, this would be p.

> $BACKUP_SOURCE_DISK_START_IDX

Starting index of the partitions, often 0 or 1.