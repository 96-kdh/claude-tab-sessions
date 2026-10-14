# Saved Claude Code sessions: backs the /save /load /del /list /clean skills.
# Usage: sessions.ps1 <save|load|del|list|clean> <currentSessionId> [name | apply]
param(
    [Parameter(Mandatory = $true)][string]$Action,
    [Parameter(Mandatory = $true)][string]$CurrentId,
    [string]$Arg = "",
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest
)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8
# A name typed with its own quotes (/save "new char") can arrive split into several args
$Arg = ((@($Arg) + @($Rest)) -join " ").Trim().Trim('"', "'").Trim()
if ($Arg -match '["]') { Write-Output "이름에는 큰따옴표를 쓸 수 없어요."; exit 0 }

$ConfigDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE ".claude" }
$ProjectsDir = Join-Path $ConfigDir "projects"
# One list shared by every account (config dir); each entry remembers its own config dir
$Store = if ($env:CLAUDE_SAVED_SESSIONS_FILE) { $env:CLAUDE_SAVED_SESSIONS_FILE } else { Join-Path $env:USERPROFILE ".claude-saved-sessions.json" }

function Read-Store {
    if (-not (Test-Path $Store)) { return @() }
    $raw = [IO.File]::ReadAllText($Store, [Text.Encoding]::UTF8)
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    # PowerShell 5.1 emits a JSON array as one object, so unroll it explicitly
    $parsed = ConvertFrom-Json -InputObject $raw
    return $parsed
}

function Write-Store($list) {
    $json = ConvertTo-Json -InputObject @($list) -Depth 3
    [IO.File]::WriteAllText($Store, $json, (New-Object Text.UTF8Encoding $false))
}

# Sessions whose process is still alive, from <config>/sessions/<pid>.json
function Get-Running {
    $map = @{}
    $dir = Join-Path $ConfigDir "sessions"
    if (-not (Test-Path $dir)) { return $map }
    foreach ($f in Get-ChildItem $dir -Filter *.json -File) {
        try {
            $s = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8) | ConvertFrom-Json
            if ($s.sessionId -and (Get-Process -Id $s.pid -ErrorAction SilentlyContinue)) { $map[$s.sessionId] = $s }
        } catch { }
    }
    return $map
}

function Find-Transcript([string]$Id, [string]$Root) {
    $p = Join-Path $Root "projects"
    if (-not (Test-Path $p)) { return $null }
    foreach ($d in Get-ChildItem $p -Directory) {
        $f = Join-Path $d.FullName "$Id.jsonl"
        if (Test-Path $f) { return Get-Item $f }
    }
    return $null
}

# Title set with /rename, if any
function Get-CustomTitle($file) {
    $hit = Select-String -Path $file.FullName -Pattern '"customTitle":"([^"]*)"' -Encoding UTF8 | Select-Object -Last 1
    if ($hit) { return $hit.Matches[0].Groups[1].Value }
    return $null
}

function Get-RetentionDays {
    $settings = Join-Path $ConfigDir "settings.json"
    if (Test-Path $settings) {
        try {
            $s = [IO.File]::ReadAllText($settings, [Text.Encoding]::UTF8) | ConvertFrom-Json
            if ($s.cleanupPeriodDays) { return [int]$s.cleanupPeriodDays }
        } catch { }
    }
    return 30
}

function Format-Size([double]$bytes) {
    if ($bytes -ge 1GB) { return "{0:N1} GB" -f ($bytes / 1GB) }
    return "{0:N1} MB" -f ($bytes / 1MB)
}

$list = @(Read-Store)

