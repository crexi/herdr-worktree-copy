# Herdr Worktree Copy

A [Herdr](https://herdr.dev) plugin that copies local files and symlinks shared directories into every worktree created through Herdr.

The plugin reads a `.worktree-copy` manifest from the repository's main worktree whenever Herdr emits `worktree.created`.

## Install

```bash
herdr plugin install crexi/herdr-worktree-copy
```

Requirements:

- Herdr 0.7.0 or newer
- Git
- `jq`
- `rsync`
- macOS or Linux

## Configure a repository

Add `.worktree-copy` at the repository root. Each entry is relative to that root:

```text
# Copy files or directories
.env
backend/.env
frontend/.npmrc

# Symlink shared files or directories
$backend/node_modules
$frontend/node_modules
```

- Plain entries are copied from the main worktree into the new worktree.
- Entries prefixed with `$` are symlinked from the main worktree.
- Blank lines and lines beginning with `#` are ignored.
- Missing source paths produce a warning and are skipped.
- Existing symlink destinations are left unchanged.
- Repositories without `.worktree-copy` are skipped.

Use copied entries for files that may diverge between worktrees, such as `.env` files. Use symlink entries for large shared directories, such as `node_modules`.

## Inspect executions

```bash
herdr plugin log list --plugin crexi.worktree-copy --limit 20
```

## Local development

```bash
git clone https://github.com/crexi/herdr-worktree-copy.git
herdr plugin link ./herdr-worktree-copy
```
