#! /bin/sh

set -e

function is_cron_format() {
    local input="$1"
    local cron_regex="^([0-9]|[1-5][0-9]|\*)\s+([0-9]|[01][0-9]|2[0-3]|\*)\s+([1-9]|[12][0-9]|3[01]|\*)\s+([1-9]|1[0-2]|\*)\s+([0-6]|\*)$"
    if [[ "$input" =~ $cron_regex ]]; then
        return 0
    else
        return 1
    fi
}

function to_crontab_format() {
    # Verificar que se reciba un argumento
    if [ -z "$1" ]; then
        echo "Error: No se ha especificado el tiempo de ejecución."
        return 1
    fi

    # Verificar que se reciba una unidad de tiempo válida
    case "$1" in
        *h) ;;
        *d) ;;
        *w) ;;
        *m) ;;
        *) echo "Error: Unidad de tiempo no válida. Utilice h, d, w o m."
           return 1;;
    esac

    # Convertir el tiempo de ejecución a formato crontab
    case "$1" in
        *h) echo "0 */${1%h} * * *";;
        *d) echo "0 0 */${1%d} * *";;
        *w) echo "0 0 * * ${1%w}";;
        *m) echo "0 0 1 */${1%m} *";;
    esac
}

# check postgres version, is set install client
if [ -n "${POSTGRES_VERSION}" ]; then
    # check postgres version, if set install client
    if [ "$POSTGRES_VERSION" -gt "9.5" ]; then
        echo "Installing postgresql${POSTGRES_VERSION}-client"
        # check if postgresql-client already installed
        if apk info | grep -q '^postgresql-client-'; then
            # check if installed version matches POSTGRES_VERSION
            INSTALLED_VERSION=$(apk info postgresql-client | sed 's/^postgresql-client-\([0-9.]*\).*$/\1/')
            if [ "$INSTALLED_VERSION" = "$POSTGRES_VERSION" ]; then
                echo "postgresql-client version $POSTGRES_VERSION already installed."
            else
                echo "Upgrading postgresql-client from $INSTALLED_VERSION to $POSTGRES_VERSION"
                apk upgrade --no-cache "postgresql${POSTGRES_VERSION}-client"
            fi
        else
            apk add --no-cache "postgresql${POSTGRES_VERSION}-client"
        fi
    else
        echo "Using default image postgresql-client"
    fi
else
  echo "POSTGRES_VERSION not set, skipping installation of PostgreSQL client"
fi


if [ -z "${SCHEDULE}" ]; then
  echo "You must set a backup schedule."
  exit 1
fi

# Convertir el formato de tiempo legible por humanos a formato crontab
if is_cron_format "${SCHEDULE}"; then
    cron_schedule="${SCHEDULE}"
else
    cron_schedule="$(to_crontab_format "${SCHEDULE}")"
fi

echo "Performing an immediate backup..."
sh backup.sh # perform an immediate backup

echo "Starting cron with schedule ${cron_schedule}"
echo "${cron_schedule} sh backup.sh >> /dockup.log 2>&1" > /crontab.conf
crontab /crontab.conf
crond -f