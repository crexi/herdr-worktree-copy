#!/bin/sh
# End-to-end checks against a throwaway repository: the git hook path (Herdr desktop
# app, plain `git worktree add`) and the Herdr server event path.
set -eu

plugin_dir="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
export WORKTREE_COPY_HOME="$scratch/install"

failures=0
check() {
  description="$1"
  shift
  if "$@"; then
    printf 'ok   %s\n' "$description"
  else
    printf 'FAIL %s\n' "$description"
    failures=$((failures + 1))
  fi
}

repo="$scratch/repo"
git init -q "$repo"
git -C "$repo" -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m init
mkdir -p "$repo/app" "$repo/node_modules/pkg"
printf 'SECRET=1\n' > "$repo/app/.env"
printf '{}\n' > "$repo/node_modules/pkg/package.json"
cat > "$repo/.worktree-copy" <<'EOF'
# Copy
app/.env
missing/.env

# Symlink
$node_modules
EOF

sh "$plugin_dir/install-git-hook.sh" "$repo" >/dev/null

hook_tree="$scratch/hook-tree"
git -C "$repo" worktree add -q -b hook-branch "$hook_tree" 2>"$scratch/hook.log"
check "git hook copies listed files" test -f "$hook_tree/app/.env"
check "git hook symlinks \$ entries" test -L "$hook_tree/node_modules"
check "git hook reports missing sources" grep -q 'Skipping missing copy source: missing/.env' "$scratch/hook.log"

server_tree="$scratch/server-tree"
git -C "$repo" worktree add -q --no-checkout -b server-branch "$server_tree"
git -C "$server_tree" checkout -q server-branch
check "git hook skips worktrees added without a checkout" test ! -e "$server_tree/app/.env"
HERDR_PLUGIN_CONTEXT_JSON="{\"worktree\":{\"checkout_path\":\"$server_tree\"}}" \
  sh "$plugin_dir/on-worktree-created.sh" >/dev/null 2>&1
check "server event copies listed files" test -f "$server_tree/app/.env"
check "server event symlinks \$ entries" test -L "$server_tree/node_modules"

sh "$plugin_dir/worktree-copy.sh" "$hook_tree" >/dev/null 2>"$scratch/rerun.log"
check "running twice leaves our symlinks alone" sh -c "! grep -q 'Skipping existing symlink target' '$scratch/rerun.log'"

git -C "$repo" checkout -b other >"$scratch/checkout.log" 2>&1
check "plain branch checkouts are ignored" sh -c "! grep -q 'Worktree setup' '$scratch/checkout.log'"

foreign="$scratch/foreign"
git init -q "$foreign"
printf '#!/bin/sh\nexit 0\n' > "$foreign/.git/hooks/post-checkout"
check "an unrelated post-checkout hook is not replaced" \
  sh -c "! sh '$plugin_dir/install-git-hook.sh' '$foreign' 2>/dev/null"

if [ "$failures" -gt 0 ]; then
  printf '%s check(s) failed\n' "$failures"
  exit 1
fi
printf 'All checks passed\n'
