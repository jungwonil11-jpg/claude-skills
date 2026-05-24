---
name: 도전100
description: 100% 단일 기능 + 도메인 종합 학습 단축 진입로. PROGRESS.md 100×100 도전 표에서 번호로 바로 회차 시작.
---

# 도전100 — 100×100 단축 진입로

`/연습` 의 **5-파일 묶음 100% 단일 기능** 또는 **종합 모드 (도메인 폴더 통째 100%)** 를 빠르게 진입하는 단축 스킬. 메뉴/도메인/매트릭스 단계 다 건너뛰고 100×100 표 → 번호 → 회차 시작.

채점은 별도 명령 없음. 기존 `/연습 채점` 그대로 사용 (`.state` mode 분기는 `/연습` 스킬이 처리).

---

## 호출 형태

| 형태 | 동작 |
|---|---|
| `/도전100` | 100×100 표 출력 → 번호 입력 대기 |
| `/도전100 <번호>` | 번호로 바로 진입 (목록 스킵) |

---

## 워크플로우

### 1. 사전 가드

`practice/*/.state` 파일이 하나라도 있으면 거절:

```
이미 진행 중인 학습이 있음: practice/<회차폴더>/
먼저 /연습 채점으로 끝내거나, 포기하려면 practice/<회차폴더>/.state 삭제 후 .practice-backup/<id>/에서 수동 복구.
```

### 2. PROGRESS.md 읽음 → 표 파싱

`practice/PROGRESS.md` 읽고 **"기능별 100×100 도전"** 섹션 표를 파싱.

표 형식:
```
| 기능 | 진행 | 만점 | 평균 정답률 | 최근 |
|---|---|---|---|---|
| Members/로그인 | 5/100 | 0 | 76.9% | 2026-05-18 (185/190) |
| Members/종합 | 0/100 | 0 | - | - |
| ...
```

- 표 행 순서대로 1, 2, 3... 번호 부여 (종합 행도 포함)
- 각 행에서 `<도메인>/<기능 한글명>` 분리
- 도메인 한글 → 소문자 슬러그 (`Members` → `members`, `GuestBook` → `guestbook`)
- 기능 한글 → 슬러그 매핑 (아래 표 참조). **`종합`** 은 특수 슬러그로 종합 모드 트리거.

**PROGRESS.md 없거나 표 섹션 없음** → 안내 후 종료:
```
practice/PROGRESS.md 또는 "기능별 100×100 도전" 표 없음. 먼저 /연습 한번 돌려서 PROGRESS 생성하셈.
```

### 3. 기능 한글 → 슬러그 매핑 테이블

| 한글 | 슬러그 |
|---|---|
| 회원가입 | register |
| 로그인 | login |
| 토큰 재발급 | refresh |
| 마이페이지 | mypage |
| 로그아웃 | logout |
| 리스트 | list |
| 등록 | insert |
| 상세 | detail |
| 수정 | update |
| 삭제 | delete |
| 종합 | 종합 (특수 — 종합 모드 트리거) |
| 회원가입+로그인+토큰 재발급+로그아웃 | register+login+refresh+logout (인증 생명주기) |
| 마이페이지+회원정보 수정+회원 탈퇴 | mypage+update+delete (RUD) |

**다중 기능 슬러그** (`+` 박힌 슬러그): `<도메인>-<기능1>+<기능2>_100` 회차 폴더로 진입. `/연습` 의 5-파일 묶음 다중 기능 100% 워크플로우 그대로 — **템플릿 시스템 ✅ 적용** (존재 체크는 `Test-Path practice/_templates/<도메인>-<기능1>+<기능2>_100`, ⚠️ Glob tool 금지 — 디렉토리 못 잡음. True 면 복사, False 면 자동 생성), features 배열에 두 원소 박힘.

**매핑 못 찾음** → 안내 후 종료:
```
기능 "<한글>" 슬러그 매핑 없음. C:\Users\jungw\.claude\skills\도전100\SKILL.md 의 매핑 테이블에 추가 필요.
```

### 4. 분기

#### 4-A. `/도전100` (인자 없음)

번호 → 도메인/기능 매핑한 결과를 다음 형식으로 출력 (기능명 + 진행 + 평균만). 종합 행은 `★` 로 시각 구분:

```
1. Members/로그인         5/100  76.9%
2. Members/토큰 재발급    0/100  -
3. Members/마이페이지     3/100  84.3%
4. Members/로그아웃       0/100  -
5. ★ Members/종합         0/100  -      ← 도메인 정복 트랙
6. GuestBook/리스트       1/100  100%
7. GuestBook/등록         1/100  96.3%
8. ★ GuestBook/종합       0/100  -      ← 도메인 정복 트랙

번호 입력:
```

정렬: PROGRESS.md 표에 등장한 순서. 종합 행은 그 도메인 마지막에 박힘. 컬럼 폭은 한글 가독성 맞춰 적당히.

사용자 입력 대기 → 받으면 4-C로.

#### 4-B. `/도전100 <번호>`

번호 유효성 검사:
- 표에 없는 번호 → 거절 + 표 출력
- 잠금 행(`🔒`)은 표에 없으니 자연히 거절됨

유효하면 4-C로.

#### 4-C. 회차 시작 — 분기

기능 슬러그가 `종합` 이면 **4-C-종합** 으로, 아니면 **4-C-단일** 으로.

---

#### 4-C-단일. 5-파일 묶음 100% 단일 기능

`/연습` 의 5-파일 묶음 100% 단일 기능 워크플로우 그대로:

1. **회차 폴더명**:
   ```
   practice/YYYY-MM-DD_<도메인>-<기능slug>_100/
   ```
   같은 폴더 있으면 `_2`, `_3` 자동.

