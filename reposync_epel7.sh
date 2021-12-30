#!/bin/bash

if [ -f /var/lock/subsys/rsync_updates ]; then
    echo "Updates via rsync already running."
    exit 0
fi

#epel6_mirror_dir="/var/mirrors/epel/6/x86_64"
epel7_mirror_dir="/nfs/repos/epel/7/x86_64"
base_dir="/nfs/repos/epel/"

#mirror_host="rsync://ftp.riken.jp/fedora/epel"
mirror_host="rsync://ftp.jaist.ac.jp/pub/Linux/Fedora/epel"

touch /var/lock/subsys/rsync_updates

#if [[ -d "$epel6_mirror_dir"  && -d "$epel7_mirror_dir" ]] ; then
if [[ -d "$epel7_mirror_dir" ]] ; then
#    rsync  -avSHP --delete rsync://mirror.wbs.co.za/fedora-epel/6/x86_64/ "$epel6_mirror_dir" && \
    rsync  -avSHP --delete $mirror_host/7/x86_64/ "$epel7_mirror_dir" && \
    rsync  -avSHP --delete $mirror_host/RPM-GPG-KEY-EPEL-7 "$base_dir" && \
#    rsync  -avSHP --delete rsync://mirror.wbs.co.za/fedora-epel/RPM-GPG-KEY-EPEL-6 "$base_dir" && \
    rm -rf /var/lock/subsys/rsync_updates

else
        echo "Directories doesn't exist"

fi

if [[ $? -eq '0' ]]; then
    echo ""
    echo "Sync successful.."
else
    echo " Syncing failed"
    exit 1
fi
