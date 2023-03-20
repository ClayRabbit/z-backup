#!/bin/sh
[ "$1" == "" ] && exit 1

[ -e "~/.ssh/backup.key" ] && echo ~/.ssh/backup.key already exist! && exit 2

ssh-keygen -t rsa -N "" -f ~/.ssh/backup.key
pubkey=$(cat ~/.ssh/backup.key)

echo <<EOF
# execute following command on backup server (assuming "backup" is zfs pool for backups):
zfs create "backup/$1"
adduser "$1" --disabled-password
zfs allow "$1" snapshot,destroy "backup/$1"
su "$1" -c "echo '$pubkey' >> '/home/$1/.ssh/authorized_keys
EOF
