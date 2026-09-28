BEGIN;
SELECT plan(8);

SELECT is(
  encode_uri_component('a b', TRUE),
  'a%20b',
  'component=true encodes spaces'
);

SELECT is(
  encode_uri_component('a b', FALSE),
  'a%20b',
  'component=false still encodes spaces'
);

SELECT is(
  encode_uri_component('a/b'),
  'a%2Fb',
  'slash is encoded in component mode'
);

SELECT is(
  encode_uri('a/b'),
  'a/b',
  'encode_uri leaves reserved slash untouched'
);

SELECT is(
  encode_uri_component('a?b=c'),
  'a%3Fb%3Dc',
  'query delimiters are encoded in component mode'
);

SELECT is(
  encode_uri('a?b=c'),
  'a?b=c',
  'encode_uri leaves query string intact'
);

SELECT is(
  encode_uri_component(NULL),
  NULL,
  'NULL input remains NULL'
);

SELECT is(
  encode_uri_component('abc'),
  'abc',
  'safe ASCII passes through unchanged'
);

SELECT * FROM finish();
ROLLBACK;
