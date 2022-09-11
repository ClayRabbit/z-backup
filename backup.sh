#!/bin/sh
[ -z "$1" ] && exit 1
pgrep backup.sh |grep -v "^$$\$" && echo already running && exit 2

#ssh://user@hostname:port/backup/dir
DEST="$1"
POOL="$2"
if [ -z "$POOL" ]; then
    POOL=${DEST#*//}
    POOL=${POOL#*/}
fi
LOG="/var/log/backup.log"
BASEDIR=$(dirname "$0")

for i in $(seq 8 -1 1); do
    if [ -e "$LOG.$i.gz" ]; then
        j=$(expr "$i" + 1)
        mv "$LOG.$i.gz" "$LOG.$j.gz"
    fi
done
[ -e "$LOG" ] && gzip "$LOG" && mv "$LOG.gz" "$LOG.1.gz"

"$BASEDIR/backup-mysql.sh" "$DEST" >"$LOG"
nice -n19 "$BASEDIR/backup-rsync.sh" "$DEST" >>"$LOG"

if [ "$(date +\%d)" = "01" ]; then #Monthly backup
    EXPIRE=60
elif [ "$(date +\%u)" = "7" ]; then #Weekly backup
    EXPIRE=30
else #Daily backup
    EXPIRE=8
fi

cat "$BASEDIR/backup-snapshot.sh" | ssh -c "ssh -s '$POOL' '$EXPIRE' '$STATUS'" "$DEST" >>"$LOG"
