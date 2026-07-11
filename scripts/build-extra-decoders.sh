#!/usr/bin/env bash
# One-shot build of OpenWebRX extra mode stack into OPENWEBRX_PREFIX.
# Idempotent where possible: skips steps when outputs already exist unless FORCE=1.
#
# Usage:
#   OPENWEBRX_PREFIX=~/Applications/OpenWebRX ./build-extra-decoders.sh
#   FORCE=1 ./build-extra-decoders.sh          # rebuild everything
#   ONLY=js8,dream ./build-extra-decoders.sh   # subset (comma-separated)
#
# Requires network, cmake, g++, gfortran, pkg-config, and many -dev packages.
# Soft AMBE (mbelib) is optional community software — see docs/extra-decoders-notes.md.
set -euo pipefail

PREFIX="${OPENWEBRX_PREFIX:-${HOME}/Applications/OpenWebRX}"
BUILD="${OPENWEBRX_BUILD_DIR:-/tmp/owrx-decoders}"
FORCE="${FORCE:-0}"
ONLY="${ONLY:-}"
JOBS="${JOBS:-$(nproc)}"
export LD_LIBRARY_PATH="${PREFIX}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export CMAKE_PREFIX_PATH="${PREFIX}"
export PATH="${PREFIX}/bin:${PATH}"
export CMAKE_POLICY_VERSION_MINIMUM="${CMAKE_POLICY_VERSION_MINIMUM:-3.5}"

VENV_PIP="${PREFIX}/venv/bin/pip"
VENV_PY="${PREFIX}/venv/bin/python"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OWRX_DOCKER_FILES="${OWRX_DOCKER_FILES:-}"

log() { printf '==> %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
skip_if_exists() {
  local path="$1"
  if [ "$FORCE" != "1" ] && [ -e "$path" ]; then
    log "skip (exists): $path"
    return 0
  fi
  return 1
}
want() {
  # want component-name — true if ONLY empty or name in ONLY list
  local name="$1"
  if [ -z "$ONLY" ]; then return 0; fi
  case ",${ONLY}," in
    *",${name},"*) return 0 ;;
    *) return 1 ;;
  esac
}

mkdir -p "$PREFIX"/{bin,lib,include,etc/codecserver,data} "$BUILD"
cd "$BUILD"

# Optional: locate openwebrx docker patches for dream
if [ -z "$OWRX_DOCKER_FILES" ]; then
  for cand in \
    "${HOME}/Documents/DragonSDR/jketterl/openwebrx/docker/files" \
    "${REPO_ROOT}/../jketterl/openwebrx/docker/files"; do
    if [ -d "$cand/dream" ]; then OWRX_DOCKER_FILES="$cand"; break; fi
  done
fi

# ---------- helpers ----------
cmake_install() {
  local src="$1"
  shift
  rm -rf "$src/build"
  mkdir -p "$src/build"
  cmake -S "$src" -B "$src/build" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_CXX_FLAGS="-I${PREFIX}/include" \
    -DCMAKE_C_FLAGS="-I${PREFIX}/include" \
    "$@"
  cmake --build "$src/build" -j"$JOBS"
  cmake --install "$src/build"
}

clone_or_update() {
  local url="$1" dir="$2" ref="${3:-}"
  if [ ! -d "$dir/.git" ]; then
    git clone --recurse-submodules "$url" "$dir"
  fi
  if [ -n "$ref" ]; then
    git -C "$dir" fetch --tags --depth 1 origin "$ref" 2>/dev/null || git -C "$dir" fetch --tags origin 2>/dev/null || true
    git -C "$dir" checkout "$ref" 2>/dev/null || true
  fi
}

# ---------- apt (best-effort) ----------
if want apt && have sudo; then
  log "apt packages (best-effort)"
  sudo -n apt-get install -y \
    wsjtx direwolf rtl-433 dump1090-mutability dablin \
    libhamlib-dev gfortran libfftw3-dev \
    qtbase5-dev qtmultimedia5-dev libqt5serialport5-dev \
    libfaad-dev libopus-dev libsndfile1-dev libpulse-dev \
    libliquid-dev libcurl4-openssl-dev libsqlite3-dev \
    libxml2-dev libjansson-dev libprotobuf-dev protobuf-compiler \
    libicu-dev libsamplerate0-dev libudev-dev \
    meson ninja-build nlohmann-json3-dev \
    2>/dev/null || log "apt skipped/partial (need password or packages missing)"
fi

