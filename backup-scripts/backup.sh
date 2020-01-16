#!/bin/bash

declare -A RETAIN=([daily]=7 [weekly]=4 [monthly]=2)

BASENAME="$(dirname $0)"
SCHEDULE=${BASENAME/\/etc\/cron./}

NFS=/var/nfsshare

BCK_SUFFIX="$(date +%F)"
BCK_FOLDER=/home/USER/k8data/backup

SSH_KEY=/opt/backup/id_rsa_backup
SSH_HOST=USER@HOSTNAME

ssh -i $SSH_KEY $SSH_HOST "[ -d $BCK_FOLDER/$SCHEDULE ] || mkdir -p $BCK_FOLDER/$SCHEDULE"

tar cz $NFS/* | ssh -i $SSH_KEY $SSH_HOST "cat - >  $BCK_FOLDER/$SCHEDULE/nfsshare_$BCK_SUFFIX.tgz"

ssh -i $SSH_KEY $SSH_HOST "tar tzf  $BCK_FOLDER/$SCHEDULE/nfsshare_$BCK_SUFFIX.tgz" > /dev/null
ret=$?
if [ "$ret" -gt "0" ]; then
    /usr/bin/logger "Unable to create tar file to machine in $SSH_HOST to $BCK_FOLDER/$SCHEDULE/nfsshare_$BCK_SUFFIX.tgz"
else
    for p in $(ssh -i $SSH_KEY $SSH_HOST "ls -r $BCK_FOLDER/$SCHEDULE | head -n -${RETAIN[$SCHEDULE]}")
    do
        echo "Removing old backup in $BCK_FOLDER/$SCHEDULE/$p"
        ssh -i $SSH_KEY $SSH_HOST "rm -f $BCK_FOLDER/$SCHEDULE/$p"
    done | /usr/bin/logger
    for p in $(ls -r $NFS/backup | head -n -2)
    do
        echo "Removing old backup in $NFS/backup/$p"
        rm -f $NFS/backup/$p
    done | /usr/bin/logger
    
fi


