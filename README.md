# pg_encode_uri

A small PostgreSQL extension providing RFC 3986 percent-encoding helpers
that mirror JavaScript's `encodeURIComponent()` and `encodeURI()`.

## Functions

### `encode_uri_component(input text, component boolean DEFAULT true) RETURNS text`

Percent-encodes all characters in `input` that are not URI-safe.

- `component = true` (default): equivalent to JavaScript's
  `encodeURIComponent()`. Only the characters
  `A-Z a-z 0-9 - _ . ! ~ * ' ( )` are left unescaped.
- `component = false`: equivalent to JavaScript's `encodeURI()`. In
  addition to the above, the URI reserved characters `; / ? : @ & = + $ , #`
  are also left unescaped.

Percent-encoded hex digits are always uppercase (e.g. `%C3%A9`), matching
JavaScript's behavior.

`NULL` input returns `NULL` (the function is `STRICT`).

### `encode_uri(input text) RETURNS text`

Equivalent to JavaScript's `encodeURI()`. Shorthand for
`encode_uri_component(input, false)`.

## Installation

```sql
CREATE EXTENSION pg_encode_uri;
-- or, to install into a specific schema:
CREATE EXTENSION pg_encode_uri SCHEMA my_schema;
```

The extension is relocatable: `ALTER EXTENSION pg_encode_uri SET SCHEMA other;`
is supported.

## Usage

```sql
SELECT encode_uri_component('a b?é/');  -- 'a%20b%3F%C3%A9%2F'
SELECT encode_uri('a b?é/');            -- 'a%20b?%C3%A9/'
```

## Development / testing

Tests use [pgTAP](https://pgtap.org/) and run inside Docker containers
(one per supported PostgreSQL major version), so no local PostgreSQL
installation is required:

```sh
test/docker-test.sh
```

See [pg_encode_uri.control](pg_encode_uri.control) for the extension
metadata and [sql/pg_encode_uri--1.0.sql](sql/pg_encode_uri--1.0.sql) for
the implementation.

## License

[PostgreSQL License](LICENSE)
