#!/bin/bash
set -o errexit

TARBALL_TO_RESTORE=$1

if [ -z "${TARBALL_TO_RESTORE}" ]; then
  echo "No tarball to restore was specified." 1>&2
  exit 1
fi

if [ ! -f "${TARBALL_TO_RESTORE}" ]; then
  echo "The tarball to restore (\"${TARBALL_TO_RESTORE}\") was not found." 1>&2
  exit 1
fi

# make temp dir ----------------------
TMPDIR="$(mktemp -d)"

# Extract tarball into temp dir
cd ${TMPDIR}
tar xzf ${TARBALL_TO_RESTORE}

# fill temp dir with output ----------
docker run --rm \
    --link neuron-catalog-db:db \
    -v ${TMPDIR}:/mongo-dump \
    dockerfile/mongodb \
    mongorestore --host db /mongo-dump && rc=$? || rc=$?

rm -rf ${TMPDIR}

exit ${rc}
