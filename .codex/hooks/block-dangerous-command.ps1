[CmdletBinding()]
param([Alias('TestRawInput')][switch]$SelfTest)

$ErrorActionPreference = 'Stop'

# Direct command heads only. Shell wrappers, substitutions, aliases, and encoded
# commands are deliberately outside this small guard's scope.
function Get-Tokens([string]$Command) {
    $pattern = '"(?:\\.|[^"])*"|''(?:[^'']|'')*''|[\r\n;&|]|[^\s;&|]+'
    [regex]::Matches($Command, $pattern) | ForEach-Object { $_.Value.Trim([char]39, [char]34) }
}

function Get-Block([string[]]$Tokens) {
    $t = @($Tokens)
    if (!$t.Count -or $t[0] -notmatch '(?i)(?:^|[\\/])git(?:\.exe|\.cmd)?$') { return }
    $i = 1
    while ($i -lt $t.Count -and $t[$i].StartsWith('-')) {
        if ($t[$i] -in @('-C','-c','--git-dir','--work-tree','--namespace','--super-prefix','--exec-path','--config-env')) { $i += 2 } else { $i++ }
    }
    if ($i -ge $t.Count) { return }
    $verb = $t[$i].ToLowerInvariant(); $a = @(); if ($i + 1 -lt $t.Count) { $a = @($t[($i + 1)..($t.Count - 1)]) }
    if ($verb -eq 'push' -and @($a | Where-Object { $_ -in @('--force','--force-with-lease','--force-if-includes','--mirror') -or $_ -match '^--force-' -or $_ -match '^--mir' -or $_ -match '^-[^-]*f' -or $_ -match '^\+' }).Count) { return 'Blocked destructive Git command: direct git push with force or mirror.' }
    if ($verb -eq 'reset' -and @($a | Where-Object { $_ -ceq '--hard' -or $_ -match '^--har' }).Count) { return 'Blocked destructive Git command: direct git reset --hard.' }
    if ($verb -ne 'clean') { return }
    $force = $false; $dry = $false
    for ($j = 0; $j -lt $a.Count; $j++) {
        $x = $a[$j]
        if ($x -ceq '--') { break }
        if ($x -ceq '--force' -or $x -match '^--for') { $force = $true } elseif ($x -ceq '--no-force') { $force = $false }
        elseif ($x -ceq '--dry-run') { $dry = $true } elseif ($x -ceq '--no-dry-run') { $dry = $false }
        elseif ($x -ceq '--exclude' -and $j + 1 -lt $a.Count) { $j++ } elseif ($x -match '^--exclude=') { continue }
        elseif ($x -match '^-[^-].*') {
            $s = $x.Substring(1)
            for ($k = 0; $k -lt $s.Length; $k++) {
                $c = $s[$k]
                if ($c -ceq 'e') {
                    if ($k + 1 -eq $s.Length -and $j + 1 -lt $a.Count) { $j++ }
                    break
                }
                if ($c -ceq 'f') { $force = $true } elseif ($c -ceq 'n') { $dry = $true }
            }
        }
    }
    if ($force -and !$dry) { return 'Blocked destructive Git command: direct git clean with force.' }
}

function Get-Reason([string]$Command) {
    $segment = @()
    foreach ($token in @(Get-Tokens $Command)) {
        if ($token -match '^[\r\n;&|]$') { $reason = Get-Block $segment; if ($reason) { return $reason }; $segment = @() } else { $segment += $token }
    }
    Get-Block $segment
}

$raw = [Console]::In.ReadToEnd(); $command = $raw
try { $p = $raw | ConvertFrom-Json; if ($p.tool_input -and $p.tool_input.command -is [string]) { $command = $p.tool_input.command } elseif ($p.command -is [string]) { $command = $p.command } } catch { }

if ($SelfTest) {
    $cases = @(
        @{ c='git status'; b=$false }; @{ c='git push --force origin main'; b=$true }; @{ c='git push --force-with-lease origin main'; b=$true }; @{ c='git push +HEAD:main'; b=$true }; @{ c='git push --mirror origin'; b=$true }
        @{ c='git reset --hard HEAD~1'; b=$true }; @{ c='git clean -f -d'; b=$true }; @{ c='git clean --force'; b=$true }; @{ c='git clean -f -n'; b=$false }; @{ c='git clean -n -f'; b=$false }
        @{ c='git clean -f -n --no-dry-run'; b=$true }; @{ c='git clean -f --no-dry-run -n'; b=$false }; @{ c='git clean --force --no-force'; b=$false }; @{ c='git clean --no-force --force'; b=$true }; @{ c='git clean -f -e -n'; b=$true }
        @{ c='git -C "path;with spaces" reset --hard'; b=$true }; @{ c='git --no-pager reset --hard'; b=$true }; @{ c='git -c alias.p="push --force" p origin main'; b=$false }
        @{ c='git status; git push -f origin main'; b=$true }; @{ c='echo "git push --force"'; b=$false }; @{ c="sh -c 'git reset --hard'"; b=$false }; @{ c='powershell -EncodedCommand Zwk='; b=$false }
        @{ c='git push --force-with-lease=refs/heads/main:abc'; b=$true }; @{ c='git push --force-w origin main'; b=$true }; @{ c='git push --mirr origin'; b=$true }
        @{ c='git reset --har'; b=$true }; @{ c='git clean --forc -d'; b=$true }; @{ c='git clean -fen'; b=$true }
    )
    $results = foreach ($case in $cases) { $blocked = $null -ne (Get-Reason $case.c); [ordered]@{ command=$case.c; blocked=$blocked; passed=($blocked -eq $case.b) } }
    $smokeCommand = 'git reset --hard HEAD'
    $smokeInput = [ordered]@{ tool_input = [ordered]@{ command = $smokeCommand } } | ConvertTo-Json -Compress
    $smokeOutput = $smokeInput | & (Get-Process -Id $PID).Path -NoProfile -File $PSCommandPath
    $smokeText = (@($smokeOutput) -join [Environment]::NewLine).Trim()
    $smokePassed = $false
    try { $smoke = $smokeText | ConvertFrom-Json; $smokePassed = $smoke.hookSpecificOutput.permissionDecision -eq 'deny' } catch { }
    $results += [ordered]@{ command="JSON stdin: $smokeCommand"; blocked=$smokePassed; passed=$smokePassed }
    $results | ConvertTo-Json -Compress; if (@($results | Where-Object { !$_.passed }).Count) { exit 1 }; exit 0
}

$reason = Get-Reason $command
if ($reason) { [ordered]@{ hookSpecificOutput=[ordered]@{ hookEventName='PreToolUse'; permissionDecision='deny'; permissionDecisionReason=$reason } } | ConvertTo-Json -Compress }
exit 0
