#!/usr/bin/env bash
set -euo pipefail

PG_MAJOR="${1:-17}"
IMAGE_NAME="pg_encode_uri:${PG_MAJOR}"
CONTAINER_NAME="pg_encode_uri_test_${PG_MAJOR}"

cd "$(dirname "$0")/.."

cleanup() {
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}

docker build --build-arg PG_MAJOR="${PG_MAJOR}" \
  -t "${IMAGE_NAME}" \
  -f test/Dockerfile \
  .

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

trap cleanup EXIT

docker run -d \
  --name "${CONTAINER_NAME}" \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=postgres \
  "${IMAGE_NAME}" \
  postgres

for _ in $(seq 1 60); do
  if docker exec "${CONTAINER_NAME}" pg_isready -U postgres -h 127.0.0.1 -q; then
    break
  fi
  sleep 1
done

# The image already contains the extension and pgTAP packages; this is the
# single point where the test suite is run against a real DB instance.
docker exec -u postgres -e PGHOST=/var/run/postgresql -e PGUSER=postgres "${CONTAINER_NAME}" bash -lc '
  set -euo pipefail
  export PATH="$(pg_config --bindir):$PATH"
  cd /usr/src/pg_encode_uri
  make installcheck
'
