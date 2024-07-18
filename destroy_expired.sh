#!/bin/sh
# Destroy expired snapshots if number of snaphot more than minimum specified.
# This script is should be executed daily on backup storage server.
MIN=8
for ZVOL in $(zfs list -Ho name | grep /); do
    for SNAP in $(zfs list -Hrt snapshot -o name "$ZVOL" | grep '@[0-9][0-9]*-[0-9][0-9]-[0-9][0-9]:[0-9][0-9]:[0-9][0-9]:[0-9][0-9]-[0-9][0-9]*$ | head -n "-$MIN"'); do
        [ ${SNAP##*-} -lt $(date +\%s) ] && zfs destroy "$SNAP";
    done
done
