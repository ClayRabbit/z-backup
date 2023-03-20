#!/bin/sh
[ "$1" == "" ] && exit 1

[ -e "~/.ssh/backup.key" ] && echo ~/.ssh/backup.key already exist! && exit 2

ssh-keygen -t rsa -N "" -f ~/.ssh/backup.key
pubkey=$(cat ~/.ssh/backup.key)

echo <<EOF
# execute following commands on backup server (assuming "backup" is zfs pool for backups):
sudo zfs create "backup/$1"
sudo adduser "$1" --disabled-password
sudo zfs allow "$1" snapshot,destroy "backup/$1"
sudo su "$1" -c "cd '/home/$1' && mkdir -pm700 .ssh && echo '$pubkey' >> .ssh/authorized_keys"
EOF