# dump1090 wrapper
if want dump1090; then
  if [ -x /usr/bin/dump1090-mutability ]; then
    cat >"$PREFIX/bin/dump1090" <<'WRAP'
#!/bin/sh
if [ "${1:-}" = "--version" ]; then
  echo "dump1090 mutability (wrapper for OpenWebRX)"
  exit 0
fi
exec /usr/bin/dump1090-mutability "$@"
WRAP
    chmod +x "$PREFIX/bin/dump1090"
    log "dump1090 wrapper installed"
  fi
fi

# ---------- codecserver + soft AMBE ----------
if want codecserver || want softmbe; then
  if ! skip_if_exists "$PREFIX/bin/codecserver"; then
    log "codecserver"
    clone_or_update https://github.com/jketterl/codecserver.git codecserver 0f3703ce285acd85fcd28f6620d7795dc173cb50
    mkdir -p "$PREFIX/etc/codecserver"
    cp -n codecserver/conf/codecserver.conf "$PREFIX/etc/codecserver/" 2>/dev/null \
      || cp codecserver/conf/codecserver.conf "$PREFIX/etc/codecserver/" 2>/dev/null || true
    cmake_install codecserver
  fi

  if ! skip_if_exists "$PREFIX/lib/libmbe.so"; then
    log "mbelib"
    clone_or_update https://github.com/szechyjs/mbelib.git mbelib
    cmake_install mbelib
  fi

  if ! skip_if_exists "$PREFIX/lib/codecserver/libmbelib.so"; then
    log "codecserver-mbelib-module"
    clone_or_update https://github.com/fventuri/codecserver-mbelib-module.git codecserver-mbelib-module
    rm -rf codecserver-mbelib-module/build && mkdir codecserver-mbelib-module/build
    cmake -S codecserver-mbelib-module -B codecserver-mbelib-module/build \
      -DCMAKE_INSTALL_PREFIX="$PREFIX" \
      -DCMAKE_PREFIX_PATH="$PREFIX" \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DCMAKE_CXX_FLAGS="-I${PREFIX}/include" \
      -DCMAKE_SHARED_LINKER_FLAGS="-L${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib"
    cmake --build codecserver-mbelib-module/build -j"$JOBS"
    cmake --install codecserver-mbelib-module/build
  fi

  # soft-MBE config
  if [ ! -f "$PREFIX/etc/codecserver/codecserver.conf" ] || [ "$FORCE" = "1" ]; then
    cp "${REPO_ROOT}/config/codecserver.conf.example" "$PREFIX/etc/codecserver/codecserver.conf"
  fi
fi

# ---------- digiham ----------
if want digiham; then
  if ! skip_if_exists "$PREFIX/bin/pocsag_decoder"; then
    log "digiham (C++20 for modern ICU)"
    clone_or_update https://github.com/jketterl/digiham.git digiham 262e6dfd9a2c56778bd4b597240756ad0fb9861d
    sed -i 's/set(CMAKE_CXX_STANDARD 11)/set(CMAKE_CXX_STANDARD 20)/' digiham/CMakeLists.txt
    cmake_install digiham
  fi
  if [ -x "$VENV_PIP" ]; then
    log "pydigiham"
    clone_or_update https://github.com/jketterl/pydigiham.git pydigiham 894aa87ea9a3534d1e7109da86194c7cd5e0b7c7
    export CFLAGS="-I${PREFIX}/include"
    export CXXFLAGS="-I${PREFIX}/include -I${PREFIX}/venv/include/site/python3.14 -std=c++17"
    export LDFLAGS="-L${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib"
    "$VENV_PIP" install ./pydigiham --no-build-isolation || \
      "$VENV_PIP" install ./pydigiham --no-build-isolation -v || true
  fi
fi

# ---------- python helpers ----------
if want python && [ -x "$VENV_PIP" ]; then
  log "js8py + paho-mqtt"
  clone_or_update https://github.com/jketterl/js8py.git js8py f7e394b7892d26cbdcce5d43c0b4081a2a6a48f6
  "$VENV_PIP" install setuptools wheel 'paho-mqtt>=1.5' ./js8py --no-build-isolation || \
    "$VENV_PIP" install setuptools wheel 'paho-mqtt>=1.5'
  "$VENV_PIP" install ./js8py --no-build-isolation || true
fi

