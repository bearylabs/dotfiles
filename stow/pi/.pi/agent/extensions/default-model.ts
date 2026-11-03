/**
 * Enforce `defaultProvider`/`defaultModel` from settings for new sessions.
 *
 * Workaround for a startup race in pi 1.4.0: registering an extension provider
 * (e.g. pi-claude-cli) fires an unawaited availability refresh that supersedes
 * the awaited startup refresh. `findInitialModel` then sometimes sees the
 * provider as unconfigured and falls back to the built-in default of another
 * logged-in provider (openai → gpt-5.5).
 *
 * Skipped for resumed sessions and when a model is passed on the command line.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const WAIT_TIMEOUT_MS = 5_000;
const POLL_INTERVAL_MS = 50;
const CLI_MODEL_FLAGS = ["--model", "--provider", "--models"];

function modelChosenOnCli(): boolean {
	return process.argv.some((arg) => CLI_MODEL_FLAGS.some((flag) => arg === flag || arg.startsWith(`${flag}=`)));
}

function hasMessages(ctx: ExtensionContext): boolean {
	return ctx.sessionManager.getBranch().some((entry) => entry.type === "message");
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (event, ctx) => {
		if (event.reason !== "startup" && event.reason !== "new") return;
		if (modelChosenOnCli() || hasMessages(ctx)) return;

		const settings = pi.getSettings() as { defaultProvider?: string; defaultModel?: string };
		const { defaultProvider, defaultModel } = settings;
		if (!defaultProvider || !defaultModel) return;
		if (ctx.model?.provider === defaultProvider && ctx.model.id === defaultModel) return;

		const deadline = Date.now() + WAIT_TIMEOUT_MS;
		while (Date.now() < deadline) {
			const model = ctx.modelRegistry.find(defaultProvider, defaultModel);
			if (model && ctx.modelRegistry.hasConfiguredAuth(model)) {
				await pi.setModel(model);
				return;
			}
			await sleep(POLL_INTERVAL_MS);
		}
	});
}
