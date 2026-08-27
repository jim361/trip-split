[CmdletBinding()]
param(
    [switch]$TestRawInput,
    [Alias('RawInput')]
    [string]$RawCommand
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-DangerousCommandReason {
    param(
        [AllowEmptyString()]
        [string]$Command
    )

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return $null
    }

    foreach ($segment in (Split-ShellCommandSegments -Command $Command)) {
        $invocation = Get-GitInvocation -Tokens $segment.Tokens
        if ($null -eq $invocation) {
            continue
        }

        $verb = $invocation.Verb
        $args = $invocation.Arguments

        switch ($verb) {
            'push' {
                if (Test-GitPushForce -Arguments $args) {
                    return 'Blocked destructive Git command: forced git push.'
                }
            }
            'reset' {
                if ($args -contains '--hard') {
                    return 'Blocked destructive Git command: git reset --hard.'
                }
            }
            'clean' {
                if (Test-GitCleanDestructive -Arguments $args) {
                    return 'Blocked destructive Git command: git clean with a force flag.'
                }
            }
        }
    }

    return $null
}

function Add-ShellToken {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Tokens,
        [Parameter(Mandatory = $true)]
        [System.Text.StringBuilder]$Builder,
        [Parameter(Mandatory = $true)]
        [ref]$TokenStarted
    )

    if ($TokenStarted.Value) {
        [void]$Tokens.Add($Builder.ToString())
        [void]$Builder.Clear()
        $TokenStarted.Value = $false
    }
}

function Add-ShellSegment {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Segments,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Tokens,
        [Parameter(Mandatory = $true)]
        [System.Text.StringBuilder]$Builder,
        [Parameter(Mandatory = $true)]
        [ref]$TokenStarted
    )

    Add-ShellToken -Tokens $Tokens -Builder $Builder -TokenStarted $TokenStarted
    if ($Tokens.Count -gt 0) {
        [void]$Segments.Add([pscustomobject]@{ Tokens = [string[]]$Tokens.ToArray() })
        [void]$Tokens.Clear()
    }
}

function Split-ShellCommandSegments {
    param(
        [AllowEmptyString()]
        [string]$Command
    )

    # Tokenize enough shell syntax to keep quoted paths intact and inspect every
    # command in a chain. This is deliberately not a shell parser and never
    # evaluates substitutions or escapes.
    $segments = [System.Collections.Generic.List[object]]::new()
    $tokens = [System.Collections.Generic.List[string]]::new()
    $builder = [System.Text.StringBuilder]::new()
    $quote = [char]0
    $tokenStarted = $false

    for ($index = 0; $index -lt $Command.Length; $index++) {
        $character = $Command[$index]

        if ($quote -ne [char]0) {
            if ($quote -eq '"' -and $character -eq '\' -and ($index + 1) -lt $Command.Length -and $Command[$index + 1] -eq '"') {
                $index++
                [void]$builder.Append('"')
                $tokenStarted = $true
                continue
            }
            if ($character -eq $quote) {
                $quote = [char]0
                $tokenStarted = $true
            }
            else {
                [void]$builder.Append($character)
                $tokenStarted = $true
            }
            continue
        }

        if ($character -eq "'") {
            $quote = $character
            $tokenStarted = $true
            continue
        }
        if ($character -eq '"') {
            $quote = $character
            $tokenStarted = $true
            continue
        }

        # In an unquoted shell word, only treat backslash as an escape when it
        # precedes syntax. Otherwise preserve Windows paths such as C:\repo.
        if ($character -eq '\' -and ($index + 1) -lt $Command.Length) {
            $next = $Command[$index + 1]
            if ([char]::IsWhiteSpace($next) -or $next -eq '\' -or $next -eq ';' -or $next -eq '|' -or $next -eq '&' -or $next -eq "'" -or $next -eq '"') {
                $index++
                [void]$builder.Append($next)
                $tokenStarted = $true
                continue
            }
        }

        if ($character -eq "`r" -or $character -eq "`n") {
            Add-ShellSegment -Segments $segments -Tokens $tokens -Builder $builder -TokenStarted ([ref]$tokenStarted)
            continue
        }

        if ([char]::IsWhiteSpace($character)) {
            Add-ShellToken -Tokens $tokens -Builder $builder -TokenStarted ([ref]$tokenStarted)
            continue
        }

        if ($character -eq ';' -or $character -eq '(' -or $character -eq ')' -or $character -eq '{' -or $character -eq '}' -or $character -eq '`') {
            Add-ShellSegment -Segments $segments -Tokens $tokens -Builder $builder -TokenStarted ([ref]$tokenStarted)
            continue
        }

        if ($character -eq '|' -or $character -eq '&') {
            Add-ShellSegment -Segments $segments -Tokens $tokens -Builder $builder -TokenStarted ([ref]$tokenStarted)
            if (($index + 1) -lt $Command.Length -and $Command[$index + 1] -eq $character) {
                $index++
            }
            continue
        }

        [void]$builder.Append($character)
        $tokenStarted = $true
    }

    Add-ShellSegment -Segments $segments -Tokens $tokens -Builder $builder -TokenStarted ([ref]$tokenStarted)
    return $segments.ToArray()
}

