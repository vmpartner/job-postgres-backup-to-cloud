#!/bin/sh

set -e

SRC=$(date '+%d%m%Y%H%M%S').sql.gz

# BACKUP
##########################################################
rm -f /dump.sql || true
echo "$POSTGRES_HOST:$POSTGRES_PORT:$POSTGRES_DATABASE:$POSTGRES_USER:$POSTGRES_PASSWORD" > /root/.pgpass
chmod 0600 /root/.pgpass
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

# LOKI
##########################################################
if [ "${LOKI_URL}" = "**None**" ]; then
  echo "INFO: Define LOKI_URL to monitor sync job"
else
  echo "Curl check url and app: ${LOKI_URL} ${LOKI_APP}"
  DT=$(date +%s%N)
  DATA="{\"streams\": [{\"stream\": {\"app\": \"${LOKI_APP}\"},\"values\": [[${DT}, 1 ]]}]}"
  echo "JSON: $DATA"
  curl -v -H "Content-Type: application/json" -XPOST -s "$LOKI_URL" --data-raw "$DATA" || true
fi

