import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

/**
 * LID L0 — always injected. Full workflow in ../kit/LID-WORKFLOW.md.
 *
 * Adapts Linked-Intent Development for pi sessions and non-code workspaces.
 * Mirrors the zanshin-pi-extension pattern: compact always-on block +
 * depth-on-demand via absolute kit paths.
 */
const extensionDir = dirname(fileURLToPath(import.meta.url));
const kitDir = join(extensionDir, "..", "kit");
const workflowPath = join(kitDir, "LID-WORKFLOW.md");
const templatesDir = join(kitDir, "templates");

function kitPathBlock(): string {
	if (!existsSync(workflowPath)) {
		return (
			"**LID kit:** Workflow file not found — re-install the extension.\n" +
			"Expected: " + workflowPath
		);
	}
	return (
		"**LID depth on demand (absolute paths on this machine):**\n" +
		`- \`${workflowPath}\` — full workflow, phase triggers, and examples\n` +
		`- \`${join(templatesDir, "INTENT.md")}\` — Intent Note template\n` +
		`- \`${join(templatesDir, "DESIGN-NOTE.md")}\` — Design Note template\n` +
		`- \`${join(templatesDir, "ACCEPTANCE.md")}\` — Acceptance Criteria template\n` +
		"Read these when planning a change — not every turn."
	);
}

const LID_L0 = `
## LID L0 — linked-intent discipline

Intent is the artifact. Changes are output. Requirements win over implementation —
when they disagree, fix the change or deliberately update the intent and cascade.

**Before executing any change, scale the intent work to the size of the change:**

- **Touch** (1–2 files, obvious scope): intent lives in the commit message.
  One sentence: what problem does this solve?

- **Change** (3–5 files, OR any new command / skill / rule / configuration):
  write a one-paragraph Intent Note before touching any files.
  State the problem, not the solution. Stop for acknowledgment before proceeding.

- **Restructure** (5+ files, new directories, or architectural shifts):
  walk the full arrow — Intent → Design Note → Acceptance Criteria → Change.
  Stop for review after each step. Do not write a line of change until
  Acceptance Criteria are approved.

**Spar the intent, not the implementation.** Run adversarial review against the
intent before executing. A wrong intent executed well is still wrong.

**Bypasses:** warn when a change skips the appropriate level. Do not block —
make the cost visible and honor the user's decision.
`.trim();

export default function (pi: ExtensionAPI) {
	pi.on("before_agent_start", async (event) => {
		const block = `${LID_L0}\n\n${kitPathBlock()}`;
		return {
			systemPrompt: `${event.systemPrompt}\n\n${block}`,
		};
	});
}
