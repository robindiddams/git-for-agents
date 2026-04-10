---
name: update-git
description: Updates this fork to the latest git/git upstream. Rebases custom commits (allowForcePush, allowAmend) onto upstream/master, resolves conflicts if possible, tests the build, and force pushes. Use when you want to sync with the latest git development.
---

# Update Git Fork

Updates this fork to the latest from git/git upstream while preserving custom commits.

## Custom Commits

This fork contains custom commits that must be preserved on top of upstream. The key changes are:

1. `push.allowForcePush` config in `builtin/push.c`
2. `commit.allowAmend` config in `builtin/commit.c`
3. `AGENTS.md` documentation

The rebase will preserve all commits between `upstream/master` and the current HEAD.

## Process

### 1. Setup Upstream Remote

```bash
# Check if upstream exists
git remote | grep upstream

# If not, add it
git remote add upstream git@github.com:git/git.git
```

### 2. Fetch Latest

```bash
git fetch upstream
```

### 3. Save Current State

```bash
# Save the current branch and SHA for potential rollback
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CURRENT_SHA=$(git rev-parse HEAD)
```

### 4. Rebase Onto Upstream

```bash
git rebase upstream/master
```

### 5. Handle Conflicts (if any)

If rebase fails with conflicts:

1. Identify conflicted files: `git diff --name-only --diff-filter=U`
2. For each conflicted file, read it and resolve the conflict:
   - Look for `<<<<<<<`, `=======`, `>>>>>>>` markers
   - The custom code to preserve is in `builtin/push.c` and `builtin/commit.c`
   - For `builtin/push.c`: preserve the `allow_force_push` variable declaration, config parsing, and the die() check before push
   - For `builtin/commit.c`: preserve the `allow_amend` variable declaration, config parsing, and the die() check before amend
3. After resolving: `git add <file>` and `git rebase --continue`
4. If resolution is not straightforward or tests fail, abort and report failure

### 6. Build and Test

```bash
make -j$(nproc)
make test  # or a subset of relevant tests
```

Specifically run the custom tests:
```bash
./t/t5556-push-allow-force.sh
./t/t7528-commit-allow-amend.sh
```

If build or tests fail, abort the rebase and report failure.

### 7. Force Push

Use system git (not this fork's git) to bypass the allowForcePush restriction:

```bash
/usr/bin/git push --force origin main
```

If system git is not available at `/usr/bin/git`, find an alternative:
```bash
which -a git  # Find all git binaries
```

### 8. Report Results

Write `REBASE_INFO.md` in the repo root:

**On success:**
```markdown
# Rebase Status: SUCCESS

Upstream SHA: <sha of upstream/master>
Previous HEAD: <old sha before rebase>
New HEAD: <new sha after rebase>

## Notes
- <any adjustments made during conflict resolution>
- tests passed
```

**On failure:**
```markdown
# Rebase Status: FAILED

Upstream SHA: <sha of upstream/master>
Previous HEAD: <old sha before rebase - where we reset back to>

## Reason
<why it failed - conflict type, test failures, etc>

## Action Required
<what the user needs to do manually>
```

On failure, reset back to original state:
```bash
git rebase --abort  # if mid-rebase
# or
git reset --hard <original-sha>  # if rebase completed but tests failed
```

DO NOT force push on failure.

### 9. Commit and Push Report

After writing REBASE_INFO.md, commit it and force push again:

```bash
git add REBASE_INFO.md
git commit -m "update REBASE_INFO after sync with upstream"
<path-to-system-git> push --force origin master
```

## Key Code to Preserve

When resolving conflicts, search for these unique identifiers in the code:

### builtin/push.c

Search for `allow_force_push` - there are three locations:
1. Variable declaration: `static int allow_force_push = -1;`
2. Config parsing: `!strcmp(k, "push.allowforcepush")`
3. Check before push: `if (allow_force_push == 0)` with the ASCII art banner

### builtin/commit.c

Search for `allow_amend` - there are three locations:
1. Variable declaration: `static int allow_amend = -1;`
2. Check before amend: `if (allow_amend == 0 && amend && !no_verify)` with the ASCII art banner
3. Config parsing: `!strcmp(k, "commit.allowamend")`

## Usage

```
/skill:update-git
```

The agent will execute the full workflow and report results in REBASE_INFO.md.
