---
name: list
description: 저장된 세션 목록 보기 (읽기 전용)
argument-hint: 
disable-model-invocation: true
allowed-tools: Bash(powershell *), PowerShell(powershell *)
---

!`powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/../save/sessions.ps1" list "${CLAUDE_SESSION_ID}" "$ARGUMENTS"`

The text above is the finished result of the /list command. Show it to the user as-is, in Korean, rendering any table as a markdown table. Do not run tools, do not take any other action, and do not add commentary.
