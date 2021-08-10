#!/bin/sh

set -e

SRC=$(date '+%d%m%Y%H%M%S').sql.gz

# BACKUP
##########################################################
rm -f /dump.sql || true
pg_dump --create --file=/dump.sql --format=c --dbname="$POSTGRES_DATABASE" --username="$POSTGRES_USER" --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" -v

# GZIP
##########################################################
cd /
rm -f dump.sql.gz
gzip dump.sql
mv dump.sql.gz "${SRC}"

# COPY
##########################################################
echo "Start $(date '+%d-%m-%Y %H:%M:%S')"
FILESIZE=$(stat -c%s /${SRC})
echo "Size of ${SRC} = $FILESIZE bytes."
rclone copy /${SRC} "$RCLONE_DEST"
rm -f "/${SRC}"
echo "Finish $(date '+%d-%m-%Y %H:%M:%S')"

# CHECK
##########################################################
if [ "${CHECK_URL}" = "**None**" ]; then
  echo "INFO: Define CHECK_URL with https://healthchecks.io to monitor sync job"
else
  echo "Curl check url: ${CHECK_URL}"
  curl "${CHECK_URL}"
fi

