#!/bin/sh

set -euo pipefail

SRC_DIR="${PROJECT_DIR}/Runner/NativeFrameworks"
DST_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

if [ ! -d "${SRC_DIR}" ]; then
  echo "[MUSA] Native frameworks source not found at ${SRC_DIR}"
  exit 1
fi

mkdir -p "${DST_DIR}"

find "${SRC_DIR}" -maxdepth 1 -name '*.dylib' -print0 | while IFS= read -r -d '' src; do
  name="$(basename "${src}")"
  dst="${DST_DIR}/${name}"

  cp -f "${src}" "${dst}"
  xattr -cr "${dst}" || true

  if [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]; then
    codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --timestamp=none "${dst}"
  else
    codesign --force --sign - --timestamp=none "${dst}"
  fi

  echo "[MUSA] Embedded native dylib ${name} -> ${dst}"
done
