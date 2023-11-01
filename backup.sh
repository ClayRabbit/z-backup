#!/bin/sh
pgrep backup.sh |grep -v "^$$\$" && echo already running && exit 1

if [ -n "$1" ]; then
    CFG="$1"
else
    CFG="backup.conf"
fi
[ ! -e "$CFG" ] && echo "$CFG" not found && exit 2

. $(realpath "$CFG")

[ -z "$DESTINATION" ] && echo destination not specified && exit 3
DEST="$DESTINATION"

SRC="$SOURCE"
if [ -z "$SRC" ]; then
    if [ "$UID" = "0" ];
        SRC="/"
    else
        SRC="$HOME"
    fi
fi

if [ -z "$POOL" ]; then
    POOL=${DEST#*//}
    POOL=${POOL#*/}
fi

BASEDIR=$(dirname "$0")

LOG="$(basename "$CFG" .conf).log"

for i in $(seq 8 -1 1); do
    if [ -e "$LOG.$i.gz" ]; then
        j=$(expr "$i" + 1)
        mv "$LOG.$i.gz" "$LOG.$j.gz"
    fi
done
[ -e "$LOG" ] && gzip "$LOG" && mv "$LOG.gz" "$LOG.1.gz"

"$BASEDIR/backup-mysql.sh" "$DEST" >"$LOG"
nice -n19 "$BASEDIR/backup-rsync.sh" "$SRC" "$DEST" >>"$LOG"

if [ "$(date +\%d)" = "01" ]; then #Monthly backup
    EXPIRE="$MONTHLY_EXPIRE"
elif [ "$(date +\%u)" = "7" ]; then #Weekly backup
    EXPIRE="$WEEKLY_EXPIRE"
else #Daily backup
    EXPIRE="$DAILY_EXPIRE"
fi

cat "$BASEDIR/backup-snapshot.sh" | ssh -c "sh -s '$POOL' '$EXPIRE' >>"$LOG"
