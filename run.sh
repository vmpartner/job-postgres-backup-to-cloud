#!/bin/sh

set -e

DT=$(date '+%d%m%Y%H%M%S')
FILENAME=/backup/${DT}.sql

cleanup() {
  echo "removing ${FILENAME}"
  rm -f ${FILENAME}
}
trap cleanup EXIT

# BACKUP
##########################################################
rm -f ${FILENAME} || true
echo "$POSTGRES_HOST:$POSTGRES_PORT:$POSTGRES_DATABASE:$POSTGRES_USER:$POSTGRES_PASSWORD" > /root/.pgpass
chmod 0600 /root/.pgpass
pg_dump --create --file=${FILENAME} --format=c --dbname="$POSTGRES_DATABASE" --username="$POSTGRES_USER" --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" -v

# STAT
##########################################################
ls -alh /backup/

# COPY
##########################################################
echo "Start copy to remote server $(date '+%d-%m-%Y %H:%M:%S')"
if [ -n "$(find "${FILENAME}" -prune -size +2147483648c)" ]; then
  echo "Split big file"
  split -b 1G ${FILENAME} /backup/dump_${DT}.
  ls -alh /backup/
  echo "Copy to remote server"
  rclone copy -v /backup/ --include "dump_${DT}*" ${RCLONE_DEST}
  rm -rf /backup/dump_*
else
  rclone copy -v ${FILENAME} ${RCLONE_DEST}
fi
echo "Finish $(date '+%d-%m-%Y %H:%M:%S')"

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
