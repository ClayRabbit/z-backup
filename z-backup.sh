#!/bin/sh
pgrep "-u$(id -u)" z-backup.sh |grep -v "^$$\$" && echo already running && exit 1

BASEDIR=$(dirname "$0")

if [ -n "$1" ]; then
    CFG="$1"
else
    CFG="$BASEDIR/z-backup.conf"
fi
[ ! -e "$CFG" ] && echo "$CFG" not found && exit 2

. $(realpath "$CFG")

[ -z "$BACKUP_HOST" ] && echo backup host not specified && exit 3
[ -z "$BACKUP_LOGIN" ] && echo backup login not specified && exit 3
[ -z "$BACKUP_PATH" ] && echo backup path not specified && exit 3
[ -z "$BACKUP_POOL" ] && echo backup pool not specified && exit 3

SRC="$SOURCE"
if [ -z "$SRC" ]; then
    if [ "$UID" = "0" ]; then
        SRC="/"
    else
        SRC="$HOME/"
    fi
fi

LOG="$BASEDIR/$(basename "$CFG" .conf).log"
SSH="ssh -oBatchMode=yes -o StrictHostKeychecking=no"
PORT=${BACKUP_HOST##*:}
if [ -n "$PORT" ]; then
    BACKUP_HOST=${BACKUP_HOST%%:*}
    SSH="$SSH -p $PORT"
fi
if [ -n "$SSH_KEY" ]; then
    SSH="$SSH -i$SSH_KEY"
fi

for i in $(seq 8 -1 1); do
    if [ -e "$LOG.$i.gz" ]; then
        j=$(expr "$i" + 1)
        mv "$LOG.$i.gz" "$LOG.$j.gz"
    fi
done
[ -e "$LOG" ] && gzip "$LOG" && mv "$LOG.gz" "$LOG.1.gz"

if [ -n "$MYSQL_USER" ]; then
    echo "### mysql backup $(date) ###" >"$LOG"
    (cd "$BASEDIR" && "./z-backup.mysql.sh" "$MYSQL_USER" "$MYSQL_PASS" "$BACKUP_LOGIN@$BACKUP_HOST" "$BACKUP_PATH" "$SSH") >>"$LOG"
fi

echo "### files backup $(date) ###" >>"$LOG"
if [ -n "$CRON_BACKUP" ]; then
    CRON=$(crontab -l 2>/dev/null)
    if [ -n "$CRON" ]; then
        echo "$CRON" | cmp -s - "$SRC/$CRON_BACKUP" || echo "$CRON" >"$SRC/$CRON_BACKUP"
    fi
fi
(cd "$BASEDIR" && nice -n19 "./z-backup.rsync.sh" "$SRC" "$BACKUP_LOGIN@$BACKUP_HOST:$BACKUP_PATH" "$SSH") >>"$LOG"

if [ "$(date +\%d)" = "01" ]; then #Monthly backup
    EXPIRE="$MONTHLY_EXPIRE"
elif [ "$(date +\%u)" = "7" ]; then #Weekly backup
    EXPIRE="$WEEKLY_EXPIRE"
else #Daily backup
    EXPIRE="$DAILY_EXPIRE"
fi

echo "### snapshots $(date) ###" >>"$LOG"
cat "$BASEDIR/z-backup.snapshot.sh" | $SSH "$BACKUP_LOGIN@$BACKUP_HOST" "/bin/sh -s '$BACKUP_POOL' '$EXPIRE'" >>"$LOG"

echo "### finished $(date) ###" >>"$LOG"
