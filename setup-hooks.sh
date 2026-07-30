#!/usr/bin/env bash
# Installe les git hooks du projet (macOS).
# À exécuter une seule fois après le clone : ./setup-hooks.sh

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "❌ Ce script doit être exécuté depuis le dépôt git." >&2
  exit 1
}

HOOKS_SRC="$REPO_ROOT/scripts/hooks"
HOOKS_DST="$(git rev-parse --git-path hooks)"

[ -d "$HOOKS_SRC" ] || { echo "❌ Dossier $HOOKS_SRC introuvable." >&2; exit 1; }
mkdir -p "$HOOKS_DST"

installed=0
for src in "$HOOKS_SRC"/*; do
  [ -f "$src" ] || continue
  name=$(basename "$src")
  dst="$HOOKS_DST/$name"

  # Sauvegarde un hook existant différent du nôtre
  if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
    cp "$dst" "$dst.backup"
    echo "⚠️  Hook '$name' existant sauvegardé dans $name.backup"
  fi

  cp "$src" "$dst"
  chmod +x "$dst"
  chmod +x "$REPO_ROOT/scripts/xcode-clean.sh" 2>/dev/null || true
  echo "✅ Hook '$name' installé"
  installed=$((installed + 1))
done

if [ "$installed" -eq 0 ]; then
  echo "Aucun hook à installer."
else
  echo ""
  echo "🎉 $installed hook(s) installé(s). Le nettoyage Xcode se lancera après chaque commit."
fi
