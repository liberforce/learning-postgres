.PHONY: printenv clean init start stop

# From https://stackoverflow.com/a/18137056/518853
makefile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
this_makefile_dir := $(patsubst %/,%,$(dir $(makefile_path)))

PGVERSION := 12
PG_BIN_DIR := /usr/lib/postgresql/${PGVERSION}/bin
DATA_DIR := $(this_makefile_dir)/data
LOGFILE := $(this_makefile_dir)/postgres.log
INITDB_CMD := $(PG_BIN_DIR)/initdb
PGCTL_CMD := $(PG_BIN_DIR)/pg_ctl
PGPORT := 5432

printenv: ## Print environment
	@echo "PGVERSION = $(PGVERSION)"
	@echo "PG_BIN_DIR = $(PG_BIN_DIR)"
	@echo "DATA_DIR = $(DATA_DIR)"
	@echo "LOGFILE = $(LOGFILE)"
	@echo "INITDB_CMD = $(INITDB_CMD)"
	@echo "PGCTL_CMD = $(PGCTL_CMD)"

clean: ## Cleanup
	rm -rf "${DATA_DIR}" "${LOGFILE}"

init: ## Setup
	mkdir "$(DATA_DIR)"
	"$(INITDB_CMD)" "$(DATA_DIR)"

	# Add me to the postgres group to be able to run the server
	# usermod --groups postgres luis

start: ## Start postgres service
start: /var/run/postgresql/.s.PGSQL.$(PGPORT)

stop: ## stop postgres service
	"$(PGCTL_CMD)" -D "$(DATA_DIR)" -l "$(LOGFILE)" stop

/var/run/postgresql/.s.PGSQL.$(PGPORT):
	"$(PGCTL_CMD)" -D "$(DATA_DIR)" -l "$(LOGFILE)" start
