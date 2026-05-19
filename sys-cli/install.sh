#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_LINE="source $SCRIPT_DIR/sys.sh"
RC_FILE="$HOME/.bashrc"

if [[ ! -f "$RC_FILE" ]]; then
  touch "$RC_FILE"
fi

if grep -Fxq "$SOURCE_LINE" "$RC_FILE" 2>/dev/null; then
  echo "이미 ~/.bashrc에 등록되어 있어요."
else
  {
    echo ""
    echo "# sys-cli"
    echo "$SOURCE_LINE"
  } >> "$RC_FILE"
  echo "✓ ~/.bashrc에 추가됨"
fi

# ccze (선택) — 로그 색상화에 사용
if ! command -v ccze >/dev/null 2>&1; then
  echo ""
  echo "ccze가 설치되어 있지 않아요 (로그 색상화에 사용)."
  read -r -p "지금 설치할까요? [y/N]: " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    if command -v apt >/dev/null 2>&1; then
      sudo apt update && sudo apt install -y ccze
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y ccze
    elif command -v brew >/dev/null 2>&1; then
      brew install ccze
    else
      echo "패키지 매니저를 못 찾아서 ccze 설치는 건너뜁니다."
    fi
  fi
else
  echo "✓ ccze 이미 설치됨"
fi

echo ""
echo "적용하려면: source ~/.bashrc"
echo "테스트: sys --help"
