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

# python3 (필수) — sys log follow 모드에서 journal JSON 필터링에 사용
if ! command -v python3 >/dev/null 2>&1; then
  echo ""
  echo "⚠️  python3가 설치되어 있지 않아요."
  echo "    sys log follow 모드가 동작하려면 python3가 필요합니다."
  echo "    Ubuntu에서는 보통 다음으로 설치할 수 있습니다:"
  echo "        sudo apt install -y python3"
fi

# ccze (선택) — 로그 색상화에 사용
if ! command -v ccze >/dev/null 2>&1; then
  echo ""
  echo "ccze가 설치되어 있지 않아요 (로그 색상화에 사용, 선택)."
  read -r -p "지금 설치할까요? [y/N]: " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    if command -v apt >/dev/null 2>&1; then
      sudo apt update && sudo apt install -y ccze
    else
      echo "apt를 못 찾아서 ccze 설치를 건너뜁니다. 수동으로 설치하세요."
    fi
  fi
else
  echo "✓ ccze 이미 설치됨"
fi

echo ""
echo "설치 완료. 이제 클론한 sys-cli 폴더는 옮기거나 지워도 됩니다."
echo "테스트: sys --help"
