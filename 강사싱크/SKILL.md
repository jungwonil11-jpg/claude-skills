---
name: 강사싱크
description: 수업 끝난 직후 실행. 강사 upstream 코드를 main에 미러링하고 study 브랜치에 머지한다.
---

# 강사싱크 — 수업 끝난 직후 실행

강사 코드를 main에 미러링하고, study에 머지한다.

## 실행 순서

### 0. 학습 중 가드 (`/연습` 진행 중이면 거절)

`practice/*/.state` 파일이 하나라도 존재하면 즉시 거절:
```
진행 중인 학습이 있어서 /강사싱크 못 함 (src/가 빈칸 상태일 수 있음).
먼저 /연습 채점으로 끝내거나, 포기하려면:
  1. .practice-backup/<id>/ 에서 src/ 수동 복구
  2. practice/<회차>/.state 삭제
  3. 다시 /강사싱크
```
.state 파일 0개일 때만 다음 단계 진행.

### 1. study 브랜치 확인
현재 브랜치가 study가 아니면 `git checkout study` 실행.

### 2. study 변경사항 처리
`git status`로 변경사항 확인.
- 변경사항 있으면: commit할지 stash할지 사용자에게 물어볼 것.
  - commit 선택 시: `git add -A && git commit -m "wip: 싱크 전 저장"`
  - stash 선택 시: `git stash push --include-untracked -m "강사싱크 전 임시저장"`
- 변경사항 없으면 생략.

### 3. main으로 이동
```
git checkout main
```

### 4. upstream 확인 및 fetch
`git remote get-url upstream` 으로 upstream URL 확인.
- upstream이 없으면: CLAUDE.md에서 `upstream:` 으로 시작하는 줄을 찾아 URL을 읽어온 뒤 자동 등록:
  ```
  git remote add upstream <CLAUDE.md에서 읽은 URL>
  ```
  CLAUDE.md에도 없으면 사용자에게 직접 URL을 물어볼 것.
- fetch 실행:
  ```
  git fetch upstream
  ```

### 5. upstream/main 파일 덮어쓰기
```
git ls-tree -r upstream/main --name-only | xargs git checkout upstream/main --
```

### 6. main에 commit
변경사항 있으면:
```
git add -A && git commit -m "sync: 강사 코드 (YYYY-MM-DD)"
```
(YYYY-MM-DD는 오늘 날짜로 치환)
변경사항 없으면 commit 생략.

### 7. origin/main push
```
git push origin main
```

### 8. study로 복귀
```
git checkout study
```

### 9. main을 study에 머지
```
git merge main
```

충돌 발생 시 — **자동 해결 금지**. 다음 절차로 처리:

1. 충돌 파일 목록 + 각 충돌 hunk 출력 (어느 라인이 강사 변경이고 어느 라인이 사용자 변경인지 명시)
2. `[LEARN]` 마커 포함 라인은 **자동으로 사용자 버전 유지 제안** (학습 메모 의도 명확)
3. `.claude/`, `CLAUDE.md`, `CLAUDE.local.md` 는 **무조건 study 버전 유지** (사용자 확인 생략)
4. 위 두 케이스 외 모든 hunk는 사용자에게 결정 받음:
   - `theirs` (강사 버전)
   - `ours` (사용자 버전)
   - `both` (양쪽 다 살림 — Claude가 의미 보고 적절히 합침)
5. 사용자 결정 후 `git add <파일> && git merge --continue`

> ⚠️ 충돌을 사용자 확인 없이 자동 해결하면 학습 메모/로그가 silent 하게 날아갈 위험. 반드시 hunk 별 결정 받을 것.

### 10. stash 복원 (2단계에서 stash했을 경우)
```
git stash pop
```

### 11. study push
```
git push origin study
```

### 12. 완료 요약
다음 항목을 출력:
- 변경된 파일 목록
- 충돌 발생 여부 및 해결 방법
- 보존된 `[LEARN]` 마커 개수 (선택)
- 현재 브랜치 (`git branch --show-current`)

---

## 학습 메모 컨벤션 — `[LEARN]` 마커

강사 코드에 학습 메모/로그 박을 때 `[LEARN]` 마커 포함:

- **주석**: `// [LEARN] SecurityContext.getPrincipal() 에서 userId 추출 — 로그인 시 박은 값`
- **로그**: `log.info("[LEARN] userId={}", userId);` (개발 중 디버깅용, 강의 끝나면 빼도 됨)

`[LEARN]` 마커가 박힌 라인은 `/강사싱크` 9번 단계 충돌 시 **자동으로 사용자 버전 유지 제안** (사용자가 최종 확인). 마커 없는 변경도 충돌 시 사용자 확인 받지만, 마커 있으면 의도 명확해서 처리 빠름.

⚠️ 마커는 **위치 보존** 룰이지 **내용 신선도 보장 X**. 강사가 메서드 로직 자체 바꾸면 메모 내용이 stale 될 수 있음 — 강사싱크 후 인접 변경 영역의 메모는 직접 검토할 것.
