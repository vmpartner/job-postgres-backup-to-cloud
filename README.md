# Backup postgres to cloud

Used https://rclone.org for rsync to cloud

## Usage k8s
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  labels:
    app: backup-db
  name: backup-db
  namespace: myspace
spec:
  timeZone: "Europe/Moscow"
  schedule: "0 22 * * *"
  successfulJobsHistoryLimit: 5
  failedJobsHistoryLimit: 5
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          nodeSelector:
            node: tm-node-3
          containers:
            - name: backup-db
              image: vmpartner/job-postgres-backup-to-cloud:16-v1.3.2
              resources:
                limits:
                  cpu: 250m
                  memory: 4096Mi
                requests:
                  cpu: 100m
                  memory: 64Mi
              env:
                - name: TZ
                  value: "Europe/Moscow"
                - name: POSTGRES_DATABASE
                  value: "myspace"
                - name: POSTGRES_HOST
                  value: "myhost"
                - name: POSTGRES_PORT
                  value: "5432"
                - name: POSTGRES_USER
                  value: "myspace"
                - name: POSTGRES_PASSWORD
                  value: "mypass"
                - name: RCLONE_CONFIG_SELECTEL_TYPE
                  value: "swift"
                - name: RCLONE_CONFIG_SELECTEL_ENV_AUTH
                  value: "false"
                - name: RCLONE_CONFIG_SELECTEL_USER
                  value: "myseluser"
                - name: RCLONE_CONFIG_SELECTEL_KEY
                  value: "myselkey"
                - name: RCLONE_CONFIG_SELECTEL_AUTH
                  value: "https://auth.selcdn.ru/v1.0"
                - name: RCLONE_CONFIG_SELECTEL_ENDPOINT_TYPE
                  value: "public"
                - name: RCLONE_DEST
                  value: "selectel:my/path/to/backup"
                - name: LOKI_URL
                  value: "http://10.90.100.31:32100/loki/api/v1/push"
                - name: LOKI_APP
                  value: "myspace.backup"
                - name: VACUM
                  value: "true"
              volumeMounts:
                - mountPath: /etc/localtime
                  name: localtime
                  readOnly: true
          restartPolicy: Never
          volumes:
            - hostPath:
                path: /etc/localtime
              name: localtime
```

## Usage docker compose
```yaml
version: '3.7'

services:
  backup-db:
    image: vmpartner/job-postgres-backup-to-cloud:16-v1.3.2
    environment:
      TZ: "Europe/Moscow"
      POSTGRES_DATABASE: "myspace"
      POSTGRES_HOST: "myhost"
      POSTGRES_PORT: "5432"
      POSTGRES_USER: "myspace"
      POSTGRES_PASSWORD: "mypass"
      RCLONE_CONFIG_SELECTEL_TYPE: "swift"
      RCLONE_CONFIG_SELECTEL_ENV_AUTH: "false"
      RCLONE_CONFIG_SELECTEL_USER: "myseluser"
      RCLONE_CONFIG_SELECTEL_KEY: "myselkey"
      RCLONE_CONFIG_SELECTEL_AUTH: "https://auth.selcdn.ru/v1.0"
      RCLONE_CONFIG_SELECTEL_ENDPOINT_TYPE: "public"
      RCLONE_DEST: "selectel:my/path/to/backup"
      VACUM: "true"
    volumes:
      - /etc/localtime:/etc/localtime:ro
    restart: "no"
```

## Add to cron
```bash
0 22 * * * /usr/local/bin/docker-compose -f /path/to/docker-compose.yml up backup-db
```

## Restore
```bash
pg_restore --clean --dbname="my_db" --username="my_user" --no-owner --no-acl -v /dump.sql
```

## Build
```bash
docker build -t vmpartner/job-postgres-backup-to-cloud:16-v1.3.2 . && docker push vmpartner/job-postgres-backup-to-cloud:16-v1.3.2
```

## Contributing
Use branch for postgres version, for example postgres-15 is v15 branch.   
Latest version is also master branch.
```
