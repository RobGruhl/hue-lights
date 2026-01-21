# Override Detection - Test Plan & Notes

## Test Plan

1. SSH to hue.local
2. Restart the server: `systemctl --user restart hue-lights`
3. Start an animation via the control panel
4. Test override scenarios:
   - Turn off a light via Hue app → animation should stop
   - Change color via Hue app → animation should stop
   - Use physical dimmer → animation should stop
5. Check `/health` endpoint shows `event_stream_connected: true`
6. Check server logs for "Override detected" messages
7. Verify UI updates to show animation stopped
8. Verify no zombie processes remain

## TODO: Bridge Traffic Limits

**Problem:** The Hue bridge has become unresponsive to the app during heavy animation use. Need to understand the bridge's capacity limits.

**Investigation needed:**
- How many API requests/second can the bridge handle?
- Does the EventStream connection count against rate limits?
- What's the relationship between number of lights animated and bridge load?
- Are there official Philips docs on rate limiting?

**Solution: Implement graceful animation cap**
- Track total lights being animated across all rooms
- Set a configurable max (e.g., 20-25 lights at once?)
- Warn user when approaching limit
- Refuse to start new animations that would exceed cap
- Consider staggering API calls in animations (already somewhat done with `wait`)

**Metrics to collect:**
- Commands sent per second during different animations
- Bridge response times under load
- Point at which bridge becomes unresponsive
