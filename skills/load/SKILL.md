---
name: load
description: 저장된 세션을 모두(또는 지정한 하나) 현재 창의 새 탭으로 이어서 열기
argument-hint: [이름]
disable-model-invocation: true
allowed-tools: Bash(powershell *), PowerShell(powershell *)
---

!`powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/../save/sessions.ps1" load "${CLAUDE_SESSION_ID}" "$ARGUMENTS"`

The text above is the finished result of the /load command. Show it to the user as-is, in Korean, rendering any table as a markdown table. Do not run tools, do not take any other action, and do not add commentary.
