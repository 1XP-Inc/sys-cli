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

# 자동 업데이트용 저장소 경로 기록 (sys ls 가 여기서 git pull 한다).
# 사용자 설정값이 아니라 설치 위치이므로, 기존 config 가 있어도 항상 최신 경로로 갱신.
if grep -q '^SYS_REPO_DIR=' "$CONFIG_FILE" 2>/dev/null; then
  sed -i.bak "s|^SYS_REPO_DIR=.*|SYS_REPO_DIR=\"$SCRIPT_DIR\"|" "$CONFIG_FILE" && rm -f "${CONFIG_FILE}.bak"
else
  printf '\n# 자동 업데이트: 클론한 저장소 경로 (sys ls 시 6시간마다 git pull). install.sh 가 관리.\nSYS_REPO_DIR="%s"\n' "$SCRIPT_DIR" >> "$CONFIG_FILE"
fi
echo "✓ 자동 업데이트 저장소 경로 기록됨: $SCRIPT_DIR"

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
    else
      echo "apt를 못 찾아서 ccze 설치를 건너뜁니다. 수동으로 설치하세요."
    fi
  fi
else
  echo "✓ ccze 이미 설치됨"
fi

echo ""
echo "설치 완료."
echo "⚠️  자동 업데이트가 이 클론 폴더에서 git pull 하므로, 폴더를 옮기거나 지우지 마세요."
echo "    (옮겼다면 그 위치에서 install.sh 를 다시 실행하면 경로가 갱신됩니다.)"
echo "    자동 업데이트를 끄려면 config 에 SYS_AUTO_UPDATE=false 를 설정하세요."
echo "테스트: sys --help"
