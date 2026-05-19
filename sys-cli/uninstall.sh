#!/usr/bin/env bash
set -e

RC_FILE="$HOME/.bashrc"

if [[ ! -f "$RC_FILE" ]]; then
  echo "~/.bashrc가 없어요."
  exit 0
fi

# # sys-cli 주석 줄과 그 다음 source 줄을 제거
if grep -q "^# sys-cli$" "$RC_FILE"; then
  sed -i.bak '/^# sys-cli$/,+1d' "$RC_FILE"
  echo "✓ ~/.bashrc에서 제거됨 (백업: ~/.bashrc.bak)"
else
  echo "~/.bashrc에 sys-cli 등록이 없어요."
fi

# 매핑 파일도 정리
if [[ -f "$HOME/.cache/sys-services" ]]; then
  rm -f "$HOME/.cache/sys-services"
  echo "✓ 매핑 파일 제거됨"
fi

echo ""
echo "적용하려면 새 터미널을 열거나: source ~/.bashrc"
