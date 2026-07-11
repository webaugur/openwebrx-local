#!/bin/sh
# CLI wrapper: inject -c $PREFIX/openwebrx.conf when not already set.
HERE="${OPENWEBRX_PREFIX:-${HOME}/Applications/OpenWebRX}"
CONF="${OPENWEBRX_CONFIG:-${HERE}/openwebrx.conf}"
# shellcheck disable=SC1091
. "${HERE}/venv/bin/activate"
export LD_LIBRARY_PATH="${HERE}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${HERE}/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export PATH="${HERE}/bin:${PATH}"
has_config=0
for a in "$@"; do
  case "$a" in
    -c|--config) has_config=1; break ;;
  esac
done
if [ "$#" -eq 0 ]; then
  exec openwebrx -c "$CONF" --help
elif [ "$has_config" -eq 0 ]; then
  exec openwebrx -c "$CONF" "$@"
else
  exec openwebrx "$@"
fi
