#!/usr/bin/env bash
# Build owrx_connector (and rely on existing csdr in PREFIX if present).
# Requires: cmake, g++, pkg-config, librtlsdr-dev, and csdr headers/libs in PREFIX.
set -euo pipefail

PREFIX="${OPENWEBRX_PREFIX:-${HOME}/Applications/OpenWebRX}"
BUILD="${OPENWEBRX_BUILD_DIR:-/tmp/owrx-build}"
export LD_LIBRARY_PATH="${PREFIX}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export CMAKE_PREFIX_PATH="${PREFIX}"
export PATH="${PREFIX}/bin:${PATH}"

mkdir -p "$PREFIX"/{bin,lib,include} "$BUILD"
cd "$BUILD"

if [ ! -f "$PREFIX/lib/libcsdr.so" ] && [ ! -f "$PREFIX/lib/libcsdr.so.0.19" ]; then
  echo "warning: libcsdr not found under $PREFIX/lib — build/install csdr first"
  echo "  https://github.com/jketterl/csdr"
fi

if [ ! -d owrx_connector/.git ]; then
  git clone https://github.com/jketterl/owrx_connector.git
fi
cd owrx_connector
rm -rf build && mkdir build && cd build
cmake .. \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_CXX_FLAGS="-I${PREFIX}/include" \
  -DCMAKE_C_FLAGS="-I${PREFIX}/include"
make -j"$(nproc)"
make install

echo "Installed connectors to $PREFIX/bin:"
ls -1 "$PREFIX/bin"/rtl_connector "$PREFIX/bin"/soapy_connector "$PREFIX/bin"/rtl_tcp_connector 2>/dev/null || true
