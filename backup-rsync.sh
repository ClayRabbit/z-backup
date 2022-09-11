#!/bin/sh
rsync -a --numeric-ids --hard-links --compress --delete --delete-after --delete-excluded --inplace \
    --exclude=/dev --exclude=/proc --exclude=/sys --exclude=/selinux --exclude=/cgroups --exclude=lost+found \
    --exclude='/tmp/*' --exclude='/var/tmp/*' --exclude='/var/run/*' --exclude='/var/log/*' --exclude='/var/lib/lxcfs/' \
    --include-from=./rsync.include --exclude-from=./rsync.exclude / "$1/d/"
