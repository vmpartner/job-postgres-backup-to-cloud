# Backup postgres to cloud

Usage example in k8s CronJob
```yaml
```

Used https://rclone.org for rsync to cloud


## Build
```bash
docker build -t vmpartner/job-postgres-backup-to-cloud:15-v1.2.6 . && \
docker push vmpartner/job-postgres-backup-to-cloud:15-v1.2.6
```