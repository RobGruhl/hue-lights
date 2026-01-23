---
name: clean-start
description: Completely reset and restart hue-lights server on Mac Mini. Stops launchd, kills processes, clears state, verifies port free, starts fresh.
disable-model-invocation: true
allowed-tools: Bash
---

# Clean Start Skill

Completely reset and restart the hue-lights server on Mac Mini. This handles all discovered nuances around process management, launchd, ports, and state files.

## Workflow

Execute these steps in order:

### 1. Stop launchd service (prevents auto-restart)
```bash
ssh hue.local 'launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.hue.server.plist 2>/dev/null || true'
```

### 2. Kill all Python server processes
```bash
ssh hue.local 'pkill -9 -f "python.*server.py" 2>/dev/null || true'
```

### 3. Kill any orphaned scene processes
```bash
ssh hue.local 'pkill -9 -f "run-scene.sh" 2>/dev/null || true'
```

### 4. Clear state files
```bash
ssh hue.local 'rm -f ~/Projects/hue-lights/.scene-state.json'
```

### 5. Turn off all lights (optional - ask user first)
If user wants lights reset to off state:
```bash
ssh hue.local 'cd ~/Projects/hue-lights && source .env && for id in $(curl -sk "https://$HUE_BRIDGE_IP/clip/v2/resource/light" -H "hue-application-key: $HUE_USERNAME" | python3 -c "import sys,json; [print(l[\"id\"]) for l in json.load(sys.stdin)[\"data\"]]"); do curl -sk -X PUT "https://$HUE_BRIDGE_IP/clip/v2/resource/light/$id" -H "hue-application-key: $HUE_USERNAME" -d "{\"on\":{\"on\":false}}"; done'
```

### 6. Clear logs (recommended for clean start)
```bash
ssh hue.local 'truncate -s 0 ~/Projects/hue-lights/logs/server.log ~/Projects/hue-lights/logs/server.error.log 2>/dev/null || true'
```

### 7. Verify port 8080 is free
```bash
ssh hue.local 'lsof -i :8080 || echo "Port 8080 is free"'
```

If port is still in use, force kill:
```bash
ssh hue.local 'kill -9 $(lsof -t -i :8080) 2>/dev/null || true'
```

### 8. Start server fresh
Run as background task:
```bash
ssh hue.local 'cd ~/Projects/hue-lights && /opt/homebrew/bin/python3.13 -u server.py 2>&1'
```

Use `run_in_background: true` on this Bash call.

Wait ~6 seconds for startup (EventStream may timeout once before connecting).

### 9. Verify server is healthy
```bash
curl -s --max-time 5 http://hue.local:8080/health | python3 -m json.tool
```

Confirm:
- Response received (server is listening)
- `event_stream_connected: true` (EventStream monitoring active)

Optional socket state check:
```bash
ssh hue.local 'lsof -i :8080 | grep LISTEN'
```
Should show `LISTEN` state.

## Success Criteria

1. Health check returns valid JSON with `status: ok`
2. Port 8080 shows `LISTEN` state
3. Control panel accessible at http://hue.local:8080/control-panel.html

## Notes

- Server can now be started via any SSH method (interactive or non-interactive)
- The socket CLOSED bug was fixed by manual socket initialization in server.py
- EventStream connection may take a few seconds to establish after server start
