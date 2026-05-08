/**
 * Package layout:
 *   kit/        — Raw markdown depth. Any tool can read these directly.
 *                 WORKING-STYLE.md is the canonical working discipline doc.
 *   extensions/ — Pi-only. This file injects the L0 compact prompt +
 *                 absolute kit paths into the Pi system prompt via
 *                 session_start. No changes needed for Copilot users.
 *   skills/     — AgentSkills standard (SKILL.md per command). Discovered
 *                 natively by Copilot CLI, Claude Code, and Pi. Add with:
 *                 /skills add <path-to-skills-dir>
 *
 * Distilled Zanshin L0 — always injected. Full markdown ships in this package
 * under ../kit/ (WORKING-STYLE.md, STYLE.md, STYLE.template.md).
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
	existsSync,
	mkdirSync,
	readdirSync,
	readFileSync,
	statSync,
	writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const extensionDir = dirname(fileURLToPath(import.meta.url));
const kitDir = join(extensionDir, "..", "kit");
const kitWorking = join(kitDir, "WORKING-STYLE.md");
const kitStyle = join(kitDir, "STYLE.md");
const kitTemplate = join(kitDir, "STYLE.template.md");

const CHECKPOINT_THRESHOLD = 5;

// ── Session logging helpers ────────────────────────────────────────────────

/**
 * Converts a workspace cwd path to the slug pi uses for its sessions directory.
 * e.g. /pvc/workspace → --pvc-workspace--
 */
