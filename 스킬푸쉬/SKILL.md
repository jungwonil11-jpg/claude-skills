---
name: 스킬푸쉬
description: claude-skills repo의 변경된 스킬을 GitHub origin/main에 자동 commit + push. 확인 없이 한 번에.
---

# 스킬푸쉬 — claude-skills 자동 푸쉬

`/스킬푸쉬` 한 방으로 스킬 변경분을 GitHub `claude-skills` repo에 올린다. 확인 단계 없이 자동.

- `/스킬푸쉬` → 자동 커밋 메시지로 push
- `/스킬푸쉬 <메시지>` → 그 메시지로 커밋

---

## ⚠️ 동작 위치 (제일 중요)

Claude의 작업 디렉토리는 **현재 프로젝트**(예: `C:\2026_myapp03`)지 스킬 repo가 아니다. 그냥 `git push` 하면 엉뚱한 repo를 건드린다. **반드시 `git -C <repo>` 로 스킬 repo를 지정**해서 돌릴 것.

### repo 경로 해석

`~/.claude/skills/<스킬>` 은 junction 으로 스킬 repo를 가리킨다. 이 스킬 자신의 junction 타겟에서 repo 루트를 구한다:

```powershell
$link = Get-Item "$env:USERPROFILE\.claude\skills\스킬푸쉬"
$repo = if ($link.Target) { Split-Path $link.Target } else { "$env:USERPROFILE\claude-skills" }
```

- junction 이면 `.Target` = `<clone>\스킬푸쉬` → 부모 폴더가 repo 루트
- 혹시 junction 이 아니면(복사된 경우) `~/claude-skills` 로 폴백
- 둘 다 실패하면 거절: "claude-skills repo 못 찾음. setup.bat 으로 junction 걸었는지 확인."

---

## 워크플로우

전부 `git -C "$repo"` 로 실행.

### 1. 변경 확인

```powershell
git -C "$repo" status --porcelain
```
- 출력 비어 있음 → "올릴 변경 없음." 출력하고 종료.
- 있음 → 다음 단계.

### 2. 원격 동기화 (다른 컴퓨터서 올렸을 수 있음)

```powershell
git -C "$repo" fetch origin
```
- 로컬이 origin/main 보다 **behind** 면 `git -C "$repo" pull --rebase origin main`.
- rebase 중 **충돌** 나면 멈추고 보고: "원격이랑 충돌남. claude-skills 에서 수동 해결 필요." (스스로 강제 push 하지 말 것)
- ahead 거나 동일하면 그대로 진행.

### 3. 스테이징 + 커밋

```powershell
git -C "$repo" add -A
```

커밋 메시지:
- `/스킬푸쉬 <메시지>` 로 인자 있으면 → 그 메시지 그대로.
- 인자 없으면 → `git -C "$repo" status --porcelain` 결과로 **바뀐 스킬 폴더명**을 뽑아 자동 생성. 표준 한국어, 시니컬 OFF.
  - 형식: `chore(skills): <스킬1>, <스킬2> 업데이트` (추가/삭제 섞이면 동사 조정)
  - 예: `chore(skills): 연습, 도전100 템플릿 존재 체크 Test-Path로 수정`

커밋 (Co-Authored-By 포함):

```powershell
git -C "$repo" commit -m @'
chore(skills): <요약>

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
'@
```

### 4. push

```powershell
git -C "$repo" push origin main
```

### 5. 결과 (채팅 한 줄)

```
올림: <커밋 해시 짧게> — <바뀐 스킬 목록>
```
push 실패하면 에러 그대로 보고.

---

## 안 하는 것

- 확인 안 물어봄 (자동이 이 스킬의 목적).
- 강제 push (`--force`) 안 함. 충돌이면 멈추고 사람한테 넘김.
- 현재 프로젝트 repo 는 절대 안 건드림 (`git -C` 로 스킬 repo 만 대상).
