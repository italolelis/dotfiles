/**
 * Claude Code-style status line for pi.
 *
 * WHY THIS EXISTS: pi-cc-extensions restyles the TRANSCRIPT (tool cards, diffs,
 * thinking, markdown) and ships themes, but it never calls setFooter — grep it.
 * The bottom of the screen stays stock pi. This closes that gap and nothing else.
 *
 *   ~/projects/khipu   ⎇ main ✱       Opus 4.6 · 58% context left · $1.23 (sub)
 *
 * This deliberately shows LESS than pi's built-in footer, which also carries
 * ↑input ↓output Rcache Wcache CH<hit-rate> and the raw model id. That density
 * is a real feature and dropping it is a taste call, not an upgrade.
 * `/statusline` toggles back to the built-in footer if you miss it.
 *
 * THREE THINGS THAT MUST NOT REGRESS, all invisible if broken:
 *
 * 1. Extension statuses are preserved. The built-in footer renders
 *    footerData.getExtensionStatuses(); a custom footer that ignored them would
 *    silently blank plan-mode indicators and subagent progress from other
 *    packages, and nobody would attribute that to this file.
 *
 * 2. Context percent comes from ctx.getContextUsage(), never from summing usage
 *    across the branch. A sum counts the same resent prompt once per turn and
 *    reports several hundred percent of the window. getContextUsage also
 *    returns tokens: null right after a compaction — a genuinely unknown value
 *    that is rendered "?" rather than guessed at.
 *
 * 3. Cost is marked "(sub)" under OAuth, and that label is the honest part of
 *    the figure. On a Claude Pro/Max (or Codex/Copilot/SuperGrok/Kimi) login,
 *    usage.cost is what the same tokens WOULD have cost on the metered API —
 *    it is not money leaving an account, and a bare "$4.10" on a flat-rate
 *    subscription is a confidently wrong number of exactly the kind this
 *    project exists to refuse. Every OAuth provider pi ships declares
 *    isSubscription: true, so auth type "oauth" is a sound proxy; the label is
 *    dropped for an API key, where the figure IS real spend.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { execFile } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, relative, resolve, sep } from "node:path";

// ---------------------------------------------------------------------------
// Tuning
// ---------------------------------------------------------------------------

/** Below this, drop the right-hand cluster rather than truncate it. Half a
 *  percentage reads as a whole one: "5%" is a cut "58%" and looks alarming. */
const MIN_WIDTH_FOR_RIGHT = 52;

/** `git status` on a large repo is not free and the footer re-renders on every
 *  keystroke, so dirty state is polled, never computed inline. */
const GIT_DIRTY_POLL_MS = 4000;

/** Claude Code's thresholds, expressed as context REMAINING. */
const CONTEXT_WARN_PCT_LEFT = 25;
const CONTEXT_DANGER_PCT_LEFT = 10;

/** Sub-cent costs render as "$0.00", which reads as free rather than as small.
 *  Below this the cost segment is omitted entirely. */
const MIN_COST_TO_SHOW = 0.005;

// ---------------------------------------------------------------------------
// Git dirty state — cached, async, never blocks a render
// ---------------------------------------------------------------------------

let dirty = false;
let lastDirtyCheck = 0;
let dirtyInFlight = false;

