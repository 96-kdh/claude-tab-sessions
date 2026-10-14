---
name: clean
description: 저장/실행 중이 아닌 세션 기록 정리. 기본은 미리보기, apply 를 붙이면 실제 삭제
argument-hint: [apply]
disable-model-invocation: true
allowed-tools: Bash(powershell *), PowerShell(powershell *)
---

!`powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/../save/sessions.ps1" clean "${CLAUDE_SESSION_ID}" "$ARGUMENTS"`

The text above is the finished result of the /clean command. Show it to the user as-is, in Korean, rendering any table as a markdown table. Do not run tools, do not take any other action, and do not add commentary.
