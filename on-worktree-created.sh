#!/bin/sh
# Herdr server `worktree.created` event handler.
set -eu

worktree_path="$(
  printf '%s' "$HERDR_PLUGIN_CONTEXT_JSON" |
    jq -er '.worktree.checkout_path'
)"

exec sh "$(dirname "$0")/worktree-copy.sh" "$worktree_path"
