# dayz-server

Containerized DayZ dedicated server — native Linux binary (no Wine), vanilla
Chernarus out of the box, mod-ready via Steam Workshop.

## Requirements

- Podman (this machine) or Docker + compose elsewhere
- A **Steam account that owns DayZ** — the server files (app `223350`) cannot
  be downloaded anonymously. A dedicated secondary account is recommended.
- UDP ports `2302-2306` and `27016` open/forwarded on your firewall + router

## Quick start

```bash
cp .env.example .env      # fill in STEAM_USERNAME / STEAM_PASSWORD
nano config/serverDZ.cfg  # set hostname + passwordAdmin
make build
make up
make logs                 # watch the first ~2.5 GB download + boot
```

First start downloads the server files; the server appears in the in-game
browser under the DZSA/community tab once `DayZServer` is up.

### Steam Guard

If Steam prompts for a guard code on first login, either:

- put the code in `STEAM_GUARD_CODE` in `.env` and start once (clear it after —
  the session is cached in the `dayz-server-steam` volume), or
- run `make steam-login` and inside the container:
  `steamcmd +login $STEAM_USERNAME $STEAM_PASSWORD`, enter the code, `quit`.

## Files

| Path | Purpose |
|---|---|
| `Containerfile` | image definition (`steamcmd/steamcmd` base) |
| `config/serverDZ.cfg` | server settings; copied into the server dir each start |
| `mods.txt` | workshop mod list — `<id> [name] [server]` per line |
| `scripts/entrypoint.sh` | update → mods → launch |
| `scripts/install-mods.sh` | workshop items → `@mods` links + `.bikey` keys |
| `docker-compose.yml` | for Docker hosts (`docker compose up -d`) |
| `Makefile` | `build` / `up` / `down` / `update` / `logs` / `shell` |

## Mods

Add a line per mod to `mods.txt`:

```
1559212036 cf           # Community Framework (client mod)
1564026768 cot server   # Community Online Tools (server-side only)
```

Then `make restart` (auto-update on start downloads them). Workshop items are
linked into the server dir as `@name`, lowercased for the Linux binary, and
their `.bikey` files are copied into `keys/` so `verifySignatures=2` works.

## Persistence / wipe

World state lives in the `dayz-server-files` volume under
`mpmissions/dayzOffline.chernarusplus/storage_1`. To wipe, remove that
directory (or change `instanceId` in `serverDZ.cfg` for a separate hive).

Logs: `dayz-server-profiles` volume (`server_console.log`, RPT, admin logs).

## Useful targets

```
make up / down / restart / update / logs / shell / status / steam-login
```

`.env` knobs: `DAYZ_PORT`, `DAYZ_AUTO_UPDATE` (0 skips the steamcmd update on
start), `DAYZ_VALIDATE` (full file validation on update), `DAYZ_EXTRA_ARGS`.
