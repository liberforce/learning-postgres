#! /bin/bash

THIS_SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

PGVERSION=12
PG_BIN_DIR=/usr/lib/postgresql/${PGVERSION}/bin
INITDB_CMD=${PG_BIN_DIR}/initdb
PGCTL_CMD=${PG_BIN_DIR}/pg_ctl
DATA_DIR=${THIS_SCRIPT_DIR}/data
LOGFILE=${THIS_SCRIPT_DIR}/postgres.log

# Cleanup
rm -rf "${DATA_DIR}" "${LOGFILE}"

# Setup
mkdir "${DATA_DIR}"
${INITDB_CMD} "${DATA_DIR}"

# Add me to the postgres group to be able to run the server
# usermod --groups postgres luis

${PGCTL_CMD} -D "${DATA_DIR}" -l "${LOGFILE}" start
sleep 5
${PGCTL_CMD} -D "${DATA_DIR}" -l "${LOGFILE}" stop
