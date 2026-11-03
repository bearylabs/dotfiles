/**
 * Show OpenAI Codex rate-limit usage in Pi's footer.
 *
 * Uses the Codex CLI's own login (`codex login`) by asking `codex app-server`
 * for the account rate limits. Codex handles credential storage and refresh.
 */

import { spawn } from "node:child_process";
import { createInterface } from "node:readline";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "codex-usage";
const STATUS_EVENT = "usage-status:update";
const REQUEST_TIMEOUT_MS = 15_000;
const CODEX_BIN = process.env.CODEX_BIN ?? "codex";

interface RateLimitWindow {
	usedPercent?: number;
	windowDurationMins?: number | null;
	resetsAt?: number | null;
}

interface RateLimitSnapshot {
	primary?: RateLimitWindow | null;
	secondary?: RateLimitWindow | null;
	planType?: string | null;
}

interface CodexUsage {
	rateLimits?: RateLimitSnapshot;
}

interface UsageResult {
	status?: string;
	details: string;
	renderStatus?: () => string;
}

class CodexAuthError extends Error {}

function readRateLimits(): Promise<CodexUsage> {
	return new Promise((resolve, reject) => {
		const child = spawn(CODEX_BIN, ["app-server"], { stdio: ["pipe", "pipe", "pipe"] });
		let settled = false;
		let stderr = "";

		const finish = (error: Error | undefined, value?: CodexUsage) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			lines.close();
			child.stdin.end();
			child.kill();
			if (error) reject(error);
			else resolve(value as CodexUsage);
		};

		const timer = setTimeout(() => finish(new Error("codex app-server timed out")), REQUEST_TIMEOUT_MS);
		const send = (message: unknown) => child.stdin.write(`${JSON.stringify(message)}\n`);

		child.on("error", (error) => finish(new Error(`cannot start codex: ${error.message}`)));
		child.on("exit", (code) => finish(new Error(`codex app-server exited (${code})${stderr ? `: ${stderr.trim()}` : ""}`)));
		child.stderr.on("data", (chunk) => { stderr = (stderr + chunk).slice(-1_000); });
		child.stdin.on("error", () => {});

		const lines = createInterface({ input: child.stdout });
		lines.on("line", (line) => {
			let message: { id?: number; result?: unknown; error?: { message?: string } };
			try {
				message = JSON.parse(line);
			} catch {
				return;
			}
			if (message.id === 1) {
				if (message.error) return finish(new Error(message.error.message ?? "initialize failed"));
				send({ method: "initialized" });
				send({ id: 2, method: "account/rateLimits/read", params: { excludeResetCreditDetails: true } });
			} else if (message.id === 2) {
				if (message.error) {
					const text = message.error.message ?? "rate limit request failed";
					return finish(/auth/i.test(text) ? new CodexAuthError(text) : new Error(text));
				}
				finish(undefined, message.result as CodexUsage);
			}
		});

		send({
			id: 1,
			method: "initialize",
			params: { clientInfo: { name: "pi-codex-usage", title: null, version: "1.0.0" }, capabilities: null },
		});
	});
}

function windowLabel(window: RateLimitWindow, fallback: string): string {
	const minutes = window.windowDurationMins;
	if (typeof minutes !== "number") return fallback;
	if (minutes >= 6 * 24 * 60) return "7d";
	if (minutes % 60 === 0) return `${minutes / 60}h`;
	return fallback;
}

function resetDescription(resetAt: number | undefined): string {
	if (typeof resetAt !== "number") return "unknown reset";
	return `resets ${new Date(resetAt * 1_000).toLocaleString()}`;
}

function resetIn(resetAt: number | undefined): string | undefined {
	if (typeof resetAt !== "number") return undefined;
	const totalMinutes = Math.floor(Math.max(0, resetAt - Date.now() / 1_000) / 60);
	if (totalMinutes < 1) return "<1m";

	const days = Math.floor(totalMinutes / (24 * 60));
	const hours = Math.floor((totalMinutes % (24 * 60)) / 60);
	const minutes = totalMinutes % 60;
	if (days > 0) return `${days}d${hours > 0 ? ` ${hours}h` : ""}`;
	if (hours > 0) return `${hours}h${minutes > 0 ? ` ${minutes}m` : ""}`;
	return `${minutes}m`;
}

