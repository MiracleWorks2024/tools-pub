# tools-pub

미라클웍스(주)의 **범용 작업 도구 모음**입니다. 여러 AI 작업 환경(claude.ai 채팅 샌드박스, Claude Code, Hermes Agent 등)에서 동일한 도구를 재사용하기 위한 공개 저장소입니다.

## 왜 공개 저장소인가

claude.ai 채팅 샌드박스는 대화 종료 시 파일시스템이 초기화되고, 네트워크는 허용 도메인 목록으로 제한됩니다. 그 목록에 `raw.githubusercontent.com`이 포함되어 있어 GitHub가 사실상 유일한 반입 경로입니다.

비공개 저장소를 쓰려면 토큰이 필요한데, 토큰을 대화창에 붙여넣으면 대화 이력에 영구히 남습니다. 따라서 **채팅 환경에서 쓸 도구는 공개 저장소에 두되, 그 대가로 사업 정보를 일절 넣지 않는다**는 원칙으로 위험을 상쇄합니다.

## 반입 금지 (예외 없음)

이 저장소는 공개됩니다. 다음은 어떤 형태로도 커밋하지 않습니다.

- API 키, 토큰, 비밀번호, 인증 정보
- 급여·인사 데이터, 재무 자료
- 정부과제 협약서, 제안서 본문, 미공개 기술 내용
- 거래처·파트너 연락처 및 내부 문서
- 고객 데이터, 개인정보

판단 기준은 저장소의 공개 여부가 아니라 **파일 내용물의 민감도**입니다. 사업 맥락이 담긴 산출물은 이 저장소가 아니라 Google Drive 또는 로컬에 둡니다.

## 사용법

### claude.ai 채팅 샌드박스

```bash
curl -sO https://raw.githubusercontent.com/MiracleWorks2024/tools-pub/main/md2html/md2html.py
pip install markdown --break-system-packages
python3 md2html.py 문서.md
```

### Claude Code

최초 1회, 컴퓨터마다 실행합니다. 공개 저장소라 **GitHub 로그인 없이** 됩니다.

```bash
git clone https://github.com/MiracleWorks2024/tools-pub.git ~/MAS/CA/tools/github-pub
sh ~/MAS/CA/tools/github-pub/setup.sh
```

`setup.sh`는 다음을 합니다. 여러 번 실행해도 안전합니다.

- `skills/` 아래 스킬을 `~/.claude/skills/`에 링크로 연결
- 터미널 명령(`app-sessions`)을 `~/.local/bin/`에 링크로 연결
- Claude Code 세션이 시작될 때마다 이 저장소를 자동으로 `git pull` 하는 훅 등록
- 대화 기록 보관기간(`cleanupPeriodDays`)이 설정돼 있지 않으면 36500일(약 100년)로 설정. 기본값 30일이면 CLI 세션 기록이 지워집니다

새 스킬이나 명령이 추가된 뒤에는 자동 pull 만으로는 연결되지 않으므로 `setup.sh`를 한 번 더 실행합니다.

**Claude 데스크톱 앱에서 할 때**는 새 세션을 열고 첫 메시지로 다음을 붙여넣습니다. 폴더는 지정하지 않아도 됩니다.

> 다음 명령을 실행해줘: git clone https://github.com/MiracleWorks2024/tools-pub.git ~/MAS/CA/tools/github-pub && sh ~/MAS/CA/tools/github-pub/setup.sh

- 저장소 이름만 말해도 Claude가 찾아서 실행하는 경우가 많지만, 이름이 같은 다른 사람의 저장소를 잡지 않도록 전체 주소를 주는 편이 확실합니다
- `~/MAS/CA`에 쓰기 승인 창이 뜨면 승인합니다
- 앱의 터미널 패널 버튼은 대화를 시작해야 나타납니다. 앱 없이 터미널.app이나 Ghostty에서 위 명령을 직접 실행해도 됩니다

설치가 끝나면 새 세션에서 `/setup-claude-default-folder`로 기본 산출물 폴더도 설정할 수 있습니다.

설치 확인:

```bash
git -C ~/MAS/CA/tools/github-pub remote get-url origin   # https://github.com/MiracleWorks2024/tools-pub.git
ls -l ~/.claude/skills/                                  # setup-claude-default-folder, app-sessions -> …/github-pub/skills/…
grep pull-tools-pub ~/.claude/settings.json              # 훅 등록 한 줄
grep cleanupPeriodDays ~/.claude/settings.json           # 대화 기록 보관기간
app-sessions | head -3                                   # 명령 동작 확인 (macOS)
```

### Hermes / 기타 로컬 환경

```bash
git clone https://github.com/MiracleWorks2024/tools-pub.git   # 최초 1회
git -C tools-pub pull                                         # 이후 갱신
```

## 여러 컴퓨터에서 함께 쓰기

| 방향 | 방식 |
|---|---|
| 받기 | **자동.** 세션 시작 시 백그라운드에서 fast-forward pull. 결과는 `~/.claude/hooks/pull-tools-pub.log` |
| 올리기 | **수동.** 공개 저장소이므로 커밋 내용을 검사한 뒤 push |

