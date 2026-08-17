#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${1:-open-webui}"

FRONTEND="/app/build/_app/immutable/chunks/BLLL3FN7.js"
BACKEND="/app/backend/open_webui/retrieval/web/utils.py"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Checking container: ${CONTAINER}"
docker inspect "${CONTAINER}" >/dev/null

echo "Restoring validated v0.11.0 originals..."

docker cp \
  "${ROOT_DIR}/frontend/BLLL3FN7.js.original" \
  "${CONTAINER}:${FRONTEND}"

docker cp \
  "${ROOT_DIR}/backend/utils.py.original" \
  "${CONTAINER}:${BACKEND}"

docker exec "${CONTAINER}" python -m py_compile "${BACKEND}"

echo "Restarting ${CONTAINER}..."
docker restart "${CONTAINER}" >/dev/null

echo
echo "Rollback completed."
echo
echo "Frontend SHA-256:"
docker exec "${CONTAINER}" sha256sum "${FRONTEND}"
echo
echo "Backend SHA-256:"
docker exec "${CONTAINER}" sha256sum "${BACKEND}"
