#!/usr/bin/env bash
# ============================================================================
# postgresql_size_all_databases.sh
# Roda postgresql_size_data_vs_index.sql (parte 1) em TODOS os bancos de um
# cluster PostgreSQL, já que cada conexão só enxerga o próprio banco.
# Parte do toolkit dbsize-audit (HTI Tecnologia) — MIT License.
#
# Uso:
#   ./postgresql_size_all_databases.sh -h HOST -U USUARIO
#   (vai pedir a senha interativamente, ou use PGPASSWORD/.pgpass)
# ============================================================================
set -euo pipefail

HOST="localhost"
PORT="5432"
USER_="postgres"

while getopts "h:p:U:" opt; do
  case $opt in
    h) HOST="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    U) USER_="$OPTARG" ;;
    *) echo "Uso: $0 -h HOST -p PORT -U USUARIO" && exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUERY_FILE="$SCRIPT_DIR/postgresql_size_data_vs_index.sql"

DATABASES=$(psql -h "$HOST" -p "$PORT" -U "$USER_" -d postgres -Atc \
  "SELECT datname FROM pg_database WHERE datistemplate = false;")

for db in $DATABASES; do
  echo "== Banco: $db =========================================="
  psql -h "$HOST" -p "$PORT" -U "$USER_" -d "$db" -f "$QUERY_FILE"
  echo
done
