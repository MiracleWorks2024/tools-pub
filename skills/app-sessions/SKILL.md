---
name: app-sessions
description: Claude 데스크탑 앱(Code 탭) 세션과 터미널 CLI 세션을 서로 옮겨 이어가게 한다. 앱 세션을 제목·폴더로 찾아 CLI 세션 ID와 `claude --resume` 명령을 알려주고(보관된 세션 포함), 반대로 아직 앱에 없는 CLI 세션을 찾아 데스크탑 앱에서 연다. "앱 세션 찾아줘", "앱에서 하던 세션 터미널에서 이어가기", "CLI 세션 앱에서 열어줘", "터미널에서 하던 작업 앱으로 가져와", "CLI 세션 ID", "보관된 세션 이어가기" 같은 요청에 사용한다.
---

# 앱 ↔ CLI 세션 옮겨 이어가기

이 스킬은 같은 폴더의 `app-sessions` 명령(Python)을 감싼다. 명령은 `~/.local/bin/app-sessions`
에 링크되어 있고, PATH에서 찾지 못하면 이 SKILL.md 옆의 `app-sessions` 파일을 직접 실행한다.
macOS 전용이다.

## 배경

- 앱 세션의 ID(`local_…`)와 CLI가 쓰는 세션 ID는 다르다. 앱 세션 정보 파일
  (`~/Library/Application Support/Claude/claude-code-sessions/*/*/local_*.json`)의
  `cliSessionId` 가 CLI 대화 기록 `~/.claude/projects/<폴더>/<id>.jsonl` 과 연결된다.
- CLI 에서 시작한 세션은 앱 사이드바에 자동으로 뜨지 않는다. CLI 의 `/desktop` 명령은 기록을
  저장한 뒤 `claude://resume?session=<CLI 세션 ID>` 링크를 여는 것이 전부다 (Claude Code v2.1.282
  코드로 확인). 그래서 CLI 가 꺼져 있으면 이 링크만 열어도 앱으로 불러와진다. 공식 문서에 없는
  내부 링크라 업데이트로 바뀔 수 있다.
- 실행 중인 세션은 `~/.claude/sessions/<pid>.json` 에 등록된다. 명령은 이것으로 `running` 을 판단한다.
- 앱에서 보관(archive)해도 대화 기록 파일은 남는다. 그래서 CLI에서 이어갈 수 있다.
- 기록 파일 자동 삭제 (Claude Code v2.1.282 의 설정 설명 기준):
  - CLI 세션, 그리고 앱 세션이라도 **CLI에서 마지막으로 이어간 것**은 `cleanupPeriodDays`
    (기본 30일) 동안 활동이 없으면 지워진다.
  - 앱 세션은 이 삭제에서 빠진다 (`desktopSessionCleanupPeriodDays` 기본 0 = 상한 없음).
    다만 앱에서 **보관**하면 유예 기간이 지난 뒤 일반 삭제 대상으로 돌아간다.
  - `setup.sh` 는 `cleanupPeriodDays` 가 없으면 36500(약 100년)으로 넣는다.
  - 지워진 세션은 이어갈 수 없다.

## A. 앱 세션 → CLI 에서 이어가기

1. **찾기.** 사용자 요청에서 검색어(제목 일부, 폴더 이름)를 뽑아 JSON으로 조회한다.

   ```bash
   app-sessions --json 검색어      # 검색어 없으면 전체, 보관된 것만은 -a 추가
   ```

   각 항목: `app_id`(앱 ID), `title`, `cwd`(작업 폴더), `cli_id`, `archived`, `running`,
   `account`(앱 세션 폴더의 계정 ID), `other_account`(CLI 로그인 계정과 다름),
   `last`(앱 기준 마지막 활동), `has_log`(CLI 기록 파일 존재 여부).
   결과가 없으면 검색어를 줄이거나 전체 목록에서 비슷한 제목을 찾아 제안한다.

