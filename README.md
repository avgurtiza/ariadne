# Ariadne

Give your AI agent persistent project memory. No more re-explaining your architecture, decisions, and current work at every session start.

**Compatible agents:** OpenCode, KiloCode, Claude Code, Gemini CLI
**Platforms:** macOS, Linux, Windows WSL

## What It Does

1. **`PROJECT-STATE.md`** — A lightweight snapshot of your project (~2-5KB). Always available.
2. **`session-bootstrap` skill** — Loads context at session start. Optionally queries Ogham MCP.
3. **`session-checkpoint` skill** — Saves progress after tasks or at session end.
4. **OpenCode plugin** — Auto-checkpoint when session goes idle, project state survives compaction.

## Install

```bash
git clone https://github.com/avgurtiza/ariadne.git /tmp/ariadne
cd /tmp/ariadne
./install.sh /path/to/your/project
```

Detects agents, OS, copies skills + plugin, patches context files. Safe to re-run.

## How It Works

### Automatic (OpenCode/KiloCode)

The plugin handles:
- **Auto-checkpoint** on `session.idle` — saves progress when you stop chatting
- **Compaction survival** — project state is injected during context compaction

### Manual (All Agents)

Your context file (AGENTS.md, GEMINI.md) is patched with:

```
Session Start:  run /session-bootstrap  (or ask agent to run session-bootstrap)
Session End:    run /checkpoint          (or ask agent to run session-checkpoint)
```

Agents are instructed these are MUST DO steps.

## Initialize PROJECT-STATE.md

After install, paste this into your agent:

```
Read PROJECT-STATE.md and fill it in based on the codebase.
Detect the stack from package.json, composer.json, Cargo.toml, go.mod, or
similar. Identify the current development stage. List the top 3-5 active
tasks from open issues, recent commits, or TODO comments. Add any known
gotchas. Keep each section concise — 1-liners for decisions, short
descriptions for gotchas. Don't overwrite the structure — just fill in the
blanks. Store key decisions to Ogham if available.
```

## File Structure

```
your-project/
├── PROJECT-STATE.md
├── AGENTS.md (patched)
├── GEMINI.md (patched, if Gemini detected)
├── .opencode/
│   ├── skills/
│   │   ├── session-bootstrap/SKILL.md
│   │   └── session-checkpoint/SKILL.md
│   ├── command/
│   │   ├── session-bootstrap.md
│   │   └── checkpoint.md
│   └── plugins/
│       └── project-memory.js
├── .claude/
│   └── skills/
│       ├── session-bootstrap/SKILL.md
│       └── session-checkpoint/SKILL.md
└── .gemini/
    └── skills/
        ├── session-bootstrap/SKILL.md
        └── session-checkpoint/SKILL.md
```

## Agent Support

| Agent | Skills | Commands | Plugin | Auto-Bootstrap | Auto-Checkpoint |
|-------|--------|----------|--------|----------------|-----------------|
| OpenCode | `.opencode/skills/` | `/session-bootstrap`, `/checkpoint` | `.opencode/plugins/` | Via AGENTS.md instructions | Plugin on `session.idle` |
| KiloCode | `.opencode/skills/` | `/session-bootstrap`, `/checkpoint` | `.opencode/plugins/` | Via AGENTS.md instructions | Plugin on `session.idle` |
| Claude Code | `.claude/skills/` | — | — | Via AGENTS.md instructions | Via AGENTS.md instructions |
| Gemini CLI | `.gemini/skills/` | — | — | Via GEMINI.md instructions | Via GEMINI.md instructions |

## Ogham Support (Optional)

[Ogham MCP](https://github.com/ogham-mcp/ogham-mcp) is a specialized Model Context Protocol (MCP) server that provides structured, persistent memory for AI agents. While Ariadne works fully with just markdown files, Ogham adds:

- **Semantic Search:** Quickly find relevant historical context or decisions without reading large files.
- **Decision Linking:** Connects current tasks to the original rationale stored in memory.
- **Cross-Session Persistence:** Richer context that survives even if local files are modified or deleted.

The `session-bootstrap` and `session-checkpoint` skills are designed to detect if Ogham is available and will skip silently if it isn't configured. Use Ogham when you need your agent to remember the "why" behind complex architectural choices across long-running projects.

## Uninstall

```bash
./uninstall.sh /path/to/your/project
```

Removes skills, plugin, commands, and context file markers. Keeps `PROJECT-STATE.md`.

## License

MIT
