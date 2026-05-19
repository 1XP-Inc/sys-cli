#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/sys-cli"
TARGET="$BIN_DIR/sys"
CONFIG_FILE="$CONFIG_DIR/config"

# 디렉토리 생성
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"

# sys 스크립트 설치
cp "$SCRIPT_DIR/sys" "$TARGET"
chmod +x "$TARGET"
echo "✓ sys 명령어 설치됨: $TARGET"

# 설정 파일 (이미 있으면 건드리지 않음)
if [[ ! -f "$CONFIG_FILE" ]]; then
  cp "$SCRIPT_DIR/config.example" "$CONFIG_FILE"
  echo "✓ 기본 설정 파일 생성됨: $CONFIG_FILE"
else
  echo "기존 설정 파일 유지: $CONFIG_FILE"
fi

# PATH 확인
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo ""
  echo "⚠️  $BIN_DIR 이 PATH에 없어요."
  echo "    Ubuntu의 ~/.profile은 보통 자동으로 추가해줍니다."
  echo "    새 터미널을 열거나, 다음을 ~/.bashrc 또는 ~/.profile 에 추가하세요:"
  echo "        export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# ccze (선택) — 로그 색상화에 사용
if ! command -v ccze >/dev/null 2>&1; then
  echo ""
  echo "ccze가 설치되어 있지 않아요 (로그 색상화에 사용, 선택)."
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
echo "설치 완료. 이제 클론한 sys-cli 폴더는 옮기거나 지워도 됩니다."
echo "테스트: sys --help"
