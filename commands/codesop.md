---
description: Run the codesop CLI. Use for explicit mechanical codesop commands like `/codesop init`, `/codesop status`, `/codesop setup`, `/codesop update`, or `/codesop version`.
---

# codesop Command

This command is a thin wrapper around the local `codesop` CLI.

## What to do

1. Run the local CLI, do not re-implement the logic in conversation.
2. Use `~/.local/bin/codesop` first.
3. Pass the user arguments through exactly.
4. If the CLI is missing, say the installation is incomplete and stop.
5. Summarize the CLI output faithfully.
6. Do not produce a separate workbench summary or skill-routing section unless the user explicitly asks for next-step advice.

## Command

```bash
bash ~/.local/bin/codesop $ARGUMENTS
```
