# Git for Agents

A fork of [git](https://github.com/git/git) with a client-side config to prevent AI agents (or anyone) from rewriting history via force push.

## The Problem

AI coding agents will sometimes use `git push --force` or `git push --force-with-lease` to "fix" a messy commit history. This rewrites remote history, which is destructive and disruptive in collaborative repos. Agents should create new commits to make corrections, not rewrite the ones that already exist.

## What Changed

A single new config variable: **`push.allowForcePush`**

When set to `false`, any `git push` that uses `--force`, `--force-with-lease`, or `--mirror` is blocked with a clear error message:

```
fatal: The user has configured this git client to prevent rewriting history.
Create a new commit to make corrections instead of force pushing.
```

The message is intentionally written to direct an AI agent toward the correct behavior: make a new commit instead.

### Files Modified

- **`builtin/push.c`** — Config parsing and enforcement check
- **`Documentation/config/push.adoc`** — Config documentation
- **`t/t5556-push-allow-force.sh`** — 6 test cases

### How It Works

1. A static variable `allow_force_push` is read from config via `git_push_config()`
2. After all push flags are resolved (including `--mirror` implying `--force`), the check runs
3. If the config is `false` and any force mechanism is detected, `git push` dies with the error message
4. Normal (non-force) pushes are unaffected
5. Default behavior is unchanged — the config must be explicitly set to `false`

## Install from Source

```bash
git clone git@github.com:robindiddams/git-for-agents.git
cd git-for-agents
make -j$(nproc)
sudo ln -sf "$(pwd)/git" /usr/local/bin/git
```

Verify:

```bash
which git
# /usr/local/bin/git
```

If you previously installed git via Homebrew, uninstall it first:

```bash
brew uninstall git
# or if other packages depend on it:
brew uninstall --ignore-dependencies git
```

## Usage

Enable globally (applies to all repos):

```bash
git config --global push.allowForcePush false
```

Enable for a single repo:

```bash
git config push.allowForcePush false
```

Disable (re-allow force push):

```bash
git config --global push.allowForcePush true
# or unset it entirely:
git config --global --unset push.allowForcePush
```

## What Gets Blocked

| Command | Blocked? |
|---|---|
| `git push --force` | Yes |
| `git push -f` | Yes |
| `git push --force-with-lease` | Yes |
| `git push --mirror` | Yes (implies `--force`) |
| `git push` | No |
| `git push origin main` | No |

## What Doesn't Get Blocked

- Normal pushes (fast-forward)
- The `+` prefix in refspecs (e.g., `git push origin +main:main`) — this is a lower-level mechanism that's less likely to be used accidentally by agents
- Server-side force push protection (e.g., `receive.denyNonFastForwards`) is a separate mechanism and still works independently
