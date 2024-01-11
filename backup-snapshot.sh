#!/bin/sh
# after backup is finished this script will be executed on remote server to create new snapshot

[ -z "$1" -o -z "$2" ] && echo not enough arguments && exit 1
POOL="$1"
EXPIRE="$2"
NOW=$(date +%s)
DATE=$(date +%Y-%m-%d:%H:%M:%S)
EXPIRE=$(expr "$NOW" + "$EXPIRE" * 24 * 60 * 60)

echo creating snapshot "$POOL@$DATE-$EXPIRE"
zfs snapshot "$POOL@$DATE-$EXPIRE"

#for SNAP in $(zfs list -t snapshot -o name | grep "^$POOL@"); do
#    EXPIRE=
#    [ -n "${SNAP##*-}" ] && [ ${SNAP##*-} -lt $(date +%s) ] && zfs destroy "$SNAP"
#done

# for security reasons deletion of expired snapshots should be implemented on server side - eg. using cron job:
#  for SNAP in $(zfs list -t snap -o name | grep '@[0-9][0-9]*-[0-9][0-9]-[0-9][0-9]:[0-9][0-9]:[0-9][0-9]:[0-9][0-9]-[0-9][0-9]*$'); do [ ${SNAP##*-} -lt $(date +\%s) ] && zfs destroy "$SNAP"; done
