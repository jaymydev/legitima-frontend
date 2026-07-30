#!/usr/bin/env bash
# Nettoyage des caches Xcode : DerivedData, simulateurs unavailable, caches CocoaPods.
# Silencieux par défaut (tout va dans le log) ; affiche l'espace libéré à la fin.
# Usage : scripts/xcode-clean.sh [--verbose]

set -u

LOG_FILE="${TMPDIR:-/tmp}/xcode-clean.log"
VERBOSE=0
[ "${1:-}" = "--verbose" ] && VERBOSE=1

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
  [ "$VERBOSE" -eq 1 ] && echo "$*"
}

# Taille d'un chemin en Ko (0 si absent)
size_kb() {
  [ -e "$1" ] && du -sk "$1" 2>/dev/null | awk '{print $1}' || echo 0
}

human() {
  awk -v kb="$1" 'BEGIN {
    if (kb >= 1048576) printf "%.1f Go", kb/1048576
    else if (kb >= 1024) printf "%.1f Mo", kb/1024
    else printf "%d Ko", kb
  }'
}

DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
PODS_CACHE="$HOME/Library/Caches/CocoaPods"

log "=== Début du nettoyage Xcode ==="

before_kb=$(( $(size_kb "$DERIVED_DATA") + $(size_kb "$PODS_CACHE") ))

# 1. DerivedData
if [ -d "$DERIVED_DATA" ]; then
  rm -rf "$DERIVED_DATA"/* 2>> "$LOG_FILE"
  log "DerivedData vidé"
else
  log "DerivedData absent, rien à faire"
fi

# 2. Simulateurs unavailable
if command -v xcrun >/dev/null 2>&1; then
  xcrun simctl delete unavailable >> "$LOG_FILE" 2>&1 \
    && log "Simulateurs unavailable supprimés" \
    || log "simctl a échoué (non bloquant)"
else
  log "xcrun introuvable, simulateurs ignorés"
fi

# 3. Caches CocoaPods (seulement si CocoaPods est installé)
if command -v pod >/dev/null 2>&1; then
  pod cache clean --all >> "$LOG_FILE" 2>&1 \
    && log "Cache CocoaPods vidé" \
    || log "pod cache clean a échoué (non bloquant)"
fi
# Le dossier de cache peut exister même sans la commande pod
if [ -d "$PODS_CACHE" ]; then
  rm -rf "$PODS_CACHE"/* 2>> "$LOG_FILE"
  log "Dossier de cache CocoaPods vidé"
fi

after_kb=$(( $(size_kb "$DERIVED_DATA") + $(size_kb "$PODS_CACHE") ))
freed_kb=$(( before_kb - after_kb ))
[ "$freed_kb" -lt 0 ] && freed_kb=0

log "=== Fin du nettoyage — espace libéré : $(human "$freed_kb") ==="
echo "🧹 Espace libéré : $(human "$freed_kb")"

exit 0