function Test-EnvironmentAssignment {
    param([string]$Token)

    return $Token -match '^[A-Za-z_][A-Za-z0-9_]*=.*$'
}

function Test-GitExecutable {
    param([string]$Token)

    # Accept the normal command name as well as an absolute path and the
    # Windows .exe/.cmd forms. A later argument containing the word "git" is
    # intentionally not considered a command.
    return $Token -match '(?i)(?:^|[\\/])git(?:\.exe|\.cmd)?$'
}

function Get-GitInvocation {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Tokens
    )

    if ($Tokens.Count -eq 0) {
        return $null
    }

    $index = 0
    while ($index -lt $Tokens.Count -and (Test-EnvironmentAssignment -Token $Tokens[$index])) {
        $index++
    }

    # Handle common transparent wrappers without treating arbitrary arguments
    # (for example `echo git push --force`) as a Git invocation.
    while ($index -lt $Tokens.Count) {
        $wrapper = $Tokens[$index].ToLowerInvariant()
        if ($wrapper -eq 'command' -or $wrapper -eq 'exec') {
            $index++
            continue
        }
        if ($wrapper -eq 'env') {
            $index++
            while ($index -lt $Tokens.Count -and (Test-EnvironmentAssignment -Token $Tokens[$index])) {
                $index++
            }
            while ($index -lt $Tokens.Count -and $Tokens[$index].StartsWith('-')) {
                if ($Tokens[$index] -eq '--') {
                    $index++
                    break
                }
                if ($Tokens[$index] -eq '-u' -or $Tokens[$index] -eq '--unset' -or $Tokens[$index] -eq '-C' -or $Tokens[$index] -eq '--chdir' -or $Tokens[$index] -eq '-S' -or $Tokens[$index] -eq '--split-string') {
                    $index += 2
                }
                else {
                    $index++
                }
            }
            while ($index -lt $Tokens.Count -and (Test-EnvironmentAssignment -Token $Tokens[$index])) {
                $index++
            }
            continue
        }
        if ($wrapper -eq 'sudo') {
            $index++
            while ($index -lt $Tokens.Count -and $Tokens[$index].StartsWith('-')) {
                if ($Tokens[$index] -eq '-u' -or $Tokens[$index] -eq '--user' -or $Tokens[$index] -eq '-g' -or $Tokens[$index] -eq '--group') {
                    $index += 2
                }
                else {
                    $index++
                }
            }
            continue
        }
        break
    }

    if ($index -ge $Tokens.Count -or -not (Test-GitExecutable -Token $Tokens[$index])) {
        return $null
    }
    $index++

    # Git's global options precede the subcommand. Resolve options that take a
    # separate value so `git -C "quoted path" reset --hard` is normalized to
    # the same invocation as `git reset --hard`.
    while ($index -lt $Tokens.Count) {
        $option = $Tokens[$index]
        if ($option -eq '--') {
            return $null
        }

        if ($option -eq '-C' -or $option -eq '-c' -or $option -eq '--git-dir' -or $option -eq '--work-tree' -or $option -eq '--namespace' -or $option -eq '--super-prefix' -or $option -eq '--exec-path' -or $option -eq '--config-env') {
            $index += 2
            continue
        }
        if ($option.StartsWith('-C') -and $option.Length -gt 2) {
            $index++
            continue
        }
        if ($option.StartsWith('-c') -and $option.Length -gt 2) {
            $index++
            continue
        }
        if ($option -match '^(?i)--(?:git-dir|work-tree|namespace|super-prefix|exec-path|config-env)=') {
            $index++
            continue
        }
        if ($option.StartsWith('-')) {
            # Unknown global options are skipped conservatively; the first
            # non-option token remains the Git subcommand.
            $index++
            continue
        }
        break
    }

    if ($index -ge $Tokens.Count) {
        return $null
    }

    [pscustomobject]@{
        Verb      = $Tokens[$index].ToLowerInvariant()
        Arguments = if (($index + 1) -lt $Tokens.Count) { [string[]]$Tokens[($index + 1)..($Tokens.Count - 1)] } else { [string[]]@() }
    }
}

function Test-GitPushForce {
    param([string[]]$Arguments)

    foreach ($argument in $Arguments) {
        if ($argument -match '^(?i)--(?:force|force-with-lease|force-if-includes)(?:=.*)?$') {
            return $true
        }
        if ($argument -match '^(?i)-[^-]*f[^-]*$') {
            return $true
        }
        if ($argument -match '^\+.+$') {
            return $true
        }
    }
    return $false
}

function Test-GitCleanDestructive {
    param([string[]]$Arguments)

    $force = $false
    $dryRun = $false
    foreach ($argument in $Arguments) {
        if ($argument -eq '-n' -or $argument -eq '--dry-run' -or $argument -match '^(?i)-[^-]*n[^-]*$') {
            $dryRun = $true
            continue
        }
        if ($argument -match '^(?i)--force(?:=.*)?$' -or $argument -match '^(?i)-[^-]*f[^-]*$') {
            $force = $true
        }
    }

    # `-n`/`--dry-run` never removes files, even when force is also present.
    return $force -and -not $dryRun
}