# ---------- freedv ----------
if want freedv; then
  if ! skip_if_exists "$PREFIX/bin/freedv_rx"; then
    log "codec2 → freedv_rx"
    clone_or_update https://github.com/drowe67/codec2.git codec2 1.2.0
    cmake_install codec2 -DUNITTEST=OFF
    if [ -x codec2/build/src/freedv_rx ]; then
      install -m 0755 codec2/build/src/freedv_rx "$PREFIX/bin/freedv_rx"
      install -m 0755 codec2/build/src/freedv_tx "$PREFIX/bin/freedv_tx" 2>/dev/null || true
    fi
  fi
fi

# ---------- m17 ----------
if want m17; then
  if ! skip_if_exists "$PREFIX/bin/m17-demod"; then
    log "m17-demod"
    clone_or_update https://github.com/mobilinkd/m17-cxx-demod.git m17-cxx-demod v2.3
    rm -rf m17-cxx-demod/build && mkdir m17-cxx-demod/build
    cmake -S m17-cxx-demod -B m17-cxx-demod/build \
      -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 || true
    # build demod even if m17-mod fails on modern g++
    cmake --build m17-cxx-demod/build --target m17-demod -j"$JOBS" 2>/dev/null \
      || cmake --build m17-cxx-demod/build -j"$JOBS" || true
    if [ -x m17-cxx-demod/build/apps/m17-demod ]; then
      install -m 0755 m17-cxx-demod/build/apps/m17-demod "$PREFIX/bin/m17-demod"
    elif [ -x m17-cxx-demod/build/m17-demod ]; then
      install -m 0755 m17-cxx-demod/build/m17-demod "$PREFIX/bin/m17-demod"
    fi
  fi
fi

# ---------- redsea ----------
if want redsea; then
  if ! skip_if_exists "$PREFIX/bin/redsea"; then
    log "redsea"
    clone_or_update https://github.com/windytan/redsea.git redsea
    if [ -f redsea/meson.build ]; then
      meson setup redsea/build --prefix="$PREFIX" --reconfigure 2>/dev/null \
        || meson setup redsea/build --prefix="$PREFIX"
      meson compile -C redsea/build
      meson install -C redsea/build
    fi
  fi
fi

# ---------- aircraft: libacars, dumpvdl2, dumphfdl ----------
if want aircraft || want dumphfdl || want dumpvdl2; then
  if ! skip_if_exists "$PREFIX/lib/libacars-2.so"; then
    log "libacars"
    clone_or_update https://github.com/szpajder/libacars.git libacars v2.2.0
    cmake_install libacars
  fi
  if want dumpvdl2 || want aircraft; then
    if ! skip_if_exists "$PREFIX/bin/dumpvdl2"; then
      log "dumpvdl2"
      clone_or_update https://github.com/szpajder/dumpvdl2.git dumpvdl2 v2.3.0
      cmake_install dumpvdl2
    fi
  fi
  if want dumphfdl || want aircraft; then
    if ! skip_if_exists "$PREFIX/bin/dumphfdl"; then
      log "dumphfdl (patch liquid version check for liquid 1.7+)"
      clone_or_update https://github.com/szpajder/dumphfdl.git dumphfdl v1.4.1
      if [ -f dumphfdl/src/CMakeLists.txt ]; then
        sed -i 's/if(LIQUIDDSP_VERSION_CHECK)/if(TRUE)/' dumphfdl/src/CMakeLists.txt || true
      fi
      cmake_install dumphfdl
    fi
  fi
fi

# ---------- DAB: csdr-eti ----------
if want dab; then
  if ! skip_if_exists "$PREFIX/lib/libcsdr-eti.so"; then
    log "csdr-eti"
    clone_or_update https://github.com/jketterl/csdr-eti.git csdr-eti e174007f9c247047dba60f092f794800297c594f
    cmake_install csdr-eti
  fi
  if [ -x "$VENV_PIP" ]; then
    log "pycsdr-eti"
    clone_or_update https://github.com/jketterl/pycsdr-eti.git pycsdr-eti 676663b4d796fbadd18dfcae0c3b80eb1b1f9147
    export CFLAGS="-I${PREFIX}/include"
    export CXXFLAGS="-I${PREFIX}/include -I${PREFIX}/venv/include/site/python3.14 -std=c++17"
    export LDFLAGS="-L${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib"
    "$VENV_PIP" install ./pycsdr-eti --no-build-isolation || true
  fi
fi

