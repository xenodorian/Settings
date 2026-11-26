#!/usr/bin/env bash
# Block branch creation and any push that does not target main.
python3 -I -c '
import json, re, subprocess, sys
d = json.load(sys.stdin)
cmd = str(d.get("tool_input", {}).get("command") or "")
def block(msg):
    sys.stderr.write("Blocked: " + msg + "\n")
    sys.exit(2)
cur = subprocess.run(["git","branch","--show-current"],capture_output=True,text=True).stdout.strip()
for seg in re.split(r"&&|\|\||;|\||\n", cmd):
    t = seg.split()
    if "git" not in t: continue
    t = t[t.index("git")+1:]
    t = [x for x in t if x not in ("-C",)]
    if not t: continue
    sub, rest = t[0], t[1:]
    if sub in ("checkout","switch") and any(a in ("-b","-B","-c","-C","--orphan") or re.fullmatch(r"-[a-zA-Z]*[bBcC]", a) for a in rest):
        block("creating branches is not allowed. Use main.")
    if sub == "branch":
        pos = [a for a in rest if not a.startswith("-")]
        flags = [a for a in rest if a.startswith("-")]
        readonly = {"--list","-l","-a","-r","-v","-vv","--show-current","--contains","--merged","--no-merged","-d","-D","--delete"}
        if pos and not (set(flags) & readonly):
            block("creating branches is not allowed. Use main.")
    if sub == "worktree" and rest[:1] == ["add"]:
        block("creating branches/worktrees is not allowed. Use main.")
    if sub == "push":
        pos = [a for a in rest if not a.startswith("-")]
        refs = pos[1:]
        if any(a in ("--all","--mirror","--tags") for a in rest):
            block("push only main.")
        if not refs:
            if cur != "main":
                block("current branch is %r. Push only main." % cur)
        for r in refs:
            if r.lstrip("+").split(":")[-1] != "main":
                block("pushes must target main only.")
'
