$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$packageRoot = $PSScriptRoot
$sourceSkill = Join-Path $packageRoot 'semily-xway-studio'
$connectionPath = Join-Path $packageRoot 'connection.json'

if (-not (Test-Path -LiteralPath (Join-Path $sourceSkill 'SKILL.md'))) {
    throw 'В папке не найден semily-xway-studio\SKILL.md. Запускайте install.ps1 из склонированного репозитория.'
}
if (-not (Test-Path -LiteralPath $connectionPath)) {
    throw 'Не найден connection.json рядом с install.ps1.'
}

$connection = Get-Content -Raw -LiteralPath $connectionPath | ConvertFrom-Json
if (
    $connection.name -ne 'semily_xway' -or
    $connection.url -ne 'https://plugin.semily.ru/mcp' -or
    -not $connection.oauth_client_id -or
    $connection.oauth_callback_port -ne 4321 -or
    $connection.oauth_callback_url -ne 'http://localhost:4321/callback'
) {
    throw 'Некорректные метаданные подключения Semily XWAY в connection.json.'
}

$testRoot = $env:SEMILY_XWAY_TEST_ROOT
if ($testRoot) {
    $codexRoot = [System.IO.Path]::GetFullPath($testRoot)
} else {
    $codexRoot = Join-Path $env:USERPROFILE '.codex'
}
$skillsRoot = Join-Path $codexRoot 'skills'
$targetSkill = Join-Path $skillsRoot 'semily-xway-studio'
New-Item -ItemType Directory -Force -Path $skillsRoot | Out-Null

$skillsResolved = [System.IO.Path]::GetFullPath($skillsRoot).TrimEnd('\') + '\'
$targetResolved = [System.IO.Path]::GetFullPath($targetSkill)
if (-not $targetResolved.StartsWith($skillsResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Небезопасный путь установки скилла.'
}
if (Test-Path -LiteralPath $targetSkill) {
    Remove-Item -LiteralPath $targetSkill -Recurse -Force
}
Copy-Item -LiteralPath $sourceSkill -Destination $targetSkill -Recurse -Force

if ($testRoot) {
    $testState = [ordered]@{
        name = [string]$connection.name
        url = [string]$connection.url
        scopes = @($connection.scopes)
        oauth_client_id = [string]$connection.oauth_client_id
        oauth_callback_port = [int]$connection.oauth_callback_port
        oauth_callback_url = [string]$connection.oauth_callback_url
    }
    $testState | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $codexRoot 'semily-xway-mcp-test-state.json') -Encoding UTF8
    Write-Host "TEST INSTALL OK: $targetSkill"
    exit 0
}

function Find-CodexExecutable {
    $localBin = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'
    if (Test-Path -LiteralPath $localBin) {
        $candidate = Get-ChildItem -LiteralPath $localBin -Filter codex.exe -Recurse -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($candidate) { return $candidate.FullName }
    }
    $command = Get-Command codex -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    throw 'Codex CLI не найден. Установите или обновите Codex Desktop и запустите install.ps1 заново.'
}

function Set-CodexTopLevelTomlValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$TomlValue
    )

    $lines = if (Test-Path -LiteralPath $Path) {
        @([System.IO.File]::ReadAllLines($Path))
    } else {
        @()
    }
    $result = [System.Collections.Generic.List[string]]::new()
    $assignment = "$Key = $TomlValue"
    $keyPattern = '^\s*' + [regex]::Escape($Key) + '\s*='
    $insideSection = $false
    $written = $false

    foreach ($line in $lines) {
        if (-not $insideSection -and $line -match '^\s*\[') {
            if (-not $written) {
                $result.Add($assignment)
                $written = $true
            }
            $insideSection = $true
        }
        if (-not $insideSection -and $line -match $keyPattern) {
            if (-not $written) {
                $result.Add($assignment)
                $written = $true
            }
            continue
        }
        $result.Add($line)
    }
    if (-not $written) {
        $result.Add($assignment)
    }

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines($Path, $result, $utf8NoBom)
}

$configPath = Join-Path $codexRoot 'config.toml'
if (Test-Path -LiteralPath $configPath) {
    Copy-Item -LiteralPath $configPath -Destination "$configPath.semily-backup" -Force
    Write-Host "Резервная копия config.toml: $configPath.semily-backup"
}
Set-CodexTopLevelTomlValue -Path $configPath -Key 'mcp_oauth_callback_port' -TomlValue ([string]$connection.oauth_callback_port)
Set-CodexTopLevelTomlValue -Path $configPath -Key 'mcp_oauth_callback_url' -TomlValue ('"' + [string]$connection.oauth_callback_url + '"')

$codexExe = Find-CodexExecutable
& $codexExe mcp get semily_xway --json 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    & $codexExe mcp remove semily_xway 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Не удалось заменить существующую MCP-запись semily_xway.'
    }
}

$addArgs = @(
    'mcp', 'add', 'semily_xway',
    '--url', [string]$connection.url,
    '--oauth-client-id', [string]$connection.oauth_client_id
)
& $codexExe @addArgs
if ($LASTEXITCODE -ne 0) {
    throw 'Не удалось сохранить MCP-сервер semily_xway с фиксированным публичным OAuth-клиентом.'
}

if ($env:SEMILY_XWAY_SKIP_LOGIN -ne '1') {
    $callbackPortOverride = 'mcp_oauth_callback_port=' + [string]$connection.oauth_callback_port
    $callbackUrlOverride = 'mcp_oauth_callback_url="' + [string]$connection.oauth_callback_url + '"'
    & $codexExe -c $callbackPortOverride -c $callbackUrlOverride mcp login semily_xway --scopes 'mcp:use,offline_access'
    if ($LASTEXITCODE -ne 0) {
        Write-Warning 'Скилл установлен, но вход в XWAY не завершён. Выполните: codex mcp login semily_xway --scopes mcp:use,offline_access'
    }
}

Write-Host ''
Write-Host 'Semily XWAY Studio установлен как отдельный skill.'
Write-Host 'Используется фиксированный публичный OAuth Client ID; динамическая регистрация клиента отключена.'
Write-Host "Callback: $($connection.oauth_callback_url)"
Write-Host 'Перезапустите Codex, создайте новую задачу и вызовите Semily XWAY Studio.'
