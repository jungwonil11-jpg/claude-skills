---
name: 연습
description: 프로젝트의 학습 파일을 src/에서 직접 빈칸 처리하고 사용자가 작성 후 채점까지 진행한다. 백업/복구로 원본 안전.
---

# 연습 — 원본 구멍 뚫기 방식 코딩 연습 사이클

두 가지 모드로 동작한다:
- `/연습` : src/의 학습 대상 파일에 빈칸 뚫기 (33/67/100%) 또는 **장인 모드** (5-파일 묶음 통째 빈 파일) 또는 **종합 모드** (도메인 폴더 통째 100% 빈칸)
- `/연습 채점` : 사용자가 작성한 코드 채점 + src/ 원본 복구

빈칸 형식은 **항상 fill-in-the-blank (`_____`)**. 퍼센티지로 빈칸 양만 조절.
장인 모드는 토큰 빈칸이 아니라 파일 자체를 빈 상태로 두는 별개 모드 — 구조부터 사용자가 직접 작성.
종합 모드는 100% 빈칸 처리하되 도메인 폴더 전체(컨트롤러+서비스+임플+매퍼+XML+VO들)를 대상으로 함.

---

## 핵심 워크플로우

src/ 원본 파일에 직접 빈칸을 뚫고, 사용자는 IDE 풀 기능(import 해결·자동완성)을 받으며 채운다. 사이클:

1. **학습 대상 파일을 `.practice-backup/<session-id>/`에 그대로 복사** (원본 경로 미러)
2. **src/의 같은 파일들을 빈칸 버전으로 덮어쓰기** — 사용자는 src/ 실제 위치에서 IDE 풀 기능 받아 작업
3. **`practice/<회차>/.state`** 에 백업 위치 + 학습 대상 파일 목록 기록 (학습 중 상태 마커)
4. **`/연습 채점`** 시: 사용자 코드를 `practice/<회차>/`에 답안 보존 + 채점 + src/ 원본 복구

= **src/ 가 일시적으로 빈칸 상태**. 학습 끝나면 git diff 0으로 원상복귀.

> ⚠️ **파일 Read 금지 원칙 (`/연습` setup 전용)**: 백업 복사(`src/` → `.practice-backup/`)와 템플릿 복사(`_templates/` → `src/`)는 **Read tool 사용 금지**. PowerShell `Copy-Item`만 사용. 파일 내용을 컨텍스트에 올리지 않음.
> - **템플릿이 이미 존재하는 경우**: Read 없이 Copy-Item만으로 백업 + src/ 덮어쓰기 끝냄.
> - **템플릿이 없는 경우 (첫 회차)**: 원본 파일을 Read해서 빈칸 처리 후 템플릿 저장 — 이때만 Read 허용.

---

## 빈칸 템플릿 시스템 (100% 전용)

`/연습 <기능> 100` 호출 시 매번 빈칸을 새로 만들지 않고 **템플릿에서 복사**한다. 100번 풀어도 동일한 빈칸 패턴 보장 + 토큰 절약.

### ⚠️ 템플릿 존재 체크 방법 (필수 — Glob tool 금지)

템플릿 폴더 존재 확인은 **반드시 PowerShell `Test-Path`** 로 한다. **Glob tool 로 디렉토리 경로를 체크하지 말 것.**

- **버그 원인**: Glob tool 은 **파일만 매칭하고 디렉토리는 매칭 못 함**. `Glob practice/_templates/<slug>_<%>` 는 폴더가 멀쩡히 있어도 항상 `No files found` 를 반환 → "템플릿 없음"으로 오판 → 매번 재생성.
- **올바른 체크**:
  ```powershell
  Test-Path 'practice/_templates/<slug>_<%>'
  ```
  `True` → 템플릿 있음 (Copy-Item 으로 src/ 덮어쓰기, Read 금지). `False` → 없음 (원본 Read + 빈칸 처리 + 템플릿 저장).
- 굳이 Glob 을 써야 하면 디렉토리가 아니라 **내부 파일**을 매칭: 패턴 끝에 `/**` 붙임 → `practice/_templates/<slug>_<%>/**`.

**slug 정규화 — 항상 소문자**:
- slug 은 **파일명(확장자 제거)을 전부 소문자**로. 예: `TodoPage.jsx` → `todopage`, `useTodoStore.jsx` → `usetodostore`, `Http.jsx` → `http`, `MemoPage.jsx` → `memopage`.
- Windows 파일시스템은 대소문자 무시라 `Test-Path` 는 케이싱이 달라도 매칭되지만(`TodoPage_67` 도 `todopage_67` 폴더에 매칭), **템플릿 폴더를 새로 만들 때는 항상 소문자**로 만들어 명명 일관성 유지.

### 적용 범위

| 모드 | 템플릿화 |
|---|---|
| 5-파일 묶음 100% 단일 기능 | ✅ |
| 단일 파일 100% | ✅ |
| **종합 모드 100%** | ✅ (`<도메인>-종합_100`) |
| **다중 기능 100% (`1,2 100`)** | ✅ (`<도메인>-<기능1>+<기능2>_100`) |
| **33%/67% (단일·다중 무관)** | ✅ (`<도메인>-<기능slug>_<%>`) |
| 장인 모드 | ❌ 빈 파일이라 불필요 |

### 템플릿 저장 위치

```
practice/_templates/
├── <도메인>-<기능slug>_100/
│   └── (학습 대상 파일을 src/ 트리 미러로 빈칸 처리해 저장)
```

예시:
```
practice/_templates/members-login_100/
├── src/main/java/com/study/myproject01/members/controller/MembersController.java
├── src/main/java/com/study/myproject01/members/service/MembersService.java
├── src/main/java/com/study/myproject01/members/service/MembersServiceImpl.java
├── src/main/java/com/study/myproject01/members/mapper/MembersMapper.java
└── src/main/resources/mapper/members-mapper.xml
```

### 워크플로우 — `/연습 <기능> 100` 호출 시

```
1. 회차 폴더 결정 (practice/YYYY-MM-DD_<도메인>-<기능>_100[_N]/)
2. 백업 생성 (.practice-backup/<session-id>/) — 매번 강사 원본 복사 (필터 적용 X)
3. 템플릿 체크: `Test-Path practice/_templates/<도메인>-<기능slug>_100` (⚠️ Glob tool 금지 — 디렉토리 못 잡음)
   ├─ True → 템플릿 파일들을 src/로 복사 ✅ (Read 없이 Copy-Item만 — 파일 내용 컨텍스트에 올리지 않음)
   └─ False → 강사 원본 Read + _filter.md 적용 + 빈칸 처리 → 템플릿으로 저장 (첫 회차, 이때만 Read 허용)
4. .state 생성 (매번 새로)
5. PROGRESS.md 매트릭스 갱신
```

### 학습 제외 필터 — `practice/_filter.md` (선택)

강사 원본의 더미 메소드(예: `hello`, `hi`)를 빈칸 처리에서 제외. 파일 없으면 무동작.

- **형식**: `## <파일 경로>` 아래 제외할 `- <메소드명>` 나열 (파일 경로 단위 매칭, 같은 이름 다른 파일은 영향 X).
- **동작**: 템플릿 생성 시에만 적용 — 해당 메소드를 어노테이션~닫는 `}` 까지 통째 삭제 후 나머지에 빈칸 처리. 백업(`.practice-backup/`)·채점은 강사 원본 기준이라 영향 없음.
- **강사싱크 후 반영**: 더미가 다시 들어오면 → `/연습 템플릿 재생성 all` → 다음 `/연습 <기능> 100`부터 자동 제외.
- **주의**: 학습 대상 메소드는 절대 넣지 말 것 (빈칸이 통째로 사라져 학습 불가). `git commit` 대상 (컴퓨터 간 동기화).

### 강사 코드 동기화 (자동 비교 X — 수동 명령)

강사가 `/강사싱크` 등으로 코드 바꾸면 사용자가 수동 명령:

