# Git for Agents

A fork of [git](https://github.com/git/git) with client-side configs to prevent AI agents (or anyone) from rewriting history via force push or commit amend.

## The Problem

AI coding agents will sometimes use `git push --force` or `git push --force-with-lease` to "fix" a messy commit history. This rewrites remote history, which is destructive and disruptive in collaborative repos. Agents should create new commits to make corrections, not rewrite the ones that already exist.

Similarly, agents will use `git commit --amend` to silently rewrite the last commit instead of creating a new one. This is less destructive than force push (it only affects local history), but it's still surprising and makes it harder to review what an agent actually did.

## What Changed

Two new config variables: **`push.allowForcePush`** and **`commit.allowAmend`**

### `push.allowForcePush`

When set to `false`, any `git push` that uses `--force`, `--force-with-lease`, or `--mirror` is blocked with a clear error message:

```
fatal:

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!
  !!     ____  _     ___   ____ _  _______ ____  _
  !!    | __ )| |   / _ \ / ___| |/ / ____|  _ \| |
  !!    |  _ \| |  | | | | |   | ' /|  _| | | | | |
  !!    | |_) | |__| |_| | |___| . \| |___| |_| |_|
  !!    |____/|_____\___/ \____|_|\_\_____|____/(_)
  !!
  !!    The user has configured this git client to prevent rewriting history.
  !!    (push.allowForcePush = false)
  !!
  !!    >>> Create a new commit to make corrections instead. <<<
  !!
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
```

The message is intentionally written to direct an AI agent toward the correct behavior: make a new commit instead.

### `commit.allowAmend`

When set to `false`, any `git commit --amend` is blocked with a clear error message:

```
fatal:

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!
  !!     ____  _     ___   ____ _  _______ ____  _
  !!    | __ )| |   / _ \ / ___| |/ / ____|  _ \| |
  !!    |  _ \| |  | | | | |   | ' /|  _| | | | | |
  !!    | |_) | |__| |_| | |___| . \| |___| |_| |_|
  !!    |____/|_____\___/ \____|_|\_\_____|____/(_)
  !!
  !!    The user has configured this git client to prevent amending commits.
  !!    (commit.allowAmend = false)
  !!
  !!    >>> Create a new commit to make corrections instead. <<<
  !!
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
```

Unlike force push, amending can be bypassed with `--no-verify` for cases where a human genuinely needs to amend. An AI agent won't add `--no-verify` on its own.

### Files Modified

- **`builtin/push.c`** — Config parsing and enforcement check
- **`builtin/commit.c`** — Config parsing and enforcement check for amend
- **`Documentation/config/push.adoc`** — Config documentation
- **`Documentation/config/commit.adoc`** — Config documentation
- **`t/t5556-push-allow-force.sh`** — 6 test cases
- **`t/t7528-commit-allow-amend.sh`** — 6 test cases

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
