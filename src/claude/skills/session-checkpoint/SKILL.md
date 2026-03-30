---
name: session-checkpoint
description: Save session progress to PROJECT-STATE.md and Ogham memory. Run manually via /checkpoint or automatically after significant tasks.
license: MIT
metadata:
  author: Ariadne
  version: "1.0"
---

## When to Use

- User says `/checkpoint`
- After completing a significant task (feature, bugfix, refactor)
- Before ending a session

## Steps

1. **Detect project name**

   ```bash
   basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
   ```

2. **Assess what changed this session**

   Review the conversation for:
   - **Decisions made** — architectural choices, library selections, approach changes
   - **Tasks completed** — features shipped, bugs fixed, tests passing
   - **Gotchas discovered** — unexpected behaviors, workarounds found
   - **Blockers encountered** — and how they were resolved

3. **Read current PROJECT-STATE.md**

   Read the file to understand what's already captured.

4. **Update PROJECT-STATE.md**

   Make targeted edits to the relevant sections:

   **Architecture Decisions** — add new decisions as 1-liners:
   ```markdown
   - {Decision}: {one-line summary of what and why}
   ```

   **Active Work** — move completed items to Recently Completed, add new items:
   ```markdown
   - [x] {completed item} (done {date})
   - [ ] {new item}
   ```

   **Recently Completed** — keep max 5 items, drop oldest:
   ```markdown
   - {item} ({date})
   ```

   **Known Gotchas** — add new discoveries:
   ```markdown
   - {description of issue and fix}
   ```

   **Current State** — update timestamp and status:
   ```markdown
   - Last updated: {YYYY-MM-DD}
   - Tests: {passing/failing/not-run}
   - Blockers: {none or description}
   ```

5. **Store to Ogham (if configured)**

   For each significant item found in step 2:

   **Decisions:**
   ```
   ogham_store_decision(
     decision: "{what was decided}",
     rationale: "{why}",
     alternatives: ["{what else was considered}"],
     tags: ["project:{name}", "type:decision"],
     source: "opencode"
   )
   ```

   **Gotchas:**
   ```
   ogham_store_memory(
     content: "{full description of the issue and fix}",
     tags: ["project:{name}", "type:gotcha"],
     source: "opencode"
   )
   ```

   **Patterns/Config:**
   ```
   ogham_store_memory(
     content: "{what was learned}",
     tags: ["project:{name}", "type:pattern"],
     source: "opencode"
   )
   ```

   Before storing, search Ogham first to avoid duplicates:
   ```
   ogham_hybrid_search("{brief description}", limit:3)
   ```
   Skip if a similar memory already exists with high confidence.

6. **Confirm**

   Output a brief summary of what was saved:
   ```
   **Checkpoint saved:**
   - Updated PROJECT-STATE.md: {what sections changed}
   - Stored to Ogham: {count} items
   ```

## Error Handling

- Ogham unavailable → update markdown only, note "Ogham offline — saved to markdown only"
- PROJECT-STATE.md missing → create it from template, then populate
- Nothing to save → note "No changes detected this session"

## Guardrails

- Never store duplicate memories (always check first)
- Keep PROJECT-STATE.md under 5KB — full detail goes to Ogham
- Ask before writing if significant architectural changes are detected
- "Recently Completed" max 5 items — oldest get dropped
