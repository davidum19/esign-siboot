#!/bin/sh
# E-Sign installer launcher for Open Minis
# Downloads the official AppleJR installer and verifies every artifact before execution.
set -eu
umask 077

VERSION="0.2.2"
BUILD="24"
ARCH="aarch64"

BASE_URL="https://applejr.net/sideload/downloads/e-sign-0.2.2-build24-aarch64-34c8b03d3975.bin"
SHA256_RAW="34c8b03d3975827d1fa62f265dade8e61ba6e435535a039cec7b69fe2d4a5302"
SHA256_XZ="731f876557fc415605341ffeafb4e0472260c72e4be25879cde3d34c130557fc"
SHA256_GZIP="a9d533e62cbeb9721c7002b68a27cc10701f44b6236b9051ac089a619bed6800"

MODE="${1:-install}"
case "$MODE" in
  install|check|pair|developer-mode|sign-out) ;;
  -h|--help|help)
    cat <<'USAGE'
E-Sign installer launcher for Open Minis

Usage:
  ./install.sh [install|check|pair|developer-mode|sign-out]

Commands are forwarded to the official AppleJR E-Sign installer.
The default command is: install
USAGE
    exit 0
    ;;
  *)
    echo "Error: unsupported command: $MODE" >&2
    echo "Use: install, check, pair, developer-mode, or sign-out" >&2
    exit 2
    ;;
esac

fail() {
  echo "Error: $*" >&2
  exit 1
}

[ "$(uname -s)" = "Linux" ] || fail "This installer requires Linux."
MACHINE="$(uname -m)"
case "$MACHINE" in
  aarch64|arm64) ;;
  *) fail "Unsupported architecture: $MACHINE (ARM64 is required)." ;;
esac

for tool in minis-bonjour minis-open sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || fail "Required command not found: $tool"
done

if command -v curl >/dev/null 2>&1; then
  DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
  DOWNLOADER="wget"
else
  fail "Install curl or wget in Open Minis, then try again."
fi

HOME_DIR="${HOME:?HOME is not set}"
INSTALL_DIR="$HOME_DIR/.e-sign/bin"
BINARY="$INSTALL_DIR/e-sign-installer"
TMP_DIR="$INSTALL_DIR/.download"
mkdir -p "$INSTALL_DIR" "$TMP_DIR"

download() {
  url="$1"
  destination="$2"
  attempt=1
  while [ "$attempt" -le 3 ]; do
    if [ "$DOWNLOADER" = "curl" ]; then
      if curl --fail --location --silent --show-error --retry 1 --continue-at - "$url" -o "$destination"; then
        return 0
      fi
    else
      if wget --quiet --continue -O "$destination" "$url"; then
        return 0
      fi
    fi
    attempt=$((attempt + 1))
    echo "Download attempt failed; retrying ($attempt/3)..." >&2
  done
  return 1
}

verify_sha256() {
  file="$1"
  expected="$2"
  actual="$(sha256sum "$file" | awk '{print $1}')"
  [ "$actual" = "$expected" ] || fail "SHA-256 verification failed for $(basename "$file")."
}

echo "E-Sign $VERSION (build $BUILD) — Open Minis / $ARCH"
echo "Preparing the official AppleJR installer..."

RAW="$TMP_DIR/e-sign-installer.bin"
XZ_FILE="$TMP_DIR/e-sign-installer.bin.xz"
GZIP_FILE="$TMP_DIR/e-sign-installer.bin.gz"
FETCHED=""

# Prefer compressed downloads, then fall back to the raw executable.
if download "${BASE_URL}.xz" "$XZ_FILE"; then
  if [ "$(sha256sum "$XZ_FILE" | awk '{print $1}')" = "$SHA256_XZ" ]; then
    command -v xz >/dev/null 2>&1 || fail "The xz utility is required to unpack the verified download."
    xz -dc "$XZ_FILE" > "$RAW" || fail "Could not unpack the XZ download."
    FETCHED="xz"
  else
    rm -f "$XZ_FILE"
    echo "XZ checksum did not match; trying another format..." >&2
  fi
fi

if [ -z "$FETCHED" ]; then
  if download "${BASE_URL}.gz" "$GZIP_FILE"; then
    if [ "$(sha256sum "$GZIP_FILE" | awk '{print $1}')" = "$SHA256_GZIP" ]; then
      command -v gzip >/dev/null 2>&1 || fail "The gzip utility is required to unpack the verified download."
      gzip -dc "$GZIP_FILE" > "$RAW" || fail "Could not unpack the GZIP download."
      FETCHED="gzip"
    else
      rm -f "$GZIP_FILE"
      echo "GZIP checksum did not match; trying the raw download..." >&2
    fi
  fi
fi

if [ -z "$FETCHED" ]; then
  download "$BASE_URL" "$RAW" || fail "Could not download the official E-Sign installer."
  FETCHED="raw"
fi

verify_sha256 "$RAW" "$SHA256_RAW"
chmod 700 "$RAW"
mv -f "$RAW" "$BINARY"
chmod 700 "$BINARY"
rm -f "$XZ_FILE" "$GZIP_FILE"

echo "Verified official installer. Starting command: $MODE"
exec "$BINARY" "$MODE" </dev/null
