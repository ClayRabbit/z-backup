#!/bin/sh
[ -z "$1" ] && exit 1
[ -z "$3" ] && exit 1
[ -z "$4" ] && exit 1
umask 066
MYSQL_USER="$1"
MYSQL_PWD="$2"
BACKUP_HOST="$3"
BKDIR="$4/m"
SSH="ssh"
if [ -n "$5" ]; then
    SSH="$5"
fi
MYSQL="mysql"
MYSQLDUMP="mysqldump"
if [ -n "MYSQL_USER" ]; then
    MYSQL="$MYSQL -u$MYSQL_USER"
    MYSQLDUMP="$MYSQLDUMP -u$MYSQL_USER"
fi
if [ -n "MYSQL_USER" ]; then
    export MYSQL_PWD
    MYSQL="$MYSQL -p$MYSQL_PWD"
    MYSQLDUMP="$MYSQLDUMP -p$MYSQL_PWD"
fi

TMPFILE=$(mktemp /var/tmp/backup_XXXXXXXXXX)
FILES=$($SSH "$BACKUP_HOST" "[ ! -e $BKDIR ] && mkdir $BKDIR || find $BKDIR")
[ $? -ne 0 ] && echo "! Can't list remote files" && exit 1

for db in $($MYSQL -Nse "SHOW DATABASES" 2>/dev/null); do
    [ $? -ne 0 ] && echo "! Can't get database '$db' list" && exit 1
    [ "$db" = "sys" -o "$db" = "information_schema" -o "$db" = "performance_schema" ] && continue
    if echo "$FILES" | grep -q "^$BKDIR/$db\$"; then
        FILES=$(echo "$FILES" | grep -v "^$BKDIR/$db\$")
    else
        $SSH "$BACKUP_HOST" "mkdir -pv '$BKDIR/$db'"
    fi
    for table in $($MYSQL -Nse "SHOW TABLES" "$db" 2>/dev/null); do
        [ "$db" = "mysql" ] && [ "$table" = "general_log" -o "$table" = "slow_log" ] && continue
        FILES=$(echo "$FILES" | grep -v "^$BKDIR/$db/$table.sql\$")
        echo -n "$db.$table: "
        $MYSQLDUMP --skip-extended-insert --skip-dump-date --default-character-set=utf8 "$db" "$table" 2>/dev/null | gzip >"$TMPFILE" || continue
        cat "$TMPFILE" | $SSH "$BACKUP_HOST" "gunzip -c > '$BKDIR/tmp.sql' && ! cmp --silent '$BKDIR/tmp.sql' '$BKDIR/$db/$table.sql' \
            && mv -f '$BKDIR/tmp.sql' '$BKDIR/$db/$table.sql' && echo 'dumped' || (echo 'not changed' && rm -f '$BKDIR/tmp.sql')"
        rm -f "$TMPFILE"
    done
done
#echo "$FILES" | grep -q / && echo "$FILES" | $SSH "$BACKUP_HOST" "xargs -l -t rm -fv
