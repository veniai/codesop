---
description: Update the local codesop installation via the codesop CLI.
---

Run the real CLI:

```bash
bash ~/.local/bin/codesop update
```

Report what was updated and whether host integrations need resync.

**Important**: When the CLI reports missing plugins or skills with install commands, you MUST preserve those install commands verbatim in your output. Do NOT summarize or reformat them into a table. Users need to copy-paste the exact `/plugin install` or `git clone` commands.

For each dependency that has a changelog, provide a **plain Chinese summary** of what changed — translate the technical changelog into everyday language so the user can quickly understand the impact without reading raw release notes.
