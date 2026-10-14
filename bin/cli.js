#!/usr/bin/env node
// Thin wrapper so `npx claude-tab-sessions install|uninstall` runs the bundled PowerShell scripts.
const { spawnSync } = require("child_process");
const path = require("path");

const [command, ...rest] = process.argv.slice(2);
const scripts = { install: "install.ps1", uninstall: "uninstall.ps1" };

if (!scripts[command]) {
  console.log("Usage: npx claude-tab-sessions <install|uninstall> [-ConfigDir <dir>] [-Force] [-Purge]");
  process.exit(command ? 1 : 0);
}
if (process.platform !== "win32") {
  console.error("claude-tab-sessions currently supports Windows only.");
  process.exit(1);
}

const script = path.join(__dirname, "..", scripts[command]);
const result = spawnSync(
  "powershell.exe",
  ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script, ...rest],
  { stdio: "inherit" }
);
process.exit(result.status ?? 1);
