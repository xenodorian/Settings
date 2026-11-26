#!/usr/bin/env bash
# Block Agent (subagent) calls unless the model is haiku.
python3 -I -c '
import json, sys
d = json.load(sys.stdin)
m = str(d.get("tool_input", {}).get("model") or "").lower()
if "haiku" not in m:
    sys.stderr.write("Blocked: subagents must use model haiku. Retry with model: \"haiku\".\n")
    sys.exit(2)
'
