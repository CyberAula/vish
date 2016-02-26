#!/bin/sh

BU_ADMINS="ebarra@dit.upm.es"
#BU_DEV="isabel@vccbk.global.dit.upm.es:/mnt/backups2" # sshfs
BU_MOUNTPOINT="/mnt/backups"
BU_DATE="$(date +%Y-%m-%d-%H:%M)"
BU_PATH="$BU_MOUNTPOINT/vishub/$BU_DATE"
BU_LASTPATH="$BU_MOUNTPOINT/vishub/last"
BU_ORIGS="/u/apps/vish/shared/exception_notification.rb \
          /u/apps/vish/shared/scripts \
          /u/apps/vish/shared/database.yml \
          /u/apps/vish/shared/system \
          /u/apps/vish/shared/pids \
          /etc/ssl \
          /etc/apache2/sites-available" ## Ommiting bundle/ because it's HUGE and documents/ because it's a symlink
BU_DBDUMP="/tmp/vish_production-$BU_DATE.sql.gz"
BU_ERROR=0

#sshfs $BU_DEV $BU_MOUNTPOINT  ## Mount target
rm -rf "$BU_PATH"
mkdir -p "$BU_PATH"

exec 6>&1
exec 7>&2
exec > $BU_LOGPATH
exec 2> $BU_LOGPATH
echo '=== Starting backup ==='

## Some database backup
UMASK=077 su isabel -c "pg_dump vish_production" | gzip -c > "$BU_DBDUMP" || BU_ERROR=1

## Make sure link to last backup called last/ points where it needs to
if ! test -L "$BU_LASTPATH"; then ln -sf "$BU_PATH" "$BU_LASTPATH"; fi

for d in $BU_ORIGS $BU_DBDUMP; do
  if test -d "$d"; then
    rsync -a --link-dest="$BU_LASTPATH/$(basename $d)" $d "$BU_PATH/$(basename $d)" || BU_ERROR=1
  else
    rsync -a $d "$BU_PATH/$(basename $d)" || BU_ERROR=1
  fi
done

rm -f "$BU_DBDUMP" "$BU_LASTPATH"
ln -s "$BU_PATH" "$BU_LASTPATH" ## Overwrite last link

echo '=== Ending backup (successfully) ==='

exec 1>&6 6>&-
exec 2>&7 7>&-

if test $BU_ERROR -gt 0; then
mail $BU_ADMINS -s "Error en el backup de ViSH" << _EOF
Ha habido un error al hacer el backup en `hostname -f`. El log se encuentra en $BU_LOGPATH y contiene lo siguiente:

---- LOG ----

$(cat $BU_LOGPATH)

---- /LOG ----

_EOF
fi

#umount $BU_MOUNTPOINT ## Umount target
