EXTENSION = pg_encode_uri
DATA = sql/pg_encode_uri--1.0.sql
PGFILEDESC = "pg_encode_uri - RFC 3986 percent-encoding helpers (encodeURIComponent/encodeURI equivalents)"

# pgTAP test suite, run via pg_prove against a running server (see
# test/docker-test.sh for the containerized local/CI harness).
TEST_SQL = $(wildcard test/sql/*.sql)
TESTDB = pg_encode_uri_test
PGUSER ?= postgres
PGHOST ?= /var/run/postgresql

PG_CONFIG = pg_config
PG_BINDIR := $(shell $(PG_CONFIG) --bindir)
PG_PROVE ?= $(shell command -v pg_prove 2>/dev/null || echo $(PG_BINDIR)/pg_prove)
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

.PHONY: installcheck
installcheck:
	dropdb --if-exists --username=$(PGUSER) $(TESTDB)
	createdb --username=$(PGUSER) $(TESTDB)
	psql -v ON_ERROR_STOP=1 -h $(PGHOST) -U $(PGUSER) -d $(TESTDB) -c 'CREATE EXTENSION pgtap;'
	psql -v ON_ERROR_STOP=1 -h $(PGHOST) -U $(PGUSER) -d $(TESTDB) -c 'CREATE EXTENSION pg_encode_uri;'
	$(PG_PROVE) -h $(PGHOST) -U $(PGUSER) -d $(TESTDB) $(TEST_SQL)
