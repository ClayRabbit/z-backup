#!/bin/sh
[ -z "$1" ] && exit 1
umask 066
DEST="$1"
BKDIR=${DEST#*//}
BKDIR="/${BKDIR#*/}/m"
HASH=$(echo "$1" | md5sum | cut -f1 -d" ")
TMPFILE="/var/tmp/backup_$hash.sql.gz"
FILES=$(ssh -c "find '$BKDIR'" "$DEST")

for db in $(mysql -Nse "SHOW DATABASES"); do
    [ "$db" = "sys" -o "$db" = "information_schema" -o "$db" = "performance_schema" ] && continue
    if echo "$FILES" | grep -q "^$BKDIR/$db\$"; then
        FILES=$(echo "$FILES" | grep -v "^$BKDIR/$db\$")
    else
        ssh -c "mkdir -pv '$BKDIR/$db'" "$DEST"
    fi
    for table in $(mysql -Nse "SHOW TABLES" "$db"); do
        [ "$db" = "mysql" ] && [ "$table" = "general_log" -o "$table" = "slow_log" ] && continue
        FILES=$(echo "$FILES" | grep -v "^$BKDIR/$db/$table.sql\$")
        echo -n "$db.$table: "
        mysqldump --skip-extended-insert --skip-dump-date --default-character-set=utf8 "$db" "$table" | gzip >"$TMPFILE" || continue
        cat "$TMPFILE" | ssh -c "gunzip -c > '$BKDIR/tmp.sql' && ! cmp --silent '$BKDIR/tmp.sql' '$BKDIR/$db/$table.sql' \
            && mv -f '$BKDIR/tmp.sql' '$BKDIR/$db/$table.sql' && echo 'dumped' || (echo 'skipped' && rm -f '$BKDIR/tmp.sql')"
        rm -f "$TMPFILE"
    done
done
#echo "$FILES" | grep -q / && echo "$FILES" | ssh -c "xargs -l -t rm -fv
