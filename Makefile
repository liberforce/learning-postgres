.PHONY: printenv clean init start stop restore psql

# From https://stackoverflow.com/a/18137056/518853
makefile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
this_makefile_dir := $(patsubst %/,%,$(dir $(makefile_path)))

PROJECT_NAME := dvdrental
PGVERSION := 12
PG_BIN_DIR := /usr/lib/postgresql/${PGVERSION}/bin
DATA_DIR := $(this_makefile_dir)/data
LOGFILE := $(this_makefile_dir)/postgres.log
INITDB_CMD := $(PG_BIN_DIR)/initdb
PGCTL_CMD := $(PG_BIN_DIR)/pg_ctl
PG_RESTORE_CMD := $(PG_BIN_DIR)/pg_restore
CREATEDB_CMD := /usr/bin/createdb
DROPDB_CMD := /usr/bin/dropdb
PSQL_CMD := /usr/bin/psql
MAINTENANCE_DB := postgres
MAINTENANCE_USER := postgres

printenv: ## Print environment
	@echo "PROJECT_NAME = $(PROJECT_NAME)"
	@echo "PGVERSION = $(PGVERSION)"
	@echo "PG_BIN_DIR = $(PG_BIN_DIR)"
	@echo "DATA_DIR = $(DATA_DIR)"
	@echo "LOGFILE = $(LOGFILE)"
	@echo "INITDB_CMD = $(INITDB_CMD)"
	@echo "PGCTL_CMD = $(PGCTL_CMD)"
	@echo "PG_RESTORE_CMD = $(PG_RESTORE_CMD)"
	@echo "CREATEDB_CMD = $(CREATEDB_CMD)"
	@echo "DROPDB_CMD = $(DROPDB_CMD)"
	@echo "MAINTENANCE_DB = $(MAINTENANCE_DB)"

clean: ## Cleanup
clean: stop
	rm -rf "${DATA_DIR}" "${LOGFILE}"

init: ## Setup
init: | data

data: # Initialize the database cluster
	mkdir "$(DATA_DIR)"
	"$(INITDB_CMD)" --username "$(MAINTENANCE_USER)" --pgdata "$(DATA_DIR)"

	# Add me to the postgres group to be able to run the server
	# usermod --append --groups postgres "${USER}"

start: ## Start postgres service
start: | data $(DATA_DIR)/postmaster.pid

stop: ## Stop postgres service
stop:
	if test -f "$(DATA_DIR)/postmaster.pid"; then \
		"$(PGCTL_CMD)" --pgdata "$(DATA_DIR)" -l "$(LOGFILE)" stop ; \
	fi

restore: ## Restores the database
restore: start
	# Make sure the db to restore into already exists by the time we call pg_restore
	# because we need it to exist to use the system locales. This avoids a
	# locale error when restoring.
	"$(DROPDB_CMD)" --username "$(MAINTENANCE_USER)" --if-exists "$(PROJECT_NAME)"
	"$(CREATEDB_CMD)" --username "$(MAINTENANCE_USER)" "$(PROJECT_NAME)"

	# Remark: the dbname here is only used to have a db to connect to,
	# to be able to run the actual SQL commands that create or clean the database
	# Any database we know for sure exists will do the trick.
	#
	# WARNING: when --create or --clean are specified, dbname is the name of the
	# maintenance db we connect to. This gives us a connection to clean or create
	# the target database into which we will restore the data.
	# But when these parameters are not specified, the semantics of the dbname
	# param change: it becomes the target database.
	# See https://dba.stackexchange.com/q/82161/63438
	"$(PG_RESTORE_CMD)"                              \
		--username "$(MAINTENANCE_USER)"         \
		--dbname "$(PROJECT_NAME)"               \
		--verbose                                \
		"$(PROJECT_NAME).tar"

$(DATA_DIR)/postmaster.pid:
	"$(PGCTL_CMD)" --pgdata "$(DATA_DIR)" -l "$(LOGFILE)" start

psql: ## Get a psql shell
	"$(PSQL_CMD)" --username "$(MAINTENANCE_USER)" --dbname "$(PROJECT_NAME)"