2. **현재 세션은 뺀다.** 지금 대화도 목록에 나온다. 데스크탑 앱이면 세션 정보 도구
   (`get_session` 에 `"self"`)로 이 세션의 앱 ID를 확인해 같은 `app_id` 는 결과에서 제외한다.

3. **보여주기.** 제목, 폴더, 마지막 활동, CLI 세션 ID를 짧은 표로 보여준다. 데스크탑 앱에서
   답할 때는 제목을 `[제목](#app_id)` 링크로 걸어 바로 열 수 있게 한다.
   - `archived: true` → "[보관]" 표시. CLI에서는 그대로 이어갈 수 있다.
   - `has_log: false` → CLI 기록이 없어 이어갈 수 없다고 알린다.
   - `other_account: true` → "[다른 계정]" 표시. 지금 앱 사이드바에는 안 보일 수 있지만 CLI 로는
     이어갈 수 있다. 여러 계정 세션이 섞여 있으면 표에 계정 열을 넣는다.
   - `running: true` → 앱에서 그 세션의 프로세스가 살아 있다. CLI 로 이어가기 전에 앱에서
     닫으라고 알린다.

4. **이어가기 안내.** Claude가 대신 이어갈 수는 없다(대화형 프로그램이라 사용자가 직접 실행).
   사용자에게 실행할 명령을 `bash` 코드 블록 하나로 준다.

   ```bash
   cd "<cwd>" && claude --resume <cli_id>
   ```

   또는 검색과 이어가기를 한 번에: `app-sessions -r 검색어` (여러 개면 번호 선택).
   함께 알릴 것: **앱에서 같은 세션이 열려 있으면 먼저 닫을 것** — 두 곳에서 동시에 쓰면
   기록이 엉킬 수 있다.

5. **앱에서 다시 보이게 하려는 경우.** 보관된 세션을 앱 사이드바로 되돌리는 것은 CLI가 아니라
   앱의 보관 해제다. 세션 관리 도구(`unarchive_session`)가 있으면 사용자에게 확인받고 쓴다.

## B. CLI 세션 → 데스크탑 앱에서 열기

1. **찾기.** 아직 앱에 없는 CLI 세션만 나온다.

   ```bash
   app-sessions --cli --json 검색어    # 검색어: 제목, 첫 메시지, 폴더, ID 일부
   ```

   각 항목: `cli_id`, `title`(AI 제목·직접 붙인 제목, 없으면 첫 메시지), `first_prompt`, `cwd`,
   `running`, `last`(기록상 마지막 대화 시각).
   결과가 없으면 이미 앱에 있는 세션일 수 있으니 A 의 조회로 찾아본다.

2. **보여주고 확인받기.** 후보를 짧은 표로 보여주고 어느 세션을 열지 확인한다.
   사용자가 이미 특정 세션을 지목했고 후보가 하나뿐이면 바로 3으로 간다.

3. **열기.** 사용자가 요청한 세션을 ID 로 정확히 지정해 연다 (여러 개가 걸리면 번호 입력을
   기다리므로 Claude 는 항상 전체 ID 를 쓴다).

   ```bash
   app-sessions -o <cli_id>
   ```

   - `running: true` 면 명령이 거절한다. 그 터미널에서 `/exit` 로 끝내거나, 그 터미널에서
     `/desktop` 을 입력하라고 안내한다.
   - 연 뒤에는 세션 관리 도구(`list_sessions`)로 `local_<cli_id>` 세션이 생겼는지 확인하고
     `[제목](#local_<cli_id>)` 링크로 알려준다. 새로 불러온 세션은 첫 대화 전까지 제목이 없을 수 있다.

## 하지 말 것

- 앱 세션 정보 파일(`local_*.json`)이나 CLI 기록 파일(`.jsonl`)을 직접 고치거나 지우지 않는다.
- 사용자가 요청하지 않았는데 `claude --resume` 이나 `app-sessions -o` 를 대신 실행하지 않는다.
- 터미널에서 실행 중인 세션을 앱에서 열지 않는다 (동시 사용).
