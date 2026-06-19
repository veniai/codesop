#!/bin/bash
# dependencies.sh - Managed dependency manifest for codesop
#
# Each entry: type|qualified_id|tier|patched|min_version
#   type:        plugin
#   tier:        core | required
#   patched:     yes | no  (whether patch_skills() overwrites this dep)
#   min_version: minimum required version (empty = any)
#
# Patch compat: if patched=yes, patches are compatible with the same
# major.minor as min_version. Different major.minor → patches skipped.

DEP_MANIFEST=(
  # Core — backbone, patches applied
  "plugin|superpowers@claude-plugins-official|core|yes|6.0.3"

  # Required — curated plugins
  "plugin|code-review@claude-plugins-official|required|no|"
  "plugin|skill-creator@claude-plugins-official|required|no|"
  "plugin|frontend-design@claude-plugins-official|required|no|"
  "plugin|context7@claude-plugins-official|required|no|"
  "plugin|code-simplifier@claude-plugins-official|required|no|"
  "plugin|playwright@claude-plugins-official|required|no|"
  "plugin|claude-md-management@claude-plugins-official|required|no|"
  "plugin|chrome-devtools-mcp@claude-plugins-official|required|no|"

  # Required — third-party marketplace
  "plugin|codex@openai-codex|required|no|"
)
