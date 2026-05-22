---
name: 시작
description: 다른 컴퓨터에서 자습 시작 전 실행. study 브랜치를 origin 최신 상태로 동기화한다.
---

# 시작 — 다른 컴퓨터에서 자습 시작 전 실행

study 브랜치를 origin 최신 상태로 맞춘다.

## 처음 셋업 (새 컴퓨터에서 딱 한 번만)

```bash
git fetch origin
git checkout -b study origin/study
```

이후로는 아래 실행 순서대로.

## 실행 순서

### 1. study 브랜치 확인
현재 브랜치가 study가 아니면 `git checkout study` 실행.

### 2. 로컬 변경사항 처리
`git status`로 변경사항 확인.
- 변경사항(수정/미추적 파일) 있으면:
  ```
  git stash push --include-untracked -m "시작 전 임시저장"
  ```
- 변경사항 없으면 생략.

### 3. origin/study pull
```
git pull origin study
```

### 4. stash 복원 (2단계에서 stash했을 경우)
```
git stash pop
```

### 5. 충돌 처리
충돌 발생 시 사용자에게 알리고, 어떤 파일에서 충돌이 났는지 보여준 뒤 해결 방향을 물어볼 것.

### 6. 완료 요약
다음 항목을 출력:
- pull로 새로 받아온 커밋 목록 (없으면 "이미 최신 상태"로 표시)
- 현재 `git status` 요약
- 현재 브랜치 (`git branch --show-current`)
