# OpenWebRX extra decoders (local notes)

Prefix: `~/Applications/OpenWebRX`

## Installed via apt

- `wsjtx`, `direwolf` (already present)
- `js8call` (GUI only; no `js8` CLI on Ubuntu package)
- `rtl-433`
- `dump1090-mutability` (wrapped as `bin/dump1090` for feature check)
- `dablin`

## Built into prefix

- `owrx_connector` → `rtl_connector`, `soapy_connector`, `rtl_tcp_connector`
- `codecserver` + ambe3k + **mbelib** soft-AMBE module
- `digiham` (+ C++20 for modern ICU) + pydigiham
- codec2 1.2.0 → `freedv_rx`, `freedv_tx`
- `m17-demod`, `redsea`
- **js8** CLI (from js8call classic tree pre-“burn the boats”; `js8 --js8` for OWRX)
- `msk144decoder` (and jt65decoder/q65decoder side targets)
- `dream` (DRM 2.1.1 + OWRX docker patch)
- `csdr-eti` + venv `csdreti` (DAB ETI; with system `dablin`)
- libacars + `dumphfdl` + `dumpvdl2`
- venv: digiham, js8py, paho-mqtt, csdreti

## Build digiham (reference)

```bash
PREFIX=$HOME/Applications/OpenWebRX
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig LD_LIBRARY_PATH=$PREFIX/lib
# In digiham CMakeLists: CMAKE_CXX_STANDARD 20 (ICU 78+)
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_PREFIX_PATH=$PREFIX \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build -j && cmake --install build
```

pydigiham needs pycsdr headers from the venv:

```bash
export CXXFLAGS="-I$PREFIX/include -I$PREFIX/venv/include/site/python3.14 -std=c++17"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"
$PREFIX/venv/bin/pip install /path/to/pydigiham --no-build-isolation
```

## AMBE / digital voice

### Software AMBE (this install)

Built:

- `mbelib` → `lib/libmbe.so`
- [codecserver-mbelib-module](https://github.com/fventuri/codecserver-mbelib-module) → `lib/codecserver/libmbelib.so`
- Config: `etc/codecserver/codecserver.conf` (`driver=mbelib`, unix socket `/tmp/codecserver.sock`)

`openwebrx-serve.sh` starts `codecserver` if the socket is missing.  
Feature check: digiham `MbeSynthesizer.hasAmbe("")` → True when codecserver is up.

**Note:** mbelib is a community reverse-engineered decoder (receive). Quality is usable but not identical to a hardware DV3K stick. Patent/licence situation is murky; use at your own risk. Official OpenWebRX only ships the **hardware** ambe3k path.

### Hardware AMBE (optional)

Uncomment in `etc/codecserver/codecserver.conf`:

```
[device:dv3k]
driver=ambe3k
tty=/dev/ttyUSB0
baudrate=921600
```

POCSAG and metadata paths work with digiham alone (no AMBE).
