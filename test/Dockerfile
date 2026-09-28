ARG PG_MAJOR=17
FROM postgres:${PG_MAJOR}

ENV PG_MAJOR=${PG_MAJOR}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        make \
        postgresql-server-dev-${PG_MAJOR} \
        postgresql-${PG_MAJOR}-pgtap \
        pgtap \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/pg_encode_uri
COPY . .
RUN make install
