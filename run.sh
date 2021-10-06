#!/bin/sh

set -e

SRC=$(date '+%d%m%Y%H%M%S').sql.gz

# BACKUP
##########################################################
rm -f /backup/dump.sql || true
echo "$POSTGRES_HOST:$POSTGRES_PORT:$POSTGRES_DATABASE:$POSTGRES_USER:$POSTGRES_PASSWORD" > /root/.pgpass
chmod 0600 /root/.pgpass
pg_dump --create --file=/backup/dump.sql --format=c --dbname="$POSTGRES_DATABASE" --username="$POSTGRES_USER" --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" -v

# STAT
##########################################################
FILESIZE=$(stat -c%s /backup/${SRC})
echo "Size of ${SRC} = $FILESIZE bytes."

# COPY
##########################################################
if [ "${RCLONE_DEST}" = "**None**" ]; then
  echo "INFO: Define RCLONE_DEST for upload backup to remote server"
else
  echo "Start $(date '+%d-%m-%Y %H:%M:%S')"
  rclone copy /backup/${SRC} "$RCLONE_DEST"
  rm -f /backup/${SRC}
  echo "Finish $(date '+%d-%m-%Y %H:%M:%S')"
fi

# CHECK
##########################################################
if [ "${CHECK_URL}" = "**None**" ]; then
  echo "INFO: Define CHECK_URL to monitor sync job"
else
  echo "Curl check url: ${CHECK_URL}"
  curl "${CHECK_URL}"
fi

# LOKI
##########################################################
if [ "${LOKI_URL}" = "**None**" ]; then
  echo "INFO: Define LOKI_URL for send ping to Grafana Loki"
else
  echo "Curl check url and app: ${LOKI_URL} ${LOKI_APP}"
  DT=$(date +%s%N)
  DATA="{\"streams\": [{\"stream\": {\"app\": \"${LOKI_APP}\"},\"values\": [[${DT}, 1 ]]}]}"
  echo "JSON: $DATA"
  curl -v -H "Content-Type: application/json" -XPOST -s "$LOKI_URL" --data-raw "$DATA" || true
fi

