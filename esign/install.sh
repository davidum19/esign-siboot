#!/bin/sh
# Lanzador del Instalador E-Sign para Open Minis
# Descarga el instalador E-Sign desde su fuente de distribucion y verifica los archivos.
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
Instalador E-Sign de Davidios para Open Minis

Uso:
  ./install.sh [install|check|pair|developer-mode|sign-out]

Los comandos se envian al instalador de E-Sign.
El comando predeterminado es: install
USAGE
    exit 0
    ;;
  *)
    echo "Error: comando no reconocido: $MODE" >&2
    echo "Opciones: install, check, pair, developer-mode o sign-out" >&2
    exit 2
    ;;
esac

fail() {
  echo "Error: $*" >&2
  exit 1
}

[ "$(uname -s)" = "Linux" ] || fail "Este instalador requiere Linux."
MACHINE="$(uname -m)"
case "$MACHINE" in
  aarch64|arm64) ;;
  *) fail "Arquitectura no compatible: $MACHINE (se requiere ARM64)." ;;
esac

for tool in minis-bonjour minis-open sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || fail "No se encontro el comando necesario: $tool"
done

command -v wget >/dev/null 2>&1 || fail "Se necesita wget en Open Minis."

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
    if wget -q -O "$destination" "$url"; then
      return 0
    fi
    if [ "$attempt" -lt 3 ]; then
      next_attempt=$((attempt + 1))
      echo "La descarga fallo. Reintentando ($next_attempt/3)..." >&2
    fi
    attempt=$((attempt + 1))
  done
  return 1
}

verify_sha256() {
  file="$1"
  expected="$2"
  actual="$(sha256sum "$file" | awk '{print $1}')"
  [ "$actual" = "$expected" ] || fail "La verificacion SHA-256 fallo para $(basename "$file")."
}

echo "E-Sign $VERSION (compilacion $BUILD) — Instalador Davidios / Open Minis / $ARCH"
echo "Descargando el Instalador E-Sign..."

RAW="$TMP_DIR/e-sign-installer.bin"
XZ_FILE="$TMP_DIR/e-sign-installer.bin.xz"
GZIP_FILE="$TMP_DIR/e-sign-installer.bin.gz"
FETCHED=""

# Utiliza formatos comprimidos solo si esta disponible la herramienta para descomprimirlos.
# wget reemplaza el archivo en cada intento para evitar errores HTTP 416 por descargas parciales anteriores.
if command -v xz >/dev/null 2>&1; then
  if download "${BASE_URL}.xz" "$XZ_FILE"; then
    if [ "$(sha256sum "$XZ_FILE" | awk '{print $1}')" = "$SHA256_XZ" ]; then
      xz -dc "$XZ_FILE" > "$RAW" || fail "No se pudo descomprimir el archivo XZ."
      FETCHED="xz"
    else
      rm -f "$XZ_FILE"
      echo "La comprobacion XZ no coincide; probando otro formato..." >&2
    fi
  fi
fi

if [ -z "$FETCHED" ] && command -v gzip >/dev/null 2>&1; then
  if download "${BASE_URL}.gz" "$GZIP_FILE"; then
    if [ "$(sha256sum "$GZIP_FILE" | awk '{print $1}')" = "$SHA256_GZIP" ]; then
      gzip -dc "$GZIP_FILE" > "$RAW" || fail "No se pudo descomprimir el archivo GZIP."
      FETCHED="gzip"
    else
      rm -f "$GZIP_FILE"
      echo "La comprobacion GZIP no coincide; probando la descarga original..." >&2
    fi
  fi
fi

if [ -z "$FETCHED" ]; then
  download "$BASE_URL" "$RAW" || fail "No se pudo descargar el Instalador E-Sign."
  FETCHED="raw"
fi

verify_sha256 "$RAW" "$SHA256_RAW"
chmod 700 "$RAW"
mv -f "$RAW" "$BINARY"
chmod 700 "$BINARY"
rm -f "$XZ_FILE" "$GZIP_FILE"

echo "Instalador verificado. Iniciando la opcion: $MODE"
exec "$BINARY" "$MODE" </dev/null
