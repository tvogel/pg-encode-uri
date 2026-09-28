# Plan: Package URI-encoding functions as a PostgreSQL extension

## Original source (as provided by user; not saved elsewhere in the repo — kept here for provenance)
```plpgsql
CREATE OR REPLACE FUNCTION app.encodeURIComponent(
  input TEXT,
  component BOOLEAN = TRUE)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO ''
STRICT IMMUTABLE
AS $$
DECLARE
  safe_pattern TEXT := CASE WHEN component
    THEN '[^-A-Za-z0-9_.!~*''()]'
    ELSE '[^-A-Za-z0-9_.!~*''();/?:@&=+$,#]'
  END;
  part text;
  result text := '';
  position int := 1;
BEGIN
  -- Split the input into plain and encoded parts:
  --   First replace all non-URI-safe characters with '^' and then delimit
  --   consecutive stretches with '`' (both those markers are encoded anyway and
  --   do not clash with the URI-safe characters)
  FOREACH part IN ARRAY regexp_split_to_array(
    regexp_replace(
      regexp_replace(input, safe_pattern, '^', 'g'),
      '(\^+)', '`\1`', 'g'),
    '`'
  ) LOOP
    IF left(part, 1) <> '^' THEN
      result := result || part;
    ELSE
      -- percent-encode the part
      result := result || regexp_replace(encode(convert_to(
        substring(input FROM position FOR length(part)),
          'UTF8'), 'hex'),
        '(..)', '%\1', 'g');
    END IF;
    position := position + length(part);
  END LOOP;
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION app.encodeURI(input TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO ''
STRICT IMMUTABLE
AS $$
BEGIN
  RETURN app.encodeURIComponent(input, FALSE);
END $$;
```

## Decisions (confirmed with user)
- Extension name: `pg_encode_uri` (repo already named pg-encode-uri)
- Function names: rename to snake_case `encode_uri_component` / `encode_uri` (drop camelCase, no quoting needed to call)
- Schema: relocatable extension using `@extschema@` substitution (no fixed schema hardcoded; user picks schema via `CREATE EXTENSION pg_encode_uri SCHEMA ...`, default public)
- Test framework: pgTAP
- License: PostgreSQL License
- CI: GitHub Actions, yes
- PGXN packaging: include META.json
- Supported/tested PG versions: 13-18 (note: 13 nearing/at EOL upstream as of 2026, but included per user request)
- Bug fix: percent-encoded hex digits must be UPPERCASE to match JS `encodeURIComponent`/`encodeURI` (wrap `encode(...,'hex')` result in `upper()`). Current code produces lowercase; RFC 3986 allows either case but JS always uses uppercase.

## File layout (all at repo root)
- `pg_encode_uri.control` — comment, default_version = '1.0', relocatable = true (no `schema` param since relocatable)
- `Makefile` — PGXS-based; `EXTENSION = pg_encode_uri`; `DATA = sql/pg_encode_uri--1.0.sql`; REGRESS/TESTS wired to `test/sql/*.sql` (pgTAP tests run via pg_regress-style `make installcheck`, expected output = captured TAP text, OR via `pg_prove` custom target — decide exact wiring during implementation, prefer whichever integrates cleanest with `make installcheck`). No C code/MODULES, so `make`'s `all` target is a no-op; PGXS is only needed for `make install`/`make installcheck` plumbing.
- `test/Dockerfile` — parameterized by `ARG PG_MAJOR`; `FROM postgres:${PG_MAJOR}`; installs `postgresql-server-dev-${PG_MAJOR}` (for `pg_config`/PGXS, no compiler needed) + `postgresql-${PG_MAJOR}-pgtap`; `COPY . .` + `RUN make install` bakes the extension into the image
- `test/docker-test.sh` — loops over PG_MAJOR 13-18: `docker build --build-arg PG_MAJOR=$v -f test/Dockerfile .`, then `docker run --rm` starting the standard postgres entrypoint in the background, waiting for `pg_isready`, then running `make installcheck` inside the container. Used both for local dev loop and CI (single source of truth).
- `sql/pg_encode_uri--1.0.sql` — versioned install script:
  - `CREATE FUNCTION encode_uri_component(input TEXT, component BOOLEAN DEFAULT TRUE) RETURNS TEXT ... SECURITY INVOKER SET search_path TO '' STRICT IMMUTABLE` — same algorithm as original `app.encodeURIComponent`, but wrap hex encode step in `upper()`
  - `CREATE FUNCTION encode_uri(input TEXT) RETURNS TEXT ...` — body calls `@extschema@.encode_uri_component(input, FALSE)` (must use `@extschema@` qualification since function itself runs with empty search_path)
  - Leading guard: `\echo Use "CREATE EXTENSION pg_encode_uri" to load this file. \quit`
  - `COMMENT ON FUNCTION` for both, documenting behavior/RFC 3986 reference
- `test/sql/*.sql` — pgTAP test suite (see cases below)
- `META.json` — PGXN metadata: name, version 1.0.0, abstract, maintainer (placeholder to fill in), license "PostgreSQL", provides.pg_encode_uri.file/version, prereqs.runtime (none beyond core), prereqs.test.requires.pgTAP, resources.repository
- `LICENSE` — PostgreSQL License text
- `README.md` — install instructions (`CREATE EXTENSION pg_encode_uri;`), usage examples, behavior notes (RFC 3986, uppercase hex, relocatable schema)
- `.github/workflows/ci.yml` — matrix job per PG major version (13,14,15,16,17,18); each job runs `docker build --build-arg PG_MAJOR=<ver> -f test/Dockerfile .` then `docker run --rm ...` (same commands as `test/docker-test.sh`, or just invokes that script with a single version); fail job on any TAP failure. No PGDG apt setup on the runner itself — Docker gives a hermetic, reproducible environment identical to local testing.

## Steps
1. **Scaffolding** (no dependencies): write `pg_encode_uri.control`, `Makefile`, `sql/pg_encode_uri--1.0.sql` (renamed functions, `@extschema@` cross-call, uppercase hex fix), `LICENSE`, `README.md`.
2. **Test design** (*depends on 1*): write pgTAP test files under `test/sql/`:
   - `01_ascii_and_reserved.sql`: unreserved chars pass through unchanged for both modes; reserved chars (`;/?:@&=+$,#`) get percent-encoded in `component=TRUE`/`encode_uri_component` default, left raw in `encode_uri`/`component=FALSE`
   - `02_percent_encoding_case.sql`: assert uppercase hex digits (e.g. space -> `%20`, `é` (UTF-8 C3 A9) -> `%C3%A9`)
   - `03_unicode_multibyte.sql`: multi-byte UTF-8 (accented Latin, CJK, emoji/non-BMP) match Node's `encodeURIComponent`/`encodeURI` reference outputs char-for-char
   - `04_edge_cases.sql`: empty string -> empty string; NULL input -> NULL (STRICT); string entirely safe chars (no percent-encoding, single-part loop); string entirely unsafe chars; unsafe run at start/end of string; apostrophe `'` and parens `()` remain unescaped (they're in the "always safe" set); backtick/caret in input handled correctly (internal delimiter chars, must not leak into output or break splitting)
   - `05_default_and_delegation.sql`: `encode_uri_component(x)` defaults to `component=TRUE`; `encode_uri(x)` behaves identically to `encode_uri_component(x, FALSE)` for representative inputs
   - `06_relocatable_schema.sql`: install extension into a non-default schema in a scratch DB/session and confirm `encode_uri()`'s internal call to `encode_uri_component` still resolves (validates `@extschema@` substitution)
3. **PGXN metadata** (*parallel with 2*): write `META.json`.
4. **Docker test harness** (*depends on 1, 2*): write `test/Dockerfile` and `test/docker-test.sh` (loop over PG_MAJOR 13-18, build + run + `make installcheck` per version, no host Postgres install required).
5. **CI workflow** (*depends on 4*): write `.github/workflows/ci.yml` as a matrix over PG_MAJOR that reuses `test/Dockerfile`/`test/docker-test.sh` for each job — same commands locally and in CI.
6. **Local verification** (*depends on 1-5*): run `test/docker-test.sh` (or a single version via `docker build`/`docker run`) locally; cross-check a handful of outputs against Node's `encodeURIComponent`/`encodeURI` manually.

## Relevant files
- `pg_encode_uri.control` (new)
- `Makefile` (new)
- `sql/pg_encode_uri--1.0.sql` (new) — reuses algorithm from user-provided `app.encodeURIComponent`/`app.encodeURI`, renamed + uppercase-hex fix + `@extschema@`
- `test/sql/*.sql` (new, pgTAP)
- `META.json` (new)
- `LICENSE`, `README.md` (new)
- `test/Dockerfile`, `test/docker-test.sh` (new)
- `.github/workflows/ci.yml` (new)

## Verification
1. `test/docker-test.sh` passes all pgTAP assertions locally for every PG major version (13-18), with no host Postgres install required.
2. GitHub Actions CI green across PG 13-18 matrix (same Dockerfile/script as local).
3. Manual spot-check: `SELECT encode_uri_component('a b?é/'), encode_uri('a b?é/');` compared against Node `encodeURIComponent`/`encodeURI` on same input.
4. Confirm `CREATE EXTENSION pg_encode_uri SCHEMA custom_schema;` works and both functions are usable/relocatable (`ALTER EXTENSION pg_encode_uri SET SCHEMA other;`).

## Explicitly out of scope
- No changes to the core percent-encoding algorithm structure itself (only the uppercase-hex fix agreed above).
- No multi-version upgrade scripts (only a single `--1.0.sql`; future `--1.0--1.1.sql` etc. left for later).
- No packaging beyond PGXS + PGXN META.json (no .deb/.rpm build scripts).
