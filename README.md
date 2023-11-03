# Backup postgres to cloud

Used https://rclone.org for rsync to cloud

## Restore
```bash
pg_restore --clean --dbname="atlassian" --username="atlassian" --no-owner --no-acl -v /dump.sql
```


## Build
```bash
docker build -t vmpartner/job-postgres-backup-to-cloud:15-v1.2.6 . && docker push vmpartner/job-postgres-backup-to-cloud:15-v1.2.6
```