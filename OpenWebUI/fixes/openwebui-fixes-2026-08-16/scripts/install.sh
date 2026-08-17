#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${1:-open-webui}"

FRONTEND="/app/build/_app/immutable/chunks/BLLL3FN7.js"
BACKEND="/app/backend/open_webui/retrieval/web/utils.py"

EXPECTED_FRONTEND="f6709c7213d4f59bd38045ba8c6bdac635f08bde6695ded41bd836fed9068dd0"
EXPECTED_BACKEND="fdf1eb27cac01f5f35a14dc93a2abd9ce7d857ebab8fdff87b66e206d6d0814f"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Checking container: ${CONTAINER}"

docker inspect "${CONTAINER}" >/dev/null

frontend_hash="$(
  docker exec "${CONTAINER}" sha256sum "${FRONTEND}" | awk '{print $1}'
)"

backend_hash="$(
  docker exec "${CONTAINER}" sha256sum "${BACKEND}" | awk '{print $1}'
)"

echo "Current frontend SHA-256: ${frontend_hash}"
echo "Current backend  SHA-256: ${backend_hash}"

if [[ "${frontend_hash}" != "${EXPECTED_FRONTEND}" ]]; then
  echo "ERROR: Frontend file does not match the validated v0.11.0 original."
  echo "Refusing to overwrite."
  exit 1
fi

if [[ "${backend_hash}" != "${EXPECTED_BACKEND}" ]]; then
  echo "ERROR: Backend file does not match the validated v0.11.0 original."
  echo "Refusing to overwrite."
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"

docker exec "${CONTAINER}" cp \
  "${FRONTEND}" \
  "${FRONTEND}.pre-openwebui-fix-${STAMP}"

docker exec "${CONTAINER}" cp \
  "${BACKEND}" \
  "${BACKEND}.pre-openwebui-fix-${STAMP}"

docker cp \
  "${ROOT_DIR}/frontend/BLLL3FN7.js.patched" \
  "${CONTAINER}:${FRONTEND}"

docker cp \
  "${ROOT_DIR}/backend/utils.py.patched" \
  "${CONTAINER}:${BACKEND}"

docker exec "${CONTAINER}" python -m py_compile "${BACKEND}"

echo "Restarting ${CONTAINER}..."
docker restart "${CONTAINER}" >/dev/null

echo
echo "Patch installed successfully."
echo "Backup suffix: pre-openwebui-fix-${STAMP}"
echo
echo "Post-install frontend SHA-256:"
docker exec "${CONTAINER}" sha256sum "${FRONTEND}"
echo
echo "Post-install backend SHA-256:"
docker exec "${CONTAINER}" sha256sum "${BACKEND}"
