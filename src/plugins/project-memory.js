import { readFileSync, existsSync } from "fs"
import { join } from "path"

// Auto-bootstrap on session start, auto-checkpoint on session idle.
// OpenCode/KiloCode only. Claude Code and Gemini CLI rely on context file instructions.

export const ProjectMemoryPlugin = async ({ directory, client }) => {
  const projectStatePath = join(directory, "PROJECT-STATE.md")
  const bootstrapped = new Set()

  return {
    event: async ({ event }) => {
      // On session creation: mark for bootstrap
      if (event.type === "session.created") {
        bootstrapped.add(event.sessionId)
      }

      // On session idle: auto-checkpoint
      if (event.type === "session.idle") {
        try {
          await client.session.prompt({
            sessionId: event.sessionId,
            message: "Run session-checkpoint to save progress. If nothing significant changed, skip silently."
          })
        } catch (e) {
          // Silently fail
        }
      }
    },

    // Inject project state context via compaction hook
    "experimental.session.compacting": async (input, output) => {
      if (existsSync(projectStatePath)) {
        try {
          const content = readFileSync(projectStatePath, "utf-8").trim()
          if (content) {
            output.context.push(`## Project State\n\n${content}`)
          }
        } catch (e) {
          // Silently fail
        }
      }
    }
  }
}
