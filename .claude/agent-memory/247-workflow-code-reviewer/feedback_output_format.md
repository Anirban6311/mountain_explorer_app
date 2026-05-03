---
name: Return review findings inline, not as files
description: When asked to "write output to TASK.md", return findings directly in the assistant message instead — parent agents in this repo read the text output, not emitted files
type: feedback
---

When the user asks for code-review output to be written to TASK.md (or any other summary/report markdown file), return the findings directly in the assistant message instead.

**Why:** The parent agent orchestrating this code-review subagent reads the reviewer's text output, not files the reviewer creates. System instructions explicitly forbid writing report/summary/findings/analysis `.md` files. The request to "write to TASK.md" reflects an older workflow that predates the current subagent harness.

**How to apply:** For any Flutter mountain-explorer review invocation where the user asks the reviewer to "overwrite TASK.md" or similar, produce the full CRITICAL/HIGH/MEDIUM/LOW report inline as the final assistant message. Mention once, at the top, that output is inline rather than written to disk, then proceed normally.