올리기를 자동화하지 않는 이유는, 비밀정보가 한 번 커밋되면 파일을 지워도 커밋 이력에 영구히 남기 때문입니다. 커밋 전에 다음을 확인합니다.

```bash
git diff --cached | grep -niE "api[_-]?key|token|secret|password|비밀번호|급여|협약서"
```

한 컴퓨터에서 커밋해 두고 아직 push 하지 않은 사이 다른 컴퓨터가 먼저 push 했거나, 받아올 변경이 아직 커밋하지 않은 로컬 수정과 겹치면 자동 pull은 아무것도 바꾸지 않고 멈춥니다. 이때는 로그를 확인하고 직접 합칩니다(보통 `git pull --rebase`).

공개하면 안 되는 도구는 이 저장소가 아니라 동기화되지 않는 `~/MAS/CA/tools/local/`에 둡니다.

### 이 컴퓨터에서도 push 하려면

받기는 로그인 없이 되지만 올리기에는 로그인이 필요합니다. 컴퓨터마다 한 번씩 합니다.
`gh auth status`로 이미 로그인돼 있으면 ①은 건너뜁니다. `gh`가 없으면 `brew install gh`부터 합니다.

**① GitHub 로그인** — 질문에 답해야 하는 대화형 명령입니다. Claude 데스크톱 앱에서는 "터미널 패널에서 아래 명령 실행해줘"라고 하거나, 터미널에서 직접 실행합니다.

```bash
gh auth login --hostname github.com --git-protocol https --web --clipboard
```

Git 인증 여부를 물으면 **Y** → **Enter** → 브라우저에서 GitHub 로그인 → 코드 붙여넣기(클립보드에 복사돼 있음) → **Authorize**.
Git 인증을 묻지 않았다면 끝난 뒤 `gh auth setup-git`을 실행합니다.

**② 커밋 신원** — 공개 저장소는 커밋마다 작성자 이메일이 공개되므로 GitHub 가림용(noreply) 주소를 씁니다. 이 저장소 소유 계정 기준 값입니다.

```bash
git config --global user.name "MiracleWorks2024"
git config --global user.email "325897086+MiracleWorks2024@users.noreply.github.com"
```

## 도구 목록

| 도구 | 용도 | 의존성 |
|---|---|---|
| `md2html/md2html.py` | 마크다운 → 인쇄 최적화 HTML(A4) 변환. 4종 테마, 메타박스 자동 승격, 출력 파일 버전 자동 증분 | `markdown` |
| `md2docx/md2docx.py` | 마크다운 → Word(.docx) 변환. 한글 글꼴 지정, 열이 많은 표는 가로 페이지 배치. [상세](md2docx/README.md) | `python-docx` |
| `skills/setup-claude-default-folder` | Claude Code 스킬. 폴더 미지정 세션의 기본 산출물 폴더를 컴퓨터별로 설정. [상세](skills/setup-claude-default-folder/README.md) | 없음 |
| `skills/app-sessions` | 터미널 명령 + Claude Code 스킬. 데스크톱 앱 세션을 CLI 에서 `claude --resume` 으로 이어가기(보관된 세션 포함), CLI 세션을 앱에서 열기 (macOS). [상세](skills/app-sessions/README.md) | 없음 |

필요한 패키지는 한 번에 설치할 수 있습니다.

```bash
python3 -m pip install -r requirements.txt
```

### md2html.py

```bash
python3 md2html.py input.md                    # input.html 생성
python3 md2html.py input.md -o report.html     # 출력 경로 지정
python3 md2html.py input.md --theme slate      # navy | slate | forest | mono
python3 md2html.py input.md --title "제목"      # 미지정 시 첫 H1 자동 추출
python3 md2html.py *.md --batch                # 일괄 변환
python3 md2html.py input.md --force            # 덮어쓰기 허용
```

기본 동작은 **기존 파일을 보존**합니다. 출력 파일이 이미 있으면 `_v2`, `_v3` 순으로 새 파일을 만듭니다.

문서 선두에 다음 형식의 불릿이 있으면 자동으로 메타 정보 박스로 렌더링됩니다.

```markdown
- **작성시각**: 2026-09-07 14:00 KST
- **작성목적**: ...
- **작성자**: ...
- **버전**: v1.0
```

## 디렉터리 구조

```
tools-pub/
├── README.md            이 문서
├── CLAUDE.md            Claude Code용 작업 규칙 (자동 로드)
├── .gitignore
├── requirements.txt     Python 의존성
├── setup.sh             Claude Code 연결 (스킬·명령 링크 + 자동 pull 훅 + 보관기간)
├── hooks/
│   └── pull-tools-pub.sh
├── md2html/
│   └── md2html.py
├── md2docx/
│   ├── md2docx.py
│   └── README.md
└── skills/
    ├── setup-claude-default-folder/
    │   ├── SKILL.md
    │   └── README.md
    └── app-sessions/
        ├── app-sessions     터미널 명령 (Python)
        ├── SKILL.md
        └── README.md
```

## 라이선스

미라클웍스(주) 사내 사용을 전제로 공개합니다. 자유롭게 참고하셔도 좋습니다.
