#!/bin/sh
# Claude Code 세션이 시작될 때 tools-pub 저장소를 원격 최신 상태로 받는다.
#
#   pull-tools-pub.sh [저장소 경로]     (기본값: ~/MAS/CA/tools/github-pub)
#
# - 백그라운드로 돌기 때문에 세션 시작을 늦추지 않는다.
# - fast-forward 로만 받는다. 올리지 않은 로컬 커밋이 있거나 충돌이 나면
#   아무것도 바꾸지 않고 멈춘다. 결과는 ~/.claude/hooks/pull-tools-pub.log 에 남는다.
# - 오프라인이거나 저장소가 없어도 조용히 끝난다.
#
# setup.sh 가 이 파일을 ~/.claude/hooks/ 로 복사해서 등록한다. 저장소 안의 파일을
# 직접 실행하지 않는 이유는, pull 로 받은 코드가 검토 없이 곧바로 자동 실행되는
# 구조를 피하기 위해서다.

REPO="${1:-$HOME/MAS/CA/tools/github-pub}"
LOG="$HOME/.claude/hooks/pull-tools-pub.log"

[ -d "$REPO/.git" ] || exit 0

(
  {
    echo "== $(date '+%Y-%m-%d %H:%M:%S') $REPO"
    GIT_TERMINAL_PROMPT=0 git -C "$REPO" \
      -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=15 \
      pull --ff-only 2>&1
    echo "exit=$?"
  } > "$LOG" 2>&1
) </dev/null >/dev/null 2>&1 &

exit 0