# ---------- msk144 ----------
if want msk144; then
  if ! skip_if_exists "$PREFIX/bin/msk144decoder"; then
    log "msk144decoder (serial Fortran build)"
    clone_or_update https://github.com/alexander-sholohov/msk144decoder.git msk144decoder fe2991681e455636e258e83c29fd4b2a72d16095
    git -C msk144decoder submodule update --init --recursive
    rm -rf msk144decoder/build && mkdir msk144decoder/build
    cmake -S msk144decoder -B msk144decoder/build \
      -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    cmake --build msk144decoder/build --target msk144decoder -j1
    cmake --install msk144decoder/build
  fi
fi

# ---------- js8 CLI ----------
if want js8; then
  if ! skip_if_exists "$PREFIX/bin/js8"; then
    log "js8 CLI (classic js8call tree before decoder removal)"
    if [ ! -d js8call-classic/.git ] && [ ! -f js8call-classic/CMakeLists.txt ]; then
      clone_or_update https://github.com/js8call/js8call.git js8call-full
      # resolve parent of "Burn the boats" if present
      cd js8call-full
      git fetch --deepen=500 2>/dev/null || git fetch --unshallow 2>/dev/null || true
      BURN=$(git log --all --oneline --grep='Burn the boats' | head -1 | awk '{print $1}')
      if [ -n "$BURN" ]; then
        PARENT=$(git rev-parse "${BURN}^")
        mkdir -p ../js8call-classic
        git archive "$PARENT" | tar -x -C ../js8call-classic
      else
        # fallback: use tree as-is and hope js8 target exists
        cp -a . ../js8call-classic 2>/dev/null || true
      fi
      cd "$BUILD"
    fi
    if [ -f js8call-classic/CMakeLists.txt ]; then
      sed -i 's/set (hamlib_STATIC 1)/set (hamlib_STATIC 0)/' js8call-classic/CMakeLists.txt || true
      rm -rf js8call-classic/build && mkdir js8call-classic/build
      cmake -S js8call-classic -B js8call-classic/build \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DWSJT_SKIP_MANPAGES=ON || true
      cmake --build js8call-classic/build --target js8 -j"$JOBS"
      if [ -x js8call-classic/build/js8 ]; then
        install -m 0755 js8call-classic/build/js8 "$PREFIX/bin/js8"
      fi
    else
      log "WARNING: could not materialize js8call-classic sources"
    fi
  fi
fi

# ---------- dream (DRM) ----------
if want dream; then
  if ! skip_if_exists "$PREFIX/bin/dream"; then
    log "dream DRM"
    if [ ! -d dream ]; then
      wget -q -O dream.tgz \
        'https://downloads.sourceforge.net/project/drm/dream/2.1.1/dream-2.1.1-svn808.tar.gz'
      tar xzf dream.tgz
    fi
    if [ -d dream ]; then
      if [ -n "$OWRX_DOCKER_FILES" ] && [ -f "$OWRX_DOCKER_FILES/dream/dream.patch" ]; then
        (cd dream && patch -Np0 -i "$OWRX_DOCKER_FILES/dream/dream.patch" || true)
      fi
      (cd dream && qmake CONFIG+=console && make -j"$JOBS")
      if [ -x dream/dream ]; then
        install -m 0755 dream/dream "$PREFIX/bin/dream"
      fi
    fi
  fi
fi

# ---------- summary ----------
log "summary under $PREFIX/bin"
for b in \
  rtl_connector soapy_connector codecserver \
  js8 msk144decoder dream dumphfdl dumpvdl2 \
  freedv_rx m17-demod redsea dump1090 pocsag_decoder; do
  if [ -x "$PREFIX/bin/$b" ]; then
    printf '  OK  %s\n' "$b"
  else
    printf '  --  %s\n' "$b"
  fi
done
if [ -f "$PREFIX/lib/codecserver/libmbelib.so" ]; then
  echo "  OK  soft AMBE (libmbelib.so)"
else
  echo "  --  soft AMBE"
fi
if [ -x "$VENV_PY" ]; then
  "$VENV_PY" - <<'PY' 2>/dev/null || true
import os
os.environ.setdefault("LD_LIBRARY_PATH", "")
try:
    from js8py.version import strictversion
    print("  OK  js8py", strictversion)
except Exception as e:
    print("  --  js8py", e)
try:
    from csdreti.modules import csdreti_version
    print("  OK  csdreti", csdreti_version)
except Exception as e:
    print("  --  csdreti", e)
try:
    from digiham.modules import digiham_version
    print("  OK  digiham", digiham_version)
except Exception as e:
    print("  --  digiham", e)
PY
fi
log "done. Start OpenWebRX with openwebrx-serve.sh (starts codecserver if configured)."
