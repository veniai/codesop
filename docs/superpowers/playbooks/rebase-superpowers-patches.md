# Re-base superpowers Patches Checklist

Run this when superpowers ships a major or minor release that changes skill files codesop patches.

## 1. Detect drift

- List installed superpowers versions: `ls ~/.claude/plugins/cache/claude-plugins-official/superpowers/` (orphans show a `.orphaned_at` marker).
- Compare installed major.minor vs `config/dependencies.sh` superpowers `min_version`. If different, `patch_skills()` prints `⚠ superpowers X.Y (patches target A.B.x) — skipping patches` at setup time.
- **Idempotency caveat**: `bash setup --host claude` prints `✓ Skill patches applied (N files)` ONLY when files differ. If patches were already applied (or silently skipped), it prints nothing. For a reliable drift audit, use `diff -q` between each patch in `patches/superpowers/` and its installed counterpart — do not rely on setup stdout alone.

## 2. Per-patch re-base (for each patched skill)

1. Read the new upstream: `~/.claude/plugins/cache/claude-plugins-official/superpowers/<NEW>/skills/<skill>/SKILL.md`
2. Diff current codesop patch vs the upstream baseline it was forked from (the `Based on:` version) to see exactly what codesop changed.
3. Diff the NEW upstream vs the baseline to see what upstream changed.
4. Take the NEW upstream as base; splice codesop's changes back in; adopt upstream's structural changes (don't clobber).
5. Update the patch header `Based on: superpowers v<NEW>` + accurate `Changes vs upstream` list.

## 3. Don't-clobber-upstream-improvements check

Confirm each upstream improvement is inherited (not regressed) by diffing the new patch vs the NEW upstream:

- [ ] Visual companion: per-session key auth + just-in-time offering (brainstorming)
- [ ] Global Constraints block (writing-plans header)
- [ ] per-task Interfaces block (writing-plans Task Structure)
- [ ] Task Right-Sizing section (writing-plans)
- [ ] worktree provenance cleanup guidance (finishing)
- [ ] task-reviewer single-prompt (subagent-driven-development — codesop does NOT patch this)

## 4. Sync setup + manifest + tests

- [ ] If a patch file was added/removed, sync `patch_skills()` mapping blocks in `setup` (else stale "not found, skipping patch" warnings)
- [ ] Bump `config/dependencies.sh` superpowers `min_version` to the new version
- [ ] Update `tests/dep-upgrade.sh` version assertion to match
- [ ] Fix any stale setup comments

## 5. Apply + verify

- [ ] `bash setup --host claude` — expect `✓ Skill patches applied (N files)`, no skip warning
- [ ] `diff` each installed skill vs its patch — must be identical. Because setup is idempotent (prints nothing when patches are already applied), always verify with explicit `diff -q` rather than trusting setup stdout.
- [ ] `bash tests/run_all.sh` — all pass

## 6. Remind users

After any superpowers upgrade (via Claude Code plugin manager, not via codesop), users MUST re-run `bash setup --host claude` so patches re-evaluate against the new version. The drift warning only fires at setup time.
