FROM google/cloud-sdk:alpine

# Networking?
RUN cat /etc/resolv.conf

# Install deps
ADD setup.sh setup.sh
RUN sh setup.sh && rm setup.sh

# Postgres Environment
ENV POSTGRES_DATABASE ''
ENV POSTGRES_HOST ''
ENV POSTGRES_PORT 5432
ENV POSTGRES_USER ''
ENV POSTGRES_PASSWORD ''
ENV POSTGRES_EXTRA_OPTS ''

# GCS Environment
ENV GCLOUD_KEYFILE_BASE64 ''
ENV GCLOUD_PROJECT_ID ''
ENV GCS_BACKUP_BUCKET ''

# Backup options
ENV SCHEDULE '1d'
ENV BACKUP_RETENTION_DAYS ''
ENV BACKUP_RETENTION_COUNT ''


ADD run.sh run.sh
ADD backup.sh backup.sh

CMD ["sh", "run.sh"]
