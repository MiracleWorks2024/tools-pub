# setup-claude-default-folder

Claude Code 데스크톱 앱에는 "새 세션의 기본 작업 폴더" 설정이 없습니다. 폴더를 고르지
않으면 세션은 임시 scratch 워크스페이스에서 열리고, 거기 만든 파일은 세션이 사라질 때
함께 사라집니다.

이 스킬은 그 대신 **폴더 미지정 세션의 산출물이 저장될 기본 폴더**를 설정합니다.
설정 파일이 전부 로컬 파일이라 계정이 아니라 **컴퓨터별**로 적용됩니다.

## 설치

**이 저장소를 clone 한 경우 (권장)** — 저장소 루트에서 실행합니다.

```bash
sh setup.sh
```

스킬이 `~/.claude/skills/` 에 심볼릭 링크로 연결되므로, 이후에는 `git pull` 만으로
스킬도 최신이 됩니다.

**파일 하나만 쓰는 경우** — `SKILL.md` 를 아래 위치에 복사합니다.

| OS | 경로 |
|---|---|
| macOS / Linux | `~/.claude/skills/setup-claude-default-folder/SKILL.md` |
| Windows | `%USERPROFILE%\.claude\skills\setup-claude-default-folder\SKILL.md` |

**설치 없이 한 번만** — Claude Code 에 `SKILL.md` 내용을 붙여넣고
"이 절차대로 설정해줘. 질문 두 개 먼저 물어보고 진행해." 라고 합니다.

## 실행

새 세션에서 `/setup-claude-default-folder` 를 실행하면 질문 두 개를 묻습니다.

1. **기본 산출물 폴더** — `~/MAS/CA/claude default` (추천), `~/Documents/Claude`, `~/Desktop/Claude`, 직접 입력
2. **SessionStart 훅 추가 여부** — CLAUDE.md 만 (추천) / 훅도 같이

## 바꾸는 파일

| 파일 | 변경 내용 |
|---|---|
| `~/.claude/CLAUDE.md` | 산출물 저장 규칙 블록 추가. 마커로 감싸서 재실행해도 중복되지 않음 |
| `~/.claude/settings.json` | `permissions.additionalDirectories` 에 폴더 추가 → 쓰기 승인 창 제거 |
| `~/.claude/hooks/default-output-folder.sh` | 훅을 선택한 경우에만 생성 |

기존 `CLAUDE.md` 와 `settings.json` 은 덮어쓰지 않고 병합하며, `settings.json` 은
변경 전에 타임스탬프를 붙여 백업합니다.

## 환경이 다를 때

- 홈 경로나 폴더명에 공백·한글이 있어도 동작합니다
- `python3` 도 `jq` 도 없으면 Claude 가 파일을 직접 편집합니다
- Windows 에서는 설정 경로가 `%USERPROFILE%\.claude\` 이고, `.sh` 훅은 건너뜁니다

## 알아둘 점

- **다음 세션부터 적용됩니다.** `CLAUDE.md` 는 세션이 시작될 때 로드됩니다.
- **세션은 여전히 "No folder" 로 열립니다.** 바뀌는 건 산출물이 임시 폴더에서 사라지지
  않는다는 점입니다.
- **계정 동기화가 되지 않습니다.** 컴퓨터마다 따로 실행해야 합니다.
