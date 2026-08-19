# Semily XWAY Studio для Codex

Skill для [Codex](https://openai.com/codex): анализ конкурентов на Wildberries, генерация пяти обложек, A/B-тест изображений в XWAY по CTR и применение подтверждённого победителя.

Версия для Claude Code — в отдельном репозитории [semily-xway-claude](https://github.com/Deleteallife/semily-xway-claude).

## Установка одной командой

Закройте Codex, затем выполните. Аккаунт GitHub и git не нужны.

**Windows (PowerShell):**

```bash
irm https://raw.githubusercontent.com/Deleteallife/semily-xway-codex/main/bootstrap.ps1 | iex
```

**macOS / Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/Deleteallife/semily-xway-codex/main/bootstrap.sh | bash
```

Команда скачает репозиторий во временную папку, установит skill, зарегистрирует MCP-сервер и откроет вход в браузере. От пользователя нужен только логин Semily. После входа перезапустите Codex и создайте новую задачу.

> Команда выполняет скрипт из этого репозитория. Если политика компании это запрещает, используйте установку через git ниже.

## Установка через git

Закройте Codex, затем:

```bash
git clone https://github.com/Deleteallife/semily-xway-codex.git
```

**Windows:**

```bash
powershell -ExecutionPolicy Bypass -File .\semily-xway-codex\install.ps1
```

**macOS / Linux:**

```bash
bash semily-xway-codex/install.sh
```

Установщик скопирует skill в `~/.codex/skills/semily-xway-studio`, зарегистрирует MCP-сервер `semily_xway` с фиксированным публичным OAuth Client ID и откроет вход в браузере. После входа перезапустите Codex и создайте новую задачу.

### Обновление

```bash
git -C semily-xway-codex pull
```

Затем снова запустите установщик — он идемпотентен и заменит прежнюю установку.

### Удаление

```bash
powershell -ExecutionPolicy Bypass -File .\semily-xway-codex\uninstall.ps1
```

```bash
bash semily-xway-codex/uninstall.sh
```

## Использование

Короткая команда на весь цикл:

```
Запусти полный цикл Semily XWAY для артикула 123456789. Прикладываю товар и референс.
```

Skill сам проведёт анализ WB, создаст и покажет пять обложек, дождётся одного «ОК», запустит XWAY, будет собирать CTR и при подтверждённом победителе начнёт следующий цикл.

## Подключение

| Параметр | Значение |
| --- | --- |
| Имя сервера | `semily_xway` |
| URL | `https://plugin.semily.ru/mcp` |
| Scopes | `mcp:use`, `offline_access` |
| OAuth callback | `http://localhost:4321/callback` |

Пароли, токены и доступ к БД в репозиторий не входят и никогда не запрашиваются в чате.

## Что изменилось в этой версии

**Callback переведён с `127.0.0.1` на `localhost`.** Это главная причина, по которой плагин ломался: Codex отправлял `http://127.0.0.1:4321/callback`, и как только в OAuth-приложении оставался разрешённым только вариант с `localhost`, вход падал с `Callback URL mismatch`. Теперь Codex и Claude Code используют один и тот же адрес — в настройках OAuth достаточно одной записи вместо двух, которые легко разъезжаются.

Остальное:

- Установщик для macOS и Linux (`install.sh`), раньше был только PowerShell.
- `config.toml` копируется в `config.toml.semily-backup` перед правкой.
- Удаление теперь убирает за собой глобальные ключи `mcp_oauth_callback_port` и `mcp_oauth_callback_url`, а не только skill и MCP-запись.
- Раздача через git вместо ZIP: обновление одним `git pull`, без проблем с кодировкой имён файлов в архиве.

## Настройка OAuth-приложения (делается один раз)

Codex не использует настроенный callback как есть — он **дописывает к нему постоянный сегмент пути**, свой для каждого имени MCP-сервера. Для сервера `semily_xway` это `Y0eju6gqPLwA`. Auth0 сверяет callback точным совпадением, поэтому в Allowed Callback URLs должны быть все четыре строки:

```
http://localhost:4321/callback,
http://127.0.0.1:4321/callback,
http://localhost:4321/callback/Y0eju6gqPLwA,
http://127.0.0.1:4321/callback/Y0eju6gqPLwA
```

Первые две — для Claude Code, вторые две — для Codex. Обе формы хоста нужны потому, что разные версии клиентов используют то `localhost`, то `127.0.0.1`.

Проверить суффикс на конкретной машине можно, не завершая вход:

```bash
codex mcp login semily_xway
```

Codex напечатает адрес авторизации — в нём видно значение после `/callback/`.

## Диагностика

**`Callback URL mismatch` при входе.** Проверьте, что в Allowed Callback URLs есть строка с суффиксом, а не только `.../callback`. Это самая частая причина: Codex всегда добавляет суффикс.

**`os error 10048` / «разрешается только одно использование адреса сокета».** Порт 4321 занят зависшим процессом Codex от прошлой неудачной попытки входа. Найти и закрыть:

```bash
Get-NetTCPConnection -LocalPort 4321 | Select-Object OwningProcess
```

Полностью закройте Codex и повторите вход.

**Вход прошёл, но инструменты возвращают 403.** При повторном входе из интерфейса Codex запрашивает не `mcp:use`, а полный список scopes из метаданных Auth0, потому что `codex mcp add` не умеет сохранять scopes — их принимает только `codex mcp login --scopes`. Войдите заново явно:

```bash
codex mcp login semily_xway --scopes mcp:use,offline_access
```

**`403 too_many_entities`.** Сервер добавлен вручную по одному URL, из-за чего включилась динамическая регистрация клиента. Закройте Codex и запустите `install.ps1` / `install.sh` отсюда — установщик заменит запись на фиксированный публичный Client ID. Не добавляйте `semily_xway` вручную только по URL.

**Порт 4321 занят.** Освободите порт на время входа: он нужен только на несколько секунд для OAuth-редиректа.

**Skill не появился в Codex.** Проверьте, что папка `~/.codex/skills/semily-xway-studio` существует и содержит `SKILL.md`, затем перезапустите Codex и создайте **новую** задачу.

**Установлен старый плагин Semily Xway Studio.** После успешной установки удалите старый плагин через раздел «Плагины», чтобы не было двух одинаковых skills.

## Лицензия

MIT
