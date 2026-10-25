#!/usr/bin/env bash
# DayZ dedicated server entrypoint.
# Flow: steamcmd update -> workshop mods -> copy config -> exec DayZServer.
set -euo pipefail

APP_ID="${DAYZ_APP_ID:-223350}"          # stable; 1042420 = experimental
WORKSHOP_APP_ID="${DAYZ_WORKSHOP_APP_ID:-221100}"

SERVER_DIR="${DAYZ_SERVER_DIR:-/opt/dayz/server}"
CONFIG_DIR="${DAYZ_CONFIG_DIR:-/opt/dayz/config}"
PROFILES_DIR="${DAYZ_PROFILES_DIR:-/opt/dayz/profiles}"
MODS_FILE="${DAYZ_MODS_FILE:-/opt/dayz/mods.txt}"
PORT="${DAYZ_PORT:-2302}"

log() { printf '[dayz] %s\n' "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

[ -n "${STEAM_USERNAME:-}" ] || die "STEAM_USERNAME is not set. The DayZ server cannot be downloaded anonymously - set a Steam account that owns DayZ in .env."
[ -n "${STEAM_PASSWORD:-}" ] || die "STEAM_PASSWORD is not set (see .env)."

mkdir -p "$SERVER_DIR" "$PROFILES_DIR"

STEAM_LOGIN=("$STEAM_USERNAME" "$STEAM_PASSWORD")
[ -n "${STEAM_GUARD_CODE:-}" ] && STEAM_LOGIN+=("$STEAM_GUARD_CODE")

# --- SteamCMD update (server + workshop mods in a single login) --------------
if [ "${DAYZ_AUTO_UPDATE:-1}" = "1" ]; then
    ARGS=(+force_install_dir "$SERVER_DIR" +login "${STEAM_LOGIN[@]}" +app_update "$APP_ID")
    [ "${DAYZ_VALIDATE:-0}" = "1" ] && ARGS+=(validate)

    while read -r id _; do
        [[ "$id" =~ ^[0-9]+$ ]] && ARGS+=(+workshop_download_item "$WORKSHOP_APP_ID" "$id")
    done < "$MODS_FILE" 2>/dev/null || true

    log "steamcmd: updating app $APP_ID"
    steamcmd "${ARGS[@]}" +quit
else
    log "DAYZ_AUTO_UPDATE=0, skipping steamcmd update"
fi

# --- Mods --------------------------------------------------------------------
MOD_ARGS=()
if [ -f "$MODS_FILE" ]; then
    # shellcheck source=install-mods.sh
    source /opt/dayz/bin/install-mods.sh
    mapfile -t MOD_ARGS < <(install_mods "$SERVER_DIR" "$MODS_FILE")
    log "mod args: ${MOD_ARGS[*]:-<none>}"
fi

# --- Config -------------------------------------------------------------------
[ -f "$CONFIG_DIR/serverDZ.cfg" ] || die "missing $CONFIG_DIR/serverDZ.cfg"
cp -f "$CONFIG_DIR/serverDZ.cfg" "$SERVER_DIR/serverDZ.cfg"

cd "$SERVER_DIR"
[ -x ./DayZServer ] || die "DayZServer binary not found in $SERVER_DIR - first run must complete a steamcmd update (DAYZ_AUTO_UPDATE=1)."

CMD=(./DayZServer
    -config=serverDZ.cfg
    "-port=$PORT"
    "-profiles=$PROFILES_DIR"
    -dologs -adminlog -netlog -freezecheck
    "${MOD_ARGS[@]}"
)

[ -n "${DAYZ_EXTRA_ARGS:-}" ] && read -r -a EXTRA <<< "$DAYZ_EXTRA_ARGS" && CMD+=("${EXTRA[@]}")

log "starting: ${CMD[*]}"
exec "${CMD[@]}"
