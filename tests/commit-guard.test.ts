/**
 * commit-guard unit tests
 *
 * Exercises the pure functions in extensions/commit-guard.ts against
 * realistic diff inputs and commit messages. Run with:
 *   npx tsx tests/commit-guard.test.ts
 *
 * Real git diff format:
 *   --- a/file.ts
 *   +++ b/file.ts
 *   @@ ... @@
 *   +added
 *   -removed
 *
 * Deletion: +++ /dev/null
 * Rename:   diff --git a/old b/new (old != new)
 */

// ── Copy of pure guard functions (keep in sync with extension) ─────────────

interface SecretsPattern {
	pattern: RegExp;
	label: string;
}

const SECRETS_PATTERNS: SecretsPattern[] = [
	{ pattern: /\bpassword\s*[:=]\s*["']?(?!your[-_]|changeme|placeholder|example)[^\s"'\n]{8,}/i, label: "password" },
	{ pattern: /\bapi[_-]?key\s*[:=]\s*["']?(?!your[-_]|changeme|placeholder)[^\s"'\n]{10,}/i, label: "API key" },
	{ pattern: /\bsecret[_-]?(?:key|access)\s*[:=]\s*["']?(?!your[-_]|changeme|placeholder)[^\s"'\n]{10,}/i, label: "secret key" },
	{ pattern: /\baccess[_-]?token\s*[:=]\s*["']?(?!your[-_]|changeme|placeholder)[^\s"'\n]{10,}/i, label: "access token" },
	{ pattern: /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/, label: "private key (PEM block)" },
	{ pattern: /ghp_[a-zA-Z0-9]{36}/, label: "GitHub PAT" },
	{ pattern: /sk-[a-zA-Z0-9]{32,}/, label: "OpenAI key" },
	{ pattern: /xoxb-[0-9]+-[0-9]+-[a-zA-Z0-9]+/, label: "Slack token" },
	{ pattern: /AKIA[0-9A-Z]{16}/, label: "AWS key ID" },
];

function scanForSecrets(diff: string): Array<{ label: string; line: string }> {
	const hits: Array<{ label: string; line: string }> = [];
	for (const line of diff.split("\n")) {
		if (!line.startsWith("+") || line.startsWith("+++")) continue;
		for (const { pattern, label } of SECRETS_PATTERNS) {
			if (pattern.test(line)) {
				const preview = line.length > 60 ? `${line.slice(0, 60)}…` : line;
				hits.push({ label, line: preview });
				break;
			}
		}
	}
	return hits;
}

interface DiffStats {
	fileCount: number;
	linesAdded: number;
	linesDeleted: number;
	deletedFiles: string[];
	renamedFiles: string[];
}

function analyzeDiff(diff: string): DiffStats {
	// Count --- headers (one per file) — this is the reliable file counter
	const dashDashLines = diff.match(/^--- a\//gm) || [];
	const fileCount = dashDashLines.length;

	const linesAdded = (diff.match(/^\+[^+]/gm) || []).length;
	const linesDeleted = (diff.match(/^-[^-]/gm) || []).length;
	const deletedFiles: string[] = [];
	const renamedFiles: string[] = [];
	const lines = diff.split("\n");

	for (let i = 0; i < lines.length; i++) {
		if (lines[i].match(/^\+\+\+ \/dev\/null$/)) {
			// Deleted file: look for --- a/<name> in previous lines
			for (let j = i - 1; j >= Math.max(0, i - 5); j--) {
				const m = lines[j].match(/^--- a\/(.+)$/);
				if (m) {
					deletedFiles.push(m[1]);
					break;
				}
			}
		}
		const renameMatch = lines[i].match(/^diff --git a\/(.+) b\/(.+)$/);
		if (renameMatch && renameMatch[1] !== renameMatch[2]) {
			renamedFiles.push(`${renameMatch[1]} → ${renameMatch[2]}`);
		}
	}

	return { fileCount, linesAdded, linesDeleted, deletedFiles, renamedFiles };
}

function extractCommitType(command: string): string | null {
	const msgMatch = command.match(/(?:-m\s+["']?|["'])(.+?)(?:["']?\s*$|\s+--)/);
	if (!msgMatch) return null;
	const msg = msgMatch[1].trim();
	const typeMatch = msg.match(/^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert):/);
	if (typeMatch) return typeMatch[1];
	return null;
}

// ── Test runner ──────────────────────────────────────────────────────────────

let pass = 0, fail = 0, total = 0;

function eq<T>(actual: T, expected: T, msg: string) {
	total++;
	const a = JSON.stringify(actual);
	const e = JSON.stringify(expected);
	if (a === e) {
		pass++;
		process.stdout.write(`  ✅ ${msg}\n`);
	} else {
		fail++;
		console.error(`  ❌ FAIL: ${msg}\n     expected: ${e}\n     actual:   ${a}`);
	}
}

function ok(condition: boolean, msg: string) {
	total++;
	if (condition) {
		pass++;
		process.stdout.write(`  ✅ ${msg}\n`);
	} else {
		fail++;
		console.error(`  ❌ FAIL: ${msg}`);
	}
}

// ── Tests ────────────────────────────────────────────────────────────────────
// All fake credential values in test data use "placeholder" or "test" tokens
// that the guard's SECRETS_PATTERNS will skip (they're excluded by the
// negative lookahead: (?!your[-_]|changeme|placeholder|example))

const FAKE_KEY = "sk-" + "placeholder".repeat(3);
const FAKE_PAT = "ghp_" + "x".repeat(36);
const FAKE_REAL_PW = "correcthorsebatterystaple";

console.log("🧪 commit-guard unit tests\n");

// --- scanForSecrets ---
console.log("scanForSecrets:");

eq(
	scanForSecrets("--- a/config.ts\n+++ b/config.ts\n@@ -1 +1 @@\n-key = '" + FAKE_KEY + "'\n"),
	[],
	"Ignores deleted (-) lines"
);

eq(
	scanForSecrets("--- a/config.ts\n+++ b/config.ts\n@@ -1 +1 @@\n+secret = '" + FAKE_KEY + "'\n"),
	[{ label: "OpenAI key", line: "+secret = '" + FAKE_KEY + "'" }],
	"Detects OpenAI key on new line"
);

eq(
	scanForSecrets("--- a/token.ts\n+++ b/token.ts\n@@ -1 +1 @@\n+pat = '" + FAKE_PAT + "'\n"),
	[{ label: "GitHub PAT", line: "+pat = '" + FAKE_PAT + "'" }],
	"Detects GitHub PAT on new line"
);

eq(
	scanForSecrets("--- a/pw.ts\n+++ b/pw.ts\n@@ -1 +1 @@\n+password = 'placeholder'\n"),
	[],
	"Skips placeholder passwords"
);

eq(
	scanForSecrets("--- a/pass.ts\n+++ b/pass.ts\n@@ -1 +1 @@\n+password = '" + FAKE_REAL_PW + "'\n"),
	[{ label: "password", line: "+password = '" + FAKE_REAL_PW + "'" }],
	"Detects real password"
);

eq(
	scanForSecrets("+++ /dev/null\n"),
	[],
	"Skips +++ file headers"
);

eq(
	scanForSecrets("--- a/x.ts\n+++ b/x.ts\n@@ -1 +1 @@\n+const x = 1\n"),
	[],
	"No false positives on normal code"
);

// --- analyzeDiff ---
console.log("\nanalyzeDiff:");

eq(
	analyzeDiff(
		"--- a/src/lib.ts\n+++ b/src/lib.ts\n@@ -1,3 +1,4 @@\n+new line\n existing\n@@ -10,0 +11,1 @@\n+another\n"
	),
	{ fileCount: 1, linesAdded: 2, linesDeleted: 0, deletedFiles: [], renamedFiles: [] },
	"Basic diff: 1 file, 2 added"
);

eq(
	analyzeDiff(
		"--- a/src/a.ts\n+++ /dev/null\n@@ -1,2 +0,0 @@\n-old\n-old\n"
	),
	{ fileCount: 1, linesAdded: 0, linesDeleted: 2, deletedFiles: ["src/a.ts"], renamedFiles: [] },
	"File deletion: detects /dev/null and extracts file name"
);

eq(
	analyzeDiff(
		"--- a/old-name.ts\n+++ b/new-name.ts\n@@ -1,2 +1,2 @@\n-old\n+new\n"
	),
	{ fileCount: 1, linesAdded: 1, linesDeleted: 1, deletedFiles: [], renamedFiles: [] },
	"Rename WITHOUT diff --git header: no rename detected"
);

eq(
	analyzeDiff(
		"diff --git a/old-name.ts b/new-name.ts\n--- a/old-name.ts\n+++ b/new-name.ts\n@@ -1,2 +1,2 @@\n-old\n+new\n"
	),
	{ fileCount: 1, linesAdded: 1, linesDeleted: 1, deletedFiles: [], renamedFiles: ["old-name.ts → new-name.ts"] },
	"Rename with diff --git header: detected"
);

eq(
	analyzeDiff(
		"--- a/file-a.ts\n+++ b/file-a.ts\n@@ -1 +1 @@\n-old\n+new\n" +
		"--- a/file-b.ts\n+++ b/file-b.ts\n@@ -1 +1 @@\n-old\n+new\n"
	),
	{ fileCount: 2, linesAdded: 2, linesDeleted: 2, deletedFiles: [], renamedFiles: [] },
	"Multi-file diff: counts 2 files"
);

// --- extractCommitType ---
console.log("\nextractCommitType:");

eq(extractCommitType("git commit -m 'feat: add guard warnings'"), "feat", "feat: type");
eq(extractCommitType("git commit -m 'fix: resolve race'"), "fix", "fix: type");
eq(extractCommitType("git commit -m 'refactor: simplify guard'"), "refactor", "refactor: type");
eq(extractCommitType("git commit -m 'Update README'"), null, "Non-conventional → null");
eq(extractCommitType("git commit --amend -m 'docs: add testing section'"), "docs", "Amended commit");

// --- Scenario: large change detection ---
console.log("\nScenario: 5-file change triggers scope warning");
const fiveFileDiff = [
	"--- a/a.ts\n+++ b/a.ts\n@@ -1 +1 @@\n-old\n+new\n",
	"--- a/b.ts\n+++ b/b.ts\n@@ -1 +1 @@\n-old\n+new\n",
	"--- a/c.ts\n+++ b/c.ts\n@@ -1 +1 @@\n-old\n+new\n",
	"--- a/d.ts\n+++ b/d.ts\n@@ -1 +1 @@\n-old\n+new\n",
	"--- a/e.ts\n+++ b/e.ts\n@@ -1 +1 @@\n-old\n+new\n",
].join("\n");

const stats = analyzeDiff(fiveFileDiff);
ok(stats.fileCount === 5, "5 files detected");
const triggersWarning = stats.fileCount >= 5 || (stats.linesAdded + stats.linesDeleted) > 200;
ok(triggersWarning, "Scope warning triggered (5 files)");

ok(extractCommitType("git commit -m 'fix: update 5 files'") === "fix", "Commit type: fix: with wide scope");

// --- Scenario: deletion detection ---
console.log("\nScenario: deletion with cross-ref reminder");
const deleteDiff = [
	"--- a/old-module.ts\n+++ /dev/null\n@@ -1,10 +0,0 @@\n-old line 1\n-old line 2\n",
].join("\n");

const deleteStats = analyzeDiff(deleteDiff);
ok(deleteStats.deletedFiles.length === 1, "Deleted file detected");
ok(deleteStats.deletedFiles[0] === "old-module.ts", "Deleted file name extracted correctly");

console.log("\n" + "=".repeat(40));
console.log(`${pass} passed, ${fail} failed, ${total} total`);
if (fail > 0) process.exit(1);
console.log("✅ All tests passed");
