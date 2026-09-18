/**
 * Show OpenAI Codex rate-limit usage in Pi's footer.
 *
 * Uses the OAuth credential already stored by `/login openai-codex`.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "codex-usage";
const STATUS_EVENT = "usage-status:update";
const REQUEST_TIMEOUT_MS = 8_000;
const USAGE_URL = "https://chatgpt.com/backend-api/wham/usage";

interface UsageWindow {
	used_percent?: number;
	limit_window_seconds?: number;
	reset_at?: number;
}

interface CodexUsage {
	plan_type?: string;
	rate_limit?: {
		primary_window?: UsageWindow;
		secondary_window?: UsageWindow;
	};
}

interface UsageResult {
	status?: string;
	details: string;
	renderStatus?: () => string;
}

function accountIdFromToken(token: string): string | undefined {
	try {
		const payload = token.split(".")[1];
		if (!payload) return undefined;
		const decoded = JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as Record<string, unknown>;
		const auth = decoded["https://api.openai.com/auth"];
		if (!auth || typeof auth !== "object") return undefined;
		const accountId = (auth as Record<string, unknown>).chatgpt_account_id;
		return typeof accountId === "string" && accountId !== "" ? accountId : undefined;
	} catch {
		return undefined;
	}
}

function windowLabel(window: UsageWindow, fallback: string): string {
	const seconds = window.limit_window_seconds;
	if (typeof seconds !== "number") return fallback;
	if (seconds >= 6 * 24 * 60 * 60) return "7d";
	if (seconds % (60 * 60) === 0) return `${seconds / (60 * 60)}h`;
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
	const primary = usage.rate_limit?.primary_window;
	const secondary = usage.rate_limit?.secondary_window;
	const windows = [
		primary && typeof primary.used_percent === "number"
			? { label: windowLabel(primary, "short"), used: primary.used_percent, resetAt: primary.reset_at }
			: undefined,
		secondary && typeof secondary.used_percent === "number"
			? { label: windowLabel(secondary, "long"), used: secondary.used_percent, resetAt: secondary.reset_at }
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
	const plan = usage.plan_type ? ` (${usage.plan_type})` : "";
	return {
		status: renderStatus(),
		details: `Codex usage${plan}: ${windows.map((window) => `${window.label} ${Math.round(window.used)}% used, ${resetDescription(window.resetAt)}`).join("; ")}`,
		renderStatus,
	};
}

async function fetchUsage(ctx: ExtensionContext): Promise<UsageResult> {
	const resolved = await ctx.modelRegistry.getProviderAuth("openai-codex");
	const accessToken = resolved?.auth.apiKey;
	if (!accessToken) {
		return { details: "No OpenAI Codex login found; run /login openai-codex" };
	}

	const accountId = accountIdFromToken(accessToken);
	if (!accountId) throw new Error("OpenAI OAuth token has no account ID");

	const response = await fetch(USAGE_URL, {
		headers: {
			Accept: "application/json",
			Authorization: `Bearer ${accessToken}`,
			"ChatGPT-Account-Id": accountId,
			"User-Agent": "pi-coding-agent",
		},
		signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
	});

	if (!response.ok) throw new Error(`OpenAI API returned ${response.status}`);
	return formatUsage(
		(await response.json()) as CodexUsage,
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
