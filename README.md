# openwebrx-local

Local install helpers for [OpenWebRX](https://github.com/webaugur/openwebrx) under a private prefix (default `~/Applications/OpenWebRX`).

This repo holds **scripts and config templates only** — not the huge SDR source trees, not the venv, not compiled binaries.

## Related repos

| Repo | Role |
|------|------|
| [webaugur/openwebrx](https://github.com/webaugur/openwebrx) `develop` | Fork with **Leaflet/OSM maps by default**, Google Maps optional, `importlib.resources` fix |
| This repo | Prefix layout, launcher, decoder build recipes |

## Quick layout after install

```text
~/Applications/OpenWebRX/
  bin/          connectors + decoders (rtl_connector, js8, dream, …)
  lib/          shared libs + codecserver modules
  etc/codecserver/codecserver.conf
  venv/         Python env (openwebrx editable install)
  data/         settings.json, users.json, uploaded images
  openwebrx.conf
```

## Bootstrap (high level)

1. **Build prefix deps** (csdr, owrx_connector, digiham stack, …):  
   `scripts/build-prefix-core.sh`
2. **Install OpenWebRX** (editable from a clone of `webaugur/openwebrx` `develop`):  
   `scripts/install-openwebrx.sh /path/to/openwebrx`
3. **Optional full decoder suite** (JS8, MSK144, DRM, DAB, HFDL, VDL2, soft AMBE, …):  
   ```bash
   ./scripts/build-extra-decoders.sh                 # all (skip existing)
   FORCE=1 ./scripts/build-extra-decoders.sh         # rebuild all
   ONLY=js8,dream,aircraft ./scripts/build-extra-decoders.sh
   ```
4. **Config**: copy `config/openwebrx.conf.example` → `$PREFIX/openwebrx.conf` and fix paths.  
   Copy `config/codecserver.conf.example` → `$PREFIX/etc/codecserver/codecserver.conf`.
5. **Run**: `scripts/openwebrx-serve.sh` (or desktop launcher pointing at it).

Environment overrides:

| Variable | Default |
|----------|---------|
| `OPENWEBRX_PREFIX` | `~/Applications/OpenWebRX` |
| `OPENWEBRX_CONFIG` | `$PREFIX/openwebrx.conf` |
| `OPENWEBRX_URL` | `http://127.0.0.1:8073/` |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/openwebrx-serve.sh` | Start server, codecserver, open browser |
| `scripts/build-prefix-core.sh` | csdr (if needed), owrx_connector |
| `scripts/build-extra-decoders.sh` | Mode stack: digiham, soft AMBE, js8, dream, aircraft, DAB, … |
| `scripts/install-openwebrx.sh` | Create venv, `pip install -e` OpenWebRX tree |

## Docs

- `docs/extra-decoders-notes.md` — what was built and how (versions, patches).
- `docs/DragonSDR-README.md` — broader monorepo app table (SDR++, SDRangel, …).

## Images (receiver panorama)

- Upload via Settings (admin): JPEG / PNG / WebP.
- Panorama max **2 MB**; avatar **250 KB**.
- Staging: `$temporary_directory`; final: `$data_directory/receiver_top_photo.{jpg,png,webp}`.
- Must **Save** after upload. Logs are the OpenWebRX process terminal.

## License

Scripts in this repository: use freely.  
Upstream tools (OpenWebRX, digiham, mbelib, dream, …) retain their own licenses; soft AMBE via mbelib is a community path with patent caveats — see decoder notes.
