#!/usr/bin/env bash
# Folio · PDF -> EPUB 一键部署 (macOS / Linux)
# 用法:  chmod +x deploy.sh && ./deploy.sh
set -euo pipefail
cd "$(dirname "$0")"

step() { printf "  [*] %s\n" "$1"; }
ok()   { printf "  [OK] %s\n" "$1"; }
err()  { printf "  [!!] %s\n" "$1" >&2; }

printf "\n  Folio · PDF -> EPUB 转换工坊\n\n"

# 1. Python
PY=""
for c in python3 python; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(0 if sys.version_info[0]==3 else 1)' 2>/dev/null; then
    PY="$c"; break
  fi
done
if [ -z "$PY" ]; then
  err "未找到 Python 3, 请先安装 (https://www.python.org 或系统包管理器)"
  exit 1
fi
ok "发现 $($PY --version)"

# 2. 虚拟环境
if [ ! -d .venv ]; then
  step "创建虚拟环境 .venv ..."
  "$PY" -m venv .venv
fi
VENV_PY=".venv/bin/python"

# 3. 依赖(有变化才重装)
REQ_HASH=$("$VENV_PY" -c "import hashlib;print(hashlib.md5(open('requirements.txt','rb').read()).hexdigest())")
STAMP=".venv/.deps-$REQ_HASH"
if [ ! -f "$STAMP" ]; then
  step "安装依赖 ..."
  "$VENV_PY" -m pip install --quiet --upgrade pip
  "$VENV_PY" -m pip install --quiet -r requirements.txt
  rm -f .venv/.deps-* 2>/dev/null || true
  touch "$STAMP"
  ok "依赖安装完成"
else
  ok "依赖已是最新"
fi

# 4. 启动
PORT=5000
URL="http://127.0.0.1:$PORT"
printf "\n"
ok "启动服务于  $URL"
printf "        按 Ctrl+C 停止\n"
( sleep 1.2; (command -v open >/dev/null && open "$URL") || (command -v xdg-open >/dev/null && xdg-open "$URL") || true ) &
exec "$VENV_PY" server.py --host 127.0.0.1 --port "$PORT"