switch ($Action) {
    "save" {
        $running = Get-Running
        $transcript = Find-Transcript $CurrentId $ConfigDir
        $cwd = if ($running.ContainsKey($CurrentId)) { $running[$CurrentId].cwd } else { (Get-Location).ProviderPath }
        $name = $Arg
        if (-not $name -and $transcript) { $name = Get-CustomTitle $transcript }
        if (-not $name) { $name = "{0}-{1}" -f (Split-Path $cwd -Leaf), $CurrentId.Substring(0, 4) }

        $other = $list | Where-Object { $_.name -eq $name -and $_.id -ne $CurrentId } | Select-Object -First 1
        if ($other) { Write-Output "'$name' 이름은 이미 다른 세션이 쓰고 있어요. 다른 이름으로 /save <이름> 해 주세요."; exit 0 }

        $existing = $list | Where-Object { $_.id -eq $CurrentId } | Select-Object -First 1
        if ($existing) {
            $old = $existing.name
            $existing.name = $name
            $existing.cwd = $cwd
            $existing.configDir = $ConfigDir
            Write-Store $list
            if ($old -ne $name) { Write-Output "이미 저장된 세션이라 이름만 바꿨어요: '$old' -> '$name'" }
            else { Write-Output "이미 '$name' 으로 저장되어 있어요." }
        } else {
            $list += [pscustomobject]@{
                name      = $name
                id        = $CurrentId
                cwd       = $cwd
                configDir = $ConfigDir
                savedAt   = (Get-Date).ToString("yyyy-MM-dd HH:mm")
            }
            Write-Store $list
            Write-Output "저장했어요: '$name' (/load 시 열릴 작업 폴더: $cwd)"
        }
        if (-not $transcript) { Write-Output "참고: 아직 대화 기록 파일이 없어요. 메시지를 하나 이상 주고받아야 /load 로 이어서 열 수 있어요." }
    }

    "del" {
        $target = if ($Arg) { $list | Where-Object { $_.name -eq $Arg } | Select-Object -First 1 }
                  else { $list | Where-Object { $_.id -eq $CurrentId } | Select-Object -First 1 }
        if (-not $target) {
            if ($Arg) { Write-Output "'$Arg' 이름의 저장된 세션이 없어요. /list 로 확인해 주세요." }
            else { Write-Output "지금 세션은 저장 목록에 없어요." }
            exit 0
        }
        Write-Store @($list | Where-Object { $_.id -ne $target.id })
        Write-Output "저장 목록에서 '$($target.name)' 을(를) 뺐어요. (대화 기록은 남아 있어요)"
        if ($target.id -eq $CurrentId) { Write-Output "이 세션을 끝내려면 /exit 를 입력하세요." }
    }

    "list" {
        if ($list.Count -eq 0) { Write-Output "저장된 세션이 없어요. 이어서 열고 싶은 세션에서 /save 하세요."; exit 0 }
        $running = Get-Running
        $days = Get-RetentionDays
        $rows = foreach ($s in $list) {
            $root = if ($s.configDir) { $s.configDir } else { $ConfigDir }
            $t = Find-Transcript $s.id $root
            $state = if ($s.id -eq $CurrentId) { "지금 세션" } elseif ($running.ContainsKey($s.id)) { "열려 있음" } elseif ($t) { "닫힘" } else { "기록 없음" }
            $left = if ($t) { $days - [int][Math]::Floor(((Get-Date) - $t.LastWriteTime).TotalDays) } else { $null }
            [pscustomobject]@{
                "이름"          = $s.name
                "상태"          = $state
                "폴더"          = Split-Path $s.cwd -Leaf
                "마지막 활동"   = if ($t) { $t.LastWriteTime.ToString("MM-dd HH:mm") } else { "-" }
                "자동삭제까지" = if ($null -ne $left) { if ($left -le 7) { "${left}일 (!)" } else { "${left}일" } } else { "-" }
            }
        }
        Write-Output ($rows | Format-Table -AutoSize | Out-String -Width 200).TrimEnd()
        Write-Output ""
        Write-Output "자동삭제까지: 마지막 활동 후 ${days}일이 지나면 Claude Code 가 기록을 지워요. 세션을 열어 대화하면 다시 늘어나요."
    }

    "load" {
        $targets = if ($Arg) { @($list | Where-Object { $_.name -eq $Arg }) } else { $list }
        if ($Arg -and $targets.Count -eq 0) { Write-Output "'$Arg' 이름의 저장된 세션이 없어요. /list 로 확인해 주세요."; exit 0 }
        if ($targets.Count -eq 0) { Write-Output "저장된 세션이 없어요."; exit 0 }
        $running = Get-Running
        $tabs = @(); $opened = @(); $skipped = @()
        foreach ($s in $targets) {
            $root = if ($s.configDir) { $s.configDir } else { $ConfigDir }
            if ($s.id -eq $CurrentId) { $skipped += "$($s.name): 지금 이 세션"; continue }
            if ($running.ContainsKey($s.id)) { $skipped += "$($s.name): 이미 다른 탭에서 열려 있음"; continue }
            if (-not (Find-Transcript $s.id $root)) { $skipped += "$($s.name): 대화 기록이 없음 (자동삭제됐을 수 있어요)"; continue }
            # wt treats a bare ';' as a subcommand separator, so the one inside the tab command is escaped as '\;'
            $cmd = '$env:CLAUDE_CONFIG_DIR=''' + $root + '''\; claude --resume ' + $s.id
            $tabs += 'nt --title "' + $s.name + '" --suppressApplicationTitle -d "' + $s.cwd + '" powershell.exe -NoExit -Command "' + $cmd + '"'
            $opened += $s.name
        }
        if ($tabs.Count -gt 0) {
            Start-Process wt.exe -ArgumentList ("-w 0 " + ($tabs -join " ; "))
            Write-Output ("새 탭으로 열었어요: " + ($opened -join ", "))
        } else {
            Write-Output "새로 연 세션이 없어요."
        }
        foreach ($m in $skipped) { Write-Output "건너뜀 - $m" }
    }

    "clean" {
        $running = Get-Running
        # The running-session registry is an undocumented Claude Code file. If it no longer lists
        # this very session, its format changed and we can't tell which sessions are open, so stop.
        if (-not $running.ContainsKey($CurrentId)) {
            Write-Output "실행 중인 세션을 확인할 수 없어서 정리를 중단했어요. (Claude Code 업데이트로 내부 형식이 바뀌었을 수 있어요)"
            exit 0
        }
        $keep = @{}
        foreach ($s in $list) { $keep[$s.id] = $true }
        foreach ($k in $running.Keys) { $keep[$k] = $true }
        $keep[$CurrentId] = $true

        $targets = @()
        if (Test-Path $ProjectsDir) {
            foreach ($d in Get-ChildItem $ProjectsDir -Directory) {
                foreach ($f in Get-ChildItem $d.FullName -Filter *.jsonl -File) {
                    if ($keep.ContainsKey($f.BaseName)) { continue }
                    $paths = @($f.FullName)
                    $side = Join-Path $d.FullName $f.BaseName
                    if (Test-Path $side) { $paths += $side }
                    $hist = Join-Path (Join-Path $ConfigDir "file-history") $f.BaseName
                    if (Test-Path $hist) { $paths += $hist }
                    $size = 0
                    foreach ($p in $paths) {
                        if (Test-Path $p -PathType Container) { $size += (Get-ChildItem $p -Recurse -File -Force | Measure-Object Length -Sum).Sum }
                        else { $size += (Get-Item $p).Length }
                    }
                    $targets += [pscustomobject]@{ Project = $d.Name; Id = $f.BaseName; Paths = $paths; Size = $size }
                }
            }
        }

        $total = ($targets | Measure-Object Size -Sum).Sum
        $kept = $keep.Count
        if ($targets.Count -eq 0) { Write-Output "정리할 세션이 없어요. (저장/실행 중 세션 $kept 개는 보존)"; exit 0 }

        if ($Arg -ne "apply") {
            Write-Output ("정리 대상: 세션 {0}개, {1}  (계정 폴더: {2})" -f $targets.Count, (Format-Size $total), $ConfigDir)
            Write-Output "보존: 저장된 세션, 지금 열려 있는 세션, 이 세션"
            Write-Output ""
            $byProject = $targets | Group-Object Project | ForEach-Object {
                [pscustomobject]@{ "프로젝트" = $_.Name; "세션 수" = $_.Count; "용량" = Format-Size (($_.Group | Measure-Object Size -Sum).Sum) }
            }
            Write-Output ($byProject | Format-Table -AutoSize | Out-String -Width 200).TrimEnd()
            Write-Output ""
            Write-Output "실제로 지우려면 /clean apply 를 입력하세요. 지운 세션은 되돌릴 수 없어요."
            exit 0
        }

        $failed = 0
        foreach ($t in $targets) {
            foreach ($p in $t.Paths) {
                try { Remove-Item -LiteralPath $p -Recurse -Force } catch { $failed++ }
            }
        }
        Write-Output ("삭제했어요: 세션 {0}개, {1}" -f $targets.Count, (Format-Size $total))
        if ($failed -gt 0) { Write-Output "일부 파일 $failed 개는 지우지 못했어요 (사용 중일 수 있어요)." }
    }

    default { Write-Output "알 수 없는 동작: $Action" }
}
