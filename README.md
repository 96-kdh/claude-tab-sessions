# claude-tab-sessions

Claude Code 세션을 저장해 두고, 나중에 **저장한 세션 전부를 Windows Terminal 탭으로 한 번에 이어서 여는** 슬래시 명령 모음.

> 현재 **Windows (PowerShell + Windows Terminal) 전용**. macOS 지원은 예정.
> English summary at the bottom.

| 명령 | 동작 |
|---|---|
| `/save [이름]` | 현재 세션을 저장 목록에 추가. 이름 생략 시 `/rename` 제목 또는 `폴더명-ID앞4자리`. 다시 실행하면 이름 변경 |
| `/load [이름]` | 저장된 세션을 현재 창의 새 탭으로 이어서 열기 (`claude --resume`). 지금 세션·이미 열린 세션·기록 없는 세션은 건너뜀 |
| `/del [이름]` | 저장 목록에서 제거 (이름 생략 시 현재 세션). 대화 기록은 남음. 세션 종료는 `/exit` |
| `/list` | 저장 목록 보기 (상태, 마지막 활동, 자동삭제까지 남은 일수) |
| `/clean [apply]` | 저장되지 않았고 실행 중도 아닌 세션 기록 정리. 기본은 미리보기, `apply` 를 붙이면 실제 삭제 |

## 설치

세 방법 중 **하나만** 쓰세요. A·C 는 `/save` 처럼 짧은 이름, B 는 플러그인 규칙상 `/tab-sessions:save` 형태가 될 수 있습니다.

### A. 한 줄 설치 (PowerShell)

```powershell
irm https://raw.githubusercontent.com/96-kdh/claude-tab-sessions/main/get.ps1 | iex
```

또는 저장소를 받아서:

```powershell
git clone https://github.com/96-kdh/claude-tab-sessions
.\claude-tab-sessions\install.ps1            # -ConfigDir <dir>, -Force
```

### B. Claude Code 플러그인

Claude Code 안에서:

```
/plugin marketplace add 96-kdh/claude-tab-sessions
/plugin install tab-sessions@claude-tab-sessions
```

### C. npm

```powershell
npx claude-tab-sessions install               # -ConfigDir <dir>, -Force
```

### 설치 위치
- `-ConfigDir` → 없으면 `CLAUDE_CONFIG_DIR` 환경변수 → 없으면 `~\.claude`
- 계정별 설정 폴더를 여러 개 쓰면 폴더마다 설치하세요. 저장 목록(`~\.claude-saved-sessions.json`)은 하나를 공유하고, 각 세션은 자기 설정 폴더로 열립니다.
- 같은 이름의 다른 스킬이 이미 있으면 덮어쓰지 않고 건너뜁니다 (`-Force` 로 덮어쓰기).
- 설치 후 **새로 여는 Claude Code 세션**부터 적용됩니다.

### 삭제

```powershell
.\uninstall.ps1                 # 또는: npx claude-tab-sessions uninstall
.\uninstall.ps1 -Purge          # 저장 목록 파일까지 삭제 (대화 기록은 건드리지 않음)
```

플러그인은 `/plugin uninstall tab-sessions@claude-tab-sessions`.

## 사용 흐름

1. 이어서 할 세션마다 `/save 이름`
2. 작업 끝나면 터미널 창을 그냥 닫기
3. 다음에 Claude Code 를 하나 열고 `/load` → 저장한 세션들이 이름 붙은 탭으로 열림

## 알아둘 것

- **이름에 따옴표를 쓰지 마세요.** `/save new char` 처럼 그대로 쓰면 공백 포함 이름이 됩니다.
- **30일 자동삭제**: Claude Code 는 마지막 활동 후 `cleanupPeriodDays`(기본 30일)가 지난 대화 기록을 지웁니다. 저장한 세션도 예외가 아니니 `/list` 의 "자동삭제까지" 를 확인하세요.
- **`/clean apply` 는 되돌릴 수 없습니다.** 저장된 세션, 실행 중인 세션, 지금 세션은 지우지 않습니다. 실행 중인 세션은 Claude Code 내부 파일(`<설정폴더>\sessions\*.json`)로 판단하는데, 이 형식이 바뀌어 지금 세션조차 확인되지 않으면 정리를 중단합니다.
- `/del` 은 목록에서만 빼고 세션을 종료하지 않습니다. Claude Code 에는 스스로 종료하는 공식 방법이 없어 `/exit` 를 직접 입력해야 합니다.
- 사용자 스킬은 같은 이름의 Claude Code 기본 명령보다 우선합니다 (로컬 터미널 기준). 나중에 기본 명령에 `/save` 등이 생겨도 이 도구가 실행됩니다.
- 사용량 한도에 걸린 상태에서는 결과 메시지를 보여주는 단계가 실패할 수 있습니다.

## 구조

```
skills/
  save/SKILL.md, save/sessions.ps1   ← 모든 로직은 sessions.ps1 하나
  load/ del/ list/ clean/SKILL.md     ← 각 명령은 sessions.ps1 을 호출해 결과만 보여줌
get.ps1                               ← A 한 줄 설치 (다운로드 후 install.ps1 실행)
install.ps1 / uninstall.ps1           ← A, C 설치
.claude-plugin/                       ← B (plugin.json, marketplace.json)
bin/cli.js, package.json              ← C (npm)
```

## License

MIT

---

## English summary

Slash commands for Claude Code that bookmark sessions and reopen all of them as Windows Terminal tabs.
`/save [name]`, `/load [name]`, `/del [name]`, `/list`, `/clean [apply]`. Windows only for now (messages are in Korean).

Install one of: `irm https://raw.githubusercontent.com/96-kdh/claude-tab-sessions/main/get.ps1 | iex`,
`/plugin marketplace add 96-kdh/claude-tab-sessions` + `/plugin install tab-sessions@claude-tab-sessions`,
or `npx claude-tab-sessions install`.
