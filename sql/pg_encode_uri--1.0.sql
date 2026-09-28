-- pg_encode_uri--1.0.sql

--------------------------------------------------------------------------
-- encode_uri_component(input, component => true)
--
-- Percent-encodes all characters in `input` that are not URI-safe,
-- mirroring the semantics of JavaScript's encodeURIComponent() (component
-- = true, the default) and encodeURI() (component = false, which leaves
-- the URI reserved characters ; / ? : @ & = + $ , # unescaped).
--
-- Percent-encoded hex digits are always uppercase (e.g. %C3%A9), matching
-- JavaScript's behavior. RFC 3986 treats hex case as insignificant, but
-- uppercase is what JS, and most other implementations, produce.
--------------------------------------------------------------------------
CREATE FUNCTION encode_uri_component(
  input TEXT,
  component BOOLEAN DEFAULT TRUE
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY INVOKER
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
      -- percent-encode the part (uppercase hex digits, matching JS behavior)
      result := result || regexp_replace(upper(encode(convert_to(
        substring(input FROM position FOR length(part)),
          'UTF8'), 'hex')),
        '(..)', '%\1', 'g');
    END IF;
    position := position + length(part);
  END LOOP;
  RETURN result;
END
$$;

COMMENT ON FUNCTION encode_uri_component(TEXT, BOOLEAN) IS
  'Percent-encode a string per RFC 3986, mirroring JavaScript''s encodeURIComponent() (component = true, default) / encodeURI() (component = false). Hex digits are uppercase.';

--------------------------------------------------------------------------
-- encode_uri(input)
--
-- Equivalent to JavaScript's encodeURI(): like encode_uri_component() but
-- leaves URI reserved characters (; / ? : @ & = + $ , #) unescaped.
--------------------------------------------------------------------------
CREATE FUNCTION encode_uri(input TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY INVOKER
STRICT IMMUTABLE
AS $$
BEGIN
  RETURN encode_uri_component(input, FALSE);
END
$$;

COMMENT ON FUNCTION encode_uri(TEXT) IS
  'Percent-encode a string per RFC 3986, mirroring JavaScript''s encodeURI(). Equivalent to encode_uri_component(input, false).';
