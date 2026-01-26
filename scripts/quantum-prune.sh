#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage:
  quantum-prune --home /home/<user> [--files <relpath> ...] [--dirs <relpath> ...]

EOF
  exit 2
}

HOME_DIR=""
FILES=()
DIRS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --home)
      [ $# -ge 2 ] || usage
      HOME_DIR="$2"
      shift 2
      ;;
    --files|--file)
      [ $# -ge 2 ] || usage
      FILES+=("$2")
      shift 2
      ;;
    --dirs|--dir)
      [ $# -ge 2 ] || usage
      DIRS+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "unknown arg: $1" >&2
      usage
      ;;
  esac
done

[ -n "$HOME_DIR" ] || { echo "--home is required" >&2; usage; }

findmnt_bin="${FINDMNT_BIN:-findmnt}"
umount_bin="${UMOUNT_BIN:-umount}"
rm_bin="${RM_BIN:-rm}"

umount_if_mounted() {
  local target="$1"
  if "$findmnt_bin" -rn --target "$target" >/dev/null 2>&1; then
    "$umount_bin" "$target" >/dev/null 2>&1 || true
  fi
}

for rel in "${FILES[@]}"; do
  [ -n "$rel" ] || continue
  p="${HOME_DIR%/}/$rel"
  umount_if_mounted "$p"
  if [ -d "$p" ] && [ ! -L "$p" ]; then
    "$rm_bin" -rf --one-file-system "$p"
  fi
done

for rel in "${DIRS[@]}"; do
  [ -n "$rel" ] || continue
  p="${HOME_DIR%/}/$rel"
  umount_if_mounted "$p"
  if [ -e "$p" ] && [ ! -d "$p" ]; then
    "$rm_bin" -f "$p"
  fi
done
