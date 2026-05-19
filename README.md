# sys-cli

PM2 스타일로 systemd 서비스를 관리하는 bash 함수.

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
source ~/.bashrc
```

설치 중에 `ccze` 미설치 시 자동 설치 여부를 물어봅니다 (로그 색상화에 사용, 선택).

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
sys log consensus           # consensus 로그 실시간 tail
sys log 1                   # 1번 서비스 로그
sys daemon                  # .service 파일 수정 후 reload
```

서비스 이름은 **정확히 일치**해야 하며, `.service` 확장자는 생략 가능합니다 (`sys status consensus`와 `sys status consensus.service` 둘 다 동작).

## 목록에 표시되는 서비스

`sys ls`는 두 종류의 서비스를 보여줍니다:

### 1. USER SERVICES — 자동 스캔
`~/.config/systemd/user/` 디렉토리에 있는 `.service` 파일을 **자동으로** 감지해서 보여줍니다. 본인이 user service를 추가/삭제하면 별도 설정 없이 즉시 반영됩니다.

→ user service만 운영한다면 별도 설정 필요 없음.

### 2. SYSTEM SERVICES — `SYS_WATCH`로 지정
system service는 한 머신에 수십~수백 개가 있어서 다 보여줄 수 없으니, **보고 싶은 것만 명시적으로 지정**해야 합니다.

`sys.sh` 안의 `SYS_WATCH` 배열을 수정하거나, `~/.bashrc`에서 override:

```bash
# install.sh 이후, sys.sh를 source한 다음
SYS_WATCH=(prometheus grafana-server node_exporter)
```

비워두면 (`SYS_WATCH=()`) SYSTEM SERVICES 섹션은 표시되지 않습니다 (기본값).

### 정리

| 운영 방식 | SYS_WATCH 설정 | 결과 |
|---|---|---|
| user service만 | `SYS_WATCH=()` | USER SERVICES만 자동 표시 |
| user + 모니터링 system service | `SYS_WATCH=(prometheus ...)` | 둘 다 표시 |
| 전부 system service | user 디렉토리 비어있음 + `SYS_WATCH=(...)` | SYSTEM SERVICES만 표시 |

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

## 제거

```bash
cd ~/sys-cli
./uninstall.sh
```

## 라이선스

MIT
