# Backup Postgres Docker containers to Google Cloud Storage

Inspired by postgres-backup-s3 and based on the work of [Nullpixel](https://github.com/Nullpixel1/postgres-docker-gcs-backup).

This docker image allows for scheduled backups of a postgres docker container to a Google Cloud Storage bucket.

## Features

-   Backs up a postgres database to a Google Cloud Storage bucket.
-   Backups are compressed using gzip.
-   Backups are encrypted using AES-256. (Password is set in the environment variable `ENCRYPTION_PASSWORD`, function is disabled for now)
-   Backups are scheduled using cron.
-   Backups are versioned using a timestamp.
-   Backups are automatically deleted after a set number of days.
-   Backups are automatically deleted after a set number of backups.
-   works with postgres 9.5+ (Change version in `POSTGRES_VERSION` environment variable)




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
| `ENCRYPTION_PASSWORD`   | The password to use for encrypting the backup. **Default:** `''`                                                |
| `BACKUP_RETENTION_DAYS` | The number of days to keep backups for. **Default:** `''`                                                        |
| `BACKUP_RETENTION_COUNT`| The number of backups to keep. **Default:** `''`                                                                 |
| `POSTGRES_VERSION`      | The version of postgres to use. **Default:** `15`                                                             |

## Scheduling

The `SCHEDULE` environment variable is used to determine how often the backup should occur. It uses the [cron](https://en.wikipedia.org/wiki/Cron) format.
Additionally, you can use the basic inline format (@every number[h, d, w, m, y]) to specify the schedule. For example, `@every 6h` will run the backup every 6 hours.

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
        BACKUP_RETENTION_DAYS: "7"
        BACKUP_RETENTION_COUNT: "10"
        POSTGRES_VERSION: "15"
        ENCRYPTION_PASSWORD: "password"
```

Note: the internet network exists as api-internal is an internal network with no connection to the internet. To enable backing up to the cloud, the service has to be on an external network which can access the internet. api-internal is the network which the database is on, so that the database hostname resolves to that service.