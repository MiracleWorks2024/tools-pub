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

최초 1회, 컴퓨터마다 실행합니다.

```bash
git clone https://github.com/MiracleWorks2024/tools-pub.git ~/Claude/tools/github-pub
sh ~/Claude/tools/github-pub/setup.sh
```

`setup.sh`는 `skills/` 아래 스킬을 `~/.claude/skills/`에 링크로 연결하고, Claude Code 세션이 시작될 때마다 이 저장소를 자동으로 `git pull` 하는 훅을 등록합니다. 여러 번 실행해도 안전합니다.

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

공개하면 안 되는 도구는 이 저장소가 아니라 동기화되지 않는 `~/Claude/tools/local/`에 둡니다.

## 도구 목록

| 도구 | 용도 | 의존성 |
|---|---|---|
| `md2html/md2html.py` | 마크다운 → 인쇄 최적화 HTML(A4) 변환. 4종 테마, 메타박스 자동 승격, 출력 파일 버전 자동 증분 | `markdown` |
| `md2docx/md2docx.py` | 마크다운 → Word(.docx) 변환. 한글 글꼴 지정, 열이 많은 표는 가로 페이지 배치. [상세](md2docx/README.md) | `python-docx` |
| `skills/setup-claude-default-folder` | Claude Code 스킬. 폴더 미지정 세션의 기본 산출물 폴더를 컴퓨터별로 설정. [상세](skills/setup-claude-default-folder/README.md) | 없음 |

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
├── setup.sh             Claude Code 연결 (스킬 링크 + 자동 pull 훅)
├── hooks/
│   └── pull-tools-pub.sh
├── md2html/
│   └── md2html.py
├── md2docx/
│   ├── md2docx.py
│   └── README.md
└── skills/
    └── setup-claude-default-folder/
        ├── SKILL.md
        └── README.md
```

## 라이선스

미라클웍스(주) 사내 사용을 전제로 공개합니다. 자유롭게 참고하셔도 좋습니다.
