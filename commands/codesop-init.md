---
description: Initialize project AGENTS.md, PRD.md, and README.md scaffolding via the codesop CLI.
---

# codesop init

Initialize a project with AI coding scaffolding.

## Step 0: Sync skill files

```bash
CODESOP_SOURCE=$(readlink -f ~/.local/bin/codesop | xargs dirname)
bash "$CODESOP_SOURCE/setup" --host claude 2>&1
```

Then read the fresh skill file and follow Steps 1+ (skip this Step 0):

```bash
cat ~/.claude/commands/codesop-init.md
```

## Step 1: Check if user preferences exist

```bash
CODESOP_SOURCE=$(readlink -f ~/.local/bin/codesop | xargs dirname)
TEMPLATE_FILE="$CODESOP_SOURCE/templates/system/AGENTS.md"

if [ -f "$TEMPLATE_FILE" ] && grep -q '{LANG}\|{STYLE}\|{FUNC_LENGTH}\|{COMMENT_STYLE}' "$TEMPLATE_FILE" 2>/dev/null; then
  echo "NEEDS_INTERVIEW:$TEMPLATE_FILE"
else
  echo "PREFERENCES_SET"
fi
```

## Step 2: Conduct interview if needed

If the output shows "NEEDS_INTERVIEW:", use AskUserQuestion to ask these 4 questions:

**Question 1:** 你希望 AI 默认使用什么语言？
- A) 中文
- B) English

**Question 2:** 你的代码风格偏好？
- A) 简洁 - 最少代码完成功能
- B) 标准 - 平衡可读性和简洁性
- C) 详细 - 充分注释和类型

**Question 3:** 函数长度偏好？
- A) 无限制
- B) 建议 <= 50 行
- C) 建议 <= 25 行

**Question 4:** 代码注释风格？
- A) 必要才注释
- B) 标准注释
- C) 详细注释

## Step 3: Write preferences to template

After collecting answers, update the template file (use the path from Step 1):

```bash
LANG_CHOICE="<answer1: 中文 or English>"
STYLE_CHOICE="<answer2: 简洁 or 标准 or 详细>"
FUNC_CHOICE="<answer3: 无限制 or 建议 <= 50 行 or 建议 <= 25 行>"
COMMENT_CHOICE="<answer4: 必要才注释 or 标准注释 or 详细注释>"

sed -i.bak \
  -e "s/{LANG}/$LANG_CHOICE/g" \
  -e "s/{STYLE}/$STYLE_CHOICE/g" \
  -e "s/{FUNC_LENGTH}/$FUNC_CHOICE/g" \
  -e "s/{COMMENT_STYLE}/$COMMENT_CHOICE/g" \
  "$TEMPLATE_FILE"

echo "✓ 用户偏好已保存"
```

## Step 4: Run CLI for system setup and project files

```bash
bash ~/.local/bin/codesop init $ARGUMENTS
```

This handles:
- Phase 0: tool detection, system links, enable CLAUDE_CODE_NEW_INIT
- Phase 1: user preferences (skipped if already done in Step 2-3)
- Phase 3: AGENTS.md, PRD.md, README.md
- Phase 4: skill dependency checks

## Step 5: Prompt user to run /init

After the CLI completes, tell the user:

> 初始化完成。请在当前会话中运行 `/init` 生成项目级 CLAUDE.md。

Do NOT generate CLAUDE.md yourself. Claude Code's official `/init` handles this better.

## After running:

- report which files were generated or preserved
- report environment detection and install/update suggestions
- do not add project scoring, workbench summary, or skill routing unless the user separately asks
