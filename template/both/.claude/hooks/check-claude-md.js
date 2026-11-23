// PostToolUse hook: warn when an edited CLAUDE.md or AGENTS.md goes over the line limit.
const fs = require("fs");
const path = require("path");

const MAX_LINES = 200;

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  let file;
  try {
    const data = JSON.parse(input);
    file = data.tool_input?.file_path || data.tool_response?.filePath;
  } catch {
    return; // bad input: stay silent, never break the edit
  }
  if (!file || !["CLAUDE.md", "AGENTS.md"].includes(path.basename(file)) || !fs.existsSync(file)) return;

  const text = fs.readFileSync(file, "utf8");
  const lines = text.split("\n").length - (text.endsWith("\n") ? 1 : 0);
  if (lines <= MAX_LINES) return;

  const msg = `${file} has ${lines} lines (limit ${MAX_LINES}). Move details to .claude/rules/, a folder AGENTS.md, or docs/.`;
  console.log(JSON.stringify({ decision: "block", reason: msg, systemMessage: msg }));
});
