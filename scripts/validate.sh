#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v docker >/dev/null 2>&1; then
  printf '%s\n' 'Docker is required to validate the Compose configuration.' >&2
  exit 1
fi

docker compose -f Setup/docker-compose.yml config --quiet
git diff --check

required_files=(
  '.env.example'
  'Setup/docker-compose.yml'
  'PostgreSQL/Scripts/dw_schema_C22466756.sql'
  'PostgreSQL/Scripts/dw_etl_C22466756.sql'
  'PostgreSQL/Scripts/Partitioning_C22466756.sql'
  'PostgreSQL/Scripts/Partitioning_Queries_C22466756.sql'
  'Cassandra/Scripts/cassandra_C22466756.cql'
  'CouchDB/Scripts & JSON/couchdb_partitioning_C22466756.txt'
  'CouchDB/Scripts & JSON/couchdb_replication_C22466756.txt'
)

for file in "${required_files[@]}"; do
  if [[ ! -s "$file" ]]; then
    printf 'Missing or empty required file: %s\n' "$file" >&2
    exit 1
  fi
done

printf '%s\n' 'Phase 3 repository validation passed.'