```
/연습 템플릿 재생성 <기능slug>          ← 해당 빈칸 템플릿 폴더 삭제. 다음 호출 시 재생성됨.
/연습 템플릿 재생성 all                 ← 모든 100% 빈칸 템플릿 폴더 삭제.
/연습 메뉴 재생성                       ← practice/_menu.md 삭제. 다음 /연습 호출 시 src/ 재스캔.
```

각 명령 받으면:
1. 사전 가드 (`.state` 진행 중 학습 있으면 거절) 통과 후
2. 해당 파일/폴더 삭제
3. 채팅에 "삭제 완료. 다음 호출 시 새로 생성됨" 안내

### 사용자 수동 편집 허용

`practice/_templates/<기능slug>_100/` 안 파일은 사용자가 IntelliJ로 직접 수정 가능:
- 빈칸 너무 많으면 일부 풀어둠 (난이도 ↓)
- 살린 자리를 빈칸으로 바꿈 (난이도 ↑)

다음 회차부터 수정본 반영. **채점은 강사 원본 백업과 비교**하므로 템플릿 수정해도 채점 룰엔 영향 X — 템플릿에서 미리 풀어둔 자리는 "이미 정답" 처리.

### git 정책

`_templates/` 는 git commit 대상 (다른 컴퓨터에서도 같은 템플릿 사용). `.gitignore` 등록 X.

---

## 빈칸 비율과 자리 정의

**핵심 원칙**: 퍼센티지는 **빈칸 양**의 비율임. 카테고리 누적 ❌, 토큰 풀 × 비율 ✅.
**빈칸 마커**: 모든 빈칸은 `_____` 5밑줄 통일 (토큰 길이와 무관).

> **이 빈칸 X/풀 룰은 자바(Spring/MyBatis) 프리셋이다.** 프로젝트 CLAUDE.md `## /연습 스킬 동작 가이드` 에 언어별 규칙이 있으면 **그게 우선**(→ "### 0. 언어 룰셋 확인"). 언어 무관 원칙만 공통: **골격(import/export·선언 시그니처·구조 키워드)은 살리고, 로직·식별자(호출명·변수·값)는 빈칸.** 아래는 그 원칙의 자바 구체화.

### 1. 빈칸 X — 모든 비율 공통 (절대 안 비움)

다음은 **33%/67%/100% 어느 비율에서도 빈칸 X**:

- **구두점/괄호/할당 기호**: `{`, `}`, `(`, `)`, `;`, `=`, `,`, `.`, `:`, `@`
- **패키지/import 구문** 전체
- **클래스 선언 + 클래스 레벨 어노테이션** (`@RestController`, `@RequestMapping("/...")` 등 — 선택 기능 메소드 범위 밖)
- **필드 선언부** (`@Autowired private GuestBookService guestBookService;`)

