#!/bin/sh
# Generic Applications/ launcher: sets LD_LIBRARY_PATH / PATH for a prefix.
# Usage: app-launch.sh <PREFIX> <relative-bin> [args...]
# Example: app-launch.sh ~/Applications/SDRPlusPlus bin/sdrpp
set -eu
PREFIX="${1:?prefix required}"
RELBIN="${2:?binary relative to prefix required}"
shift 2
export LD_LIBRARY_PATH="${PREFIX}/lib:${PREFIX}/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="${PREFIX}/bin:${PATH}"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export XDG_DATA_DIRS="${PREFIX}/share:${HOME}/.local/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
cd "$PREFIX"
exec "${PREFIX}/${RELBIN}" "$@"
