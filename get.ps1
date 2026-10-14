# Bootstrap for the one-line install:
#   irm https://raw.githubusercontent.com/96-kdh/claude-tab-sessions/main/get.ps1 | iex
# Downloads the repo and runs install.ps1 from it. Kept ASCII-only and param-free because it runs through Invoke-Expression.
# Options via env vars: CLAUDE_CONFIG_DIR (target), CLAUDE_TAB_SESSIONS_FORCE=1, CLAUDE_TAB_SESSIONS_REF (branch/tag)
& {
    $ErrorActionPreference = "Stop"
    $ref = if ($env:CLAUDE_TAB_SESSIONS_REF) { $env:CLAUDE_TAB_SESSIONS_REF } else { "main" }
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("claude-tab-sessions-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory $tmp | Out-Null
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $zip = Join-Path $tmp "src.zip"
        Write-Host "Downloading github.com/96-kdh/claude-tab-sessions ($ref)"
        Invoke-WebRequest "https://codeload.github.com/96-kdh/claude-tab-sessions/zip/$ref" -OutFile $zip -UseBasicParsing
        Expand-Archive $zip $tmp
        $root = (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "install.ps1")
    } finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
