#!/usr/bin/env node
// Compiles MDX to JavaScript with @mdx-js/mdx, which has no CLI of its own.
//
//   mdx [--options <file.json>] [--out-dir <dir>] <file>...
//
// The options file holds @mdx-js/mdx's compile options, except that
// remarkPlugins, rehypePlugins and recmaPlugins name each plugin by the path
// of its entry file, alone or as [path, options]. Each input is written as a
// `.js` file beside itself, or under --out-dir at the same relative path.
import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { parseArgs } from "node:util";
import { compile } from "@mdx-js/mdx";

const usage = "Usage: mdx [--options <file.json>] [--out-dir <dir>] <file>...";

const { values, positionals } = parseArgs({
	allowPositionals: true,
	options: {
		help: { type: "boolean", short: "h" },
		options: { type: "string" },
		"out-dir": { type: "string", short: "o" },
		version: { type: "boolean", short: "v" },
	},
});

if (values.version) {
	console.log("@version@");
} else if (values.help) {
	console.log(usage);
} else if (positionals.length === 0) {
	console.error(usage);
	process.exitCode = 1;
} else {
	await main();
}

async function main() {
	const options = values.options
		? JSON.parse(await fs.readFile(values.options, "utf8"))
		: {};

	for (const key of ["remarkPlugins", "rehypePlugins", "recmaPlugins"]) {
		if (options[key]) options[key] = await Promise.all(options[key].map(load));
	}

	for (const input of positionals) {
		const output = path.join(
			values["out-dir"] ?? ".",
			path.dirname(input),
			path.basename(input, path.extname(input)) + ".js",
		);

		try {
			const value = await fs.readFile(input, "utf8");
			const file = await compile({ path: input, value }, options);
			await fs.mkdir(path.dirname(output), { recursive: true });
			await fs.writeFile(output, String(file));
			for (const message of file.messages) console.error(String(message));
		} catch (error) {
			console.error(input + ": " + String(error));
			process.exitCode = 1;
		}
	}
}

async function load(plugin) {
	const [file, ...rest] = Array.isArray(plugin) ? plugin : [plugin];
	const module = await import(pathToFileURL(path.resolve(file)).href);
	return [module.default, ...rest];
}
