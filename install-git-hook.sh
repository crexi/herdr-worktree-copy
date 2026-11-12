#!/bin/sh
# Installs the post-checkout hook that applies .worktree-copy, for worktrees that the
# Herdr desktop app (or plain `git worktree add`) creates.
# Usage: install-git-hook.sh [--force] <repo>...
set -eu

usage() {
  printf 'Usage: %s [--force] <repo>...\n' "$0" >&2
  exit 2
}

force=false
if [ "${1:-}" = "--force" ]; then
  force=true
  shift
fi
[ "$#" -gt 0 ] || usage

plugin_dir="$(cd "$(dirname "$0")" && pwd)"
install_dir="${WORKTREE_COPY_HOME:-$HOME/.local/share/worktree-copy}"

mkdir -p "$install_dir"
install -m 0755 "$plugin_dir/worktree-copy.sh" "$install_dir/worktree-copy.sh"
printf 'Installed %s\n' "$install_dir/worktree-copy.sh"

status=0
for repo in "$@"; do
  hooks_dir="$(git -C "$repo" rev-parse --path-format=absolute --git-path hooks)" || {
    status=1
    continue
  }
  hook="$hooks_dir/post-checkout"

  if [ -e "$hook" ] && ! grep -q 'worktree-copy' "$hook" && [ "$force" = false ]; then
    printf '%s already has a post-checkout hook; rerun with --force to replace it.\n' "$repo" >&2
    status=1
    continue
  fi

  mkdir -p "$hooks_dir"
  install -m 0755 "$plugin_dir/hooks/post-checkout" "$hook"
  printf 'Installed %s\n' "$hook"
done

exit "$status"
