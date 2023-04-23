#! /bin/sh

set -e
set -o pipefail

# Environment checks
check_env_variable() {
  if [ "${!1}" = "**None**" ]; then
    echo "You need to set the $1 environment variable."
    exit 1
  fi
}

check_env_variable "POSTGRES_DATABASE"
check_env_variable "POSTGRES_USER"
check_env_variable "POSTGRES_PASSWORD"
check_env_variable "GCLOUD_KEYFILE_BASE64"
check_env_variable "GCLOUD_PROJECT_ID"
check_env_variable "GCS_BACKUP_BUCKET"

# Set default values
: ${POSTGRES_PORT:=5432}
: ${POSTGRES_HOST:=${POSTGRES_PORT_5432_TCP_ADDR:-}}

# Google Cloud Auth
echo "Authenticating to Google Cloud"
echo "$GCLOUD_KEYFILE_BASE64" | base64 -d > /key.json
gcloud auth activate-service-account --key-file /key.json --project "$GCLOUD_PROJECT_ID" -q

# Postgres dumping
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
FILE_PREFIX="${POSTGRES_DATABASE}_backup"
FILENAME="${FILE_PREFIX}_${DATE}.dump"
export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"

echo "Uploading pg_dump to $GCS_BACKUP_BUCKET"
pg_dump $POSTGRES_HOST_OPTS -Fc $POSTGRES_DATABASE | gsutil cp - $GCS_BACKUP_BUCKET/$FILENAME
echo "SQL backup uploaded successfully"

# Delete old backups if BACKUP_RETENTION_DAYS is set
if [ "$BACKUP_RETENTION_DAYS" -gt 0 ]; then
  echo "Deleting backups older than $BACKUP_RETENTION_DAYS days"
  gsutil ls -l $GCS_BACKUP_BUCKET/$FILE_PREFIX*.dump | sort -k2 | awk -v BACKUP_RETENTION_DAYS=$BACKUP_RETENTION_DAYS -v prefix=$FILE_PREFIX '{ if (NR > BACKUP_RETENTION_DAYS) { print $3 } }' | xargs -I {} gsutil rm {}
fi

# Delete old backups if BACKUP_RETENTION_COUNT is set
if [ "$BACKUP_RETENTION_COUNT" -gt 0 ]; then
  echo "Deleting backups older than $BACKUP_RETENTION_COUNT newest backups"
  gsutil ls -l $GCS_BACKUP_BUCKET/$FILE_PREFIX*.dump | sort -k2 | awk -v BACKUP_RETENTION_COUNT=$BACKUP_RETENTION_COUNT -v prefix=$FILE_PREFIX '{ if (NR > BACKUP_RETENTION_COUNT) { print $3 } }' | xargs -I {} gsutil rm {}
fi

echo "Backup completed"