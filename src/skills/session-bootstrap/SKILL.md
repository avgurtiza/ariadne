---
name: session-bootstrap
description: Load project context at session start. Reads PROJECT-STATE.md and optionally queries Ogham memory for recent decisions and gotchas.
license: MIT
metadata:
  author: Ariadne
  version: "1.0"
---

## When to Use

Run at the start of every session to bootstrap project context. Saves the agent from reading multiple files to understand what the project is and what's being worked on.

## Steps

1. **Read PROJECT-STATE.md**

   Read `PROJECT-STATE.md` from the project root. This is the fast, always-available context layer.

   If the file doesn't exist, note "No PROJECT-STATE.md found — starting cold" and skip to step 4.

2. **Detect project name**

   Run:
   ```bash
   basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
   ```

3. **Try Ogham query (optional, graceful failure)**

   Check if Ogham MCP is available by attempting:
   ```
   ogham_hybrid_search("project:{project_name} current state recent decisions", limit=5)
   ```

   If Ogham is unavailable or the query fails, silently skip. Do not error or warn the user.

4. **Output summary**

   Output 5-10 bullets covering:
   - What the project is (from Identity section)
   - Current stage/status
   - Top 2-3 active work items
   - Any fresh Ogham memories not reflected in PROJECT-STATE.md
   - Any gotchas relevant to the current task (if one is known)

   Keep it under 10 lines. This is a quick orientation, not a full report.

5. **Check for stale state**

   If PROJECT-STATE.md has a "Last updated" date older than 7 days, note:
   > "PROJECT-STATE.md may be stale (last updated: {date}). Consider running `/checkpoint` to refresh."

## Output Format

```
**Project Context:**
- {project_name}: {one-line description}
- Stage: {current stage}
- Active: {top 3 work items}
- Gotchas: {1-2 most relevant if any}

{If Ogham provided fresh context:}
**Recent from memory:**
- {bullet from Ogham}
```

## Error Handling

- Missing PROJECT-STATE.md → proceed without it, suggest running install
- Ogham MCP not configured → skip silently
- Ogham query timeout → skip silently
- No git repo → use current directory name

## Guardrails

- Never fail the session start due to missing context
- Never read more than PROJECT-STATE.md (lazy-load other files as needed)
- Keep output under 10 bullets
