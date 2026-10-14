---
name: del
description: 저장 목록에서 세션 제거 (이름 생략 시 현재 세션). 대화 기록은 남음
argument-hint: [이름]
disable-model-invocation: true
allowed-tools: Bash(powershell *), PowerShell(powershell *)
---

!`powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/../save/sessions.ps1" del "${CLAUDE_SESSION_ID}" "$ARGUMENTS"`

The text above is the finished result of the /del command. Show it to the user as-is, in Korean, rendering any table as a markdown table. Do not run tools, do not take any other action, and do not add commentary.
