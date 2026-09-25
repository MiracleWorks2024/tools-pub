#!/bin/sh
# tools-pub 를 이 컴퓨터의 Claude Code 에 연결한다. 여러 번 실행해도 안전하다.
#
#   sh setup.sh
#
# 하는 일
#   1. skills/* 를 ~/.claude/skills/ 에 심볼릭 링크로 연결한다.
#      링크라서 git pull 만 하면 스킬도 최신이 된다.
#   2. 터미널 명령(app-sessions 등)을 ~/.local/bin/ 에 심볼릭 링크로 연결한다.
#   3. 세션 시작 시 자동 pull 훅을 ~/.claude/hooks/ 에 복사하고
#      ~/.claude/settings.json 의 hooks.SessionStart 에 등록한다.
#      같은 파일에 대화 기록 보관기간(cleanupPeriodDays)이 없으면 36500일로 넣는다.
#   4. 도구 실행에 필요한 Python 패키지가 있는지 확인만 한다 (설치는 하지 않는다).
#
# macOS / Linux / WSL / Git Bash 에서 동작한다.

set -eu

REPO=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAUDE_DIR="$HOME/.claude"
TS=$(date +%Y%m%d-%H%M%S)
BAK_DIR="$CLAUDE_DIR/skills.bak"   # skills/ 안에 두면 백업이 스킬로 로드되므로 밖에 둔다

echo "저장소: $REPO"
echo

# ── 1. 스킬 연결 ─────────────────────────────────────────
mkdir -p "$CLAUDE_DIR/skills"

# 이름이 바뀌어 더 이상 쓰지 않는 스킬. 남아 있으면 중복으로 뜨므로 치운다.
for old in setup-default-folder; do
  if [ -e "$CLAUDE_DIR/skills/$old" ] || [ -L "$CLAUDE_DIR/skills/$old" ]; then
    mkdir -p "$BAK_DIR"
    mv "$CLAUDE_DIR/skills/$old" "$BAK_DIR/$TS-$old"
    echo "옛 스킬 정리: $old  ->  $BAK_DIR/$TS-$old"
  fi
done

for dir in "$REPO"/skills/*/; do
  dir=${dir%/}
  [ -f "$dir/SKILL.md" ] || continue
  name=$(basename "$dir")
  dest="$CLAUDE_DIR/skills/$name"
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    mkdir -p "$BAK_DIR"
    mv "$dest" "$BAK_DIR/$TS-$name"
    echo "기존 스킬 백업: $BAK_DIR/$TS-$name"
  fi
  ln -s "$dir" "$dest"
  echo "스킬 연결: $dest  ->  $dir"
done
echo

# ── 2. 명령 연결 ─────────────────────────────────────────
BIN_DIR="$HOME/.local/bin"
COMMANDS="skills/app-sessions/app-sessions"
mkdir -p "$BIN_DIR"
for rel in $COMMANDS; do
  src="$REPO/$rel"
  [ -f "$src" ] || continue
  chmod +x "$src"
  dest="$BIN_DIR/$(basename "$rel")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "건너뜀: $dest 에 같은 이름의 파일이 이미 있습니다 (링크가 아님)"
    continue
  fi
  ln -sf "$src" "$dest"
  echo "명령 연결: $dest  ->  $src"
done
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "주의: $BIN_DIR 가 PATH 에 없습니다. ~/.zshrc 에 다음을 추가하십시오:"
     echo "  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac
echo

# ── 3. 자동 pull 훅 · 보관기간 ────────────────────────────
mkdir -p "$CLAUDE_DIR/hooks"
HOOK="$CLAUDE_DIR/hooks/pull-tools-pub.sh"
cp "$REPO/hooks/pull-tools-pub.sh" "$HOOK"
chmod +x "$HOOK"
echo "훅 설치: $HOOK"

HOOK_CMD="\"$HOOK\" \"$REPO\""
SETTINGS="$CLAUDE_DIR/settings.json"

if command -v python3 >/dev/null 2>&1; then
  python3 - "$SETTINGS" "$HOOK_CMD" "$TS" <<'PYEOF'
import json, os, shutil, sys

path, cmd, ts = sys.argv[1:4]
try:
    with open(path, encoding='utf-8') as f:
        raw = f.read()
except FileNotFoundError:
    raw = ''
data = json.loads(raw or '{}')

entry = {'type': 'command', 'command': cmd, 'timeout': 10}
session_start = data.setdefault('hooks', {}).setdefault('SessionStart', [])

found = False
for group in session_start:
    for h in group.get('hooks', []):
        if 'pull-tools-pub.sh' in h.get('command', ''):
            h.update(entry)
            found = True
if not found:
    session_start.append({'matcher': 'startup', 'hooks': [entry]})

# 대화 기록 보관기간. 기본 30일이면 CLI 세션 기록이 지워진다. 이미 값이 있으면 존중한다.
added_retention = 'cleanupPeriodDays' not in data
if added_retention:
    data['cleanupPeriodDays'] = 36500

new = json.dumps(data, indent=2, ensure_ascii=False) + '\n'
if new == raw:
    print('settings.json: 이미 등록되어 있음 (변경 없음)')
else:
    if raw:
        shutil.copy2(path, f'{path}.bak.{ts}')
        print(f'settings.json 백업: {path}.bak.{ts}')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new)
    print('settings.json: SessionStart 훅 ' + ('갱신' if found else '등록'))
    if added_retention:
        print('settings.json: cleanupPeriodDays = 36500 (대화 기록 약 100년 보관)')
PYEOF
else
  echo "python3 가 없어 settings.json 은 자동으로 고치지 못했습니다."
  echo "아래 내용을 $SETTINGS 의 \"hooks\" 에 직접 넣으십시오 (기존 내용은 유지):"
  echo
  echo "  \"SessionStart\": [ { \"matcher\": \"startup\", \"hooks\": [ {"
  echo "    \"type\": \"command\", \"timeout\": 10,"
  echo "    \"command\": \"\\\"$HOOK\\\" \\\"$REPO\\\"\" } ] } ]"
fi
echo

# ── 4. Python 패키지 확인 ────────────────────────────────
missing=""
command -v python3 >/dev/null 2>&1 || missing="python3"
if [ -z "$missing" ]; then
  python3 -c "import markdown" 2>/dev/null || missing="$missing markdown"
  python3 -c "import docx" 2>/dev/null || missing="$missing python-docx"
fi
if [ -n "$missing" ]; then
  echo "없는 패키지:$missing"
  echo "  설치: python3 -m pip install -r \"$REPO/requirements.txt\""
  echo "  (Homebrew Python 이면 끝에 --break-system-packages 를 붙이거나 venv 를 쓰십시오)"
else
  echo "Python 패키지: 모두 있음"
fi
echo
echo "완료. 새 Claude Code 세션부터 적용됩니다."
