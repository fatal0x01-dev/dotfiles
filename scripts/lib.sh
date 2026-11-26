#!/usr/bin/env bash
# Shared helpers for every stage. Sourced, not executed.

# ---- colours / logging ----------------------------------------------------
if [[ -t 1 ]]; then
    _c_reset=$'\e[0m'; _c_blue=$'\e[1;34m'; _c_grn=$'\e[1;32m'
    _c_yel=$'\e[1;33m'; _c_red=$'\e[1;31m'; _c_dim=$'\e[2m'
else
    _c_reset= _c_blue= _c_grn= _c_yel= _c_red= _c_dim=
fi
log()    { printf '%s==>%s %s\n'  "$_c_blue" "$_c_reset" "$*"; }
ok()     { printf '%s  ✓%s %s\n'  "$_c_grn"  "$_c_reset" "$*"; }
warn()   { printf '%s  !%s %s\n'  "$_c_yel"  "$_c_reset" "$*" >&2; }
die()    { printf '%s  ✗ %s%s\n'  "$_c_red"  "$*" "$_c_reset" >&2; exit 1; }
banner() { printf '\n%s┌─ %s ─┐%s\n' "$_c_blue" "$*" "$_c_reset"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# Run a stage script, aborting the whole install if it hard-fails.
run_stage() {
    local s="$1"
    [[ -f "$s" ]] || die "Missing stage script: $s"
    log "Stage: $(basename "$s")"
    # shellcheck disable=SC1090
    bash "$s" || die "Stage failed: $(basename "$s")"
}

# ---- shared state (written by 00-preflight.sh, read by later stages) -------
export STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/macos-kde-install.$$"
export STATE_FILE="/tmp/macos-kde-install.state"   # survives across stages
export BUILD_DIR="$HOME/.cache/macos-kde-dotfiles/build"
export BACKUP_DIR="$HOME/.config/.macos-kde-backup-$(date +%Y%m%d-%H%M%S)"

# kconfig CLI differs by name across installs; resolve once.
kwrite() { if have_cmd kwriteconfig6; then kwriteconfig6 "$@"; else kwriteconfig5 "$@"; fi; }
kread()  { if have_cmd kreadconfig6;  then kreadconfig6  "$@"; else kreadconfig5  "$@"; fi; }
qd()     { if have_cmd qdbus6;         then qdbus6        "$@"; else qdbus         "$@"; fi; }

# Persist a key=value pair for later stages.
state_set() { grep -v "^$1=" "$STATE_FILE" 2>/dev/null > "$STATE_FILE.tmp" || true; echo "$1=$2" >> "$STATE_FILE.tmp"; mv "$STATE_FILE.tmp" "$STATE_FILE"; }
state_get() { [[ -f "$STATE_FILE" ]] && grep "^$1=" "$STATE_FILE" | tail -1 | cut -d= -f2- || true; }
