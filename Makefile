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

printenv: ## Print environment
	@echo "PGVERSION = $(PGVERSION)"
	@echo "PG_BIN_DIR = $(PG_BIN_DIR)"
	@echo "DATA_DIR = $(DATA_DIR)"
	@echo "LOGFILE = $(LOGFILE)"
	@echo "INITDB_CMD = $(INITDB_CMD)"
	@echo "PGCTL_CMD = $(PGCTL_CMD)"

clean: ## Cleanup
clean: stop
	rm -rf "${DATA_DIR}" "${LOGFILE}"

init: ## Setup
init: | data

data: # Initialize the database cluster
	mkdir "$(DATA_DIR)"
	"$(INITDB_CMD)" --pgdata "$(DATA_DIR)"

	# Add me to the postgres group to be able to run the server
	# usermod --append --groups postgres "${USER}"

start: ## Start postgres service
start: | data $(DATA_DIR)/postmaster.pid

stop: ## Stop postgres service
stop:
	if test -f "$(DATA_DIR)/postmaster.pid"; then \
		"$(PGCTL_CMD)" --pgdata "$(DATA_DIR)" -l "$(LOGFILE)" stop ; \
	fi

$(DATA_DIR)/postmaster.pid:
	"$(PGCTL_CMD)" --pgdata "$(DATA_DIR)" -l "$(LOGFILE)" start
