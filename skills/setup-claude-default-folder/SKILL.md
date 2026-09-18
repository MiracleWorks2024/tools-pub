---
name: setup-claude-default-folder
description: 이 컴퓨터에 Claude Code의 기본 산출물 폴더를 설정한다. 폴더를 지정하지 않고 연 세션(임시 scratch 워크스페이스)에서 만든 결과물이 세션 종료와 함께 사라지지 않도록, 지정한 폴더에 저장하게 만든다. "기본 폴더 설정", "산출물 저장 위치", "새 컴퓨터에 클로드 코드 설정", "default output folder" 같은 요청에 사용한다.
---

# 기본 산출물 폴더 설정

## 목적

Claude Code 데스크톱 앱에는 "새 세션의 기본 작업 폴더"를 지정하는 설정이 없다. 폴더를
고르지 않으면 세션은 임시 scratch 워크스페이스에서 열리고, 거기 만든 파일은 세션이
사라질 때 함께 사라진다.

이 스킬은 그 대신 **폴더 미지정 세션의 산출물이 저장될 기본 폴더**를 이 컴퓨터에
설정한다. 설정 파일은 모두 로컬 파일이므로 계정이 아니라 **컴퓨터별**로 적용된다.

건드리는 파일은 두 개다.

| 파일 | 역할 |
|---|---|
| `~/.claude/CLAUDE.md` | 전역 규칙. 모든 세션에 자동 로드된다 |
| `~/.claude/settings.json` | `permissions.additionalDirectories`(승인 창 제거), 선택 시 `hooks.SessionStart` |

## 절차

아래 순서를 그대로 따른다. 절대 건너뛰지 말 것.

### 0단계 — 환경 파악

먼저 이 컴퓨터의 상태를 확인한다. 뒤 단계의 분기와 질문 내용이 여기 결과에 달려 있다.

```bash
echo "HOME=$HOME"; uname -s; echo "---"
ls -la "$HOME/.claude/CLAUDE.md" "$HOME/.claude/settings.json" 2>&1
echo "--- 후보 폴더 존재 여부 ---"
for d in "$HOME/Claude/default" "$HOME/Documents/Claude" "$HOME/Desktop/Claude"; do
  [ -d "$d" ] && echo "있음: $d" || echo "없음: $d"
done
echo "--- JSON 도구 ---"
command -v python3 || command -v jq || echo "(둘 다 없음 — 직접 편집할 것)"
```

기존 `CLAUDE.md`나 `settings.json`이 있으면 **반드시 내용을 먼저 읽는다.** 이 스킬은
기존 내용을 보존한 채 병합해야 하며, 통째로 덮어쓰면 안 된다.

### 1단계 — 두 가지 질문

`AskUserQuestion`으로 **두 질문을 한 번에** 묻는다. 옵션 라벨의 경로는 0단계에서 확인한
실제 `$HOME` 값으로 치환해서 보여준다(`~` 로 줄여 표기해도 좋다). 이미 존재하는 폴더는
설명에 "이미 있음"이라고 적어 준다.

**질문 1 — 기본 산출물 폴더를 어디로 할까요?** (`header: "기본 폴더"`)

- `~/Claude/default` (추천) — `~/Claude` 를 산출물(`default/`)·공용 도구(`tools/`)·프로젝트(`projects/`)로 나눠 쓰는 구조의 산출물 칸
- `~/Documents/Claude` — 문서와 함께 관리. iCloud Drive 동기화 설정이 켜져 있으면 다른 기기에서도 보인다
- `~/Desktop/Claude` — 결과물이 바로 눈에 보이지만 바탕화면이 지저분해질 수 있다

사용자가 "Other"로 직접 경로를 입력할 수 있다. 입력받은 경로는 `~` 를 `$HOME`으로 펼치고
절대 경로로 정규화한다.

**질문 2 — scratch 세션용 SessionStart 훅도 같이 넣을까요?** (`header: "훅 추가"`)

- `CLAUDE.md만 (추천)` — 전역 메모리 규칙만 설정. 단순하고 대부분의 경우 충분하다
- `훅도 같이 설정` — 폴더 미지정 세션에서 시작 시점에 규칙을 한 번 더 주입한다. 더 확실하지만 `settings.json`에 훅 설정이 추가된다

