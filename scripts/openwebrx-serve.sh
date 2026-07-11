#!/bin/sh
# Start OpenWebRX with local defaults, then open the default browser.
# PREFIX defaults to ~/Applications/OpenWebRX (override with OPENWEBRX_PREFIX).
set -eu

HERE="${OPENWEBRX_PREFIX:-${HOME}/Applications/OpenWebRX}"
CONF="${OPENWEBRX_CONFIG:-${HERE}/openwebrx.conf}"
URL="${OPENWEBRX_URL:-http://127.0.0.1:8073/}"
WAIT_SECS="${OPENWEBRX_BROWSER_WAIT:-3}"
PORT=8073

if [ ! -d "${HERE}/venv" ]; then
  echo "error: venv not found at ${HERE}/venv — install OpenWebRX first (see README)."
  exit 1
fi

# shellcheck disable=SC1091
. "${HERE}/venv/bin/activate"
export LD_LIBRARY_PATH="${HERE}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${HERE}/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export PATH="${HERE}/bin:${PATH}"

mkdir -p "${HERE}/data" /tmp/openwebrx
cd "$HERE"

# Software/hardware AMBE for digital voice (DMR/YSF/D-STAR/NXDN) via digiham
start_codecserver() {
  if ! command -v codecserver >/dev/null 2>&1; then
    return 0
  fi
  if [ -S /tmp/codecserver.sock ]; then
    return 0
  fi
  codecserver -c "${HERE}/etc/codecserver/codecserver.conf" \
    >>"${HERE}/data/codecserver.log" 2>&1 &
  echo $! >"${HERE}/data/codecserver.pid"
  i=0
  while [ "$i" -lt 20 ]; do
    if [ -S /tmp/codecserver.sock ]; then
      echo "codecserver ready (soft MBE / mbelib)."
      return 0
    fi
    i=$((i + 1))
    sleep 0.1
  done
  echo "warning: codecserver started but socket not ready yet (check ${HERE}/data/codecserver.log)"
}
start_codecserver

if command -v ss >/dev/null 2>&1; then
  if ss -ltn 2>/dev/null | grep -qE ":${PORT}\\b"; then
    echo "OpenWebRX already listening on port ${PORT}; opening browser..."
    xdg-open "$URL" 2>/dev/null || gio open "$URL" 2>/dev/null || true
    exit 0
  fi
fi

echo "Starting OpenWebRX..."
echo "  config: ${CONF}"
echo "  URL:    ${URL}"
echo "  data:   ${HERE}/data"

openwebrx -c "$CONF" &
SERVER_PID=$!

cleanup() {
  if kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup INT TERM

i=0
max=$((WAIT_SECS * 10))
if [ "$max" -lt 30 ]; then max=30; fi
while [ "$i" -lt "$max" ]; do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "OpenWebRX exited before becoming ready (check terminal output above)."
    wait "$SERVER_PID" || true
    exit 1
  fi
  if command -v curl >/dev/null 2>&1; then
    if curl -sf -o /dev/null --connect-timeout 1 "$URL" 2>/dev/null; then
      break
    fi
  else
    sleep "$WAIT_SECS"
    break
  fi
  i=$((i + 1))
  sleep 0.3
done

sleep 0.5
echo "Opening default browser: ${URL}"
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" >/dev/null 2>&1 || true
elif command -v gio >/dev/null 2>&1; then
  gio open "$URL" >/dev/null 2>&1 || true
fi

echo "OpenWebRX running (PID ${SERVER_PID}). Close this terminal or Ctrl+C to stop."
wait "$SERVER_PID"
