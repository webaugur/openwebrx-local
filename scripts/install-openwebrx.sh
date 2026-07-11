#!/usr/bin/env bash
# Create/update OpenWebRX venv and install an editable source tree.
set -euo pipefail

PREFIX="${OPENWEBRX_PREFIX:-${HOME}/Applications/OpenWebRX}"
SRC="${1:-}"

if [ -z "$SRC" ] || [ ! -f "$SRC/setup.py" ] && [ ! -f "$SRC/pyproject.toml" ]; then
  echo "Usage: $0 /path/to/openwebrx-source"
  echo "  Clone: git clone -b develop https://github.com/webaugur/openwebrx.git"
  exit 1
fi

mkdir -p "$PREFIX"/{bin,lib,include,data,etc/codecserver}
python3 -m venv "$PREFIX/venv"
# shellcheck disable=SC1091
. "$PREFIX/venv/bin/activate"
export LD_LIBRARY_PATH="${PREFIX}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export PATH="${PREFIX}/bin:${PATH}"

pip install -U pip wheel setuptools
pip install -e "$SRC"

if [ ! -f "$PREFIX/openwebrx.conf" ]; then
  sed "s|PREFIX|${PREFIX}|g" \
    "$(dirname "$0")/../config/openwebrx.conf.example" \
    >"$PREFIX/openwebrx.conf"
  echo "Wrote $PREFIX/openwebrx.conf"
fi

if [ ! -f "$PREFIX/etc/codecserver/codecserver.conf" ]; then
  cp "$(dirname "$0")/../config/codecserver.conf.example" \
    "$PREFIX/etc/codecserver/codecserver.conf"
fi

echo "OpenWebRX installed into $PREFIX"
echo "Run: OPENWEBRX_PREFIX=$PREFIX $(dirname "$0")/openwebrx-serve.sh"
