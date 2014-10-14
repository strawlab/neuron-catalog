#!/bin/bash
set -o errexit

# (This file is backup-docker-mongo.sh in the neuron-catalog project.)

# This script is meant to be called daily (e.g. with cron). It
# produces a rolling backup with daily backups going back for a week
# and monthly backups going back for a year.

# ultimate backup location -----------
BACKUP_DIR1=/var/lib/neuron-catalog-backups/daily
BACKUP_DIR2=/var/lib/neuron-catalog-backups/monthly
WEEKDAY=$(date +"%A")
MONTH=$(date +"%B")
TARGET1="${BACKUP_DIR1}/neuron-catalog-backup.${WEEKDAY}.tar.gz"
TARGET2="${BACKUP_DIR2}/neuron-catalog-backup.${MONTH}.tar.gz"

mkdir -p ${BACKUP_DIR1}
mkdir -p ${BACKUP_DIR2}

# make temp dir ----------------------
TMPDIR="$(mktemp -d)"

# fill temp dir with output ----------
docker run --rm \
    --link neuron-catalog-db:db \
    -v ${TMPDIR}:/mongo-dump \
    dockerfile/mongodb \
    mongodump --host db --quiet --out /mongo-dump && rc=$? || rc=$?

if [[ ${rc} == 0 ]]; then
    tar czf ${TARGET1} -C ${TMPDIR} .
    cp ${TARGET1} ${TARGET2}
fi
rm -rf ${TMPDIR}

exit ${rc}