function refreshDirty(cwd: string, onChange: () => void): void {
	const now = Date.now();
	if (dirtyInFlight || now - lastDirtyCheck < GIT_DIRTY_POLL_MS) return;
	dirtyInFlight = true;
	lastDirtyCheck = now;

	execFile(
		"git",
		["status", "--porcelain", "--untracked-files=no"],
		{ cwd, timeout: 2000 },
		(err, stdout) => {
			dirtyInFlight = false;
			// Not a repo, or git failed: "not dirty". The branch segment is already
			// absent in that case, so there is nothing for the marker to attach to.
			const next = !err && stdout.trim().length > 0;
			if (next !== dirty) {
				dirty = next;
				onChange();
			}
		},
	);
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Auth mode — read once; a login mid-session is rare and /statusline re-reads
// ---------------------------------------------------------------------------

/** True when this provider is authenticated by OAuth, i.e. a subscription.
 *  Read from disk because ExtensionContext exposes no modelRuntime, so
 *  isUsingSubscription() is not reachable from an extension. Any failure
 *  returns false: an UNLABELLED figure is the safe default only because it
 *  overstates spend, never understates it. */
function isOAuthProvider(provider: string | undefined): boolean {
	if (!provider) return false;
	try {
		const dir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
		const auth = JSON.parse(readFileSync(join(dir, "auth.json"), "utf8")) as Record<
			string,
			{ type?: string } | undefined
		>;
		return auth[provider]?.type === "oauth";
	} catch {
		return false;
	}
}

/** Mirrors pi's own formatCwdForFooter: only collapse to ~ when genuinely
 *  inside home, so a sibling path like /Users/other is never mislabelled. */
function shortenCwd(cwd: string): string {
	const home = process.env.HOME || process.env.USERPROFILE;
	if (!home) return cwd;
	const rel = relative(resolve(home), resolve(cwd));
	const inside = rel === "" || (rel !== ".." && !rel.startsWith(`..${sep}`) && !isAbsolute(rel));
	if (!inside) return cwd;
	return rel === "" ? "~" : `~${sep}${rel}`;
}

/** "claude-opus-4-6-20251101" → "Opus 4.6". Falls through unrecognised ids
 *  unchanged: a wrong pretty name is worse than an ugly accurate one. */
function prettyModel(id: string): string {
	const m = id.match(/(opus|sonnet|haiku)-(\d+)(?:[-.](\d+))?/i);
	if (m) {
		const family = m[1][0].toUpperCase() + m[1].slice(1).toLowerCase();
		return `${family} ${m[3] ? `${m[2]}.${m[3]}` : m[2]}`;
	}
	return id;
}

/**
 * Session cost, summed the way pi's own footer sums it: over getEntries() —
 * the WHOLE session — not getBranch(). Three entry kinds carry usage and
 * missing any of them understates spend silently:
 *   - assistant messages
 *   - toolResult messages (tools that call a model themselves, e.g. subagents)
 *   - compaction / branch_summary entries (the summarising call is billable)
 * The last two are easy to forget precisely because they are intermittent.
 */
function sessionCost(entries: readonly unknown[]): number {
	let cost = 0;
	for (const entry of entries as {
		type?: string;
		message?: { role?: string; usage?: { cost?: { total?: number } } };
		usage?: { cost?: { total?: number } };
	}[]) {
		if (entry?.type === "message") {
			const role = entry.message?.role;
			if (role === "assistant" || role === "toolResult") {
				cost += entry.message?.usage?.cost?.total ?? 0;
			}
		} else if (entry?.type === "compaction" || entry?.type === "branch_summary") {
			cost += entry.usage?.cost?.total ?? 0;
		}
	}
	return cost;
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
	let enabled = true;

	type Ctx = Parameters<Parameters<ExtensionAPI["on"]>[1]>[1];

	const install = (ctx: Ctx) => {
		if (!ctx?.hasUI || ctx.mode !== "tui") return;

		const subscription = isOAuthProvider(ctx.model?.provider);

		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsub = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					const cwd = process.cwd();
					refreshDirty(cwd, () => tui.requestRender());

					// ---- left: where you are ----
					let left = theme.fg("accent", shortenCwd(cwd));
					const branch = footerData.getGitBranch();
					if (branch) {
						left +=
							theme.fg("dim", "   ") +
							theme.fg("muted", `⎇ ${branch}`) +
							(dirty ? theme.fg("warning", " ✱") : "");
					}

					// ---- middle: other extensions' statuses (see header note 1) ----
					const middle = [...footerData.getExtensionStatuses().values()]
						.filter((s) => s && s.trim())
						.join(theme.fg("dim", " · "));

					// ---- right: what you have left ----
					const right: string[] = [];
					const modelId = ctx.model?.id;
					if (modelId) right.push(theme.fg("muted", prettyModel(modelId)));

					const usage = ctx.getContextUsage();
					if (usage && usage.contextWindow > 0) {
						if (usage.percent === null) {
							// Post-compaction: genuinely unknown until the next response.
							right.push(theme.fg("dim", "? context left"));
						} else {
							const pctLeft = Math.max(0, Math.min(100, Math.round(100 - usage.percent)));
							const colour =
								pctLeft <= CONTEXT_DANGER_PCT_LEFT
									? "error"
									: pctLeft <= CONTEXT_WARN_PCT_LEFT
										? "warning"
										: "dim";
							right.push(theme.fg(colour, `${pctLeft}% context left`));
						}
					}

					const cost = sessionCost(ctx.sessionManager.getEntries());
					if (cost >= MIN_COST_TO_SHOW) {
						// See header note 3: the "(sub)" suffix is load-bearing.
						right.push(
							theme.fg("dim", `$${cost.toFixed(2)}`) +
								(subscription ? theme.fg("dim", " (sub)") : ""),
						);
					}

					const rightStr = right.join(theme.fg("dim", " · "));

					// ---- assemble ----
					if (width < MIN_WIDTH_FOR_RIGHT) return [truncateToWidth(left, width)];

					const lw = visibleWidth(left);
					const rw = visibleWidth(rightStr);
					const mw = visibleWidth(middle);

					// Middle only earns its place if all three fit with real gaps;
					// otherwise it is dropped, never squeezed.
					if (mw > 0 && lw + mw + rw + 4 <= width) {
						const slack = width - lw - mw - rw;
						const gapL = " ".repeat(Math.max(2, Math.floor(slack / 2)));
						const gapR = " ".repeat(Math.max(2, slack - gapL.length));
						return [truncateToWidth(left + gapL + middle + gapR + rightStr, width)];
					}
					if (lw + rw + 2 > width) return [truncateToWidth(left, width)];
					return [left + " ".repeat(width - lw - rw) + rightStr];
				},
			};
		});
	};

	pi.on("session_start", async (_event, ctx) => {
		if (enabled) install(ctx);
	});

	pi.registerCommand("statusline", {
		description: "Toggle the Claude Code-style status line",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			if (enabled) {
				install(ctx);
				ctx.ui.notify("Claude Code status line on", "info");
			} else {
				ctx.ui.setFooter(undefined);
				ctx.ui.notify("Built-in pi footer restored (tokens, cache, cost)", "info");
			}
		},
	});
}
