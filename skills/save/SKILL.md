---
name: save
description: 현재 세션을 저장 목록에 추가 (이름 생략 시 /rename 제목 또는 폴더명)
argument-hint: [이름]
disable-model-invocation: true
allowed-tools: Bash(powershell *), PowerShell(powershell *)
---

!`powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/../save/sessions.ps1" save "${CLAUDE_SESSION_ID}" "$ARGUMENTS"`

The text above is the finished result of the /save command. Show it to the user as-is, in Korean, rendering any table as a markdown table. Do not run tools, do not take any other action, and do not add commentary.
