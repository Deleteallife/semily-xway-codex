#!/usr/bin/env bash
# Установка Semily XWAY Studio для Codex на macOS и Linux.
# Windows: powershell -ExecutionPolicy Bypass -File .\install.ps1

set -euo pipefail

package_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_skill="$package_root/semily-xway-studio"
connection="$package_root/connection.json"

if [ ! -f "$source_skill/SKILL.md" ]; then
  echo "В папке не найден semily-xway-studio/SKILL.md. Запускайте install.sh из склонированного репозитория." >&2
  exit 1
fi
if [ ! -f "$connection" ]; then
  echo "Не найден connection.json рядом с install.sh." >&2
  exit 1
fi

server_name="semily_xway"
server_url="https://plugin.semily.ru/mcp"
client_id="b7mFlRgJXJwBfF8DdGId8aCD4KvdwIr0"
callback_port="4321"
callback_url="http://localhost:4321/callback"

codex_root="${SEMILY_XWAY_TEST_ROOT:-$HOME/.codex}"
skills_root="$codex_root/skills"
target_skill="$skills_root/semily-xway-studio"

mkdir -p "$skills_root"
rm -rf "$target_skill"
cp -R "$source_skill" "$target_skill"
echo "Skill установлен: $target_skill"

if [ -n "${SEMILY_XWAY_TEST_ROOT:-}" ]; then
  echo "TEST INSTALL OK: $target_skill"
  exit 0
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "Codex CLI не найден. Установите или обновите Codex и запустите install.sh заново." >&2
  exit 1
fi

config="$codex_root/config.toml"
if [ -f "$config" ]; then
  cp "$config" "$config.semily-backup"
  echo "Резервная копия config.toml: $config.semily-backup"
fi

# Переписываем два top-level ключа, не трогая секции [...] ниже.
tmp="$(mktemp)"
written=0
inside_section=0
if [ -f "$config" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      \[*)
        if [ "$inside_section" -eq 0 ] && [ "$written" -eq 0 ]; then
          printf 'mcp_oauth_callback_port = %s\n' "$callback_port" >> "$tmp"
          printf 'mcp_oauth_callback_url = "%s"\n' "$callback_url" >> "$tmp"
          written=1
        fi
        inside_section=1
        ;;
    esac
    if [ "$inside_section" -eq 0 ]; then
      case "$line" in
        mcp_oauth_callback_port*|mcp_oauth_callback_url*) continue ;;
      esac
    fi
    printf '%s\n' "$line" >> "$tmp"
  done < "$config"
fi
if [ "$written" -eq 0 ]; then
  printf 'mcp_oauth_callback_port = %s\n' "$callback_port" >> "$tmp"
  printf 'mcp_oauth_callback_url = "%s"\n' "$callback_url" >> "$tmp"
fi
mkdir -p "$codex_root"
mv "$tmp" "$config"

if codex mcp get "$server_name" --json >/dev/null 2>&1; then
  codex mcp remove "$server_name" >/dev/null 2>&1 || true
fi

codex mcp add "$server_name" --url "$server_url" --oauth-client-id "$client_id"

if [ "${SEMILY_XWAY_SKIP_LOGIN:-}" != "1" ]; then
  if ! codex -c "mcp_oauth_callback_port=$callback_port" -c "mcp_oauth_callback_url=\"$callback_url\"" \
       mcp login "$server_name" --scopes 'mcp:use,offline_access'; then
    echo "Skill установлен, но вход в XWAY не завершён. Выполните: codex mcp login $server_name --scopes mcp:use,offline_access" >&2
  fi
fi

echo
echo "Semily XWAY Studio установлен как отдельный skill."
echo "Callback: $callback_url"
echo "Перезапустите Codex, создайте новую задачу и вызовите Semily XWAY Studio."
