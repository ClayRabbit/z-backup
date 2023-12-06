#!/bin/sh
# after backup is finished this script will be executed on remote server to create new snapshot and prune expired snapshots

[ -z "$1" -o -z "$2" ] && echo not enough arguments && exit 1
POOL="$1"
EXPIRE="$2"
NOW=$(date +%s)
DATE=$(date +%Y-%m-%d:%H:%M:%S)
EXPIRE=$(expr "$NOW" + "$EXPIRE" * 24 * 60 * 60)

echo creating snapshot "$POOL@$DATE-$EXPIRE"
zfs snapshot "$POOL@$DATE-$EXPIRE"
for SNAP in $(zfs list -t snapshot -o name | grep "^$POOL@"); do
    EXPIRE=${SNAP##*-}
    [ $EXPIRE -gt 0 ] || continue
    [ $EXPIRE -lt $NOW ] && echo deleting snapshot "$SNAP" && zfs destroy "$SNAP"
done
