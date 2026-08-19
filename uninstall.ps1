$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$testRoot = $env:SEMILY_XWAY_TEST_ROOT
if ($testRoot) {
    $codexRoot = [System.IO.Path]::GetFullPath($testRoot)
} else {
    $codexRoot = Join-Path $env:USERPROFILE '.codex'
}
$skillsRoot = Join-Path $codexRoot 'skills'
$targetSkill = Join-Path $skillsRoot 'semily-xway-studio'
$skillsResolved = [System.IO.Path]::GetFullPath($skillsRoot).TrimEnd('\') + '\'
$targetResolved = [System.IO.Path]::GetFullPath($targetSkill)
if (-not $targetResolved.StartsWith($skillsResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Небезопасный путь удаления скилла.'
}

Write-Host "Skill: $targetSkill"
Write-Host 'MCP: semily_xway'
if (Test-Path -LiteralPath $targetSkill) {
    Remove-Item -LiteralPath $targetSkill -Recurse -Force
}

if ($testRoot) {
    $state = Join-Path $codexRoot 'semily-xway-mcp-test-state.json'
    if (Test-Path -LiteralPath $state) { Remove-Item -LiteralPath $state -Force }
    Write-Host 'TEST UNINSTALL OK'
    exit 0
}

function Remove-CodexTopLevelTomlValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Key
    )

    if (-not (Test-Path -LiteralPath $Path)) { return }
    $lines = @([System.IO.File]::ReadAllLines($Path))
    $result = [System.Collections.Generic.List[string]]::new()
    $keyPattern = '^\s*' + [regex]::Escape($Key) + '\s*='
    $insideSection = $false

    foreach ($line in $lines) {
        if (-not $insideSection -and $line -match '^\s*\[') { $insideSection = $true }
        if (-not $insideSection -and $line -match $keyPattern) { continue }
        $result.Add($line)
    }

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines($Path, $result, $utf8NoBom)
}

$command = Get-Command codex -ErrorAction SilentlyContinue
if ($command) {
    & $command.Source mcp logout semily_xway 2>$null | Out-Null
    & $command.Source mcp remove semily_xway 2>$null | Out-Null
} else {
    Write-Warning 'Skill удалён. Уберите semily_xway вручную в настройках MCP — Codex CLI не найден.'
}

# Глобальные ключи OAuth-callback добавлял установщик Semily — убираем их за собой.
$configPath = Join-Path $codexRoot 'config.toml'
if (Test-Path -LiteralPath $configPath) {
    Copy-Item -LiteralPath $configPath -Destination "$configPath.semily-backup" -Force
    Remove-CodexTopLevelTomlValue -Path $configPath -Key 'mcp_oauth_callback_port'
    Remove-CodexTopLevelTomlValue -Path $configPath -Key 'mcp_oauth_callback_url'
    Write-Host "Ключи mcp_oauth_callback_* убраны из config.toml (копия: $configPath.semily-backup)."
}

Write-Host 'Semily XWAY Studio удалён.'
