---
name: 최초셋팅
description: 새 컴퓨터에서 Claude Code 개인 환경을 한 번에 설치한다 — 20대 시니컬 페르소나 + statusline(model/effort/context) + 완료/입력대기 토스트 알림. Windows 전용, 머신당 1회.
---

# 최초셋팅 — 새 컴퓨터 Claude Code 환경 부트스트랩

이 PC에 내 개인 Claude Code 환경을 깐다. **머신마다 한 번만** 실행.
배포 대상은 전부 `~/.claude/` 글로벌 로컬 파일이라 git(study 레포)에 안 실리는 것들 — 그래서 이 스킬 `assets/`에 **번들 스냅샷**으로 들고 다님.

## 전제
- Windows + PowerShell 7(`pwsh`) + Git 설치돼 있어야 함
- 배포할 파일은 `~/.claude/skills/최초셋팅/assets/`에 있음 (setup.ps1이 레포 `최초셋팅/`을 여기로 junction 연결 → 레포 파일과 동일). 아래 단계의 `assets/`는 전부 이 경로 기준 — persona-20대시니컬남성.md, statusline.ps1, hooks/notify.ps1

## ⚠️ 절대 규칙 (안 지키면 *조용히* 실패함)
1. settings.json의 `command` 경로는 **반드시 슬래시**(`C:/Users/...`). 백슬래시 쓰면 Claude Code가 Windows에서 Git Bash 경유로 실행할 때 백슬래시를 escape로 먹어버려 **에러 없이 실패**함
2. 인터프리터는 `powershell`(5.1) 아니라 **`pwsh`(7)**. BurntToast가 PS7 모듈 경로에만 깔리고, pwsh가 UTF-8 출력도 안정적이라 그럼
3. 홈 경로는 하드코딩 금지 — 실행하는 PC의 `$HOME`에서 동적 생성

## 실행 순서

### 0. OS 확인
Windows 아니면 중단하고 사용자에게 알림 (이 스킬은 Windows 전용).

### 1. 페르소나 배포 + 활성화

페르소나는 **실물 파일 + 그 파일을 부르는 `@import` 줄** 둘 다 있어야 켜진다. 실물만 깔면 고아 파일이라 말투가 안 먹는다.

**(a) 실물 파일 배포**
- `assets/persona-20대시니컬남성.md` → `~/.claude/persona-20대시니컬남성.md` 복사 (덮어쓰기 OK)

**(b) 글로벌 CLAUDE.md에 import 줄 멱등 추가**
`~/.claude/CLAUDE.md` 에 import 한 줄을 박아 **전역으로** 켠다 (프로젝트별 CLAUDE.md import 에 의존하면 import 없는 프로젝트에선 말투가 안 먹음 — 전역으로 한 번에 켜는 게 확실).

- 파일 없음 → 그 줄만 담아 생성
- 있는데 줄 없음 → 끝에 append
- 이미 있음 → 스킵 (멱등)

```powershell
$cm = "$HOME\.claude\CLAUDE.md"
$line = '@~/.claude/persona-20대시니컬남성.md'
$cur = if (Test-Path $cm) { Get-Content $cm -Raw } else { '' }
if ($cur -notmatch [regex]::Escape($line)) {
    if ($cur -and -not $cur.EndsWith("`n")) { Add-Content $cm "" -Encoding utf8 }
    Add-Content $cm $line -Encoding utf8
}
```

> ⚠️ 글로벌 `~/.claude/CLAUDE.md` 는 개인 프로필이 담긴 파일이라 **통째 생성·덮어쓰기 금지.** settings.json 머지(3단계)와 동일하게 **import 한 줄만 멱등 추가** — 기존 내용은 절대 안 건드린다.

### 2. 스크립트 배포
- `assets/statusline.ps1` → `~/.claude/statusline.ps1`
- `~/.claude/hooks/` 폴더 없으면 생성 → `assets/hooks/notify.ps1` → `~/.claude/hooks/notify.ps1`

### 3. settings.json 머지 (기존 키 보존 · 멱등)
`~/.claude/settings.json` 읽어서(없으면 `{}`) 아래 키만 추가/갱신. **다른 기존 키는 절대 건드리지 말 것.** 경로는 `$HOME` 기반 슬래시로 생성.

- `statusLine` = `{ "type":"command", "command":"pwsh -NoProfile -File <HOME>/.claude/statusline.ps1" }`
- `hooks.Stop` = `[{ "hooks":[{ "type":"command", "command":"pwsh -NoProfile -File <HOME>/.claude/hooks/notify.ps1 -EventType Stop" }] }]`
- `hooks.Notification` = `[{ "hooks":[{ "type":"command", "command":"pwsh -NoProfile -File <HOME>/.claude/hooks/notify.ps1 -EventType Notification" }] }]`

이미 동일 설정 있으면 스킵(멱등). PowerShell로 머지 예시:
```powershell
$f = "$HOME\.claude\settings.json"
$h = ($HOME -replace '\\','/')
$s = if (Test-Path $f) { Get-Content $f -Raw | ConvertFrom-Json } else { [pscustomobject]@{} }
$s | Add-Member statusLine ([pscustomobject]@{ type='command'; command="pwsh -NoProfile -File $h/.claude/statusline.ps1" }) -Force
# hooks 는 중첩 객체라 해시테이블로 구성해 Add-Member -Force 후 ConvertTo-Json -Depth 10
```

### 4. BurntToast 설치 (없을 때만)
```powershell
if (-not (Get-Module -ListAvailable BurntToast)) {
  Set-PSRepository PSGallery -InstallationPolicy Trusted
  Install-Module BurntToast -Scope CurrentUser -Force -AllowClobber
}
```

### 5. 검증
```bash
# statusline 출력 확인
echo '{"model":{"display_name":"Opus"},"effort":{"level":"high"},"context_window":{"used_percentage":28}}' | pwsh -NoProfile -File ~/.claude/statusline.ps1
# 알림 토스트 1발 (소리+토스트 떠야 정상)
echo '{}' | pwsh -NoProfile -File ~/.claude/hooks/notify.ps1 -EventType Stop
```
statusline이 `Opus · effort high · ctx ▓▓░░░░░░░░ 28%` 식으로 나오면 OK.

### 6. 완료 요약 + 재시작 안내
- 배포/머지한 파일 목록 출력
- **"Claude Code 껐다 켜야 statusline·hooks 적용됨"** 안내 (settings.json 변경은 현재 세션 자동 반영 X)

## 유지보수
`assets/`는 **스냅샷**임. 이 PC에서 페르소나·스크립트·설정 고치면 → 이 스킬 `assets/`에도 반영하고 `claude-skills` 레포에 커밋해야 다른 PC에 전파됨. (안 그러면 다른 PC는 옛날 버전 깔림)