function cwdToSessionSlug(cwd: string): string {
	return "--" + cwd.replace(/^\//, "").replace(/\//g, "-") + "--";
}

/** Path to pi's native JSONL session store for this workspace. */
function piSessionsDir(cwd: string): string {
	return join(homedir(), ".pi", "agent", "sessions", cwdToSessionSlug(cwd));
}

/** Path to the human-readable session extracts inside the workspace. */
function workspaceSessionsDir(cwd: string): string {
	return join(cwd, "sessions");
}

interface ParsedMessage {
	timestamp: string;
	role: "user" | "assistant";
	text: string;
}

interface SessionExtract {
	sessionId: string;
	startTime: string;
	endTime: string;
	messageCount: number;
	messages: ParsedMessage[];
	filesModified: string[];
}

/**
 * Parse a pi JSONL session file into a structured extract.
 * Skips thinking blocks; captures user/assistant text and toolCall file paths.
 */
function parseSessionJSONL(filePath: string): SessionExtract {
	const lines = readFileSync(filePath, "utf-8")
		.split("\n")
		.filter((l) => l.trim());

	const events: Record<string, unknown>[] = [];
	for (const line of lines) {
		try {
			events.push(JSON.parse(line));
		} catch {
			// skip malformed lines (e.g. partial write at shutdown)
		}
	}

	const sessionEvent = events.find((e) => e.type === "session") as
		| Record<string, string>
		| undefined;
	const lastEvent = events[events.length - 1] as
		| Record<string, string>
		| undefined;

	const messages: ParsedMessage[] = [];
	const filesModified = new Set<string>();
	let messageCount = 0;

	for (const event of events) {
		if (event.type !== "message") continue;

		const msg = event.message as Record<string, unknown> | undefined;
		if (!msg) continue;

		const role = msg.role as string;
		const content = (msg.content ?? []) as Array<Record<string, unknown>>;

		if (role === "user") {
			messageCount++;
			const text = content
				.filter((c) => c.type === "text")
				.map((c) => String(c.text ?? ""))
				.join(" ")
				.trim()
				.slice(0, 300);
			if (text) {
				messages.push({
					timestamp: String(event.timestamp ?? ""),
					role: "user",
					text,
				});
			}
		} else if (role === "assistant") {
			messageCount++;
			// Extract visible text (skip thinking blocks)
			const text = content
				.filter((c) => c.type === "text")
				.map((c) => String(c.text ?? ""))
				.join(" ")
				.trim()
				.slice(0, 300);
			if (text) {
				messages.push({
					timestamp: String(event.timestamp ?? ""),
					role: "assistant",
					text,
				});
			}
			// Extract file paths from tool calls
			for (const block of content) {
				if (
					block.type === "toolCall" &&
					["write", "edit"].includes(String(block.name ?? ""))
				) {
					const args = block.arguments as Record<string, unknown> | undefined;
					if (args?.path) filesModified.add(String(args.path));
				}
			}
		}
		// role === "toolResult" — skip; not useful in a human summary
	}

	return {
		sessionId: String(sessionEvent?.id ?? "unknown"),
		startTime: String(sessionEvent?.timestamp ?? ""),
		endTime: String(lastEvent?.timestamp ?? ""),
		messageCount,
		messages,
		filesModified: Array.from(filesModified).sort(),
	};
}

/** Format a parsed session as a readable markdown extract. */
function formatExtract(extract: SessionExtract): string {
	const date = extract.startTime
		? extract.startTime.split("T")[0]
		: "unknown";

	const lines: string[] = [
		`# Session Extract — ${date}`,
		``,
		`**ID:** ${extract.sessionId}`,
		`**Started:** ${extract.startTime}`,
		`**Ended:** ${extract.endTime}`,
		`**Messages:** ${extract.messageCount}`,
		``,
		`## Conversation`,
	];

	for (const msg of extract.messages) {
		const ts = msg.timestamp
			? msg.timestamp.replace("T", " ").split(".")[0]
			: "";
		const role = msg.role === "user" ? "User" : "Assistant";
		const text = msg.text.replace(/\n/g, " ");
		const truncated = text.length >= 300 ? text + "…" : text;
		lines.push(`- \`${ts}\` **${role}:** ${truncated}`);
	}

	if (extract.filesModified.length > 0) {
		lines.push("", "## Files Modified");
		for (const f of extract.filesModified) {
			lines.push(`- \`${f}\``);
		}
	}

	lines.push(
		"",
		"---",
		"*Structured extract — generated at session shutdown. Run `/summarize-session` to append an LLM narrative.*",
	);

	return lines.join("\n") + "\n";
}

/**
 * Find JSONL session files that don't yet have a corresponding extract in the workspace.
 * Returns basenames (without extension) of unsummarized sessions, oldest first.
 * Excludes the most recent file (assumed to be the current session).
 */
function findUnsummarizedSessions(
	piSessions: string,
	wsSessions: string,
): string[] {
	if (!existsSync(piSessions)) return [];

	const jsonlFiles = readdirSync(piSessions)
		.filter((f) => f.endsWith(".jsonl"))
		.sort(); // ISO timestamps sort correctly lexicographically

	if (jsonlFiles.length === 0) return [];

	// Exclude the most recent (current session)
	const previousSessions = jsonlFiles.slice(0, -1);

	if (!existsSync(wsSessions)) return previousSessions.map((f) => f.replace(".jsonl", ""));

	const existingExtracts = new Set(
		readdirSync(wsSessions)
			.filter((f) => f.endsWith(".md") && f !== "README.md")
			.map((f) => f.replace(".md", "")),
	);

	return previousSessions
		.map((f) => f.replace(".jsonl", ""))
		.filter((base) => !existingExtracts.has(base));
}

// ── Kit path block ─────────────────────────────────────────────────────────

function kitPathBlock(): string {
	if (!existsSync(kitWorking)) {
		return (
			"**Kit files not found** next to this extension (unexpected after `pi install`). " +
			"Ask the user for the path to `WORKING-STYLE.md` if depth is needed."
		);
	}
	return (
		"**Kit (read when task needs full detail — not every turn):**\n" +
		`- \`${kitWorking}\` — full working discipline\n` +
		`- \`${kitStyle}\` — style defaults\n` +
		`- \`${kitTemplate}\` — blank style template`
	);
}

/**
 * Minimal L0 — just failure modes, available commands, and auto-behaviors.
 * Full discipline lives in kit/WORKING-STYLE.md (read on demand).
 */
const ZANSHIN_L0 = `\
## Zanshin

Three failure modes: (1) **Cross-session statelessness** — commit decisions to files; use the repo as truth. (2) **Context compaction** — re-read files before depending on their contents. (3) **Fluent-but-wrong** — challenge significant outputs; do not fabricate.

**Commands:** \`/spar [target]\` · \`/shoshin\` · \`/checkpoint\` · \`/summarize-session [file]\` · \`/push <topic>\` · \`/pop\` · \`/stack\`

**Auto-behaviors:** Notifies on session start when an existing project is detected (run \`/shoshin\`). Surfaces a checkpoint reminder after ${CHECKPOINT_THRESHOLD} file writes. Stack state persists across sessions. A structured session extract is written to \`sessions/\` in the workspace at shutdown. Previous sessions without summaries are flagged at startup.`;

export default function (pi: ExtensionAPI) {
	// ── State ──────────────────────────────────────────────────────────────────

	let stack: string[] = [];
	let changesSinceCheckpoint = 0;

	// ── Session start: restore state + auto-shoshin notify ────────────────────

	pi.on("session_start", async (event, ctx) => {
		stack = [];
		changesSinceCheckpoint = 0;

		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type !== "custom") continue;
			if (entry.customType === "zanshin-stack") {
				stack = (entry.data as { stack: string[] }).stack ?? [];
			}
			if (entry.customType === "zanshin-changes") {
				changesSinceCheckpoint = (entry.data as { count: number }).count ?? 0;
			}
		}

		if (event.reason === "startup") {
			const hasScope =
				existsSync(join(ctx.cwd, ".planning", "brief.md")) ||
				existsSync(join(ctx.cwd, ".planning", "whats-next.md")) ||
				existsSync(join(ctx.cwd, "BRIEF.md"));

			if (hasScope) {
				ctx.ui.notify(
					"Zanshin: existing project detected — run /shoshin before proceeding",
					"info",
				);
			}

			// Check for previous sessions that haven't been summarized yet
			try {
				const piSessions = piSessionsDir(ctx.cwd);
				const wsSessions = workspaceSessionsDir(ctx.cwd);
				const unsummarized = findUnsummarizedSessions(piSessions, wsSessions);
				if (unsummarized.length > 0) {
					ctx.ui.notify(
						`Zanshin: ${unsummarized.length} previous session(s) without summaries — run /summarize-session`,
						"info",
					);
				}
			} catch {
				// sessions dirs may not exist yet — silently skip
			}
		}
	});

	// ── System prompt: minimal L0 ─────────────────────────────────────────────

	pi.on("before_agent_start", async (event) => {
		const block = `${ZANSHIN_L0}\n\n${kitPathBlock()}`;
		return { systemPrompt: `${event.systemPrompt}\n\n${block}` };
	});

	// ── Progressive bookkeeping: track file writes ────────────────────────────

	pi.on("tool_result", async (event, ctx) => {
		if (event.toolName !== "write" && event.toolName !== "edit") return;
		if (event.isError) return;

		changesSinceCheckpoint++;
		pi.appendEntry("zanshin-changes", { count: changesSinceCheckpoint });

		if (changesSinceCheckpoint >= CHECKPOINT_THRESHOLD) {
			ctx.ui.notify(
				`Zanshin: ${changesSinceCheckpoint} file changes since last checkpoint — run /checkpoint`,
				"warning",
			);
			// Don't reset here; let /checkpoint reset it so the reminder persists
			// until the user explicitly checkpoints.
		}
	});

	// ── Session shutdown: write structured extract + warn if no checkpoint ─────

	pi.on("session_shutdown", async (event, ctx) => {
		if (event.reason !== "quit") return;

		// ── Checkpoint warning (existing behaviour) ──────────────────────────
		if (changesSinceCheckpoint > 0) {
			const hasCheckpoint = existsSync(
				join(ctx.cwd, ".planning", "whats-next.md"),
			);
			if (!hasCheckpoint) {
				ctx.ui.notify(
					`Zanshin: ${changesSinceCheckpoint} uncommitted changes with no checkpoint — run /checkpoint next session`,
					"warning",
				);
			}
		}

		// ── Session extract ──────────────────────────────────────────────────
		try {
			const piSessions = piSessionsDir(ctx.cwd);
			if (!existsSync(piSessions)) return;

			// Current session = most recently modified JSONL (still being written)
			const jsonlFiles = readdirSync(piSessions)
				.filter((f) => f.endsWith(".jsonl"))
				.map((f) => ({ name: f, mtime: statSync(join(piSessions, f)).mtimeMs }))
				.sort((a, b) => b.mtime - a.mtime);

			if (jsonlFiles.length === 0) return;

			const currentFile = join(piSessions, jsonlFiles[0].name);
			const baseName = jsonlFiles[0].name.replace(".jsonl", "");

			const wsSessions = workspaceSessionsDir(ctx.cwd);
			const outputPath = join(wsSessions, `${baseName}.md`);

			// Idempotent — don't overwrite if extract already exists
			if (existsSync(outputPath)) return;

			mkdirSync(wsSessions, { recursive: true });

			const extract = parseSessionJSONL(currentFile);
			writeFileSync(outputPath, formatExtract(extract));
		} catch (err) {
			ctx.ui.notify(
				`Zanshin: session extract failed — ${String(err)}`,
				"warning",
			);
		}
	});

	// ── /spar ─────────────────────────────────────────────────────────────────

	pi.registerCommand("spar", {
		description: "Adversarial review — steel-man arguments against the current approach",
		handler: async (args, ctx) => {
			const target =
				args?.trim() || "the current approach or most recent decision";
			await ctx.waitForIdle();
			pi.sendUserMessage(
				`Apply Zanshin spar discipline to: ${target}.\n\n` +
					`Generate 3–5 arguments against it. For each use this structure:\n\n` +
					`**N. [Argument title]**\n` +
					`Type: Structural | Presentation | Scope | Evidence | Consistency\n` +
					`The argument: [steel-manned — strongest version, not a strawman]\n` +
					`Why it matters: [what breaks or weakens if this is valid — concrete]\n` +
					`Strength: Strong | Moderate | Weak — [one sentence]\n\n` +
					`Close with a Self-Audit:\n\n` +
					`**Self-Audit**\n` +
					`Strongest: [N] — [why this one actually matters]\n` +
					`Weakest: [N] — [why this might be contrarian pattern-matching]\n` +
					`What I might be missing: [blind spots in this review itself]\n\n` +
					`End with: "Where am I right, and where am I pattern-matching into a devil's advocate role?"`,
			);
		},
	});

	// ── /shoshin ──────────────────────────────────────────────────────────────

	pi.registerCommand("shoshin", {
		description: "Surface assumptions before proceeding",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();
			pi.sendUserMessage(
				`Apply Zanshin shoshin. Before proceeding, pause and name what's being assumed:\n\n` +
					`- Is the problem stated correctly, or are we solving the wrong thing?\n` +
					`- Are the constraints real, or inherited from habit or prior context?\n` +
					`- Is the scope appropriate, or has it drifted?\n` +
					`- What would a beginner ask that an expert would skip?\n\n` +
					`Find the one assumption whose examination dissolves the complexity or reframes the problem. ` +
					`State it plainly: "I'm assuming X — is that still true?"`,
			);
		},
	});

	// ── /checkpoint ───────────────────────────────────────────────────────────

	pi.registerCommand("checkpoint", {
		description: "Write a Zanshin checkpoint to .planning/whats-next.md",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();

			const stackState =
				stack.length > 0
					? stack
							.map((t, i) =>
								i === stack.length - 1
									? `  - [open] ${t}`
									: `  - [bottom] ${t}`,
							)
							.join("\n")
					: "none";

			// Reset the counter immediately so the reminder stops firing.
			changesSinceCheckpoint = 0;
			pi.appendEntry("zanshin-changes", { count: 0 });

			pi.sendUserMessage(
				`Write a Zanshin checkpoint. Use the write tool to append to .planning/whats-next.md ` +
					`(create .planning/ if needed; if the file exists, append — do not replace).\n\n` +
					`Use this format exactly:\n\n` +
					`# Checkpoint — YYYY-MM-DD\n\n` +
					`**In progress:** [one sentence — what is mid-flight right now]\n` +
					`**Just completed:** [1–3 bullets]\n` +
					`**Next step:** [one sentence — what happens next if the session continues]\n` +
					`**Key decision:** [one sentence capturing anything that would be re-litigated without knowing it was settled — or "none"]\n` +
					`**Git state:** [run \`git log -1 --format="%h %s"\` and paste result]\n` +
					`**Open threads:** ${stackState}\n\n` +
					`Use today's date. Run git log -1 to get the git state before writing.`,
			);
		},
	});

	// ── /summarize-session ────────────────────────────────────────────────────

	pi.registerCommand("summarize-session", {
		description: "Generate an LLM narrative summary for a session extract in sessions/",
		handler: async (args, ctx) => {
			const wsSessions = workspaceSessionsDir(ctx.cwd);

			if (!existsSync(wsSessions)) {
				ctx.ui.notify(
					"No sessions/ directory found — extracts are written at session shutdown",
					"warning",
				);
				return;
			}

			const extractFiles = readdirSync(wsSessions)
				.filter((f) => f.endsWith(".md") && f !== "README.md")
				.sort()
				.reverse(); // most recent first

			if (extractFiles.length === 0) {
				ctx.ui.notify("No session extracts found in sessions/", "warning");
				return;
			}

			// Use the provided filename, or default to most recent
			const target = args?.trim()
				? args.trim().endsWith(".md")
					? args.trim()
					: args.trim() + ".md"
				: extractFiles[0];

			const targetPath = join(wsSessions, target);

			if (!existsSync(targetPath)) {
				ctx.ui.notify(`Session extract not found: ${target}`, "warning");
				return;
			}

			await ctx.waitForIdle();
			pi.sendUserMessage(
				`Read the session extract at \`${targetPath}\`.\n\n` +
					`Generate a concise narrative summary (5–10 lines) covering:\n` +
					`- What topics were discussed\n` +
					`- Key decisions made\n` +
					`- Files modified\n` +
					`- Any notable outcomes or open threads\n\n` +
					`Append it to the file under a \`## Summary\` heading, after the existing content. ` +
					`If a \`## Summary\` section already exists, replace it in place.`,
			);
		},
	});

	// ── /push ─────────────────────────────────────────────────────────────────

	pi.registerCommand("push", {
		description: "Push a topic onto the Zanshin stack",
		handler: async (args, ctx) => {
			const topic = args?.trim();
			if (!topic) {
				ctx.ui.notify("Usage: /push <topic name>", "warning");
				return;
			}
			stack.push(topic);
			pi.appendEntry("zanshin-stack", { stack: [...stack] });
			ctx.ui.notify(
				`↓ pushed "${topic}" (stack depth ${stack.length})`,
				"info",
			);
		},
	});

	// ── /pop ──────────────────────────────────────────────────────────────────

	pi.registerCommand("pop", {
		description: "Pop current topic and return to parent",
		handler: async (args, ctx) => {
			if (stack.length === 0) {
				ctx.ui.notify("Stack is empty", "warning");
				return;
			}
			const popped = stack.pop()!;
			pi.appendEntry("zanshin-stack", { stack: [...stack] });
			const parent = stack[stack.length - 1] ?? "root";
			ctx.ui.notify(`↑ resolved "${popped}" — back to "${parent}"`, "info");
		},
	});

	// ── /stack ────────────────────────────────────────────────────────────────

	pi.registerCommand("stack", {
		description: "Show the current Zanshin stack",
		handler: async (args, ctx) => {
			if (stack.length === 0) {
				ctx.ui.notify("Stack is empty", "info");
				return;
			}
			const lines = stack
				.map((t, i) => {
					const marker = i === stack.length - 1 ? "→" : " ";
					return `${marker} ${i + 1}. ${t}`;
				})
				.join("\n");
			ctx.ui.notify(`Stack (depth ${stack.length}):\n${lines}`, "info");
		},
	});
}
