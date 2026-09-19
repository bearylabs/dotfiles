/**
 * Show the Claude extra-usage budget relevant to Pi in its footer.
 *
 * Pi's Anthropic subscription OAuth traffic is billed as extra usage rather
 * than counting against Claude's 5-hour or 7-day plan limits.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "claude-usage";
const STATUS_EVENT = "usage-status:update";
const REQUEST_TIMEOUT_MS = 8_000;
const API_BASE_URL = "https://api.anthropic.com";
const USAGE_URL = `${API_BASE_URL}/api/oauth/usage`;
const PROFILE_URL = `${API_BASE_URL}/api/oauth/profile`;

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
}

interface ExtraUsageDisplay {
	enabled: boolean;
	used?: string;
	limit?: string;
	percent?: number;
	limitReached: boolean;
	disabledReason?: string;
}

function percentage(value: number): string {
	return `${Math.round(Math.max(0, value))}%`;
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
			disabledReason: spend.disabled_reason ?? undefined,
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
		disabledReason: extra?.disabled_reason ?? undefined,
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

function formatUsage(
	usage: ClaudeUsage,
	currentBalance: string | undefined,
	prominent: (text: string) => string,
): UsageResult {
	const extra = extraUsageDisplay(usage);
	if (!extra.enabled) {
		const reason = extra.disabledReason ? `: ${extra.disabledReason}` : "";
		return {
			status: "Claude: off",
			details: `Claude usage is disabled${reason}`,
		};
	}

	const amounts = extra.used && extra.limit ? `${extra.used}/${extra.limit}` : extra.used;
	const percent = extra.percent === undefined ? undefined : percentage(extra.percent);
	const summary = [amounts, percent ? `(${percent})` : undefined].filter(Boolean).join(" ") || "enabled";
	const balance = currentBalance ? ` · Bal. ${prominent(currentBalance)}` : "";
	const warning = extra.limitReached ? " !" : "";

	return {
		status: `Claude: ${prominent(summary)}${balance}${warning}`,
		details: `Claude usage: ${summary}${currentBalance ? `; current balance ${currentBalance}` : ""}${extra.limitReached ? ", limit reached" : ""}`,
	};
}

async function fetchUsage(ctx: ExtensionContext): Promise<UsageResult> {
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
	const [usageResponse, profileResponse] = await Promise.all([
		fetch(USAGE_URL, { headers, signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) }),
		fetch(PROFILE_URL, { headers, signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) }),
	]);
	if (!usageResponse.ok) throw new Error(`Anthropic usage API returned ${usageResponse.status}`);
	if (!profileResponse.ok) throw new Error(`Anthropic profile API returned ${profileResponse.status}`);

	const usage = (await usageResponse.json()) as ClaudeUsage;
	const profile = (await profileResponse.json()) as ClaudeProfile;
	const organizationId = profile.organization?.uuid;
	if (!organizationId) throw new Error("Anthropic profile has no organization ID");

	const balanceResponse = await fetch(
		`${API_BASE_URL}/api/oauth/organizations/${encodeURIComponent(organizationId)}/prepaid/credits`,
		{
			headers: { ...headers, "x-organization-uuid": organizationId },
			signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
		},
	);
	if (!balanceResponse.ok) throw new Error(`Anthropic balance API returned ${balanceResponse.status}`);
	const balance = formatBalance((await balanceResponse.json()) as CreditBalance);

	return formatUsage(
		usage,
		balance,
		(text) => ctx.ui.theme.fg("accent", ctx.ui.theme.bold(text)),
	);
}

export default function (pi: ExtensionAPI) {
	let request: Promise<UsageResult> | undefined;
	let active = false;
	let lastResult: UsageResult | undefined;

	async function refresh(ctx: ExtensionContext): Promise<UsageResult> {
		if (!request) request = fetchUsage(ctx).finally(() => { request = undefined; });

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
	});

	pi.on("agent_settled", (_event, ctx) => {
		void refresh(ctx);
	});

	pi.on("session_shutdown", () => {
		active = false;
		pi.events.emit(STATUS_EVENT, { key: STATUS_KEY, status: undefined });
	});

	pi.registerCommand("claude-usage", {
		description: "Refresh and show Claude usage",
		handler: async (_args, ctx) => {
			const result = await refresh(ctx);
			ctx.ui.notify(result.details, result.status === "Claude: unavailable" ? "error" : "info");
		},
	});
}
