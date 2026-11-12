# Herdr Worktree Copy

Copies local files and symlinks shared directories into every new worktree of a repository. It works with the [Herdr](https://herdr.dev) desktop app, the Herdr server, and plain `git worktree add`.

It reads a `.worktree-copy` manifest from the repository's main worktree.

## Requirements

- Git
- `rsync`
- macOS or Linux
- For the Herdr server plugin: Herdr 0.7.0 or newer, and `jq`

## Install for the Herdr desktop app

The desktop app creates worktrees with `git worktree add`, so a `post-checkout` git hook applies the manifest. Install the hook in each clone, on each machine where you create worktrees:

```bash
git clone https://github.com/crexi/herdr-worktree-copy.git
herdr-worktree-copy/install-git-hook.sh ~/work/my-repo ~/work/other-repo
```

The installer copies `worktree-copy.sh` to `~/.local/share/worktree-copy` and writes `.git/hooks/post-checkout` in each repository. Set `WORKTREE_COPY_HOME` to use a different folder.

If a repository already has a `post-checkout` hook, the installer leaves it alone and reports an error. Rerun with `--force` to replace that hook.

For a remote machine in the desktop app, run the installer on that machine.

## Install for the Herdr server

```bash
herdr plugin install crexi/herdr-worktree-copy
```

The plugin runs when Herdr emits `worktree.created`. You can install the git hook too. The second run changes nothing.

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

## Apply the manifest by hand

```bash
herdr-worktree-copy/worktree-copy.sh <worktree-path>
```

## Inspect executions

The git hook prints its output in the terminal that ran `git worktree add`. For the Herdr server plugin:

```bash
herdr plugin log list --plugin crexi.worktree-copy --limit 20
```

## Local development

```bash
git clone https://github.com/crexi/herdr-worktree-copy.git
herdr plugin link ./herdr-worktree-copy
sh herdr-worktree-copy/tests/run.sh
```
