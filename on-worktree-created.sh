#!/bin/sh
set -eu

worktree_path="$(
  printf '%s' "$HERDR_PLUGIN_CONTEXT_JSON" |
    jq -er '.worktree.checkout_path'
)"

source_root="$(
  git -C "$worktree_path" worktree list --porcelain |
    awk 'NR == 1 && /^worktree / { sub(/^worktree /, ""); print; exit }'
)"

if [ -z "$source_root" ]; then
  printf 'Could not determine the main worktree for %s.\n' "$worktree_path" >&2
  exit 1
fi

manifest="$source_root/.worktree-copy"
if [ ! -f "$manifest" ]; then
  printf 'No .worktree-copy found in %s; skipping setup.\n' "$source_root"
  exit 0
fi

copy_list="$(mktemp)"
trap 'rm -f "$copy_list"' EXIT HUP INT TERM
symlink_count=0
copy_count=0

while IFS= read -r raw_item || [ -n "$raw_item" ]; do
  item="$(printf '%s' "$raw_item" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

  case "$item" in
    ''|'#'*)
      continue
      ;;
    '$'*)
      relative_path="${item#\$}"
      source_path="$source_root/$relative_path"
      target_path="$worktree_path/$relative_path"

      if [ ! -e "$source_path" ]; then
        printf 'Skipping missing symlink source: %s\n' "$relative_path" >&2
        continue
      fi

      if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        printf 'Skipping existing symlink target: %s\n' "$target_path" >&2
        continue
      fi

      mkdir -p "$(dirname "$target_path")"
      ln -s "$source_path" "$target_path"
      printf 'Symlinked: %s -> %s\n' "$target_path" "$source_path"
      symlink_count=$((symlink_count + 1))
      ;;
    *)
      if [ ! -e "$source_root/$item" ]; then
        printf 'Skipping missing copy source: %s\n' "$item" >&2
        continue
      fi

      printf '%s\n' "$item" >> "$copy_list"
      copy_count=$((copy_count + 1))
      ;;
  esac
done < "$manifest"

if [ "$copy_count" -gt 0 ]; then
  if ! command -v rsync >/dev/null 2>&1; then
    printf 'rsync is required to copy entries from %s.\n' "$manifest" >&2
    exit 1
  fi

  rsync -aH --links --relative --files-from="$copy_list" \
    "$source_root/" "$worktree_path/"
fi

printf 'Worktree setup complete: copied %s entr%s and symlinked %s entr%s.\n' \
  "$copy_count" "$(if [ "$copy_count" -eq 1 ]; then printf 'y'; else printf 'ies'; fi)" \
  "$symlink_count" "$(if [ "$symlink_count" -eq 1 ]; then printf 'y'; else printf 'ies'; fi)"
