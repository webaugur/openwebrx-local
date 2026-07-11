# DragonSDR

Local monorepo of SDR applications, libraries, and desktop launchers for KG9AE / WebAugur.

Most end-user apps install under **`~/Applications/`** with a `.desktop` launcher and (usually) a private prefix or venv. Source trees live in this directory, often as upstream git clones.

## Installed applications

| App | Location | Launch |
|-----|----------|--------|
| OpenWebRX | `~/Applications/OpenWebRX` | Desktop icon or `openwebrx-serve.sh` → http://127.0.0.1:8073/ |
| SDR++ | `~/Applications/SDRPlusPlus` | Desktop icon |
| SDRangel | `~/Applications/SDRangel` | Desktop icon |
| AbracaDABra | `~/Applications/AbracaDABra` | Desktop icon |
| qradiolink | `~/Applications/qradiolink` | Desktop icon |
| habdec | `~/Applications/habdec` | Desktop icon |
| SigDigger | `~/Applications/SigDigger` | Desktop icon |
| HackRF tools | `~/Applications/hackrf` | Desktop icon / CLI |

Desktop `.desktop` files also live under `~/Applications/` and are synced to the desktop via IndianaDell scripts (see below).

## OpenWebRX (web receiver)

**Config:** `~/Applications/OpenWebRX/openwebrx.conf`  
**User data / settings:** `~/Applications/OpenWebRX/data/`  
**Start:** `~/Applications/OpenWebRX/openwebrx-serve.sh` (starts server, waits for HTTP, opens browser)

### Maps

- **Default:** free **Leaflet / OpenStreetMap** (no API key).
- **Google Maps:** Settings → Map type → Google Maps + API key (still supported).
- **Local tiles:** set `map_tile_url` (e.g. `http://127.0.0.1:8080/tiles/{z}/{x}/{y}.png`).
- Fork / branch: [webaugur/openwebrx](https://github.com/webaugur/openwebrx) `feature/leaflet-default-maps` (importlib.resources fix + Leaflet default).

### Decoders & tools (prefix `~/Applications/OpenWebRX`)

Built or packaged helpers used by OpenWebRX:

| Capability | How provided |
|------------|----------------|
| RTL / Soapy connectors | Built: `bin/rtl_connector`, `soapy_connector`, `rtl_tcp_connector` |
| csdr / nmux | Built into prefix |
| digiham / pydigiham | Built (POCSAG + DMR/YSF/D-STAR/NXDN pipelines) |
| codecserver + soft MBE | Built (`bin/codecserver` + `lib/codecserver/libmbelib.so` via **mbelib**); optional USB DV3K/ambe3k still supported |
| WSJT-X (FT8/WSPR/…) | System package `wsjtx` |
| Packet / APRS | System package `direwolf` |
| ISM / 433 MHz | System package `rtl-433` |
| ADS-B | `bin/dump1090` wrapper → `dump1090-mutability` |
| DAB audio client | System package `dablin` (full DAB chain still needs csdr-eti) |
| M17 | Built: `bin/m17-demod` |
| FreeDV | Built: `bin/freedv_rx` (codec2 1.2.0) |
| FM RDS | Built: `bin/redsea` |
| JS8Call | Built: `bin/js8` CLI + venv `js8py` (Ubuntu GUI package alone is not enough) |
| MSK144 | Built: `bin/msk144decoder` |
| DRM | Built: `bin/dream` |
| DAB/DAB+ | Built: csdr-eti + pycsdr-eti; apt `dablin` |
| HFDL / VDL2 | Built: `bin/dumphfdl`, `bin/dumpvdl2` (+ libacars) |
| MQTT publish | `paho-mqtt` in venv |

**Only hardware backends still missing** (unless you own the radio): SDRPlay, Afedri, Funcube Pro+, FiFiSDR, HPSDR, Perseus, Radioberry, R&S EB200, SDDC. See `~/Applications/OpenWebRX/install-extra-decoders-notes.md`.

Reinstall helpers (after clone tools):

```bash
# Connectors (example)
# see prior build under /tmp/owrx-build/owrx_connector

# Ensure launcher sees prefix binaries
export PATH="$HOME/Applications/OpenWebRX/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/Applications/OpenWebRX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

Feature report (while server is running): http://127.0.0.1:8073/features  

Admin users: `openwebrx admin` **with** `-c ~/Applications/OpenWebRX/openwebrx.conf` (or use the venv wrapper that injects config).

### Hardware notes

- Plug in the SDR **before** starting OpenWebRX.
- Default configured device in this install: **RTL-SDR** only (avoids noisy failures for Airspy/SDRPlay when not present).
- Add more devices under Settings → SDR devices, or edit `data/settings.json`.

## Source layout (this repo)

| Path | Contents |
|------|----------|
| `jketterl/openwebrx` | OpenWebRX source (editable install into OpenWebRX venv) |
| `AlexandreRouma/SDRPlusPlus` | SDR++ and modules |
| `f4exb/sdrangel` | SDRangel |
| `qradiolink/` | qradiolink |
| `community/`, `tools/`, … | Other clones and helper scripts |
| `Documentation/` | Combined docs / PDF build |

## Desktop icons (GNOME / Nautilus)

After adding or changing `.desktop` files under `~/Applications` or the Desktop:

```bash
~/Documents/IndianaDell/scripts/gnome/fix-nautilus-desktop-launch.sh
~/Documents/IndianaDell/scripts/gnome/sync-desktop-icons.sh
```

## Forks

- OpenWebRX: https://github.com/webaugur/openwebrx  

## License

Each upstream project retains its own license (often GPL/AGPL). This monorepo layout and local scripts are for personal/local use unless noted otherwise.
