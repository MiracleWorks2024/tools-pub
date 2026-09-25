# app-sessions

Claude 데스크톱 앱(Code 탭)에서 만든 세션을 **터미널 CLI 에서 이어가기** 위한 명령과 스킬입니다.

앱 사이드바의 세션 ID(`local_…`)와 CLI 가 쓰는 세션 ID 는 다릅니다. 이 명령은 앱의 세션 정보
파일에서 둘의 대응을 읽어, 제목으로 세션을 찾고 `claude --resume` 으로 이어가게 해 줍니다.
앱에서 **보관(archive)한 세션도 포함**됩니다.

macOS 전용입니다 (앱 세션 정보 위치: `~/Library/Application Support/Claude/claude-code-sessions/`).

## 설치

저장소 루트에서 `sh setup.sh` 를 실행하면 두 가지가 연결됩니다.

- 명령: `~/.local/bin/app-sessions` → 이 폴더의 `app-sessions`
- 스킬: `~/.claude/skills/app-sessions` → 이 폴더

## 명령 사용법

| 명령 | 동작 |
|---|---|
| `app-sessions` | 앱 세션 전체 (최근 활동 순): 날짜, 제목, 폴더, CLI 세션 ID |
| `app-sessions 검색어` | 제목·폴더에 검색어가 들어간 세션만 |
| `app-sessions -r 검색어` | 찾은 세션의 폴더로 이동해 `claude --resume` 실행. 여러 개면 번호 선택 |
| `app-sessions -a` | 보관된 세션만 |
| `app-sessions --json` | JSON 출력 (스킬이 사용) |

표시: `[보관]` 보관된 세션, `[기록 없음]` CLI 기록 파일이 지워져 이어갈 수 없는 세션.

## 스킬

Claude 에게 "앱 세션 찾아줘", "어제 하던 보고서 세션 터미널에서 이어가게 해줘" 처럼 말하면 스킬이 이 명령을
실행해 결과를 표로 정리하고 이어갈 명령을 알려 줍니다. 이어가기 자체는 대화형이라 사용자가 직접
실행합니다.

## 주의

- 앱에서 같은 세션이 열려 있으면 먼저 닫습니다. 두 곳에서 동시에 쓰면 기록이 엉킬 수 있습니다.
- 앱 세션을 CLI 에서 이어가면 그 기록은 CLI 쪽 보관기간(`cleanupPeriodDays`, 기본 30일)을
  따르게 됩니다. `setup.sh` 는 이 값이 없으면 36500(약 100년)으로 설정합니다.
- 앱 세션 정보 파일의 구조는 공식 문서에 없는 내부 형식입니다. 앱 업데이트로 바뀌면 이 명령을
  고쳐야 할 수 있습니다.
