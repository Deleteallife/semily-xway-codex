#!/usr/bin/env bash
# Удаление Semily XWAY Studio для Codex на macOS и Linux.

set -euo pipefail

codex_root="${SEMILY_XWAY_TEST_ROOT:-$HOME/.codex}"
target_skill="$codex_root/skills/semily-xway-studio"

echo "Skill: $target_skill"
echo "MCP: semily_xway"
rm -rf "$target_skill"

if [ -n "${SEMILY_XWAY_TEST_ROOT:-}" ]; then
  rm -f "$codex_root/semily-xway-mcp-test-state.json"
  echo "TEST UNINSTALL OK"
  exit 0
fi

if command -v codex >/dev/null 2>&1; then
  codex mcp logout semily_xway >/dev/null 2>&1 || true
  codex mcp remove semily_xway >/dev/null 2>&1 || true
else
  echo "Skill удалён. Уберите semily_xway вручную в настройках MCP — Codex CLI не найден." >&2
fi

# Глобальные ключи OAuth-callback добавлял установщик Semily — убираем их за собой.
config="$codex_root/config.toml"
if [ -f "$config" ]; then
  cp "$config" "$config.semily-backup"
  tmp="$(mktemp)"
  inside_section=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      \[*) inside_section=1 ;;
    esac
    if [ "$inside_section" -eq 0 ]; then
      case "$line" in
        mcp_oauth_callback_port*|mcp_oauth_callback_url*) continue ;;
      esac
    fi
    printf '%s\n' "$line" >> "$tmp"
  done < "$config"
  mv "$tmp" "$config"
  echo "Ключи mcp_oauth_callback_* убраны из config.toml (копия: $config.semily-backup)."
fi

echo "Semily XWAY Studio удалён."
