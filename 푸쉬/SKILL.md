---
name: 푸쉬
description: 현재 브랜치를 origin에 push. fetch → 충돌 분석 → 사용자 결정 → push 순으로 진행.
---

# 푸쉬 — 현재 브랜치를 origin에 push

## 사전 준비
CLAUDE.md에서 아래 두 항목 읽기. 없으면 사용자에게 직접 물어볼 것.
- `my-branch`: 내 작업 브랜치명
- `integration-branch`: 통합 브랜치명 (dev, main 등)

## 실행 순서

### 0. 학습 중 가드 (`/연습` 진행 중이면 거절)

`practice/*/.state` 파일이 하나라도 존재하면 즉시 거절:
```
진행 중인 학습이 있어서 /푸쉬 못 함 (src/가 빈칸 상태일 수 있음).
먼저 /연습 채점으로 끝낸 다음 다시 /푸쉬.
```
.state 파일 0개일 때만 다음 단계 진행.

### 1. 브랜치 정보 확인
CLAUDE.md에서 `my-branch`, `integration-branch` 값 읽기.
없으면 사용자에게 물어볼 것.

### 2. git fetch
```
git fetch origin
```

### 3. integration-branch에 새 커밋 있는지 확인
```
git log --oneline <my-branch>..origin/<integration-branch>
```
- 새 커밋 없으면 → 6단계로 바로 이동
- 새 커밋 있으면 → 4단계 진행

### 4. 충돌 가능성 분석 후 사용자에게 보고
```
git diff --name-only <my-branch>...origin/<integration-branch>
```
내가 건드린 파일과 겹치는 파일 목록을 정리해서 보고.
사용자에게 선택 물어볼 것:
- **그대로 push** — 통합은 나중에 PR에서
- **merge 후 push** — `git merge origin/<integration-branch>` 시도

### 5. merge 선택 시
충돌 발생하면:
- 충돌 파일 목록과 양쪽 내용 분석해서 사용자에게 보고
- 사용자 결정 후 Edit으로 충돌 마커 제거
- `git add` + merge commit

### 6. 커밋 메시지 제안
미커밋 변경사항 있으면 Claude가 메시지 후보 제시 → 사용자 승인 후 커밋.
변경사항 없으면 생략.

### 7. push
```
git push origin <my-branch>
```