단, 0단계에서 확인한 OS가 Windows이고 사용 가능한 bash가 없다면, 질문 2에서 훅 옵션이
이 환경에서는 셸 스크립트 실행이 필요해 권장되지 않는다는 점을 설명에 적는다.

### 2단계 — 폴더 생성

```bash
mkdir -p "<선택한 폴더>" && ls -ld "<선택한 폴더>"
```

경로에 공백이나 한글이 들어갈 수 있으므로 **모든 경로를 반드시 따옴표로 감싼다.**

### 3단계 — `~/.claude/CLAUDE.md` 갱신 (멱등)

`~/.claude` 디렉터리가 없으면 먼저 만든다.

파일이 없으면 새로 만들고, **있으면 기존 내용을 절대 지우지 않는다.** 아래 마커 블록을
사용해 재실행해도 중복되지 않게 한다.

- 파일에 `<!-- BEGIN claude-default-output-folder -->` 가 이미 있으면 → 그 마커부터
  `<!-- END claude-default-output-folder -->` 까지를 새 내용으로 **교체**
- 없으면 → 파일 끝에 빈 줄 하나를 두고 **추가**

삽입할 블록 (`<선택한 폴더>` 는 실제 절대 경로로 치환):

```markdown
<!-- BEGIN claude-default-output-folder -->
## 산출물 저장 위치

작업 폴더가 지정되지 않은 세션(앱에서 "No folder"로 시작해 임시 scratch 워크스페이스에서
실행 중인 경우), 사용자에게 전달할 최종 산출물은 임시 워크스페이스가 아니라 아래 폴더에 저장한다.

**기본 산출물 폴더: `<선택한 폴더>`**

- 세션마다 `<선택한 폴더>/YYYY-MM-DD-작업명/` 형태의 하위 폴더를 만들고 그 안에 저장한다.
- 임시 파일·중간 결과물·스크립트는 계속 scratch 디렉터리에 두고, 최종 산출물만 이 폴더에 저장한다.
- 저장한 뒤에는 파일의 전체 경로를 사용자에게 알려준다.
- 사용자가 다른 저장 위치를 지정했거나 세션이 실제 프로젝트 폴더에서 열린 경우에는
  이 규칙을 적용하지 않고 해당 폴더를 따른다.
<!-- END claude-default-output-folder -->
```

### 4단계 — `~/.claude/settings.json` 병합

**먼저 백업한다.** 파일이 있을 때만:

```bash
cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.bak.$(date +%Y%m%d-%H%M%S)"
```

그다음 병합한다. 파일이 없거나 비어 있으면 `{}` 에서 시작한다.

1. `permissions.additionalDirectories` 배열에 선택한 폴더를 추가한다.
   **이미 있으면 추가하지 않는다.** `permissions` 나 배열이 없으면 만든다.
   기존 `permissions.allow` / `deny` / 그 밖의 모든 키는 그대로 둔다.
   단, 선택한 폴더가 `~/Claude/default` 이면 상위 폴더 `~/Claude` 를 대신 등록한다.
   같은 루트 아래 `tools/`, `projects/` 도 승인 창 없이 써야 하기 때문이다.

2. 질문 2에서 훅을 선택한 경우에만, 5단계의 훅 설정을 추가한다.

JSON 병합은 `python3` 가 있으면 그걸 쓰는 게 안전하다:

```bash
python3 - <<'PYEOF'
import json, os
p = os.path.expanduser('~/.claude/settings.json')
try:
    with open(p) as f:
        d = json.loads(f.read() or '{}')
except FileNotFoundError:
    d = {}
target = '<선택한 폴더의 절대 경로>'
dirs = d.setdefault('permissions', {}).setdefault('additionalDirectories', [])
if target not in dirs:
    dirs.append(target)
with open(p, 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write('\n')
print('ok')
PYEOF
```

`python3` 도 `jq` 도 없으면 **Read/Edit 도구로 직접 편집한다.** 이 경우 파일 전체를 읽고,
기존 키를 하나도 빠뜨리지 않은 채 병합한 결과를 쓴다. 새로 만드는 경우가 아니라면
Write로 통째로 덮어쓰지 말고 Edit을 쓴다.

### 5단계 — SessionStart 훅 (질문 2에서 선택한 경우에만)

