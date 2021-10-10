#!/bin/sh

set -e

TRG=$(date '+%d%m%Y%H%M%S').sql

cleanup() {
  echo "removing /backup/${TRG}"
  rm -f /backup/${TRG}
}
trap cleanup EXIT

# BACKUP
##########################################################
rm -f /backup/${TRG} || true
echo "$POSTGRES_HOST:$POSTGRES_PORT:$POSTGRES_DATABASE:$POSTGRES_USER:$POSTGRES_PASSWORD" > /root/.pgpass
chmod 0600 /root/.pgpass
pg_dump --create --file=/backup/${TRG} --format=c --dbname="$POSTGRES_DATABASE" --username="$POSTGRES_USER" --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" -v

# STAT
##########################################################
ls -alh /backup/

# COPY
##########################################################
if [ "${RCLONE_DEST}" = "**None**" ]; then
  echo "INFO: Define RCLONE_DEST for upload backup to remote server"
else
  echo "Start $(date '+%d-%m-%Y %H:%M:%S')"
  rclone copy /backup/${TRG} "$RCLONE_DEST"
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

