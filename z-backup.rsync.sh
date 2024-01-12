#!/bin/sh
SSH="ssh"
if [ -n "$3" ]; then
    SSH="$3"
fi
rsync -e "$SSH" -avz --numeric-ids --no-specials --no-devices --hard-links --delete --delete-after --delete-excluded --inplace -M--fake-super \
    --exclude=/dev --exclude=/proc --exclude=/sys --exclude=/selinux --exclude=/cgroups --exclude=lost+found \
    --exclude='/tmp/*' --exclude='/var/tmp/*' --exclude='/run/*' --exclude='/var/run/*' --exclude='/var/log/*' --exclude=/var/lib/lxcfs/ \
    --include-from=./rsync.include --exclude-from=./rsync.exclude "$1" "$2/d/"
