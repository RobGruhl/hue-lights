---
name: sync-servers
description: Sync hue-lights code between laptop and Mac Mini via GitHub. Pushes local changes, pulls on remote, and validates identical code.
disable-model-invocation: true
allowed-tools: Bash
argument-hint: [push|pull|validate|all]
---

# Sync Servers via GitHub

Synchronize hue-lights code between development laptop and Mac Mini server using GitHub as the source of truth.

## Usage

- `/sync-servers` or `/sync-servers all` - Full sync: commit, push, pull, validate
- `/sync-servers push` - Commit and push local changes to GitHub
- `/sync-servers pull` - Pull latest from GitHub on Mac Mini
- `/sync-servers validate` - Verify both machines have identical code

## Full Sync Workflow

### 1. Check local status
```bash
git status
git log --oneline -3
```

### 2. Commit and push (if changes exist)
```bash
git add -A
git commit -m "Sync: <describe changes>"
git push origin main
```

### 3. Pull on Mac Mini
```bash
ssh hue.local 'cd ~/Projects/hue-lights && git pull origin main'
```

### 4. Validate both machines match
```bash
# Get commit hashes
LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(ssh hue.local 'cd ~/Projects/hue-lights && git rev-parse HEAD')

echo "Local:  $LOCAL_HASH"
echo "Remote: $REMOTE_HASH"

if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
    echo "✓ Both machines are in sync"
else
    echo "✗ Machines are NOT in sync!"
fi
```

## Important Notes

- Always commit changes before syncing (never use scp for code)
- The Mac Mini server should be stopped before pulling changes
- After sync, restart the server: `ssh hue.local 'cd ~/Projects/hue-lights && python3.13 -u server.py &'`
