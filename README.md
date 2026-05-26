# sys-cli

systemd 서비스를 간편하게 관리하는 CLI 도구.

user service와 system service를 자동으로 감지하고, 번호 ID로 짧게 다루기를 지원합니다.

## 기능

- `sys ls` 한 번에 본인이 만든 user service + 지정한 system service를 한눈에
- 각 서비스 앞에 번호 ID가 붙어서 PM2처럼 짧게 다룰 수 있음
- 정확한 이름 매칭 — 의도치 않은 다른 서비스에 영향 없음
- user/system 자동 감지 (sudo 알아서 붙임)
- `.service` 확장자 생략 가능
- ccze 설치되어 있으면 로그에 색상 자동 적용

## 설치

```bash
git clone https://github.com/1XP-Inc/sys-cli.git ~/sys-cli
cd ~/sys-cli
./install.sh
```

설치되는 것:
- 실행 파일: `~/.local/bin/sys`
- 기본 설정: `~/.config/sys-cli/config`
- (선택) ccze 미설치 시 자동 설치 여부를 물어봅니다

설치 후엔 클론한 폴더를 옮기거나 지워도 명령어는 계속 동작합니다.

`~/.local/bin`이 `PATH`에 없다면 install.sh가 알려줍니다. 일반적으로 Ubuntu의 `~/.profile`이 자동으로 추가하므로 새 터미널을 열면 바로 됩니다.

## 명령어

```
sys <COMMAND> [NAME|ID]

COMMANDS:
    start              서비스 시작
    stop               서비스 정지
    log, logs          실시간 로그 따라가기 (journalctl -f)
    l, ls, list        서비스 목록 (번호 매겨서 표시)
    status, st         서비스 상태 + 최근 로그
    restart, r         서비스 재시작
    enable             부팅 시 자동 시작 등록
    disable            부팅 시 자동 시작 해제
    delete, del, rm    sys ls 목록에서 제거 (USER는 파일까지, SYS_WATCH는 항목만)
    cat                .service 파일 내용 출력 (읽기 전용)
    edit               .service 파일 편집 (편집 전 .bak 자동 백업)
    daemon             .service 파일 수정 후 systemd 재로딩
    help, -h, --help   도움말 출력
```

터미널에서 직접 확인하려면 `sys --help` 또는 `sys -h` (인자 없이 `sys`만 쳐도 됨).

## 사용 예시

`consensus`, `execution` 이라는 이름으로 user service를 만들었다고 가정:

```bash
sys ls                      # 전체 목록 (번호 매겨서)
sys status consensus        # consensus 서비스 상태
sys status execution        # execution 서비스 상태
sys status 1                # 1번 서비스 (sys ls의 번호 사용)
sys restart execution       # execution 재시작
sys restart 2               # 2번 서비스 재시작
sys log consensus           # consensus 실시간 로그 tail
sys log 1                   # 1번 서비스 로그
sys cat consensus           # .service 파일 내용 보기 (읽기 전용)
sys edit consensus          # .service 파일 편집 (편집 전 .bak 자동 백업)
sys delete consensus        # sys ls 목록에서 제거
sys daemon                  # .service 파일 수정 후 reload
```

서비스 이름은 **정확히 일치**해야 하며, `.service` 확장자는 생략 가능합니다 (`sys status consensus`와 `sys status consensus.service` 둘 다 동작).

### 로그 옵션 (`sys log`)

`sys log <name>` 뒤에 journalctl 옵션을 자유롭게 추가할 수 있습니다.

```bash
sys log consensus -n 100              # 최근 100줄부터 tail (실시간)
sys log consensus --head 100          # 시작부터 100줄 (스냅샷, 실시간 안 함)
sys log consensus -n 100 -g ERROR     # 100줄 + ERROR 패턴 필터
sys log consensus | grep "block"      # shell pipe도 가능
```

자주 쓰는 옵션:

| 옵션 | 설명 |
|---|---|
| `-n N`, `--lines N` | 마지막 N줄부터 시작 (실시간 tail 유지) |
| `--head N` | 시작부터 N줄만 보기 (스냅샷, 실시간 안 함) |
| `-g PATTERN`, `--grep PATTERN` | 정규식 패턴 필터 (case-insensitive) |

