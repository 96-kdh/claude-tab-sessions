# Installs the /save /load /del /list /clean skills into a Claude Code config dir.
#
#   Local checkout : .\install.ps1 [-ConfigDir <dir>] [-Force]
#   One-liner      : irm https://raw.githubusercontent.com/96-kdh/claude-tab-sessions/main/get.ps1 | iex  (downloads, then runs this)
#
# Target dir: -ConfigDir, else $env:CLAUDE_CONFIG_DIR, else ~\.claude
# Existing skills with the same names are left alone unless they were installed by this tool, or -Force is given.
param(
    [string]$ConfigDir,
    [switch]$Force
)
$ErrorActionPreference = "Stop"
$Skills = "save", "load", "del", "list", "clean"
$Marker = ".claude-tab-sessions"

if (-not $ConfigDir) { $ConfigDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE ".claude" } }
if (-not $Force -and $env:CLAUDE_TAB_SESSIONS_FORCE -eq "1") { $Force = $true }

$src = Join-Path $PSScriptRoot "skills"

$dest = Join-Path $ConfigDir "skills"
New-Item -ItemType Directory $dest -Force | Out-Null
$installed = @(); $skipped = @()
foreach ($name in $Skills) {
    $target = Join-Path $dest $name
    if ((Test-Path $target) -and -not (Test-Path (Join-Path $target $Marker)) -and -not $Force) {
        $skipped += $name
        continue
    }
    if (Test-Path $target) { Remove-Item $target -Recurse -Force }
    Copy-Item (Join-Path $src $name) $target -Recurse
    Set-Content (Join-Path $target $Marker) "installed by claude-tab-sessions" -Encoding ASCII
    $installed += $name
}

Write-Host "설치 위치: $dest"
if ($installed.Count -gt 0) { Write-Host ("설치함: " + (($installed | ForEach-Object { "/$_" }) -join " ")) }
if ($skipped.Count -gt 0) {
    Write-Host ("건너뜀 (같은 이름의 다른 스킬이 이미 있음): " + (($skipped | ForEach-Object { "/$_" }) -join " ")) -ForegroundColor Yellow
    Write-Host "덮어쓰려면 -Force 를 붙이거나, 한 줄 설치라면 `$env:CLAUDE_TAB_SESSIONS_FORCE='1' 을 먼저 설정하세요." -ForegroundColor Yellow
}
Write-Host "새로 여는 Claude Code 세션부터 사용할 수 있어요."
