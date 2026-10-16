#!/usr/bin/env node
// retext has no CLI of its own; this is remark-cli's, pointed at retext.
import { retext } from "retext";
import { args } from "unified-args";

args({
	description: "Command line interface to inspect and change prose with retext",
	extensions: ["txt", "text"],
	ignoreName: ".retextignore",
	name: "retext",
	packageField: "retextConfig",
	pluginPrefix: "retext",
	processor: retext,
	rcName: ".retextrc",
	version: "@version@",
});
