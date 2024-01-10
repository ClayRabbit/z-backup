#!/bin/sh
# usage: prepare.sh [username]
USER="$1"

if [ -n "$REMOTE_ADDR" ]; then
    echo -e "Content-Type: text/plain\n"
    exec 2>&1
    [ -n "$QUERY_STRING" ] && USER="$QUERY_STRING"
fi

if [ "$USER" == "" ]; then
    USER=$(whoami)
    if [ "${USER%root}" != "$USER" ]; then
        USER=$(hostname -s)
    fi
    if [ -z "$REMOTE_ADDR" ]; then
        read -p "\"$USER\" will be used as remote username. Generate ssh key and remote commands? " YN
        case $YN in
            [Yy]* ) break;;
            * ) exit;;
        esac
    fi
fi
#[ -e ~/.ssh/"backup-$USER.key" ] && echo ~/.ssh/"backup-$USER.key" already exist! && exit 2

ssh-keygen -t rsa -N "" -f ~/.ssh/"backup-$USER.key"
PUBKEY=$(cat ~/.ssh/"backup-$USER.key.pub")

[ $? != 0 ] && exit $?

cat <<EOF
# execute following commands on backup server (assuming "backup" is zfs pool for backups):
sudo zfs create "backup/$USER" \
&& sudo adduser "$USER" --disabled-password \
&& sudo zfs allow "$USER" snapshot,destroy,mount "backup/$USER" && sudo chown "$USER" "backup/$USER" \
&& sudo su "$USER" -c "cd '/home/$USER' && mkdir -pm700 .ssh && echo '$PUBKEY' >> .ssh/authorized_keys"
EOF
