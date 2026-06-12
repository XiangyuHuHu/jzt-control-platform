#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(dirname "$script_dir")"
env_file="$root_dir/.env.docker"
env_example="$root_dir/.env.docker.example"

if ! command -v docker >/dev/null 2>&1; then
  echo "未找到 docker 命令，请先安装 Docker Engine 或 Docker Desktop。" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "未找到 docker compose，请安装 Docker Compose v2。" >&2
  exit 1
fi

if [[ ! -f "$env_file" ]]; then
  cp "$env_example" "$env_file"
  echo "已生成 .env.docker，请先检查账号、密码和现场地址配置："
  echo "  $env_file"
fi

cd "$root_dir"

export SMART_DENSITY_ENABLED="${SMART_DENSITY_ENABLED:-true}"
export SMART_DENSITY_BASE_URL="${SMART_DENSITY_BASE_URL:-http://smart-density:6789}"
export SMART_REAGENT_ENABLED="${SMART_REAGENT_ENABLED:-true}"
export SMART_REAGENT_BASE_URL="${SMART_REAGENT_BASE_URL:-http://smart-reagent:6788}"
export SMART_DENSITY_RHO_SOURCE="${SMART_DENSITY_RHO_SOURCE:-param}"
export SMART_DENSITY_DB_HOST="${SMART_DENSITY_DB_HOST:-smart-density-mysql}"

docker compose --env-file .env.docker -p coal-platform-jzt --profile models up -d --build

echo ""
echo "容器已启动，当前状态："
docker compose --env-file .env.docker -p coal-platform-jzt ps
echo ""
echo "访问地址（金正泰默认 81 端口）："
echo "  管控平台: http://localhost:81/coal"
echo "  API 代理: http://localhost:81/api"
echo "  后端直连: http://localhost:8081/api"
echo ""
echo "如需查看日志："
echo "  docker compose --env-file .env.docker -p coal-platform-jzt logs -f server"
echo "  docker compose --env-file .env.docker -p coal-platform-jzt logs -f smart-density"
echo "  docker compose --env-file .env.docker -p coal-platform-jzt logs -f smart-reagent"