훅 명령을 JSON 문자열 안에 인라인으로 넣으면 따옴표 이스케이프가 지저분해진다.
별도 스크립트 파일로 만들고 경로만 참조한다.

`~/.claude/hooks/default-output-folder.sh` 생성 (`<선택한 폴더>` 치환):

```sh
#!/bin/sh
# 폴더 미지정(scratch 워크스페이스) 세션에서만 기본 산출물 폴더 규칙을 주입한다.
case "$PWD" in
  *scratch-workspaces*)
    printf '%s' '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"이 세션은 작업 폴더가 지정되지 않았다. 사용자에게 전달할 최종 산출물은 임시 워크스페이스가 아니라 <선택한 폴더>/YYYY-MM-DD-작업명/ 아래에 저장하고, 저장 후 전체 경로를 알려줄 것."}}'
    ;;
esac
exit 0
```

`chmod +x` 를 잊지 말 것. 그다음 `settings.json` 의 `hooks.SessionStart` 에 추가한다.
**`hooks` 나 `SessionStart` 가 이미 있으면 기존 항목을 유지한 채 배열에 append 한다.**
같은 스크립트 경로가 이미 등록되어 있으면 중복 추가하지 않는다.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          { "type": "command", "command": "<$HOME의 절대 경로>/.claude/hooks/default-output-folder.sh" }
        ]
      }
    ]
  }
}
```

`matcher` 로 쓸 수 있는 값은 `startup`, `resume`, `clear`, `compact` 이다.
새 세션만 대상으로 하므로 `startup` 을 쓴다.

### 6단계 — 검증

추측하지 말고 실제로 확인한다.

```bash
echo "--- settings.json JSON 유효성 ---"
python3 -c "import json,os;json.load(open(os.path.expanduser('~/.claude/settings.json')));print('valid')" \
  2>/dev/null || cat "$HOME/.claude/settings.json"
echo "--- CLAUDE.md 블록 ---"
grep -c "claude-default-output-folder" "$HOME/.claude/CLAUDE.md"
echo "--- 대상 폴더 ---"
ls -ld "<선택한 폴더>"
```

훅을 설정했다면 스크립트가 실제로 동작하는지도 확인한다:

```bash
(cd /tmp && PWD=/tmp/scratch-workspaces-test sh "$HOME/.claude/hooks/default-output-folder.sh"); echo
```

JSON이 깨졌으면 백업에서 되돌리고 사용자에게 알린다.

### 7단계 — 보고

사용자에게 다음을 명확히 전달한다.

- 바꾼 파일과 각각 무슨 역할인지
- **다음 세션부터 적용**된다는 점 (`CLAUDE.md`는 세션 시작 시점에 로드됨)
- 설정 파일이 이 컴퓨터의 로컬 파일이라 **다른 컴퓨터에는 적용되지 않는다**는 점
- 백업 파일 위치
- 여전히 세션은 "No folder"로 열리며, 앱에 기본 폴더 자동 선택 옵션은 없다는 점.
  바뀌는 건 산출물이 사라지지 않는다는 것뿐이다.

## 환경별 주의사항

- **경로 인용** — 홈 경로나 폴더명에 공백·한글이 들어갈 수 있다. 모든 셸 명령에서 경로를
  따옴표로 감싼다.
- **기존 설정 보존** — `settings.json` 에 이미 권한·훅·MCP·환경변수 설정이 있을 수 있다.
  병합만 하고, 모르는 키는 절대 건드리지 않는다.
- **`python3` 부재** — macOS에서 Xcode Command Line Tools가 없으면 `python3` 가 없을 수 있다.
  설치를 유도하지 말고 Read/Edit 도구로 직접 편집한다.
- **Windows** — `$HOME` 대신 `%USERPROFILE%` 이지만 Git Bash/WSL에서는 `$HOME` 이 동작한다.
  설정 경로는 `%USERPROFILE%\.claude\` 다. 네이티브 셸만 있는 경우 `.sh` 훅은 실행되지
  않으므로 CLAUDE.md 방식만 설정한다.
- **재실행 안전성** — 이 스킬은 여러 번 실행해도 안전해야 한다. 마커 블록 교체, 배열
  중복 검사가 그 역할을 한다. 폴더를 바꾸려고 재실행하는 경우, 이전 경로가
  `additionalDirectories` 에 남아 있으면 사용자에게 제거할지 물어본다.
