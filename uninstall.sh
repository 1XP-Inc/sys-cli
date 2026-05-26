#!/usr/bin/env bash
set -e

TARGET="$HOME/.local/bin/sys"
CONFIG_DIR="$HOME/.config/sys-cli"
CACHE_DIR="$HOME/.cache/sys-cli"
LEGACY_CACHE="$HOME/.cache/sys-services"

# 명령어 제거
if [[ -f "$TARGET" ]]; then
  rm "$TARGET"
  echo "✓ $TARGET 제거됨"
else
  echo "$TARGET 가 없어요. 이미 제거되었을 수 있어요."
fi

# 매핑 캐시 제거 (셸별 매핑 파일 디렉토리)
if [[ -d "$CACHE_DIR" ]]; then
  rm -rf "$CACHE_DIR"
  echo "✓ 매핑 캐시 제거됨: $CACHE_DIR"
fi
# 구버전(단일 파일) 매핑 캐시도 있으면 제거
if [[ -f "$LEGACY_CACHE" ]]; then
  rm -f "$LEGACY_CACHE"
  echo "✓ 구버전 매핑 파일 제거됨: $LEGACY_CACHE"
fi

# 설정은 보존 (사용자 의도가 있을 수 있으니)
if [[ -d "$CONFIG_DIR" ]]; then
  echo ""
  echo "설정 디렉토리는 보존됩니다: $CONFIG_DIR"
  echo "완전히 지우려면 직접 삭제하세요:"
  echo "    rm -rf $CONFIG_DIR"
fi

echo ""
echo "제거 완료."