`--head`를 제외한 옵션은 모두 journalctl에 그대로 전달되니, 필요하면 `--since`, `-p` 같은 journalctl 옵션도 자유롭게 사용 가능합니다. 기본적으로 `-f -o cat`이 적용되어 PM2처럼 메타데이터 없이 깔끔하게 실시간 출력됩니다 (`--head` 사용 시는 실시간 모드 꺼짐).

## 설정 (`~/.config/sys-cli/config`)

설치 시 자동 생성되는 설정 파일에서 동작을 커스터마이즈할 수 있습니다.

### 편집 방법

```bash
nano ~/.config/sys-cli/config
# 또는 vim, code 등 본인이 편한 에디터 사용
```

예시 내용:

```bash
# ~/.config/sys-cli/config

# sys ls 에서 함께 표시할 system service들 (user service는 자동 표시)
SYS_WATCH=(prometheus grafana-server node_exporter)
```

저장 후 별도의 source/reload 없이 다음 `sys` 명령 실행 시 바로 반영됩니다.

설정 파일은 업데이트(install.sh 재실행) 시 **덮어쓰이지 않습니다**. 따라서 안심하고 본인 환경에 맞게 수정해도 됩니다.

## 목록에 표시되는 서비스

`sys ls`는 두 종류의 서비스를 보여줍니다:

### 1. USER SERVICES — 자동 스캔
`~/.config/systemd/user/` 디렉토리에 있는 `.service` 파일을 **자동으로** 감지해서 보여줍니다. 본인이 user service를 추가/삭제하면 별도 설정 없이 즉시 반영됩니다.

→ user service만 운영한다면 별도 설정 필요 없음.

### 2. SYSTEM SERVICES — `SYS_WATCH`로 지정
system service는 한 머신에 수십~수백 개가 있어서 다 보여줄 수 없으니, **보고 싶은 것만 명시적으로 지정**해야 합니다. 위의 설정 파일에서 `SYS_WATCH` 배열을 채우면 됩니다.

비워두면 (`SYS_WATCH=()`, 기본값) SYSTEM SERVICES 섹션은 표시되지 않습니다.

### 정리

| 운영 방식 | SYS_WATCH 설정 | 결과 |
|---|---|---|
| user service만 | `SYS_WATCH=()` | USER SERVICES만 자동 표시 |
| user + 모니터링 system service | `SYS_WATCH=(prometheus ...)` | 둘 다 표시 |
| 전부 system service | user 디렉토리 비어있음 + `SYS_WATCH=(...)` | SYSTEM SERVICES만 표시 |

### 출력 컬럼

`sys ls` 결과는 각 서비스마다 한 줄로 다음 컬럼들이 표시됩니다:

| 컬럼 | 의미 | 자주 보이는 값 |
|---|---|---|
| `UNIT` | 서비스 파일 이름 | `myapp.service` |
| `LOAD` | systemd가 unit 파일을 잘 읽었는지 | `loaded` / `not-found` / `masked` / `error` |
| `ACTIVE` | 큰 분류 상태 | `active` / `inactive` / `failed` / `activating` |
| `SUB` | 세부 상태 (타입마다 다름) | `running` / `exited` / `dead` / `failed` |
| `BOOT` | 재부팅 시 자동 시작 여부 | ✓ `enabled` / ✗ `disabled` / `-` 그 외 |
| `DESCRIPTION` | unit 파일의 `Description=` 값 | 사람이 알아보라고 적어둔 설명 |

같은 표가 `sys ls` 출력 하단에도 짧게 함께 나오므로, 명령어를 따로 외울 필요는 없습니다.

## user service 만드는 법

`~/.config/systemd/user/<name>.service` 위치에 service 파일 생성 후:

```bash
systemctl --user daemon-reload
systemctl --user enable --now <name>
```

로그아웃해도 계속 돌게 하려면 (한 번만):

```bash
sudo loginctl enable-linger $USER
```

## 의존성

- bash 4+
- systemd
- (선택) `ccze` — 로그 색상화. install.sh가 자동 설치 여부를 물어봄.

## 업데이트

```bash
cd ~/sys-cli
git pull
./install.sh    # 새 sys 스크립트로 덮어씀. 설정 파일은 보존됨.
```

## 제거

```bash
cd ~/sys-cli
./uninstall.sh
```

설정 디렉토리(`~/.config/sys-cli/`)는 보존됩니다. 완전히 지우고 싶으면 메시지에 안내된 대로 직접 삭제하세요.

## 라이선스

MIT
