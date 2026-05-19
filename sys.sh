# sys - systemd 서비스 관리 도우미 (user/system 자동 감지)
#
# 사용법: sys --help

# sys ls 했을 때 같이 표시할 system service들 (빈 배열이면 표시 안 함)
SYS_WATCH=()

# 번호 ↔ 서비스명 매핑을 저장할 파일
SYS_STATE="${HOME}/.cache/sys-services"

sys_help() {
  echo "sys - systemd 서비스 관리 도우미 (user/system 자동 감지)"
  echo ""
  echo "USAGE:"
  echo "    sys <COMMAND> [NAME|ID]"
  echo ""
  echo "COMMANDS:"
  echo "    start              서비스 시작"
  echo "    stop               서비스 정지"
  echo "    log, logs          실시간 로그 따라가기 (journalctl -f)"
  echo "    l, ls, list        서비스 목록 (번호 매겨서 표시)"
  echo "    status, st         서비스 상태 + 최근 로그"
  echo "    restart, r         서비스 재시작"
  echo "    enable             부팅 시 자동 시작 등록"
  echo "    disable            부팅 시 자동 시작 해제"
  echo "    daemon             .service 파일 수정 후 systemd 재로딩"
  echo "    help, -h, --help   이 도움말 출력"
  echo ""
  echo "NAME 자리에 ID 숫자도 사용 가능 (sys ls의 번호)"
  echo "    예: sys status 1   → sys ls의 1번 서비스 상태"
  echo ""
  echo "EXAMPLES:"
  echo "    sys ls                       # 전체 서비스 목록"
  echo "    sys status <UNIT Name>      # 단일 서비스 상태"
  echo "    sys status 1                 # 1번 서비스 상태"
  echo "    sys restart <UNIT Name>        # 단일 서비스 재시작"
  echo "    sys log <UNIT Name>         # 단일 서비스 로그 tail"
  echo "    sys daemon                   # .service 수정 후 reload"
}

sys() {
  local cmd="$1"
  local target="$2"
  local match="" scope_flag="" use_sudo=""

  if [[ "$cmd" == "-h" || "$cmd" == "--help" || "$cmd" == "help" || -z "$cmd" ]]; then
    sys_help
    return 0
  fi

  # ls는 target 처리 없이 바로
  if [[ "$cmd" == "l" || "$cmd" == "ls" || "$cmd" == "list" ]]; then
    mkdir -p "$(dirname "$SYS_STATE")"
    > "$SYS_STATE"
    local idx=1

    # User services (본인이 ~/.config/systemd/user/ 에 만든 것만)
    local user_services=()
    if [[ -d "$HOME/.config/systemd/user" ]]; then
      for f in "$HOME/.config/systemd/user"/*.service; do
        [[ -e "$f" ]] && user_services+=("$(basename "$f" .service)")
      done
    fi

    if [[ ${#user_services[@]} -gt 0 ]]; then
      echo "=== USER SERVICES ==="
      for s in "${user_services[@]}"; do
        echo "$s" >> "$SYS_STATE"
        local line
        line=$(systemctl --user list-units --all --no-legend "${s}.service" 2>/dev/null | head -1)
        if [[ -n "$line" ]]; then
          printf "  %2d) %s\n" "$idx" "$line"
        else
          printf "  %2d) %s.service (not loaded)\n" "$idx" "$s"
        fi
        ((idx++))
      done
      echo
    fi

    # System services from SYS_WATCH
    if [[ ${#SYS_WATCH[@]} -gt 0 ]]; then
      echo "=== SYSTEM SERVICES (watched) ==="
      for s in "${SYS_WATCH[@]}"; do
        echo "$s" >> "$SYS_STATE"
        local line
        line=$(sudo systemctl list-units --all --no-legend "${s}.service" 2>/dev/null | head -1)
        if [[ -n "$line" ]]; then
          printf "  %2d) %s\n" "$idx" "$line"
        else
          printf "  %2d) %s.service (not loaded)\n" "$idx" "$s"
        fi
        ((idx++))
      done
    fi
    return 0
  fi

  # daemon은 target 불필요
  if [[ "$cmd" == "daemon" ]]; then
    # daemon-reload는 양쪽 다 reload하는 게 안전
    systemctl --user daemon-reload 2>/dev/null
    sudo systemctl daemon-reload
    return 0
  fi

  # 숫자면 매핑 파일에서 이름 찾기
  if [[ "$target" =~ ^[0-9]+$ ]]; then
    if [[ -f "$SYS_STATE" ]]; then
      local resolved
      resolved=$(sed -n "${target}p" "$SYS_STATE")
      if [[ -n "$resolved" ]]; then
        target="$resolved"
      else
        echo "sys: ID $target에 해당하는 서비스가 없어요. 'sys ls'로 번호 다시 확인하세요."
        return 1
      fi
    else
      echo "sys: 매핑 파일이 없어요. 'sys ls'를 먼저 실행하세요."
      return 1
    fi
  fi

  target="${target%.service}"

  if [[ -z "$target" ]]; then
    echo "sys: 서비스 이름 또는 ID가 필요해요."
    echo "도움말 보려면: sys --help"
    return 1
  fi

  # 정확한 이름 매칭만 (user 우선, 없으면 system)
  if systemctl --user cat -- "${target}.service" >/dev/null 2>&1; then
    match="$target"
    scope_flag="--user"
  elif systemctl cat -- "${target}.service" >/dev/null 2>&1; then
    match="$target"
    use_sudo="sudo"
  else
    echo "sys: '$target' 서비스를 찾을 수 없어요."
    return 1
  fi

  case "$cmd" in
    status|st)  $use_sudo systemctl $scope_flag status "$match" ;;
    start)      $use_sudo systemctl $scope_flag start "$match" ;;
    stop)       $use_sudo systemctl $scope_flag stop "$match" ;;
    restart|r)  $use_sudo systemctl $scope_flag restart "$match" ;;
    log|logs)
      if command -v ccze >/dev/null 2>&1; then
        $use_sudo journalctl $scope_flag -f -u "$match" | ccze -A
      else
        $use_sudo journalctl $scope_flag -f -u "$match"
      fi
      ;;
    enable)     $use_sudo systemctl $scope_flag enable "$match" ;;
    disable)    $use_sudo systemctl $scope_flag disable "$match" ;;
    *)
      echo "sys: 알 수 없는 명령어 '$cmd'"
      echo "도움말 보려면: sys --help"
      return 1
      ;;
  esac
}
