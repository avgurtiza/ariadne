---
description: Load project context at session start (reads PROJECT-STATE.md + Ogham)
---

Load project context at session start.

Invoke the `session-bootstrap` skill. It will:
1. Read PROJECT-STATE.md for project snapshot
2. Try Ogham query for recent decisions (if configured)
3. Output a concise summary of what the project is, what's active, and any gotchas
