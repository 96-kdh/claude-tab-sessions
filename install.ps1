# Installs the /save /load /del /list /clean skills into a Claude Code config dir.
#
#   Local checkout : .\install.ps1 [-ConfigDir <dir>] [-Force]
#   One-liner      : irm https://raw.githubusercontent.com/96-kdh/claude-tab-sessions/main/install.ps1 | iex
#
# Target dir: -ConfigDir, else $env:CLAUDE_CONFIG_DIR, else ~\.claude
# Existing skills with the same names are left alone unless they were installed by this tool, or -Force is given.
param(
    [string]$ConfigDir,
    [switch]$Force
)
$ErrorActionPreference = "Stop"
$Repo = "96-kdh/claude-tab-sessions"
$Ref = if ($env:CLAUDE_TAB_SESSIONS_REF) { $env:CLAUDE_TAB_SESSIONS_REF } else { "main" }
$Skills = "save", "load", "del", "list", "clean"
$Marker = ".claude-tab-sessions"

if (-not $ConfigDir) { $ConfigDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE ".claude" } }
if (-not $Force -and $env:CLAUDE_TAB_SESSIONS_FORCE -eq "1") { $Force = $true }

# Use the files next to this script when run from a checkout or the npm package; otherwise download them
$tmp = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "skills\save\sessions.ps1"))) {
    $src = Join-Path $PSScriptRoot "skills"
} else {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("claude-tab-sessions-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory $tmp | Out-Null
    $zip = Join-Path $tmp "src.zip"
    Write-Host "다운로드 중: github.com/$Repo ($Ref)"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest "https://codeload.github.com/$Repo/zip/$Ref" -OutFile $zip -UseBasicParsing
    Expand-Archive $zip $tmp
    $src = Join-Path (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName "skills"
}

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
if ($tmp) { Remove-Item $tmp -Recurse -Force }

Write-Host "설치 위치: $dest"
if ($installed.Count -gt 0) { Write-Host ("설치함: " + (($installed | ForEach-Object { "/$_" }) -join " ")) }
if ($skipped.Count -gt 0) {
    Write-Host ("건너뜀 (같은 이름의 다른 스킬이 이미 있음): " + (($skipped | ForEach-Object { "/$_" }) -join " ")) -ForegroundColor Yellow
    Write-Host "덮어쓰려면 -Force 를 붙이거나, 한 줄 설치라면 `$env:CLAUDE_TAB_SESSIONS_FORCE='1' 을 먼저 설정하세요." -ForegroundColor Yellow
}
Write-Host "새로 여는 Claude Code 세션부터 사용할 수 있어요."
