#!/bin/sh
[ "$1" == "" ] && exit 1
set -xe
zfs create "backup/$1"
adduser "$1" --disabled-password
zfs allow "$1" snapshot,destroy "backup/$1"
su "$1" -c 'ssh-keygen -t rsa -N ""'
cat "/home/$1/.ssh/id_rsa.pub"