> ⚠️ **VO 클래스 예외 (종합 모드 한정)**: VO 파일에서는 **클래스 레벨 Lombok 어노테이션** (`@Getter`, `@Setter`, `@NoArgsConstructor` 등) 과 **필드 선언** (타입 + 필드명) 도 빈칸 처리. VO는 데이터 매핑이 학습 본질이라 어노테이션·필드 살리면 빈칸 0개가 되어 의미 X. 채점은 [채점 기준](#채점-기준) 섹션의 "VO 필드명" / "Lombok 어노테이션" 항목 참고.

**33%/67%에서만 빈칸 X, 100%에서는 빈칸 O**:

- **데이터성 문자열 리터럴** (사용자 메시지: `"없는 아이디 입니다."`, `"로그인 성공"` 등) — 100%에서는 `"_____"` 로 빈칸 처리
- **XML 태그 속성값** (`parameterType="String"`, `resultType="MembersVO"` 등) — 100%에서는 속성값을 `"_____"` 로 빈칸 처리. 33%/67%에서는 그대로 유지.

> ⚠️ 어노테이션 파라미터 문자열(`"/myPage"`, `"/login"` 같은 URL 경로)은 데이터성 문자열이 아닌 **식별자 역할**이라 빈칸 대상 — P4에 속함.

### 2. 빈칸 가능 토큰 풀

위 "빈칸 X" 외 모든 토큰 = **빈칸 풀**.

자리 예시:
- 메소드 레벨 어노테이션 이름 + 파라미터: `GetMapping`, `"/list"`, `MembersVO.class`
- 메소드 시그니처 리턴 타입: `DataVO`, 메소드명, 파라미터 타입/이름
- 변수 선언 타입: `DataVO`, `List<GuestBookVO>`, `Exception`
- 생성자 호출: `new`, 클래스명
- 메소드 호출 체인 호출명: `getContext()`, `getAuthentication()`, `getMessage()` 등
- getter/setter, 필드 참조
- 메소드 호출 인자 (변수, Boolean)
- 조건 연산자: `==`, `!=`, `||`, `&&`
- 값 토큰: `null`, `Boolean.TRUE/FALSE`, 숫자
- 구조/흐름 키워드: `try`, `catch`, `if`, `else`, `for`, `while`, `return`, `throw`
- 표준 라이브러리 클래스명: `SecurityContextHolder`, `Exception`, `String`(캐스팅)
- 변수명, 접근제어자(`public`)
- **(100% 전용)** 데이터성 문자열 리터럴 (`"없는 아이디 입니다"`, `"로그인 성공"` 등)
- **(100% 전용)** XML 태그 속성값 (`parameterType`, `resultType` 등의 값)

### 3. 비율 적용 방식

| 비율 | 빈칸 범위 |
|---|---|
| **33%** | 빈칸 풀 ≈ N × 0.33 (P1~P4 위주). 구조/흐름 키워드, 값 토큰, 조건 연산자, 변수명, 컨트롤러 메소드명, `public` 살림. 데이터성 문자열·XML 속성값 살림 |
| **67%** | 빈칸 풀 ≈ N × 0.67 (P1~P7). 구조/흐름 키워드, 값 토큰, 조건 연산자, 변수명, 컨트롤러 메소드명, `public` 살림. 데이터성 문자열·XML 속성값 살림 |
| **100%** | **33%/67% 공통 빈칸 X 목록 외 전부 빈칸**. 구조 키워드·흐름 키워드·어노테이션 이름·조건 연산자·값 토큰·클래스명·변수명·접근제어자 + **데이터성 문자열 + XML 태그 속성값**까지 다 빈칸 |

같은 토큰 여러 번 등장해도 100%에선 전부 비움.

### 4. 100% 모드 SQL / XML 세부 룰

XML mapper 파일의 SQL 본문·태그명·MyBatis 플레이스홀더는 일반 룰만으로 모호 → 100% 모드 별도 명시:

| # | 자리 | 처리 | 예시 |
|---|------|------|------|
| ① | SQL 본문 토큰 (키워드 + 식별자 + 와일드카드 `*`) | **다 빈칸** | `select * from members where m_id=#{m_id}` → `_____ _____ _____ _____ _____ _____=#{_____}` |
| ② | XML 태그명 (`select`, `insert`, `update`, `delete` 등) | **빈칸** (`<` `>` 만 살림) | `<select id="...">` → `<_____ id="_____">` |
| ③ | MyBatis 플레이스홀더 `#{...}` | **안만 빈칸** (`#{` / `}` 살림) | `#{m_id}` → `#{_____}` |
| ④ | SQL 구두점 (`=` 비교 연산자, `,` 콤마, 세미콜론) | **살림** | `set m_name=#{m_name}, m_addr=#{m_addr}` → `_____ _____=#{_____}, _____=#{_____}` |
| ⑤ | log 호출문 데이터성 문자열 (한글 메시지) | **통째 빈칸** (format placeholder `{}` 포함) | `log.info("로그인 시도: m_id={}", id)` → `log.info("_____", id)` |

**의도**: SQL 토큰은 짧고 키워드 반복 多 → 자르지 않으면 학습 가치 없음. XML 태그명은 CRUD 종류 결정짓는 자리라 학습 대상. MyBatis 문법(`#{`)은 살림이 자연스러움. log 메시지는 사용자 작명이라 통째 빈칸.

**100% 빈칸 예시 (참고)**:
```java
// 원본
@GetMapping("/myPage")
public DataVO getMyPage(){
    DataVO dataVO = new DataVO();
    try{
        String userId = (String)SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        MembersVO mvo = membersService.findById(userId);
        if(mvo == null){
            dataVO.setSuccess(Boolean.FALSE);
            dataVO.setMessage("없는 아이디 입니다.");
        }
    } catch (Exception e) {
        dataVO.setMessage(e.getMessage());
    }
    return dataVO;
}

// 100% 빈칸
@_____ ("_____")
_____ _____ _____(){
    _____ _____ = _____ _____();
    _____{
        _____ _____ = (_____)_____._____()._____()._____();
        _____ _____ = _____._____(_____);
        _____(_____ _____ _____){
            _____._____(_____._____);
            _____._____("_____");   ← 100%에서는 데이터성 문자열도 빈칸
        }
    } _____ (_____ _____) {
        _____._____(_____._____());
    }
    _____ _____;
}
```

### 5. 33% / 67% 선별 우선순위 (P1 → P8)

비율 채울 때 위에서부터 비움 (100%에선 P1~P8 전부 + 키워드/연산자/값/변수명/접근제어자/클래스명까지):

1. **Service/Mapper 메소드 호출명** (5-파일 묶음 핵심)
2. **getter/setter 첫 등장**
3. **표준 라이브러리 메소드 호출** (`isEmpty`, `getMessage`, `equals` 등)
4. **어노테이션 파라미터** (`"/list"`, `MembersVO.class` 등 — URL 경로 문자열 포함)
5. **같은 토큰 중복 등장** (setter 2번째 이후 등)
6. **변수 타입, 생성자(`new`), 시그니처 리턴 타입**
7. **표준 라이브러리 클래스명** (`SecurityContextHolder`, `Exception`)
8. **어노테이션 이름** (`GetMapping`, `Override` 등 — `@`는 항상 유지)

### 6. 카테고리 ① — 메소드명 빈칸 범위 (5-파일 묶음 핵심)

- ✅ 메소드 호출 위치 (예: `guestBookService.guestBookList()`)
- ✅ 서비스/매퍼 **인터페이스** 시그니처의 메소드명
- ✅ `@Override` 메소드 시그니처의 메소드명 (ServiceImpl)
- ✅ XML `<select id="...">` 등 매퍼 쿼리 id 속성값
- ❌ **컨트롤러 클래스의 메소드명**은 33%/67%에선 빈칸 X (자유 작명이라 채점 모호). 100%에서만 빈칸.

> 의도: Controller가 부른 메소드명이 ↔ Service 시그니처 ↔ 임플 `@Override` ↔ Mapper 시그니처 ↔ XML `id` 가 **전부 정확히 같아야 동작**한다는 일관성을 5번 채우면서 자연스럽게 익힘.

---

## 사전 가드 — 학습 중 중복 호출 거절

`/연습` 호출 시 가장 먼저 확인:

1. `practice/*/.state` 파일이 하나라도 있는지 검사
2. 있으면 → **거절**:
   ```
   이미 진행 중인 학습이 있음: practice/<회차폴더>/
   먼저 /연습 채점으로 끝내거나, 포기하려면 practice/<회차폴더>/.state 삭제 후 .practice-backup/<id>/에서 수동 복구.
   ```
3. 없으면 정상 진행

= **한 번에 한 회차만 진행** (src/가 빈칸 상태인 동안 다른 회차 동시 진행 금지)

---

## 모드 A: `/연습` — src/에 구멍 뚫기

### 0. 언어 룰셋 확인 (첫 실행 셋업 — 메뉴보다 먼저)

빈칸/채점 규칙은 언어마다 다르다. 메뉴 띄우기 전에 **이 프로젝트에 어떤 언어 룰셋을 쓸지** 먼저 확정한다.

```
프로젝트 CLAUDE.md 에 `## /연습 스킬 동작 가이드` 섹션 있나?
├─ 있음 → 그 언어별 빈칸/채점 규칙 우선 적용. 바로 "### 1. 연습 파일 파악"으로 (안 물어봄).
└─ 없음 → 첫 실행 셋업 (아래)
```

**첫 실행 셋업** (CLAUDE.md 에 가이드 없을 때 — clone 직후 등):

1. `src/` 주 확장자로 언어 감지 (`.java` / `.jsx`·`.tsx` / `.py` / ...)
2. 감지 언어로 빈칸·채점 규칙 블록 생성:
   - **자바** (`.java` 위주) → 이 SKILL.md 의 빈칸 X/풀 룰 + 5-파일 묶음이 그대로 프리셋. 블록엔 "자바: SKILL.md 기본 룰 사용"만 기록.
   - **그 외 언어** → 아래 "언어 룰셋 블록 템플릿"을 감지 언어에 맞게 채워 생성.
3. **생성한 블록 전문을 사용자에게 보여주고 확인** — "이 프로젝트 <언어>로 보임. 빈칸 규칙 이렇게 박을게요. 빈칸 범위 고칠 거 있음?" (`/노션정리` 의 CLAUDE.md 기록 패턴과 동일).
4. 승인/수정 반영 → 프로젝트 CLAUDE.md 에 `## /연습 스킬 동작 가이드` 섹션으로 append.
5. 그다음 "### 1. 연습 파일 파악"으로 진행.

> 한 번 기록되면 2회차부터 위 1번에서 바로 통과. **언어 룰은 프로젝트 CLAUDE.md 가 소유, SKILL.md 는 자바 프리셋 + 골격만 보유.** 새 언어는 SKILL.md 안 고치고 CLAUDE.md 블록만 추가하면 확장됨.

#### 언어 룰셋 블록 템플릿 (비자바 언어 추가용)

React 레퍼런스 구현은 `2026_myapp03` 의 CLAUDE.md 참고. 새 언어는 아래 골격을 채워 프로젝트 CLAUDE.md 에 박는다.

````markdown
## /연습 스킬 동작 가이드

### <언어> 빈칸 처리 규칙
**항상 유지(모든 비율)**: import/export, 선언 시그니처(클래스·함수·컴포넌트), 구두점, 언어별 골격(JSX `className`/`style`, Python 데코레이터 등)
**33% (핵심 식별자)**: 호출 메소드명, 핸들러명, hook/라이브러리 API 이름
**67% (+)**: 태그명·prop·키워드·조건 피연산자
**100% (+)**: 함수 본문 로직 전체, 데이터성 문자열, 상태/변수명

### 채점 규칙
| 자리 유형 | 기준 |
|----------|------|
| 라이브러리 API 이름 | 완전 일치 |
| 사용자 정의 식별자(핸들러·액션명) | 호출부/정의부 일관되면 O (강사와 달라도) |
| 데이터성 문자열 | 의미 동일 O |

### 파일 모드
- 5-파일 묶음 적용 여부 (자바 Spring/MyBatis 전용. 아니면 단일/다중 파일만)

### PROGRESS.md 구조
- 파일별 매트릭스 / 도메인 매트릭스 중 택1
````

### 1. 연습 파일 파악 (메뉴 템플릿 시스템)

UI 선택지 쓰지 말 것. 텍스트 목록 출력하고 채팅 응답 기다림.

**메뉴 캐싱**: `practice/_menu.md` 존재 → 그 내용 그대로 출력. 없으면 `src/` 동적 스캔해서 목록 구성 + `_menu.md` 에 저장.

흐름:
```
1. practice/_menu.md 존재?
   ├─ 있음 → 파일 내용 그대로 출력 ✅ (빠름)
   └─ 없음 → src/ 동적 스캔 + _menu.md 생성 + 출력 (첫 호출)
2. 사용자 입력 대기
```

**강사 새 파일 추가 시 동기화** (자동 비교 X — 수동):
- 사용자가 `practice/_menu.md` 직접 편집
- 또는 `/연습 메뉴 재생성` 명령 (사전 가드 통과 후 `_menu.md` 삭제하고 src/ 다시 스캔해서 생성)

메뉴 출력 형식 (`_menu.md` 첫 생성 시 적용):
```
[JWT / Security 공통]
1. JwtUtil
2. JwtRequestFilter
3. JwtConfig
4. DataVO

[Members]
5. MembersController       ← 5-파일 묶음
6. MembersVO
7. RefreshTokenVO

[GuestBook]
8. GuestBookController     ← 5-파일 묶음
9. GuestBookVO
```

> 5-파일 묶음에 속하는 Service/ServiceImpl/Mapper/mapper.xml은 목록에 따로 표시하지 않음 (컨트롤러 선택 시 자동 포함).

> `_menu.md` 는 git commit 대상 (다른 컴퓨터 동기화). 사용자가 수동 편집 자유.

### 2. 분기

- **선택이 컨트롤러면** → 2-A. 5-파일 묶음 모드 (⚠️ **자바 Spring/MyBatis 전용** — 타 언어는 5-파일 묶음 없이 단일/다중 파일 모드만)
- **그 외 단일 파일이면** → 2-B. 단일 파일 모드

---

### 2-A. 5-파일 묶음 모드

#### a. PROGRESS 확인

`practice/PROGRESS.md` 읽음. 없으면 자동 생성 (구조는 아래 "PROGRESS.md 구조" 참고). 기능 목록은 `src/` 컨트롤러를 분석해서 동적으로 채움.

#### b. 기능 + 퍼센티지 선택

해당 컨트롤러 도메인 매트릭스 출력. UI 선택지 X.

```
컨트롤러 선택. 5-파일 묶음 모드.

[Members] 진척도:
| # | 기능 | 33% | 67% | 100% |
|---|---|---|---|---|
| 1 | 로그인 | ⬜ | ⬜ | ⬜ |
| 2 | 토큰 재발급 | ⬜ | ⬜ | ⬜ |
| 3 | 마이페이지 | ⬜ | ⬜ | ⬜ |
| 🔒 | 로그아웃 (강사 미구현) | | | |

진행할 기능과 퍼센티지 입력:
  - 단일: "1 33", "2 67", "3 100"
  - 다중 (한 회차에 여러 기능 동시 학습): "1,2 67" 또는 "1 2 67" (쉼표 또는 공백 구분)
  - 장인 (5-파일 묶음 통째 빈 파일): "장인" — 모든 구현 기능을 한꺼번에, 빈 .java/.xml에서 처음부터 작성 (2-A-장인 섹션 참고)
  - 종합 (도메인 폴더 통째 100% 빈칸): "종합" — 모든 구현 기능 + 도메인 내 VO들까지 한번에 (2-A-종합 섹션 참고)
```

- 잠금(🔒) 기능은 선택 못 함. 강사 코드에 해당 메소드가 없으면 자동 잠금.
- 이미 ✅인 셀도 다시 풀 수 있음 (반복 학습 허용).
- **다중 기능**: 같은 컨트롤러 안의 여러 기능을 동시에 빈칸 처리. 빈칸 양 늘어나지만 5-파일 묶음 파일 셋은 동일하니까 백업/복구는 똑같이 동작.
- **장인 모드**: 100% 상위. 토큰 빈칸 대신 5-파일 묶음을 통째로 빈 파일로 만들어 구조부터 직접 작성. 별도 워크플로우 — 2-A-장인 섹션에서 다룸.
- **종합 모드**: 다중 기능 100% 의 확장. 도메인의 모든 기능 + VO 파일들까지 한 회차로. 보통 `/연습100` 에서 호출. 별도 워크플로우 — 2-A-종합 섹션에서 다룸.

#### c. 회차 폴더 + 백업 생성

회차 폴더명:
```
단일 기능:  practice/YYYY-MM-DD_<도메인>-<기능slug>_<%>/
다중 기능:  practice/YYYY-MM-DD_<도메인>-<기능1>+<기능2>_<%>/
```
예: `practice/2026-05-16_guestbook-list+insert_67/`

같은 회차 폴더 이미 있으면 `_2`, `_3` 자동 추가.

**학습 대상 파일 목록 결정** (5-파일 묶음 기준):
- `src/main/java/com/study/myproject01/<도메인>/controller/<도메인>Controller.java`
- `src/main/java/com/study/myproject01/<도메인>/service/<도메인>Service.java`
- `src/main/java/com/study/myproject01/<도메인>/service/<도메인>ServiceImpl.java`
- `src/main/java/com/study/myproject01/<도메인>/mapper/<도메인>Mapper.java`
- `src/main/resources/mapper/<도메인>-mapper.xml`

**백업 폴더 생성**:
```
.practice-backup/<session-id>/
  └── (src/ 트리 미러로 학습 대상 파일들을 그대로 복사)
```
`<session-id>` = `YYYY-MM-DD_<도메인>-<기능slug>_<%>` (회차 폴더명과 동일하게 — _2, _3 suffix 포함)

각 학습 대상 파일을 백업 위치에 그대로 복사 (디렉토리 구조 유지). **Read tool 사용 금지 — Copy-Item만.**

#### d. src/ 파일들 빈칸 버전으로 덮어쓰기

**모든 회차 (33%/67%/100%, 단일·다중 무관)는 템플릿 시스템 우선 사용** ("빈칸 템플릿 시스템" 섹션 참고):
- 단일: `practice/_templates/<도메인>-<기능slug>_<%>/`
- 다중: `practice/_templates/<도메인>-<기능1>+<기능2>_<%>/` (`+` 결합)
- **존재 체크는 `Test-Path` (⚠️ Glob tool 금지 — 디렉토리 못 잡아서 항상 없다고 오판). slug 는 소문자.**
- True → 템플릿 파일들을 src/로 Copy-Item 후 종료. **파일 내용 Read 금지.**
- False → 원본 파일 Read 후 빈칸 처리 + 결과를 `_templates/` 에 저장 (이때만 Read 허용)

각 파일을 "빈칸 비율과 자리 정의" 룰대로 처리해서 **src/의 실제 위치에 덮어쓰기**:

| 파일 | 처리 방식 |
|---|---|
| 컨트롤러 | 선택 기능의 메소드만 빈칸. 다른 기능 메소드는 원본 그대로. |
| 서비스 인터페이스 | **선택 기능의 시그니처(메소드명+리턴타입+파라미터 타입) 빈칸**. 다른 기능은 그대로. |
| 서비스 임플 | 선택 기능 메소드만 빈칸. 다른 기능 구현은 그대로. |
| 매퍼 인터페이스 | 서비스 인터페이스와 동일. |
| 매퍼 XML | 선택 기능 SQL만 빈칸. 다른 쿼리는 그대로. |

> 서비스/매퍼 **인터페이스 2곳도 시그니처 메소드명 빈칸**. 카테고리①의 "5곳 일관성"(Controller↔Service↔Impl↔Mapper↔XML) 의도상 인터페이스도 채워야 함.

#### e. `.state` 파일 생성

`practice/<회차>/.state` 작성 (JSON 형식). `features`는 항상 배열:

```json
{
  "mode": "5-file",
  "session_id": "2026-05-16_guestbook-list+insert_67",
  "domain": "guestbook",
  "features": [
    { "slug": "list",   "label": "방명록 리스트" },
    { "slug": "insert", "label": "방명록 등록" }
  ],
  "percent": 67,
  "started_at": "2026-05-16T22:30:00",
  "backup_dir": ".practice-backup/2026-05-16_guestbook-list+insert_67",
  "target_files": [
    "src/main/java/com/study/myproject01/guestbook/controller/GuestBookController.java",
    "src/main/java/com/study/myproject01/guestbook/service/GuestBookService.java",
    "src/main/java/com/study/myproject01/guestbook/service/GuestBookServiceImpl.java",
    "src/main/java/com/study/myproject01/guestbook/mapper/GuestBookMapper.java",
    "src/main/resources/mapper/guestbook-mapper.xml"
  ]
}
```

단일 기능이어도 `features` 배열에 1개 원소로 기록.

#### f. PROGRESS.md 갱신

해당 셀을 ⌛(진행 중)로 변경. `마지막 갱신` 날짜 오늘로.

---

### 2-A-장인. 장인 모드 (5-파일 묶음 통째)

100% 모드의 상위. 토큰 빈칸 박지 않음. **5-파일 묶음 전체를 빈 파일로 덮어쓰기** — 사용자가 import부터, 클래스 선언부터, 어노테이션 위치부터, 메소드 시그니처부터, SQL부터 전부 직접 작성. 강사 코드 대신 README의 **스펙(URL/요청/응답/SQL 동작)** 만 보고 5-파일 묶음을 처음부터 짜는 모드.

#### a. 입력

5-파일 묶음 매트릭스 출력 후 기능+퍼센티지 자리에 `장인` 입력. 부분 기능 선택 불가 — **컨트롤러의 모든 구현된 기능을 한꺼번에 작업**. 잠금(🔒) 기능은 자동 제외.

#### b. 회차 폴더

```
practice/YYYY-MM-DD_<도메인>-장인/
```
예: `practice/2026-05-17_guestbook-장인/`. 같은 이름 폴더 있으면 `_2`, `_3` 추가.

#### c. 백업

5-파일 묶음 일반 모드와 동일. `.practice-backup/<session-id>/` 에 5개 파일 그대로 복사.

#### d. src/ 빈 파일로 덮어쓰기

각 학습 대상 파일을 다음 내용으로 덮어쓰기:

**Controller / Service / ServiceImpl / Mapper (.java)**:
```java
package com.study.myproject01.<도메인>.<하위>;

// 장인 모드: 본인이 처음부터 작성
```

**Mapper XML**:
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper
        PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
        "https://mybatis.org/dtd/mybatis-3-mapper.dtd">

<mapper namespace="com.study.myproject01.<도메인>.mapper.<도메인>Mapper">

</mapper>
```

= 패키지 선언 / 네임스페이스만 있고 나머지 0줄.

#### e. `.state` 파일

```json
{
  "mode": "5-file-craftsman",
  "session_id": "2026-05-17_guestbook-장인",
  "domain": "guestbook",
  "started_at": "2026-05-17T22:30:00",
  "backup_dir": ".practice-backup/2026-05-17_guestbook-장인",
  "target_files": [
    "src/main/java/com/study/myproject01/guestbook/controller/GuestBookController.java",
    "src/main/java/com/study/myproject01/guestbook/service/GuestBookService.java",
    "src/main/java/com/study/myproject01/guestbook/service/GuestBookServiceImpl.java",
    "src/main/java/com/study/myproject01/guestbook/mapper/GuestBookMapper.java",
    "src/main/resources/mapper/guestbook-mapper.xml"
  ],
  "spec": {
    "features": [
      {
        "label": "방명록 리스트",
        "url": "GET /guestbook/list",
        "request": "없음",
        "response": "DataVO { success, message, data: List<GuestBookVO> }",
        "sql_intent": "g_active=0 인 행 전체 SELECT"
      }
    ]
  }
}
```

`spec.features` 는 강사 백업 코드 분석해서 자동 채움 — URL(`@GetMapping/@PostMapping`), 시그니처, SQL 동작을 추출.

#### f. README.md — 스펙 명세

코드 0줄. URL/요청/응답/SQL 동작만 박음.

```markdown
# YYYY-MM-DD <도메인> 장인 모드

## 모드
**장인 모드** — 5-파일 묶음 통째 빈 파일에서 시작. 토큰 빈칸 없음. 본인이 import부터 SQL까지 처음부터 작성.

## 학습 대상 파일 (전부 빈 상태, 패키지 선언만 박힘)
1. src/.../controller/<도메인>Controller.java
2. src/.../service/<도메인>Service.java
3. src/.../service/<도메인>ServiceImpl.java
4. src/.../mapper/<도메인>Mapper.java
5. src/main/resources/mapper/<도메인>-mapper.xml

## 스펙 (참고용 — 구현은 본인이)

### 기능 1: 방명록 리스트
- URL: GET /guestbook/list
- 요청: 없음
- 응답: DataVO { success, message, data: List<GuestBookVO> }
- SQL: g_active=0 인 행 전체 SELECT

### 기능 2: 방명록 등록
(반복)

## 진행 방법
1. IntelliJ에서 5개 파일 열고 통째 작성
2. import, 어노테이션, 클래스 선언, 메소드 시그니처, SQL 모두 본인이
3. 빌드 통과 확인: `./gradlew build`
4. 끝나면 `/연습 채점`

## 채점 방식 (토큰 비교 X)
- 컴파일 통과 (`./gradlew build`)
- 강사 스펙 ↔ 시그니처/URL/SQL 매칭
- 5-파일 일관성 (메소드명 5곳)
- SCORE_<N>.md 에 기능 단위 체크리스트로 결과 기록
```

#### g. PROGRESS.md 영향

장인 모드는 33/67/100 매트릭스 셀 갱신 **안 함**. PROGRESS.md 끝에 별도 섹션 "장인 회차 기록" 자동 추가/갱신 (구조는 PROGRESS.md 구조 섹션 참고).

---

### 2-A-종합. 종합 모드 (도메인 폴더 통째 100%)

다중 기능 100% 의 확장. 도메인의 **모든 구현된 기능 + 도메인 내 모든 VO 파일** 을 한 회차에 100% 빈칸 처리. 도메인 정복용. common(JWT, DataVO 등)은 제외.

룰 대부분은 5-파일 묶음 100% 와 동일. **차이점만** 아래 박음.

#### a. 입력

5-파일 묶음 매트릭스에서 `종합` 입력. 부분 선택 X — 도메인의 모든 구현 기능 + 도메인 내 모든 VO 자동 포함. 잠금(🔒) 기능 자동 제외 (`_filter.md` 에 박힌 메서드도 제외).

보통 `/연습100` 표에서 `★ <도메인>/종합` 항목으로 진입.

#### b. 회차 폴더

```
practice/YYYY-MM-DD_<도메인>-종합_100[_N]/
```
예: `practice/2026-05-20_members-종합_100/`. 같은 이름이면 `_2`, `_3` 자동.

#### c. 학습 대상 파일 목록 자동 탐지

도메인 폴더 (`src/main/java/com/study/myproject01/<도메인>/`) 하위 **모든 `.java` 파일** + 매퍼 XML:

- `<도메인>/controller/*.java` (보통 1개)
- `<도메인>/service/*.java` (인터페이스 + 임플 보통 2개)
- `<도메인>/mapper/*.java` (보통 1개)
- `<도메인>/vo/*.java` (1개 이상 — Members면 MembersVO + RefreshTokenVO)
- `src/main/resources/mapper/<도메인>-mapper.xml`

총 6~10개. common 폴더는 자동 제외.

#### d. 백업 + src/ 덮어쓰기

5-파일 묶음 100% 와 동일하게 처리하되 대상 파일이 도메인 폴더 전체. 템플릿 위치는 `practice/_templates/<도메인>-종합_100/`.

**VO 파일 빈칸 처리 룰**:
- 클래스 레벨 Lombok 어노테이션 (`@Getter`, `@Setter`, `@NoArgsConstructor` 등) → `@_____` 로 빈칸
- 필드 선언: 타입 + 필드명 둘 다 빈칸 (`_____ _____ _____;`)
- 패키지/import/클래스 선언/구두점은 그대로 살림

`_filter.md` 적용: 메서드 단위만. VO 필드 단위 제외 룰은 X.

#### e. `.state` 파일

```json
{
  "mode": "domain-all",
  "session_id": "2026-05-20_members-종합_100",
  "domain": "members",
  "features": [
    { "slug": "login",   "label": "로그인" },
    { "slug": "refresh", "label": "토큰 재발급" },
    { "slug": "mypage",  "label": "마이페이지" },
    { "slug": "logout",  "label": "로그아웃" }
  ],
  "include_vos": true,
  "percent": 100,
  "started_at": "2026-05-20T22:30:00",
  "backup_dir": ".practice-backup/2026-05-20_members-종합_100",
  "target_files": [
    "src/main/java/com/study/myproject01/members/controller/MembersController.java",
    "src/main/java/com/study/myproject01/members/service/MembersService.java",
    "src/main/java/com/study/myproject01/members/service/MembersServiceImpl.java",
    "src/main/java/com/study/myproject01/members/mapper/MembersMapper.java",
    "src/main/java/com/study/myproject01/members/vo/MembersVO.java",
    "src/main/java/com/study/myproject01/members/vo/RefreshTokenVO.java",
    "src/main/resources/mapper/members-mapper.xml"
  ]
}
```

`features` 는 컨트롤러 구현 메서드 분석해서 자동 채움 (`_filter.md` 제외 메서드 빼고).

#### f. PROGRESS.md 갱신

- 5-파일 묶음 매트릭스 셀은 안 건드림 (종합은 별도 트랙)
- **"기능별 100×100 도전"** 표의 `<도메인>/종합` 행 갱신 (없으면 자동 추가)
- 회차 로그에도 기록 (기능 칸은 `종합`)

#### h. 채점 (mode == `domain-all`)

다중 기능 채점 룰 그대로 + VO 파일 처리만 추가:

- **VO 필드명** → 완전 일치 (DB 컬럼 매핑 자리, 자유 작명 X)
- **VO Lombok 어노테이션** → 완전 일치 (어노테이션 이름 룰 재사용)
- **VO 필드 타입** → 완전 일치 (변수 타입 룰 재사용)

SCORE.md 의 파일 단위 섹션에 VO 파일도 추가 (Controller → Service → ServiceImpl → Mapper → XML → VO 순).

기능별 100×100 표 갱신: `<도메인>/종합` 행 1개에 +1 (개별 기능 행은 X — 별도 트랙).

---

### 2-B. 단일 파일 모드

#### a. 퍼센티지 선택

```
난이도 입력 (33, 67, 100 중 하나):
33  — 빈칸 풀의 약 1/3 (P1~P4 핵심 위주)
67  — 빈칸 풀의 약 2/3 (P1~P7)
100 — 빈칸 풀 전부 (변수명/접근제어자까지)
```

#### b. 회차 폴더 + 백업 생성

회차 폴더명:
```
practice/YYYY-MM-DD_<파일명slug>_<%>/
```
- `파일명slug`: **파일명(확장자 제거) 전부 소문자** ("템플릿 존재 체크 방법" 섹션의 정규화 규칙과 동일). 예: `TodoPage.jsx` → `todopage`, `useTodoStore.jsx` → `usetodostore`, `Http.jsx` → `http`. (기존 템플릿 폴더가 그 명명을 쓰므로 그대로 맞춤.)
- 같은 회차 폴더 이미 있으면 `_2`, `_3` 자동 추가.

학습 대상은 1개 파일. 그 파일을 `.practice-backup/<session-id>/`에 백업 (src/ 트리 미러). **Read tool 사용 금지 — Copy-Item만.**

#### c. src/ 파일 빈칸 버전으로 덮어쓰기

**템플릿 존재 체크는 `Test-Path practice/_templates/<파일명slug>_<%>` (⚠️ Glob tool 금지 — 디렉토리 못 잡음).** True 면 Copy-Item만으로 처리(**Read 금지**). False 면 원본 Read 후 빈칸 처리 + 템플릿 저장.

#### d. `.state` 파일 생성

```json
{
  "mode": "single",
  "session_id": "2026-05-16_jwt-util_67",
  "file_slug": "jwt-util",
  "percent": 67,
  "started_at": "2026-05-16T22:30:00",
  "backup_dir": ".practice-backup/2026-05-16_jwt-util_67",
  "target_files": [
    "src/main/java/com/study/myproject01/common/jwt/JwtUtil.java"
  ]
}
```

> 단일 파일 모드는 PROGRESS.md 갱신 안 함.

---

## 모드 B: `/연습 채점` — 채점 + 원본 복구

### 1. 진행 중 회차 찾기

`practice/*/.state` 파일을 찾음.
- 0개 → 거절: "진행 중인 학습 없음. 먼저 /연습으로 시작해줘."
- 1개 → 그 회차로 진행
- 2개 이상 → 거절 + 목록 출력. 사용자에게 폴더명 지정 요청 (`/연습 채점 <회차폴더명>`)

### 2. .state 읽기

`backup_dir`, `target_files`, `session_id`, `mode`, `percent` 등 추출.

**mode 분기**:
- `5-file`, `single`, `domain-all` → 아래 3~9단계 (토큰 비교 채점)
- `5-file-craftsman` → "장인 모드 채점" 섹션으로

`domain-all` 모드는 다중 기능 채점 룰 그대로 + VO 파일 채점 룰만 추가 (2-A-종합 h 참고). PROGRESS.md 갱신은 `<도메인>/종합` 행 1개에 +1 (개별 기능 행 X — 별도 트랙).

### 3. 채점

각 `target_files` 파일에 대해:
- **사용자 작성본**: `src/` 의 현재 파일 (사용자가 빈칸 채워놓은 상태)
- **원본 정답**: `.practice-backup/<session-id>/` 의 같은 경로 파일
- **빈칸 위치**: 원본 vs 빈칸 파일 비교는 필요 없음 — **사용자 작성본 vs 원본 정답** 토큰 비교

자리별 O/X 판정 (기준은 아래 "채점 기준" 표).

### 4. 사용자 작성본 → `practice/<회차>/`에 보존

각 `target_files`의 사용자 작성본을 회차 폴더 안에 동일 경로 구조로 복사:
```
practice/2026-05-16_members-login_67/
├── README.md
├── SCORE_1.md
├── .state                                                   ← 채점 후 삭제될 것
├── src/main/java/com/study/myproject01/members/controller/MembersController.java
├── src/main/java/com/study/myproject01/members/service/MembersService.java
├── src/main/java/com/study/myproject01/members/service/MembersServiceImpl.java
├── src/main/java/com/study/myproject01/members/mapper/MembersMapper.java
└── src/main/resources/mapper/members-mapper.xml
```
= **사용자 답안 영구 보존**.

### 5. SCORE_<N>.md 작성

학습형 SCORE.md. **파일 단위로 묶음**. 개념 묶음·잘한 점·다음에 할 것 섹션 **금지**.

**파일명 규칙**: `SCORE_<N>.md` (N=1부터 시작, 같은 회차 폴더에서 재채점할 때마다 +1).
- 첫 채점 → `SCORE_1.md`
- 두 번째 채점 → `SCORE_2.md` (이전 보존 — 진척 비교용)
- 회차 폴더별로 독립 카운터

```markdown
# 채점 결과 #<N> — YYYY-MM-DD <도메인> <기능> <%>

(이전 채점이 있으면 1줄: `> 이전 채점: SCORE_<N-1>.md (X/Y, Z%)`)

## 점수
**X / Y (Z%)**

| 파일 | 점수 |
| ... | ... |

---

## <파일명1> (X/Y)

### L<라인>: `<오답>` → `<정답>`
- **왜 틀렸나**: 컴파일러·런타임 관점에서 근본 원인 (1~3줄)
- **외우는 법**: 다음번에 안 틀리게 하는 패턴/연상법 (1~2줄)

(반복)

---

## <파일명2> (X/Y)
(반복)
```

#### 작성 룰

- **파일 단위 묶음 고정**: Controller → Service → ServiceImpl → Mapper → XML 순. 5-파일 묶음이면 5개 섹션, 단일 파일이면 1개 섹션
- **각 오답마다 정답 박을 것**. 빈칸 자리의 정답 토큰만
- **맞은 빈칸은 SCORE.md에 안 적음**. 틀린 것만 나열
- **잘한 점 / 다음에 할 것 / 개념별 묶음 섹션 박지 말 것**
- **왜 틀렸나·외우는 법은 매 오답마다 1~3줄로 짧게**. 똑같은 이유로 여러 군데 틀렸으면 첫 번째에만 자세히 쓰고 다음부터는 "같은 이유" 한 줄
- 미작성(`_____` 그대로) 빈칸도 오답. 정답 박고 "미작성" 이유 한 줄

### 6. src/ 원본 복구

`.practice-backup/<session-id>/` 의 파일들을 src/ 의 같은 경로로 복사 (덮어쓰기) → src/ 가 학습 전 강사 코드 상태로 복귀.

### 7. 정리

- `.practice-backup/<session-id>/` 폴더 삭제
- `practice/<회차>/.state` 파일 삭제
- `practice/<회차>/`는 그대로 (README + SCORE_*.md + 답안 보존)

### 8. PROGRESS.md 갱신 (5-파일 묶음일 경우)

#### 8-a. 매트릭스 셀 갱신 (모든 비율 공통)

`.state`의 `features` 배열 각 기능에 대해 **기능별로 채점 → PROGRESS 매트릭스 셀 갱신**:
- 만점 → ✅
- 부분 점수 → ⌛ (시도했지만 만점 못 받음)
- 0점 → ⬜ 회귀

다중 기능이면 각 행의 해당 % 셀을 각각 갱신.

#### 8-b. 기능별 100×100 도전 트래커 갱신 (`percent == 100` 일 때만)

PROGRESS.md 의 "기능별 100×100 도전" 표와 "회차 로그" 표를 갱신. 섹션 없으면 자동 생성.

**1) 기능별 100×100 표 갱신**:

**`mode == 'domain-all'` (종합 모드)**: `features` 배열 개별 기능 행에는 +1 X. 대신 **`<도메인>/종합` 행에만** +1. 만점 여부는 회차 전체 점수 기준 (= 총점이 만점이면 만점 +1).

**그 외 (`5-file`, `single`)**: `.state` 의 `features` 배열 각 기능마다:
- **진행** = `<현재값+1>/100` (다중 기능 회차도 각 기능에 +1)
- **만점** +1 (그 기능 점수가 만점일 때만 — 다중 기능이면 SCORE.md 의 기능별 점수 표 참조)
- **평균 정답률** = (그 기능 누적 점수 합계) / (그 기능 누적 빈칸 합계) — 가중 평균
- **최근** = `<오늘 날짜> (<점수>)`

**다중 기능 회차 묶음 행 카운트** (`features` 배열 2개 이상일 때):
- 개별 기능 행 +1 (위 룰) **+ 묶음 행** (`<도메인>/<기능1>+<기능2>+...` 형식 한글 라벨) 도 PROGRESS.md 표에 존재하면 동일 룰로 +1
- 묶음 행의 빈칸 합계·점수는 회차 전체 합계 사용 (개별 기능 SCORE 합산 X — 회차 통째)
- 묶음 행 없으면 (사용자가 표에 안 박은 조합) 묶음 카운트 스킵 — 개별 행만 +1
- 한글 라벨 매칭: `.state` 의 `features` 배열 label 들을 `+` 로 join (예: `로그인+토큰 재발급`) → PROGRESS.md 행과 비교. 공백 무시.

**2) 회차 로그에 행 추가**:
```
| <다음번호> | <오늘 날짜> | <세션폴더명>/<이번 SCORE 파일명> | <기능명> | X/Y | Z% |
```
- `<다음번호>` = 기존 회차 로그 마지막 번호 +1
- 다중 기능이면 기능명 칸은 `리스트+등록` 식으로 `+` 결합
- 종합 모드면 기능명 칸은 `종합`
- 점수는 SCORE.md 의 회차 전체 합계 사용

**상단 통계 박스(총 시도/만점 회차/평균 정답률)는 두지 않음** — 기능별 표가 메인.

**트래커 섹션 자동 생성 시 구조** (없으면 이 형식으로 생성):

```markdown
---

## 기능별 100×100 도전

각 기능마다 5-파일 묶음 100% 풀이를 100번 도전. 강사 새 기능 추가 시 행 추가.

| 기능 | 진행 | 만점 | 평균 정답률 | 최근 |
|---|---|---|---|---|
| Members/로그인 | 0/100 | 0 | - | - |
| Members/토큰 재발급 | 0/100 | 0 | - | - |
| Members/마이페이지 | 0/100 | 0 | - | - |
| ★ Members/종합 | 0/100 | 0 | - | - |
| GuestBook/리스트 | 0/100 | 0 | - | - |
| GuestBook/등록 | 0/100 | 0 | - | - |
| ★ GuestBook/종합 | 0/100 | 0 | - | - |

> - 다중 기능 회차는 각 기능에 +1씩 카운트.
> - 종합 모드(★)는 도메인 정복 별도 트랙. 개별 기능 행에는 +1 X.
> - 평균 정답률 = (그 기능 누적 점수 합계) / (그 기능 누적 빈칸 합계). 가중 평균.
> - 점수 출처: 회차 SCORE.md의 기능별 점수 표.

## 회차 로그 (어떤 회차에 무엇을 풀었는지 흔적)

| # | 날짜 | 회차/SCORE | 기능 | 점수 | 정답률 |
|---|---|---|---|---|---|

> "시도" = SCORE.md 1개 = 1회. 회차 로그 행 = SCORE.md 1개.
```

**강사 새 기능 추가 시**: 자동 분석 안 함. 사용자가 "새 기능 추가됨" 알리면 그때 PROGRESS.md 매트릭스 + 기능별 표에 행 수동 추가.

단일 파일 모드 (`mode: "single"`)는 PROGRESS.md 안 건드림 (매트릭스도, 기능별 표도).

### SCORE.md 다중 기능 처리

SCORE.md는 **파일 단위** 묶음 유지하되, 다중 기능이면 점수 표에 기능별 합계도 표시:
```markdown
| 기능 | 점수 |
| 방명록 리스트 | X/Y |
| 방명록 등록 | X/Y |

| 파일 | 점수 |
| GuestBookController.java | X/Y |
...
```
오답 섹션은 파일 단위로만. 기능별 분리하지 않음 (같은 파일에 두 기능 메소드가 들어있어도 한 섹션에 다 나열).

### 9. 채팅 응답

채팅엔 다음만:
1. 총점 (한 줄)
2. `[SCORE.md](path) 참고` 안내
3. "src/ 원본 복구 완료. git diff 0 확인 가능." 한 줄

오답 나열·요약 채팅에 박지 말 것.

---

## 장인 모드 채점 (mode == `5-file-craftsman`)

`.state` 의 `mode` 가 `5-file-craftsman` 이면 위의 일반 채점(3~5, 8단계)을 우회하고 다음 절차로 진행. 토큰 자리 비교 안 함 — 자리 자체가 없음.

### a. 빌드 검사

`./gradlew build` 실행. 결과 캡처.
- 통과: PASS
- 실패: FAIL — 컴파일 에러 메시지를 SCORE.md 메모에 3줄 이내로 인용

### b. 기능별 매칭

`.state` 의 `spec.features` 각 기능마다 사용자 작성본을 4가지 축으로 검사:

| 체크 | 기준 |
|---|---|
| URL 매핑 | 컨트롤러에 해당 `@GetMapping/@PostMapping` 있는지 |
| 시그니처 | 메소드 리턴 타입·파라미터가 스펙과 의미 단위 일치 |
| 5-파일 일관성 | Controller 호출명 ↔ Service ↔ Impl ↔ Mapper ↔ XML id 동일 |
| SQL 의미 | 강사 의도(`sql_intent`)와 사용자 SQL이 의미적으로 같은지 (테이블·컬럼·조건) |

기능당 4점. 일반 모드의 토큰 자리별 점수와는 다른 척도.

### c. 사용자 작성본 보존

일반 모드와 동일 — `practice/<회차>/src/...` 트리에 사용자 코드 복사.

### d. SCORE_<N>.md (장인 모드 형식)

```markdown
# 장인 모드 채점 #N — YYYY-MM-DD <도메인>

## 빌드
[O/X] `./gradlew build` 통과
(실패 시 에러 메시지 인용 — 3줄 이내)

## 기능 1: <기능명>
- [O/X] URL 매핑 (<URL>)
- [O/X] 시그니처
- [O/X] 5-파일 일관성
- [O/X] SQL 의미 (<sql_intent>)
- 메모: <발견된 이슈 / 개선점, 1~3줄>

(기능 반복)

## 종합
- 빌드: O/X
- 기능 통과율: X/Y (각 기능 4점 만점 합계)
- 평가: 2~3줄 코멘트 (강점·약점)
```

### e. src/ 원본 복구

일반 모드와 동일 — 백업에서 src/로 복사.

### f. PROGRESS.md 갱신 — 장인 회차 기록 섹션

매트릭스 셀은 안 건드림. PROGRESS.md 끝에 "장인 회차 기록" 섹션 있는지 확인, 없으면 추가, 있으면 새 행 append (구조는 아래 PROGRESS.md 구조 섹션 참고).

### g. 정리 + 채팅 응답

일반 모드와 동일. `.practice-backup/` 삭제, `.state` 삭제, 회차 폴더 보존. 채팅엔 빌드 결과 + 기능 통과율 + SCORE 링크 + 복구 안내만.

---

## 채점 기준

빈칸 위치(원본 정답 vs 사용자 작성본)별 O/X:

| 자리 유형 | 채점 기준 |
|---|---|
| **5-파일 묶음 메소드명** | **사용자가 5곳에서 일관되게 사용했으면 O**. 강사 코드와 다른 이름이어도 동작하면 인정 |
| getter/setter, 필드 접근 | 완전 일치 (Lombok 자동 생성이라 변경 불가) |
| **어노테이션 이름** (`GetMapping`, `Override` 등) | 완전 일치 (Spring/Java 정의된 이름) |
| **어노테이션 파라미터** (URL 경로, 클래스 참조) | 완전 일치 |
| SQL 식별자 (테이블·컬럼) | 완전 일치 (대소문자 무시) |
| **데이터성 문자열 리터럴** (사용자 메시지) | 33%/67%에서는 빈칸 X (채점 대상 아님). **100%에서는 빈칸 → 의미 동일하면 O** (예: "토큰이 없음" ↔ "refreshToken이 없네요" 인정. 글자 안 같아도 의미 같으면 ✅) |
| **XML 태그 속성값** (`parameterType`, `resultType`) | 33%/67%에서는 빈칸 X. **100%에서는 빈칸 → 완전 일치** |
| 변수 타입, 시그니처 리턴 타입, 생성자 | 완전 일치 |
| **구조 키워드** (`try`/`catch`/`if`/`else`/`for`/`while`) | 완전 일치 (Java 문법) — **100% 전용** |
| **흐름 키워드** (`return`/`throw`/`break`/`continue`) | 완전 일치 — **100% 전용** |
| **조건 연산자** (`==`/`!=`/`&&`/`\|\|`) | 의미 동일하면 O — **100% 전용** |
| **값 토큰** (`null`/`Boolean.*`/숫자) | 의미 동일하면 O (예: `Boolean.FALSE` ↔ `false` 허용) — **100% 전용** |
| **표준 라이브러리 클래스명** (`SecurityContextHolder`, `Exception`, `String`) | 완전 일치 — **100% 전용** |
| **표준 라이브러리 메소드 호출** (`getContext()`, `getMessage()` 등) | 완전 일치 |
| 변수명, 컨트롤러 메소드명, `public` 접근제어자 | 사용자가 일관되게 사용했으면 O — **100% 전용** |
| **VO 필드명** (`m_id`, `rt_user_id` 등) | 완전 일치 (DB 컬럼 매핑이라 자유 작명 X) — **종합 모드 전용** |
| **VO Lombok 어노테이션** (`@Getter`, `@Setter`, `@NoArgsConstructor` 등) | 완전 일치 (어노테이션 이름 룰 재사용) — **종합 모드 전용** |
| **VO 필드 타입** (`String`, `Date`, `int` 등) | 완전 일치 (변수 타입 룰 재사용) — **종합 모드 전용** |

**원칙**:
- **자유 작명 가능 자리** (5-파일 묶음 메소드명, 변수명, 컨트롤러 메소드명) → 5곳/메소드 내 일관성으로 채점
- **고정 의미 자리** (Java/Spring 키워드, 표준 라이브러리, getter/setter, 어노테이션 이름) → 완전 일치
- **의미 동등 허용 자리** (조건 연산자, 값 토큰) → 동작이 같으면 O (`Boolean.FALSE` ↔ `false`)
- 강사 코드와 스타일 차이는 오답 아님 (단 의미가 같아야 함)

점수: `맞은 빈칸 / 전체 빈칸`

---

## PROGRESS.md 구조

위치: `practice/PROGRESS.md` (회차 폴더 밖, 마스터 진척도)

PROGRESS.md가 없으면 `/연습` 첫 실행 시 자동 생성. 기능 목록은 `src/`의 컨트롤러를 분석해서 동적으로 채움.

```markdown
# 5-파일 묶음 연습 진척도

마지막 갱신: YYYY-MM-DD

## GuestBook (`/guestbook`)
| # | 기능 | 33% | 67% | 100% |
|---|---|---|---|---|
| 1 | 방명록 리스트 | ⬜ | ⬜ | ⬜ |
| 2 | 방명록 등록 | ⬜ | ⬜ | ⬜ |
| 🔒 | 방명록 상세 (강사 미구현) | | | |

## Members (`/members`)
| # | 기능 | 33% | 67% | 100% |
|---|---|---|---|---|
| 1 | 로그인 | ⬜ | ⬜ | ⬜ |
| 2 | 토큰 재발급 | ⬜ | ⬜ | ⬜ |
| 3 | 마이페이지 | ⬜ | ⬜ | ⬜ |
| 🔒 | 로그아웃 (강사 미구현) | | | |

## 표기
- ⬜ 미진행
- ⌛ 진행 중 (빈칸 생성 후 채점 전)
- ✅ 만점 완료
- 🔒 잠김 (강사 미구현)

## 잠금 해제 방법
강사가 새 기능을 강의/구현한 후, 위 표에서 해당 행의 🔒를 #(다음 번호)로 바꾸고 셀을 ⬜로 추가.

## 장인 회차 기록 (5-파일 묶음 통째 작성)
*장인 모드 채점 후 자동 추가/갱신. 매트릭스와 별개 트랙.*

| 날짜 | 도메인 | 빌드 | 기능 통과 | 메모 |
|---|---|---|---|---|
| 2026-05-17 | GuestBook | O | 2/2 | 4점 만점 |
```

### 학습 곡선 기준 기본 순서 (PROGRESS 자동 생성 시 적용)

**GuestBook** (JWT 무관 → 진입용):
1. 리스트 조회 (단순 SELECT)
2. 등록 (INSERT + `@RequestBody`)
3. 상세 — 강사 미구현이면 🔒

**Members** (JWT 필요):
1. 로그인 (BCrypt + JwtUtil + 2테이블)
2. 토큰 재발급 (로그인 패턴 재활용)
3. 마이페이지 (SecurityContext)
4. 로그아웃 — 강사 미구현이면 🔒

---

## .gitignore 추가 사항

이 스킬은 다음 항목이 `.gitignore`에 있다고 가정한다 (없으면 추가):
```
.practice-backup/
practice/*/.state
```

이유:
- `.practice-backup/`: 학습 중 임시 백업. commit 대상 아님.
- `practice/*/.state`: 학습 중 상태 마커. 휘발성.

회차 폴더 자체와 README, SCORE_*.md, 답안 파일들은 git에 commit해서 보존.

---

## 다른 스킬들과의 충돌 방지

`practice/*/.state`가 존재하는 동안 다음 스킬은 거절해야 함:
- `/강사싱크` — src/가 빈칸 상태라 머지 꼬임
- `/푸쉬` — 빈칸 상태가 git에 들어감

각 스킬에서 사전 체크 후 거절 메시지 출력. 사용자에게 `/연습 채점` 먼저 안내.