function formatUsage(
	usage: CodexUsage,
	muted: (text: string) => string,
	prominent: (text: string) => string,
): UsageResult {
	const primary = usage.rateLimits?.primary;
	const secondary = usage.rateLimits?.secondary;
	const windows = [
		primary && typeof primary.usedPercent === "number"
			? { label: windowLabel(primary, "short"), used: primary.usedPercent, resetAt: primary.resetsAt ?? undefined }
			: undefined,
		secondary && typeof secondary.usedPercent === "number"
			? { label: windowLabel(secondary, "long"), used: secondary.usedPercent, resetAt: secondary.resetsAt ?? undefined }
			: undefined,
	].filter((window): window is { label: string; used: number; resetAt: number | undefined } => window !== undefined);

	if (windows.length === 0) {
		return { status: "Codex: no usage data", details: "No Codex rate-limit usage available" };
	}

	const renderStatus = () => `Codex: ${windows.map((window) => {
		const remaining = resetIn(window.resetAt);
		const reset = remaining ? ` ${muted(`(${remaining})`)}` : "";
		return `${window.label} ${prominent(`${Math.round(window.used)}%`)}${reset}`;
	}).join(" · ")}`;
	const planType = usage.rateLimits?.planType;
	const plan = planType ? ` (${planType})` : "";
	return {
		status: renderStatus(),
		details: `Codex usage${plan}: ${windows.map((window) => `${window.label} ${Math.round(window.used)}% used, ${resetDescription(window.resetAt)}`).join("; ")}`,
		renderStatus,
	};
}

async function fetchUsage(ctx: ExtensionContext): Promise<UsageResult> {
	let usage: CodexUsage;
	try {
		usage = await readRateLimits();
	} catch (error) {
		if (error instanceof CodexAuthError) {
			return { status: undefined, details: "No Codex CLI login found; run `codex login`" };
		}
		throw error;
	}
	return formatUsage(
		usage,
		(text) => ctx.ui.theme.fg("dim", text),
		(text) => ctx.ui.theme.fg("accent", ctx.ui.theme.bold(text)),
	);
}

export default function (pi: ExtensionAPI) {
	let request: Promise<UsageResult> | undefined;
	let active = false;
	let lastResult: UsageResult | undefined;
	let countdownTimer: ReturnType<typeof setInterval> | undefined;

	function updateCountdown() {
		if (!active || !lastResult?.renderStatus) return;
		lastResult.status = lastResult.renderStatus();
		pi.events.emit(STATUS_EVENT, { key: STATUS_KEY, status: lastResult.status });
	}

	async function refresh(ctx: ExtensionContext): Promise<UsageResult> {
		if (!request) request = fetchUsage(ctx).finally(() => { request = undefined; });

		try {
			const result = await request;
			lastResult = result;
			if (active) pi.events.emit(STATUS_EVENT, { key: STATUS_KEY, status: result.status });
			return result;
		} catch (error) {
			const message = error instanceof Error ? error.message : "unknown error";
			const result = { status: "Codex: unavailable", details: `Codex usage unavailable: ${message}` };
			lastResult = result;
			if (active) pi.events.emit(STATUS_EVENT, { key: STATUS_KEY, status: result.status });
			return result;
		}
	}

	pi.on("session_start", (_event, ctx) => {
		active = true;
		pi.events.emit(STATUS_EVENT, { key: STATUS_KEY, status: lastResult?.status });
		void refresh(ctx);
		if (countdownTimer) clearInterval(countdownTimer);
		countdownTimer = setInterval(updateCountdown, 30_000);
		countdownTimer.unref();
	});

	pi.on("agent_settled", (_event, ctx) => {
		void refresh(ctx);
	});

	pi.on("session_shutdown", () => {
		active = false;
		if (countdownTimer) clearInterval(countdownTimer);
		countdownTimer = undefined;
		pi.events.emit(STATUS_EVENT, { key: STATUS_KEY, status: undefined });
	});

	pi.registerCommand("codex-usage", {
		description: "Refresh and show OpenAI Codex rate-limit usage",
		handler: async (_args, ctx) => {
			const result = await refresh(ctx);
			ctx.ui.notify(result.details, result.status === "Codex: unavailable" ? "error" : "info");
		},
	});
}
