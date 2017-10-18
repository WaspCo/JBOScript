#!/bin/bash
#Purpose = Backup of Important Data
#Created on 17-1-2012
#Pour modifier le scheduling, => crontab -e
#Version 1.0
#START

START_TIME=$SECONDS
TIME=`date +%b-%d-%y`            # This Command will add date in Backup File Name.
FILENAME=backup-$TIME.tar.gz    # Here i define Backup file name format.
SRCDIR=/                    # Location of Important Data Directory (Source of backup).
DESDIR=/mnt/data/backup/bpi_server_backup            # Destination of backup file.

echo " "
echo "--------------------------------------"
echo "----- Lancement de la sauvegarde -----"
echo "--------------------------------------"
echo " "
echo "Source -> $SRCDIR"
echo "Destination -> $DESDIR"
echo " "

tar -cpzf $DESDIR/$FILENAME --exclude='/boot' --exclude='/mnt/data' --exclude='/mnt/usb' --exclude='/pro$

ELAPSED_TIME=$(($SECONDS - $START_TIME))

echo " "
echo "Execution en $ELAPSED_TIME secondes."
echo "--------------------------------------"
echo "---------------- FIN -----------------"
echo "--------------------------------------"
echo " "
#END
