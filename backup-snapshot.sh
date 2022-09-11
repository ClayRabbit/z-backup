#!/bin/sh
[ -z "$1" -o -z "$2" ] && exit 1
POOL="$1"
EXPIRE="$2"
NOW=$(date +%s)
DATE=$(date +%Y-%m-%d:%H:%M:%S)
EXPIRE=$(expr "$NOW" + "$EXPIRE" * 24 * 60 * 60)

zfs snapshot "$POOL@$DATE-$EXPIRE"
for SNAP in $(zfs list -t snapshot -o name | grep "^$POOL@"); do
    EXPIRE=${SNAP##*-}
    [ $EXPIRE -gt 0 ] || continue
    [ $EXPIRE -lt $NOW ] && zfs destroy "$SNAP"
done
