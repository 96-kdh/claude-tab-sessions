# Removes the skills installed by install.ps1 (only folders carrying its marker file).
#
#   .\uninstall.ps1 [-ConfigDir <dir>] [-Purge]
#
# -Purge also deletes the saved-session list (~\.claude-saved-sessions.json). Conversation transcripts are never touched.
param(
    [string]$ConfigDir,
    [switch]$Purge
)
$ErrorActionPreference = "Stop"
$Skills = "save", "load", "del", "list", "clean"
$Marker = ".claude-tab-sessions"

if (-not $ConfigDir) { $ConfigDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE ".claude" } }

$removed = @()
foreach ($name in $Skills) {
    $target = Join-Path (Join-Path $ConfigDir "skills") $name
    if (Test-Path (Join-Path $target $Marker)) {
        Remove-Item $target -Recurse -Force
        $removed += "/$name"
    }
}
if ($removed.Count -gt 0) { Write-Host ("삭제함: " + ($removed -join " ") + "  ($ConfigDir)") }
else { Write-Host "이 도구로 설치된 스킬이 없어요. ($ConfigDir)" }

if ($Purge) {
    $store = Join-Path $env:USERPROFILE ".claude-saved-sessions.json"
    if (Test-Path $store) { Remove-Item $store -Force; Write-Host "저장 목록도 삭제했어요: $store" }
}
