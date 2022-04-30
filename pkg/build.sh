#!/bin/sh -eu

init_variables() {
  APP_NAME="backlightd"
  APP_VERSION="0.1.0"

  SOURCE_DIR="$( pwd )"
  STAGE_DIR="$( mktemp -d -t "${APP_NAME}-${APP_VERSION}" )"

  PKG_PREFIX="${STAGE_DIR}/usr/local"
  PKG_ARCHIVE_DIR="${SOURCE_DIR}/pkg/archive"
  PKG_METADATA_DIR="${SOURCE_DIR}/pkg/metadata"
  PKG_FILE_NAME="${APP_NAME}-${APP_VERSION}.pkg"

  SERVICES_SOURCE_DIR="${SOURCE_DIR}/pkg/services"
  SERVICES_DEST_DIR="${PKG_PREFIX}/etc/rc.d"

  APP_SOURCE_PATH="${SOURCE_DIR}/${APP_NAME}"
  APP_DEST_DIR="${STAGE_DIR}/usr/local/bin"
  APP_DEST_PATH="${APP_DEST_DIR}/${APP_NAME}"
}


ensure_directory_structure() {
  mkdir -p "${APP_DEST_DIR}"
  mkdir -p "${SERVICES_DEST_DIR}"
  mkdir -p "${PKG_ARCHIVE_DIR}"
  echo "[ok] Created directory structure in: ${STAGE_DIR}"
}

include_pkg_metadata_files() {
  cp -a "${PKG_METADATA_DIR}/" "${STAGE_DIR}"
  sed -i -e "s/VERSION/${APP_VERSION}/g" "${STAGE_DIR}/+MANIFEST"
  chmod +x ${STAGE_DIR}/+PRE* 2>/dev/null || true
  chmod +x ${STAGE_DIR}/+POST* 2>/dev/null || true
  echo "[ok] Include pkg metadata files"
}

include_rc_services() {
  cp ${SERVICES_SOURCE_DIR}/* "${SERVICES_DEST_DIR}"
  chmod +x ${SERVICES_DEST_DIR}/*
  echo "[ok] Include rc services"
}

include_app_release() {
  cp -a "${APP_SOURCE_PATH}" "${APP_DEST_PATH}"
  chmod +x "${APP_DEST_PATH}"
  echo "[ok] Include ${APP_NAME} release"
}

build_pkg_plist() {
  cd "${STAGE_DIR}" || exit 1
  find "usr" -type f -ls| awk '{print "/" $NF}' >> "${STAGE_DIR}/plist"
  cd "${SOURCE_DIR}" || exit 1
  echo "[ok] Build pkg plist"
}

create_package() {
  echo "[info] Create package: ${PKG_FILE_NAME}"
  pkg create -m "${STAGE_DIR}/" \
             -r "${STAGE_DIR}/" \
             -p "${STAGE_DIR}/plist" \
             -o "${PKG_ARCHIVE_DIR}" 
  echo "[ok] Package created and saved at: ${PKG_ARCHIVE_DIR}/${PKG_FILE_NAME}"
}

# --- Main entry point

init_variables

ensure_directory_structure
include_pkg_metadata_files
include_rc_services
include_app_release
build_pkg_plist
create_package
