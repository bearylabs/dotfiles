/**
 * Show Claude subscription rate-limit usage in Pi's footer.
 *
 * Mirrors codex-usage.ts: shows the 5-hour and 7-day windows with a reset
 * countdown. Extra usage (billed beyond the plan) is appended when enabled.
 *
 * Uses the OAuth credential already stored by `/login anthropic`.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "claude-usage";
const STATUS_EVENT = "usage-status:update";
const REQUEST_TIMEOUT_MS = 8_000;
const API_BASE_URL = "https://api.anthropic.com";
const USAGE_URL = `${API_BASE_URL}/api/oauth/usage`;
const PROFILE_URL = `${API_BASE_URL}/api/oauth/profile`;

interface UsageWindow {
	utilization?: number | null;
	resets_at?: string | null;
}

interface ExtraUsage {
	is_enabled?: boolean;
	monthly_limit?: number | null;
	used_credits?: number | null;
	utilization?: number | null;
	currency?: string | null;
	decimal_places?: number | null;
	spend_limit_reached?: boolean;
	disabled_reason?: string | null;
}

interface Money {
	amount_minor?: number;
	currency?: string;
	exponent?: number;
}

interface SpendUsage {
	enabled?: boolean;
	used?: Money | null;
	limit?: Money | null;
	percent?: number | null;
	severity?: string;
	disabled_reason?: string | null;
}

interface ClaudeUsage {
	five_hour?: UsageWindow | null;
	seven_day?: UsageWindow | null;
	seven_day_opus?: UsageWindow | null;
	seven_day_sonnet?: UsageWindow | null;
	extra_usage?: ExtraUsage | null;
	spend?: SpendUsage | null;
}

interface ClaudeProfile {
	organization?: {
		uuid?: string;
	};
}

interface CreditBalance {
	amount?: number;
	currency?: string;
	balance?: {
		money?: Money | null;
	} | null;
}

interface UsageResult {
	status?: string;
	details: string;
	renderStatus?: () => string;
}

interface ExtraUsageDisplay {
	enabled: boolean;
	used?: string;
	limit?: string;
	percent?: number;
	limitReached: boolean;
}

interface WindowDisplay {
	label: string;
	used: number;
	resetAt: number | undefined;
}

function formatMoney(amountMinor: number, currency: string, decimalPlaces: number, omitZeroFraction = false): string {
	const divisor = 10 ** decimalPlaces;
	const fractionDigits = omitZeroFraction && amountMinor % divisor === 0 ? 0 : decimalPlaces;
	try {
		return new Intl.NumberFormat(undefined, {
			style: "currency",
			currency,
			minimumFractionDigits: fractionDigits,
			maximumFractionDigits: fractionDigits,
		}).format(amountMinor / divisor);
	} catch {
		return `${(amountMinor / divisor).toFixed(fractionDigits)} ${currency}`;
	}
}

function extraUsageDisplay(usage: ClaudeUsage): ExtraUsageDisplay {
	const spend = usage.spend;
	if (spend) {
		const used = spend.used;
		const limit = spend.limit;
		return {
			enabled: spend.enabled === true,
			used: typeof used?.amount_minor === "number" && used.currency
				? formatMoney(used.amount_minor, used.currency, used.exponent ?? 2)
				: undefined,
			limit: typeof limit?.amount_minor === "number" && limit.currency
				? formatMoney(limit.amount_minor, limit.currency, limit.exponent ?? 2, true)
				: undefined,
			percent: typeof spend.percent === "number" ? spend.percent : undefined,
			limitReached: spend.severity === "exhausted" || (spend.percent ?? 0) >= 100,
		};
	}

	const extra = usage.extra_usage;
	const currency = extra?.currency || "USD";
	const decimals = typeof extra?.decimal_places === "number" ? extra.decimal_places : 2;
	return {
		enabled: extra?.is_enabled === true,
		used: typeof extra?.used_credits === "number"
			? formatMoney(extra.used_credits, currency, decimals)
			: undefined,
		limit: typeof extra?.monthly_limit === "number"
			? formatMoney(extra.monthly_limit, currency, decimals, true)
			: undefined,
		percent: typeof extra?.utilization === "number" ? extra.utilization : undefined,
		limitReached: extra?.spend_limit_reached === true,
	};
}

function formatBalance(credits: CreditBalance): string | undefined {
	const money = credits.balance?.money;
	if (typeof money?.amount_minor === "number" && money.currency) {
		return formatMoney(money.amount_minor, money.currency, money.exponent ?? 2);
	}
	if (typeof credits.amount === "number" && credits.currency) {
		return formatMoney(credits.amount, credits.currency, 2);
	}
	return undefined;
}

function parseResetAt(value: string | null | undefined): number | undefined {
	if (!value) return undefined;
	const ms = Date.parse(value);
	return Number.isNaN(ms) ? undefined : ms / 1_000;
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

function toWindow(window: UsageWindow | null | undefined, label: string): WindowDisplay | undefined {
	if (!window || typeof window.utilization !== "number") return undefined;
	return { label, used: window.utilization, resetAt: parseResetAt(window.resets_at) };
}

function formatUsage(
	usage: ClaudeUsage,
	currentBalance: string | undefined,
	muted: (text: string) => string,
	prominent: (text: string) => string,
): UsageResult {
	const windows = [
		toWindow(usage.five_hour, "5h"),
		toWindow(usage.seven_day, "7d"),
	].filter((window): window is WindowDisplay => window !== undefined);
	const detailWindows = [
		...windows,
		toWindow(usage.seven_day_opus, "7d Opus"),
		toWindow(usage.seven_day_sonnet, "7d Sonnet"),
	].filter((window): window is WindowDisplay => window !== undefined);

	const extra = extraUsageDisplay(usage);
	const extraAmounts = extra.used && extra.limit ? `${extra.used}/${extra.limit}` : extra.used;

	if (windows.length === 0 && !extra.enabled) {
		return { status: "Claude: no usage data", details: "No Claude rate-limit usage available" };
	}

	const renderStatus = () => {
		const parts = windows.map((window) => {
			const remaining = resetIn(window.resetAt);
			const reset = remaining ? ` ${muted(`(${remaining})`)}` : "";
			return `${window.label} ${prominent(`${Math.round(window.used)}%`)}${reset}`;
		});
		if (extra.enabled && extraAmounts) {
			parts.push(`Extra ${prominent(extraAmounts)}${extra.limitReached ? " !" : ""}`);
		}
		return `Claude: ${parts.join(" · ")}`;
	};

	const detailParts = detailWindows.map(
		(window) => `${window.label} ${Math.round(window.used)}% used, ${resetDescription(window.resetAt)}`,
	);
	if (extra.enabled) {
		const percent = extra.percent === undefined ? "" : ` (${Math.round(extra.percent)}%)`;
		detailParts.push(`extra usage ${extraAmounts ?? "enabled"}${percent}${extra.limitReached ? ", limit reached" : ""}`);
	}
	if (currentBalance) detailParts.push(`current balance ${currentBalance}`);

	return {
		status: renderStatus(),
		details: `Claude usage: ${detailParts.join("; ")}`,
		renderStatus,
	};
}

async function fetchBalance(headers: Record<string, string>): Promise<string | undefined> {
	try {
		const profileResponse = await fetch(PROFILE_URL, { headers, signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) });
		if (!profileResponse.ok) return undefined;
		const organizationId = ((await profileResponse.json()) as ClaudeProfile).organization?.uuid;
		if (!organizationId) return undefined;

		const balanceResponse = await fetch(
			`${API_BASE_URL}/api/oauth/organizations/${encodeURIComponent(organizationId)}/prepaid/credits`,
			{
				headers: { ...headers, "x-organization-uuid": organizationId },
				signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
			},
		);
		if (!balanceResponse.ok) return undefined;
		return formatBalance((await balanceResponse.json()) as CreditBalance);
	} catch {
		return undefined;
	}
}

async function fetchUsage(ctx: ExtensionContext, includeBalance: boolean): Promise<UsageResult> {
	const resolved = await ctx.modelRegistry.getProviderAuth("anthropic");
	const accessToken = resolved?.auth.apiKey;
	if (!accessToken) {
		return { details: "No Anthropic login found; run /login anthropic" };
	}
	if (!accessToken.startsWith("sk-ant-oat")) {
		return { details: "Claude usage requires an Anthropic subscription login; API keys have no subscription quota" };
	}

	const headers = {
		Accept: "application/json",
		Authorization: `Bearer ${accessToken}`,
		"anthropic-beta": "oauth-2025-04-20",
		"User-Agent": "pi-coding-agent",
	};
	const [usageResponse, balance] = await Promise.all([
		fetch(USAGE_URL, { headers, signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) }),
		includeBalance ? fetchBalance(headers) : Promise.resolve(undefined),
	]);
	if (!usageResponse.ok) throw new Error(`Anthropic usage API returned ${usageResponse.status}`);

	return formatUsage(
		(await usageResponse.json()) as ClaudeUsage,
		balance,
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

	async function refresh(ctx: ExtensionContext, includeBalance = false): Promise<UsageResult> {
		if (!request) request = fetchUsage(ctx, includeBalance).finally(() => { request = undefined; });

		try {
			const result = await request;
			lastResult = result;
			if (active) pi.events.emit(STATUS_EVENT, { key: STATUS_KEY, status: result.status });
			return result;
		} catch (error) {
			const message = error instanceof Error ? error.message : "unknown error";
			const result = { status: "Claude: unavailable", details: `Claude usage unavailable: ${message}` };
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

	pi.registerCommand("claude-usage", {
		description: "Refresh and show Claude rate-limit usage",
		handler: async (_args, ctx) => {
			const result = await refresh(ctx, true);
			ctx.ui.notify(result.details, result.status === "Claude: unavailable" ? "error" : "info");
		},
	});
}
