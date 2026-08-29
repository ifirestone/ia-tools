#!/usr/bin/env bash
set -euo pipefail

# Symlinkea cada skill del repo a los directorios locales que leen los
# distintos harnesses de IA:
#   - ~/.claude/skills: Claude Code
#   - ~/.agents/skills: Codex y otros harnesses compatibles con Agent Skills
# Cada entrada es un symlink hacia este repo, así que un `git pull` alcanza
# para tener las skills instaladas siempre al día.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESTS=("$HOME/.claude/skills" "$HOME/.agents/skills")

names=()
srcs=()
while IFS= read -r -d '' skill_md; do
  src="$(dirname "$skill_md")"
  names+=("$(basename "$src")")
  srcs+=("$src")
done < <(find "$REPO/skills" -name SKILL.md -not -path '*/node_modules/*' -not -path '*/deprecated/*' -print0)

for DEST in "${DESTS[@]}"; do
  # Si $DEST es un symlink que resuelve dentro de este repo, terminaríamos
  # escribiendo los symlinks de cada skill de vuelta en el propio árbol
  # skills/ del repo. Detectarlo y frenar en vez de ensuciar el working copy.
  if [ -L "$DEST" ]; then
    resolved="$(readlink -f "$DEST")"
    case "$resolved" in
      "$REPO"|"$REPO"/*)
        echo "error: $DEST es un symlink hacia este repo ($resolved)." >&2
        echo "Borralo (rm \"$DEST\") y volvé a correr el script; se recreará como directorio real." >&2
        exit 1
        ;;
    esac
  fi

  mkdir -p "$DEST"

  for i in "${!names[@]}"; do
    name="${names[$i]}"
    src="${srcs[$i]}"
    target="$DEST/$name"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      rm -rf "$target"
    fi

    ln -sfn "$src" "$target"
    echo "linked $name -> $src ($DEST)"
  done
done
