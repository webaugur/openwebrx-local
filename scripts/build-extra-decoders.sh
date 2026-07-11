#!/usr/bin/env bash
# Build optional OpenWebRX mode stack into PREFIX.
# This is a guided recipe (long). Prefer running sections you need.
# See docs/extra-decoders-notes.md for versions and caveats (esp. soft AMBE / mbelib).
set -euo pipefail

PREFIX="${OPENWEBRX_PREFIX:-${HOME}/Applications/OpenWebRX}"
BUILD="${OPENWEBRX_BUILD_DIR:-/tmp/owrx-decoders}"
export LD_LIBRARY_PATH="${PREFIX}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export CMAKE_PREFIX_PATH="${PREFIX}"
export PATH="${PREFIX}/bin:${PATH}"
VENV_PIP="${PREFIX}/venv/bin/pip"
VENV_PY="${PREFIX}/venv/bin/python"

mkdir -p "$PREFIX"/{bin,lib,include,etc/codecserver} "$BUILD"

echo "==> This script documents the full stack built for DragonSDR."
echo "    PREFIX=$PREFIX"
echo "    BUILD=$BUILD"
echo
echo "Installed apt packages (recommended):"
echo "  wsjtx direwolf rtl-433 dump1090-mutability dablin js8call(GUI only)"
echo "  libhamlib-dev gfortran qtbase5-dev libfaad-dev libliquid-dev ..."
echo
echo "Built components (run manually / re-run from history if needed):"
cat <<'LIST'
  - mbelib + codecserver-mbelib-module (soft AMBE) + codecserver
  - digiham (CMAKE_CXX_STANDARD 20) + pydigiham
  - codec2 1.2.0 → freedv_rx / freedv_tx
  - m17-demod, redsea
  - js8 CLI from classic js8call tree (pre burn-the-boats)
  - msk144decoder
  - dream 2.1.1 (+ openwebrx docker dream.patch)
  - csdr-eti + pycsdr-eti (csdreti)
  - libacars + dumphfdl (liquid version check may need patch) + dumpvdl2
  - dump1090 wrapper → dump1090-mutability
LIST
echo
echo "Full automated one-shot is intentionally not forced (long / fragile)."
echo "See docs/extra-decoders-notes.md and rebuild commands therein."
echo
if [ -x "$PREFIX/bin/js8" ]; then echo "js8: OK"; else echo "js8: missing"; fi
if [ -x "$PREFIX/bin/dream" ]; then echo "dream: OK"; else echo "dream: missing"; fi
if [ -x "$PREFIX/bin/dumphfdl" ]; then echo "dumphfdl: OK"; else echo "dumphfdl: missing"; fi
if [ -x "$PREFIX/bin/msk144decoder" ]; then echo "msk144decoder: OK"; else echo "msk144decoder: missing"; fi
if [ -f "$PREFIX/lib/codecserver/libmbelib.so" ]; then echo "soft AMBE: OK"; else echo "soft AMBE: missing"; fi