2. **학습 대상 파일 목록** (5-파일 묶음):
   - `src/main/java/com/study/myproject01/<도메인>/controller/<도메인 PascalCase>Controller.java`
   - `src/main/java/com/study/myproject01/<도메인>/service/<도메인 PascalCase>Service.java`
   - `src/main/java/com/study/myproject01/<도메인>/service/<도메인 PascalCase>ServiceImpl.java`
   - `src/main/java/com/study/myproject01/<도메인>/mapper/<도메인 PascalCase>Mapper.java`
   - `src/main/resources/mapper/<도메인>-mapper.xml`

   도메인 PascalCase: `members` → `Members`, `guestbook` → `GuestBook`.

3. **백업** — `.practice-backup/<session-id>/` (5개 파일 그대로).

4. **템플릿 체크** (⚠️ **`Test-Path` 사용, Glob tool 금지** — Glob 은 디렉토리를 못 잡아서 폴더가 있어도 "없음" 오판 → 매번 재생성. slug 은 소문자):
   - `Test-Path practice/_templates/<도메인>-<기능slug>_100` → True 면 src/로 Copy-Item (Read 금지)
   - False → 강사 원본 Read + `_filter.md` 적용 + 100% 빈칸 처리 → `_templates/` 저장 → src/로 복사

5. **`.state`**:
   ```json
   {
     "mode": "5-file",
     "session_id": "<회차 폴더명>",
     "domain": "<도메인>",
     "features": [ { "slug": "<기능slug>", "label": "<기능 한글>" } ],
     "percent": 100,
     "started_at": "<ISO 8601>",
     "backup_dir": ".practice-backup/<session-id>",
     "target_files": [ ... 5개 경로 ... ]
   }
   ```

6. **README.md** — 회차 정보, 학습 대상 파일 5개, "끝나면 /연습 채점".

7. **PROGRESS.md 갱신** — 도메인 매트릭스의 100% 셀 ⌛, 마지막 갱신 오늘.

---

#### 4-C-종합. 도메인 폴더 통째 100%

`/연습` 의 **2-A-종합 종합 모드** 워크플로우 그대로:

1. **회차 폴더명**:
   ```
   practice/YYYY-MM-DD_<도메인>-종합_100/
   ```
   같은 폴더 있으면 `_2`, `_3` 자동.

2. **학습 대상 파일 자동 탐지** (도메인 폴더 전체):
   - `src/main/java/com/study/myproject01/<도메인>/controller/*.java`
   - `src/main/java/com/study/myproject01/<도메인>/service/*.java`
   - `src/main/java/com/study/myproject01/<도메인>/mapper/*.java`
   - `src/main/java/com/study/myproject01/<도메인>/vo/*.java`  ← VO 포함
   - `src/main/resources/mapper/<도메인>-mapper.xml`

   총 6~10개. common 폴더는 제외.

3. **features 자동 채움** — 컨트롤러 메서드 분석, `_filter.md` 제외. 각 메서드를 `{ slug, label }` 로 변환 (한글-슬러그 매핑 테이블 재사용).

4. **백업** — `.practice-backup/<session-id>/` 에 위 파일들 그대로 복사.

5. **템플릿 체크** (⚠️ **`Test-Path` 사용, Glob tool 금지** — Glob 은 디렉토리를 못 잡아서 폴더가 있어도 "없음" 오판 → 매번 재생성. slug 은 소문자):
   - `Test-Path practice/_templates/<도메인>-종합_100` → True 면 src/로 Copy-Item (Read 금지)
   - False → 강사 원본 Read + `_filter.md` 적용 + 100% 빈칸 처리 (VO 룰 포함 — `/연습` 2-A-종합 d 참고) → `_templates/` 저장 → src/로 복사

6. **`.state`**:
   ```json
   {
     "mode": "domain-all",
     "session_id": "<회차 폴더명>",
     "domain": "<도메인>",
     "features": [ ...자동 채움... ],
     "include_vos": true,
     "percent": 100,
     "started_at": "<ISO 8601>",
     "backup_dir": ".practice-backup/<session-id>",
     "target_files": [ ...자동 탐지... ]
   }
   ```

7. **README.md** — "종합 모드 — 도메인 정복 회차" 강조, 학습 대상 파일 전부 명시, "끝나면 /연습 채점".

8. **PROGRESS.md 갱신**:
   - 도메인 매트릭스 셀은 안 건드림 (종합은 별도 트랙)
   - 기능별 100×100 도전 표의 `<도메인>/종합` 행만 ⌛(또는 진행 카운터 미증가 — 채점 후 +1)
   - 마지막 갱신 오늘

### 5. 마무리 채팅

회차 시작 완료 한 줄:
```
회차 시작: practice/<회차폴더>/ — 5개 파일 빈칸 처리 완료. IntelliJ에서 열고 ㄱㄱ. 끝나면 /연습 채점.
```

---

## 다른 스킬과의 관계

- `/연습 채점` — 채점은 이 명령으로. `.state` mode 동일 (`5-file`) 이라 분기 필요 X.
- `/연습 템플릿 재생성 <slug>` — 템플릿 재생성은 `/연습` 쪽 명령 그대로 사용.
- `/강사싱크`, `/푸쉬` — 자체 가드(`.state` 체크) 통과해야 진행.

---

## 강사 새 기능 추가 시

1. 강사가 새 기능 구현 → `/강사싱크` → main에 코드 들어옴
2. 사용자가 `/연습 메뉴 재생성` + `/연습 템플릿 재생성 all`
3. `practice/PROGRESS.md` 매트릭스에 행 추가 + "기능별 100×100 도전" 표에 행 추가 (수동)
4. 새 기능 한글명이 매핑 테이블(3절) 에 없으면 이 SKILL.md 매핑 테이블에 추가
