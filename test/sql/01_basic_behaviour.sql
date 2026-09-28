BEGIN;
SELECT plan(56);

SELECT is(
  encode_uri(''),
  '',
  'encode_uri preserves empty input'
);
SELECT is(
  encode_uri_component(''),
  '',
  'encode_uri_component preserves empty input'
);

SELECT is(
  encode_uri(' '),
  '%20',
  'encode_uri encodes space'
);
SELECT is(
  encode_uri_component(' '),
  '%20',
  'encode_uri_component encodes space'
);

SELECT is(
  encode_uri('%'),
  '%25',
  'encode_uri escapes percent sign'
);
SELECT is(
  encode_uri_component('%'),
  '%25',
  'encode_uri_component escapes percent sign'
);

SELECT is(
  encode_uri('-'),
  '-',
  'encode_uri leaves hyphen raw'
);
SELECT is(
  encode_uri_component('-'),
  '-',
  'encode_uri_component leaves hyphen raw'
);

SELECT is(
  encode_uri('_'),
  '_',
  'encode_uri leaves underscore raw'
);
SELECT is(
  encode_uri_component('_'),
  '_',
  'encode_uri_component leaves underscore raw'
);

SELECT is(
  encode_uri('.'),
  '.',
  'encode_uri leaves period raw'
);
SELECT is(
  encode_uri_component('.'),
  '.',
  'encode_uri_component leaves period raw'
);

SELECT is(
  encode_uri('!'),
  '!',
  'encode_uri leaves exclamation raw'
);
SELECT is(
  encode_uri_component('!'),
  '!',
  'encode_uri_component leaves exclamation raw'
);

SELECT is(
  encode_uri('+'),
  '+',
  'encode_uri leaves plus raw'
);
SELECT is(
  encode_uri_component('+'),
  '%2B',
  'encode_uri_component encodes plus'
);

SELECT is(
  encode_uri(','),
  ',',
  'encode_uri leaves comma raw'
);
SELECT is(
  encode_uri_component(','),
  '%2C',
  'encode_uri_component encodes comma'
);

SELECT is(
  encode_uri(';'),
  ';',
  'encode_uri leaves semicolon raw'
);
SELECT is(
  encode_uri_component(';'),
  '%3B',
  'encode_uri_component encodes semicolon'
);

SELECT is(
  encode_uri(':'),
  ':',
  'encode_uri leaves colon raw'
);
SELECT is(
  encode_uri_component(':'),
  '%3A',
  'encode_uri_component encodes colon'
);

SELECT is(
  encode_uri('@'),
  '@',
  'encode_uri leaves at-sign raw'
);
SELECT is(
  encode_uri_component('@'),
  '%40',
  'encode_uri_component encodes at-sign'
);

SELECT is(
  encode_uri('&'),
  '&',
  'encode_uri leaves ampersand raw'
);
SELECT is(
  encode_uri_component('&'),
  '%26',
  'encode_uri_component encodes ampersand'
);

SELECT is(
  encode_uri('='),
  '=',
  'encode_uri leaves equals raw'
);
SELECT is(
  encode_uri_component('='),
  '%3D',
  'encode_uri_component encodes equals'
);

SELECT is(
  encode_uri('$'),
  '$',
  'encode_uri leaves dollar raw'
);
SELECT is(
  encode_uri_component('$'),
  '%24',
  'encode_uri_component encodes dollar'
);

SELECT is(
  encode_uri('('),
  '(',
  'encode_uri leaves left paren raw'
);
SELECT is(
  encode_uri_component('('),
  '(',
  'encode_uri_component leaves left paren raw'
);

SELECT is(
  encode_uri(')'),
  ')',
  'encode_uri leaves right paren raw'
);
SELECT is(
  encode_uri_component(')'),
  ')',
  'encode_uri_component leaves right paren raw'
);

SELECT is(
  encode_uri('*'),
  '*',
  'encode_uri leaves asterisk raw'
);
SELECT is(
  encode_uri_component('*'),
  '*',
  'encode_uri_component leaves asterisk raw'
);

SELECT is(
  encode_uri(''''),
  '''',
  'encode_uri leaves apostrophe raw'
);
SELECT is(
  encode_uri_component(''''),
  '''',
  'encode_uri_component leaves apostrophe raw'
);

SELECT is(
  encode_uri('/'),
  '/',
  'encode_uri leaves slash raw'
);
SELECT is(
  encode_uri_component('/'),
  '%2F',
  'encode_uri_component encodes slash'
);

SELECT is(
  encode_uri('?'),
  '?',
  'encode_uri leaves question mark raw'
);
SELECT is(
  encode_uri_component('?'),
  '%3F',
  'encode_uri_component encodes question mark'
);

SELECT is(
  encode_uri('#'),
  '#',
  'encode_uri leaves hash raw'
);
SELECT is(
  encode_uri_component('#'),
  '%23',
  'encode_uri_component encodes hash'
);

SELECT is(
  encode_uri('a/b?c#d'),
  'a/b?c#d',
  'encode_uri leaves reserved URI characters raw'
);
SELECT is(
  encode_uri_component('a/b?c#d'),
  'a%2Fb%3Fc%23d',
  'encode_uri_component encodes reserved URI characters'
);

SELECT is(
  encode_uri('a~b'),
  'a~b',
  'encode_uri leaves tilde raw'
);
SELECT is(
  encode_uri_component('a~b'),
  'a~b',
  'encode_uri_component leaves tilde raw'
);

SELECT is(
  encode_uri('abc def'),
  'abc%20def',
  'encode_uri encodes spaces in plain text'
);
SELECT is(
  encode_uri_component('abc def'),
  'abc%20def',
  'encode_uri_component encodes spaces in plain text'
);

SELECT is(
  encode_uri('é'),
  '%C3%A9',
  'encode_uri encodes UTF-8 text'
);
SELECT is(
  encode_uri_component('é'),
  '%C3%A9',
  'encode_uri_component encodes UTF-8 text'
);

SELECT is(
  encode_uri('😀'),
  '%F0%9F%98%80',
  'encode_uri encodes emoji as UTF-8 bytes'
);
SELECT is(
  encode_uri_component('😀'),
  '%F0%9F%98%80',
  'encode_uri_component encodes emoji as UTF-8 bytes'
);

SELECT is(
  encode_uri(NULL),
  NULL,
  'encode_uri preserves NULL'
);
SELECT is(
  encode_uri_component(NULL),
  NULL,
  'encode_uri_component preserves NULL'
);

SELECT * FROM finish();
ROLLBACK;
