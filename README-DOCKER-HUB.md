# Backup Postgres Docker containers to Google Cloud Storage

Inspired by postgres-backup-s3 and based on the work of [Nullpixel](postgres-docker-gcs-backup).

This docker image allows for scheduled backups of a postgres docker container to a Google Cloud Storage bucket.

## Features

-   Backs up a postgres database to a Google Cloud Storage bucket.
-   Backups are compressed using gzip.
-   Backups are encrypted using AES-256.
-   Backups are scheduled using cron.
-   Backups are versioned using a timestamp.
-   Backups are automatically deleted after a set number of days.
-   Backups are automatically deleted after a set number of backups.
-   Backups are automatically deleted after a set number of backups per day.
-   works with postgres 15 (tested) - [change pg_dump version at](/setup.sh#L10) `setup.sh`




## Usage

This image is published on the docker hub.

### Environment variables
| Variable                | Description                                                                                                    |
|-------------------------|----------------------------------------------------------------------------------------------------------------|
| `POSTGRES_DATABASE`     | The name of the database to backup.                                                                            |
| `POSTGRES_HOST`         | The host of the database to backup.                                                                            |
| `POSTGRES_PORT`         | The port of the database to backup.  **Default:** 5432                                                         |
| `POSTGRES_USER`         | The username of the backup user.                                                                               |
| `POSTGRES_PASSWORD`     | The password of the backup user.                                                                               |
| `POSTGRES_EXTRA_OPTS`   | Any additional options you wish to pass to `pg_dump`. **Default:** `''`                                        |
| `GCLOUD_KEYFILE_BASE64` | The GCP service account's credential file, in base64. See below for recommendations regarding this.            |
| `GCLOUD_PROJECT_ID`     | The Project ID which the bucket you wish to backup to is in.                                                   |
| `GCS_BACKUP_BUCKET`     | The gs:// path to the storage bucket you wish to backup to.                                                    |
| `SCHEDULE`              | How often you wish the backup to occur. See [Scheduling](#scheduling) for more information on formatting this. |

## Scheduling

More information on the schedule format can be found [here](https://golang.org/pkg/time/#ParseDuration).

## Google Cloud Service Account

We recommend creating a new, write-only service account to the storage bucket you wish to backup to (with the `storage.objects.list` and `storage.objects.create` permissions).

## Docker Compose

Below is a sample Docker Compose service.

<!-- create yaml -->
```yaml
dbbackups:
    image: "linuxer41/automate-postgres-backup:latest"
    depends_on:
      - database
    networks:
      - internet
      - api-internal
    environment:
      SCHEDULE: "@every 6h"
      POSTGRES_HOST: "database"
      POSTGRES_DATABASE: "SomeDatabase"
      POSTGRES_USER: "postgres"
      POSTGRES_PASSWORD: "postgres"
      GCLOUD_KEYFILE_BASE64: "BASE64_PROJECT_KEYFILE_HERE"
      GCLOUD_PROJECT_ID: "hello-world"
      GCS_BACKUP_BUCKET: "gs://my-backup-bucket-name"
```

Note: the internet network exists as api-internal is an internal network with no connection to the internet. To enable backing up to the cloud, the service has to be on an external network which can access the internet. api-internal is the network which the database is on, so that the database hostname resolves to that service.