function Get-CommandFromRawInput {
    param(
        [AllowEmptyString()]
        [string]$RawInput
    )

    if ([string]::IsNullOrWhiteSpace($RawInput)) {
        return $null
    }

    $trimmed = $RawInput.Trim()
    if ($trimmed.StartsWith('{')) {
        try {
            $payload = $trimmed | ConvertFrom-Json
            if ($null -ne $payload.tool_input -and $payload.tool_input.command -is [string]) {
                return [string]$payload.tool_input.command
            }
            if ($payload.command -is [string]) {
                return [string]$payload.command
            }
        }
        catch {
            return $null
        }

        return $null
    }

    return $RawInput
}

function Write-DenyDecision {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Reason
    )

    [ordered]@{
        hookSpecificOutput = [ordered]@{
            hookEventName          = 'PreToolUse'
            permissionDecision     = 'deny'
            permissionDecisionReason = $Reason
        }
    } | ConvertTo-Json -Compress
}

if ($TestRawInput) {
    $testCases = @(
        @{ Command = 'git status'; ExpectedBlocked = $false }
        @{ Command = 'git push origin main --force'; ExpectedBlocked = $true }
        @{ Command = 'git push -f origin main'; ExpectedBlocked = $true }
        @{ Command = 'git push --force-with-lease'; ExpectedBlocked = $true }
        @{ Command = 'git push --force-if-includes'; ExpectedBlocked = $true }
        @{ Command = 'git push origin +HEAD:main'; ExpectedBlocked = $true }
        @{ Command = "git status`ngit push origin +HEAD:main"; ExpectedBlocked = $true }
        @{ Command = 'git push --no-force origin main'; ExpectedBlocked = $false }
        @{ Command = 'git -C "path with spaces" --no-pager -c core.foo=bar reset --hard HEAD~1'; ExpectedBlocked = $true }
        @{ Command = 'git.exe -C "path;with spaces" reset --hard'; ExpectedBlocked = $true }
        @{ Command = 'git reset --hard HEAD~1; git status'; ExpectedBlocked = $true }
        @{ Command = 'git clean -fd'; ExpectedBlocked = $true }
        @{ Command = 'git clean -dfx'; ExpectedBlocked = $true }
        @{ Command = 'git clean -f -d'; ExpectedBlocked = $true }
        @{ Command = 'git clean --force'; ExpectedBlocked = $true }
        @{ Command = 'git clean -fdn'; ExpectedBlocked = $false }
        @{ Command = 'git checkout --theirs conflict.txt'; ExpectedBlocked = $false }
        @{ Command = 'git checkout feature'; ExpectedBlocked = $false }
        @{ Command = 'git restore --staged file'; ExpectedBlocked = $false }
        @{ Command = 'echo "git push --force"'; ExpectedBlocked = $false }
        @{ Command = 'git clean -n'; ExpectedBlocked = $false }
    )

    if (-not [string]::IsNullOrWhiteSpace($RawCommand)) {
        $testCases = @(@{ Command = (Get-CommandFromRawInput -RawInput $RawCommand); ExpectedBlocked = $null })
    }
    elseif ([Console]::IsInputRedirected) {
        $pipedInput = [Console]::In.ReadToEnd()
        if (-not [string]::IsNullOrWhiteSpace($pipedInput)) {
            $testCases = @(@{ Command = (Get-CommandFromRawInput -RawInput $pipedInput); ExpectedBlocked = $null })
        }
    }

    $results = foreach ($testCase in $testCases) {
        # Exercise the same JSON shape supplied by a PreToolUse hook, rather
        # than testing only the internal command-string helper.
        $hookInput = [ordered]@{
            hook_event_name = 'PreToolUse'
            tool_name       = 'Bash'
            tool_input      = [ordered]@{ command = $testCase.Command }
        } | ConvertTo-Json -Compress
        $parsedCommand = Get-CommandFromRawInput -RawInput $hookInput
        $reason = Get-DangerousCommandReason -Command $parsedCommand
        $blocked = $null -ne $reason
        $passed = if ($null -eq $testCase.ExpectedBlocked) { $true } else { $blocked -eq $testCase.ExpectedBlocked }
        [ordered]@{
            command = $parsedCommand
            blocked = $blocked
            expectedBlocked = $testCase.ExpectedBlocked
            passed = $passed
        }
    }

    $results | ConvertTo-Json -Compress
    if (@($results | Where-Object { -not $_.passed }).Count -gt 0) {
        exit 1
    }
    exit 0
}

$rawInput = [Console]::In.ReadToEnd()
$command = Get-CommandFromRawInput -RawInput $rawInput
$reason = Get-DangerousCommandReason -Command $command

if ($null -ne $reason) {
    Write-DenyDecision -Reason $reason
}

exit 0
