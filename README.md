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
- `sys log` follow 중 unit 이름이 장시간 프로세스 argv에 남지 않도록 처리
- `sys log` follow 중 `q` + Enter 또는 Ctrl+C로 종료 (Ctrl 키 없는 핸드폰/웹터미널 대응)
- `sys ls` 실행 시 6시간마다 자동으로 최신 버전을 받아옴 (수동 업데이트 거의 불필요)

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

설치 후에도 **클론한 폴더는 남겨두세요.** `sys ls`가 그 폴더에서 자동 업데이트(`git pull`)를 수행합니다. 폴더를 옮겼다면 그 위치에서 `install.sh`를 다시 실행하면 경로가 갱신됩니다. (자동 업데이트를 끄면 폴더를 지워도 됩니다 — [자동 업데이트](#자동-업데이트) 참고.)

`~/.local/bin`이 `PATH`에 없다면 install.sh가 알려줍니다. 일반적으로 Ubuntu의 `~/.profile`이 자동으로 추가하므로 새 터미널을 열면 바로 됩니다.

## 명령어

```
sys <COMMAND> [NAME|ID]

COMMANDS:
    start              서비스 시작
    stop               서비스 정지
    log, logs          실시간 로그 따라가기 (journalctl -f, q+Enter 또는 Ctrl+C로 종료)
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

`--head`를 제외한 대부분의 옵션은 journalctl에 그대로 전달되니, 필요하면 `--since`, `-p` 같은 journalctl 옵션도 자유롭게 사용 가능합니다. 기본 follow 모드는 PM2처럼 메타데이터 없이 깔끔하게 실시간 출력됩니다 (`--head` 사용 시는 실시간 모드 꺼짐). 단, follow 모드는 내부적으로 JSON 출력을 사용하므로 `-o`, `--output`, `--output-fields`, `-u`, `--unit`, `--user-unit`, `-f`, `--follow`는 지원하지 않습니다.

기본 follow 모드는 최근 로그를 짧게 출력한 뒤, 장시간 떠 있는 follower에서는 unit 이름을 프로세스 argv에 남기지 않습니다. 일부 서비스가 프로세스 command line을 넓게 검색하는 경우 `journalctl -u <unit>` 자체를 같은 서비스 프로세스로 오인할 수 있기 때문입니다.

같은 이유로 follow 모드에서는 추가 journalctl 옵션 인자 안에 대상 unit 이름이 직접 들어가는 경우도 거부합니다.

#### 로그에서 빠져나오기

실시간 follow 중에는 **`q` + Enter** 또는 **Ctrl+C**로 종료할 수 있습니다. Ctrl 키가 없는 핸드폰/웹 기반 터미널에서도 `q`만 입력하면 빠져나옵니다. (`--head` 스냅샷 모드는 N줄 출력 후 자동 종료되므로 별도 종료가 필요 없습니다.)

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

# 자동 업데이트 (아래 "자동 업데이트" 참고)
SYS_AUTO_UPDATE=true        # false 로 두면 자동 업데이트 끔
SYS_UPDATE_INTERVAL=21600   # 체크 주기(초). 기본 21600 = 6시간
# SYS_REPO_DIR 은 install.sh 가 자동으로 기록하므로 직접 건드릴 필요 없음
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
- python3 — `sys log` follow 모드의 안전한 journal JSON 필터링에 사용
- (선택) `ccze` — 로그 색상화. install.sh가 자동 설치 여부를 물어봄.

## 자동 업데이트

`sys ls`를 실행할 때 **6시간마다 한 번** 클론한 저장소에서 `git pull` 해서 `sys`를 최신으로 갱신합니다 (동기 + 쓰로틀 방식). 새 버전이 있으면 그 실행에 바로 반영되고, 주기 안의 나머지 실행은 `git`을 건드리지 않아 빠릅니다.

- 동작 조건: 클론한 저장소 폴더가 그대로 남아 있어야 하고, 설치본(`~/.local/bin/sys`)에 자동 업데이트 기능이 들어 있어야 합니다. **이 기능이 추가되기 전 버전에서 올라오는 경우, 한 번은 수동으로 `git pull && ./install.sh`를 실행해 자동 업데이터를 설치해야 합니다.** 그 이후로는 자동입니다.
- 끄기 / 주기 변경: 설정 파일에서 `SYS_AUTO_UPDATE=false` 또는 `SYS_UPDATE_INTERVAL=<초>`.
- 범위: 자동 업데이트는 `sys` 스크립트만 교체합니다. `install.sh`나 설정 항목(config) 자체가 바뀌는 변경은 자동 반영되지 않으니, 그때는 아래 수동 업데이트가 필요합니다.

확인: 설치본에 자동 업데이터가 들어 있는지 보려면

```bash
grep -c sys_auto_update ~/.local/bin/sys && grep SYS_REPO_DIR ~/.config/sys-cli/config
```

둘 다 출력되면 자동 업데이트가 켜져 있는 상태입니다.

## 수동 업데이트

자동 업데이트를 껐거나, `install.sh`/설정 구조가 바뀌는 변경을 받을 때:

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
