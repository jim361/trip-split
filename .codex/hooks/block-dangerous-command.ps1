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

    # Keep a queue of tokenized commands. Wrapper payloads are parsed as text;
    # they are never evaluated or passed to a shell.
    $segments = [System.Collections.Generic.List[object]]::new()
    foreach ($segment in (Split-ShellCommandSegments -Command $Command)) {
        [void]$segments.Add($segment)
    }

    $segmentIndex = 0
    while ($segmentIndex -lt $segments.Count) {
        $segment = $segments[$segmentIndex]
        $segmentIndex++

        $invocation = Get-GitInvocation -Tokens $segment.Tokens
        if ($null -ne $invocation) {
            $verb = $invocation.Verb
            $args = $invocation.Arguments

            switch ($verb) {
                'push' {
                    if (Test-GitPushForce -Arguments $args) {
                        return 'Blocked destructive Git command: git push with force or mirror.'
                    }
                }
                'reset' {
                    if (Test-GitResetHard -Arguments $args) {
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

        foreach ($payload in @(Get-ShellCommandPayload -Tokens $segment.Tokens)) {
            if ([string]::IsNullOrWhiteSpace($payload)) {
                continue
            }

            foreach ($nestedSegment in (Split-ShellCommandSegments -Command $payload)) {
                [void]$segments.Add($nestedSegment)
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

function Get-GitLongOptions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Verb
    )

    # Keep these lists in sync with the command-specific options exposed by
    # Git. Git accepts a long-option abbreviation only when it identifies one
    # option uniquely; resolving against a command-specific list prevents an
    # ambiguous prefix such as `git push --for` from being treated as force.
    switch ($Verb.ToLowerInvariant()) {
        'push' {
            return [string[]]@(
                'verbose', 'quiet', 'repo', 'all', 'branches', 'mirror',
                'delete', 'tags', 'dry-run', 'porcelain', 'force',
                'force-with-lease', 'force-if-includes', 'recurse-submodules',
                'thin', 'receive-pack', 'exec', 'set-upstream', 'progress',
                'prune', 'verify', 'no-verify', 'follow-tags', 'signed',
                'atomic', 'push-option', 'ipv4', 'ipv6'
            )
        }
        'reset' {
            return [string[]]@(
                'no-refresh', 'refresh', 'mixed', 'soft', 'hard', 'merge',
                'keep', 'recurse-submodules', 'patch', 'unified',
                'inter-hunk-context', 'intent-to-add', 'pathspec-from-file',
                'pathspec-file-nul', 'stdin'
            )
        }
        'clean' {
            return [string[]]@('quiet', 'dry-run', 'force', 'interactive', 'exclude')
        }
        default {
            return [string[]]@()
        }
    }
}

function Resolve-GitLongOption {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Argument,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$ValidOptions
    )

    if (-not $Argument.StartsWith('--') -or $Argument.Length -le 2) {
        return $null
    }

    $body = $Argument.Substring(2)
    $equalsIndex = $body.IndexOf('=')
    if ($equalsIndex -ge 0) {
        $name = $body.Substring(0, $equalsIndex)
    }
    else {
        $name = $body
    }

    if ([string]::IsNullOrWhiteSpace($name)) {
        return $null
    }

    $negated = $false
    $hasValue = $equalsIndex -ge 0
    if ($name.StartsWith('no-', [System.StringComparison]::Ordinal)) {
        $negated = $true
        $name = $name.Substring(3)
    }

    # Git's --no- form is only meaningful for options that support negation;
    # the dangerous options below all do, and non-dangerous options remain
    # harmless even if an invalid --no-* spelling is supplied.
    $exact = @($ValidOptions | Where-Object {
            $_.Equals($name, [System.StringComparison]::Ordinal)
        })
    if ($exact.Count -eq 1) {
        return [pscustomobject]@{
            Canonical = $exact[0]
            Negated   = $negated
            HasValue  = $hasValue
        }
    }

    $candidates = @($ValidOptions | Where-Object {
            $_.StartsWith($name, [System.StringComparison]::Ordinal)
        })
    if ($candidates.Count -ne 1) {
        return $null
    }

    [pscustomobject]@{
        Canonical = $candidates[0]
        Negated   = $negated
        HasValue  = $hasValue
    }
}

function Get-ShellWrapperStartIndex {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Tokens
    )

    $index = 0
    while ($index -lt $Tokens.Count -and (Test-EnvironmentAssignment -Token $Tokens[$index])) {
        $index++
    }

    # Match the same transparent wrappers accepted by Get-GitInvocation. This
    # only finds a command head; words later in an echo/string are untouched.
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

    return $index
}

function Get-ShellCommandPayload {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Tokens
    )

    $index = Get-ShellWrapperStartIndex -Tokens $Tokens
    if ($index -ge $Tokens.Count) {
        return @()
    }

    $shell = ($Tokens[$index] -split '[\\/]')[-1].ToLowerInvariant()
    if ($shell.EndsWith('.exe') -or $shell.EndsWith('.cmd')) {
        $shell = $shell.Substring(0, $shell.Length - 4)
    }

    $shellKind = $null
    if ($shell -eq 'sh' -or $shell -eq 'bash' -or $shell -eq 'dash' -or $shell -eq 'zsh' -or $shell -eq 'ksh' -or $shell -eq 'ash' -or $shell -eq 'fish') {
        $shellKind = 'posix'
    }
    elseif ($shell -eq 'pwsh' -or $shell -eq 'powershell') {
        $shellKind = 'powershell'
    }
    elseif ($shell -eq 'cmd') {
        $shellKind = 'cmd'
    }
    else {
        return @()
    }

    $switchIndex = -1
    for ($optionIndex = $index + 1; $optionIndex -lt $Tokens.Count; $optionIndex++) {
        $option = $Tokens[$optionIndex]
        if ($shellKind -eq 'cmd' -and -not $option.StartsWith('/')) {
            # After cmd.exe reaches its command text, a later literal `/c`
            # belongs to that command and must not be treated as a cmd switch.
            break
        }
        if (($shellKind -eq 'posix' -and $option -cmatch '^-[^-]*c[^-]*$') -or
            ($shellKind -eq 'powershell' -and (Test-PowerShellCommandSwitch -Option $option)) -or
            ($shellKind -eq 'cmd' -and (Test-CmdCommandSwitch -Option $option))) {
            $switchIndex = $optionIndex
            break
        }
    }

    if ($switchIndex -lt 0 -or ($switchIndex + 1) -ge $Tokens.Count) {
        return @()
    }

    if ($shellKind -eq 'posix') {
        # `sh -c` consumes exactly one command-string argument; any following
        # argument is the shell's $0 and is not part of that command string.
        return [string[]]@($Tokens[$switchIndex + 1])
    }

    # PowerShell -Command and cmd /c consume the remainder when the payload
    # was not quoted as one token. Joining here reconstructs that command as
    # text for the tokenizer without executing it.
    return [string[]]@($Tokens[($switchIndex + 1)..($Tokens.Count - 1)] -join ' ')
}

function Test-PowerShellCommandSwitch {
    param([string]$Option)

    # PowerShell accepts case-insensitive, unambiguous prefixes of -Command.
    # Restrict prefix matching to the actual word "command" so -Configuration
    # and other unrelated switches are not treated as command payloads.
    if (-not $Option.StartsWith('-') -or $Option.Length -le 1) {
        return $false
    }

    $name = $Option.Substring(1)
    return 'command'.StartsWith($name, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-CmdCommandSwitch {
    param([string]$Option)

    if ($Option -ieq '/c') {
        return $true
    }

    # cmd.exe accepts slash-delimited switch bundles such as /d/s/c and /d/c.
    # Only recognize documented switches before the final /c so arbitrary
    # slash-containing arguments are not reinterpreted as command payloads.
    if (-not $Option.StartsWith('/')) {
        return $false
    }

    $parts = @($Option.Substring(1).Split('/'))
    if ($parts.Count -lt 2 -or $parts[-1] -ine 'c') {
        return $false
    }

    foreach ($part in $parts[0..($parts.Count - 2)]) {
        if ($part -notmatch '^(?i:d|q|a|u|s|e:(?:on|off)|f:(?:on|off)|v:(?:on|off))$') {
            return $false
        }
    }

    return $true
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

    $validOptions = Get-GitLongOptions -Verb 'push'
    foreach ($argument in $Arguments) {
        $resolved = Resolve-GitLongOption -Argument $argument -ValidOptions $validOptions
        if ($null -ne $resolved -and -not $resolved.Negated -and ($resolved.Canonical -eq 'force' -or $resolved.Canonical -eq 'force-with-lease' -or $resolved.Canonical -eq 'force-if-includes' -or $resolved.Canonical -eq 'mirror')) {
            return $true
        }
        if ($argument -cmatch '^-[^-]*f[^-]*$') {
            return $true
        }
        if ($argument -match '^\+.+$') {
            return $true
        }
    }
    return $false
}

function Test-GitResetHard {
    param([string[]]$Arguments)

    $validOptions = Get-GitLongOptions -Verb 'reset'
    foreach ($argument in $Arguments) {
        $resolved = Resolve-GitLongOption -Argument $argument -ValidOptions $validOptions
        if ($null -ne $resolved -and -not $resolved.Negated -and $resolved.Canonical -eq 'hard') {
            return $true
        }
    }
    return $false
}

function Test-GitCleanDestructive {
    param([string[]]$Arguments)

    $validOptions = Get-GitLongOptions -Verb 'clean'
    $force = $false
    $dryRun = $false
    $argumentIndex = 0
    while ($argumentIndex -lt $Arguments.Count) {
        $argument = $Arguments[$argumentIndex]

        if ($argument -ceq '--') {
            break
        }

        $resolved = Resolve-GitLongOption -Argument $argument -ValidOptions $validOptions
        if ($null -ne $resolved) {
            if ($resolved.Canonical -ceq 'exclude') {
                if (-not $resolved.HasValue -and ($argumentIndex + 1) -lt $Arguments.Count) {
                    $argumentIndex++
                }
            }
            elseif ($resolved.Canonical -ceq 'dry-run') {
                # Git boolean options use the last positive or --no-* spelling.
                $dryRun = -not $resolved.Negated
            }
            elseif ($resolved.Canonical -ceq 'force') {
                $force = -not $resolved.Negated
            }

            $argumentIndex++
            continue
        }

        if ($argument -cmatch '^-[^-].*$') {
            $shortOptions = $argument.Substring(1)
            $shortIndex = 0
            $excludeConsumesNext = $false
            while ($shortIndex -lt $shortOptions.Length) {
                $shortOption = [string]$shortOptions[$shortIndex]
                if ($shortOption -ceq 'e') {
                    # `-e` consumes the rest of this token as its pattern, or
                    # the next token when no attached pattern exists. A value
                    # such as `-n` must not be reinterpreted as dry-run.
                    $excludeConsumesNext = ($shortIndex + 1) -ge $shortOptions.Length
                    break
                }
                if ($shortOption -ceq 'f') {
                    $force = $true
                }
                elseif ($shortOption -ceq 'n') {
                    $dryRun = $true
                }
                $shortIndex++
            }

            if ($excludeConsumesNext -and ($argumentIndex + 1) -lt $Arguments.Count) {
                $argumentIndex++
            }
        }

        $argumentIndex++
    }

    # The effective final dry-run state wins; a later --no-dry-run re-enables
    # destructive execution and a later -n/--dry-run makes the command safe.
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
        @{ Command = 'git push --force-w origin main'; ExpectedBlocked = $true }
        @{ Command = 'git push --force-i origin main'; ExpectedBlocked = $true }
        @{ Command = 'git push --for origin main'; ExpectedBlocked = $false }
        @{ Command = 'git push --force-z origin main'; ExpectedBlocked = $false }
        @{ Command = 'git push --mirror origin'; ExpectedBlocked = $true }
        @{ Command = 'git push --mir origin'; ExpectedBlocked = $true }
        @{ Command = 'git push --no-mirror origin'; ExpectedBlocked = $false }
        @{ Command = 'git push origin +HEAD:main'; ExpectedBlocked = $true }
        @{ Command = "git status`ngit push origin +HEAD:main"; ExpectedBlocked = $true }
        @{ Command = 'git push --no-force origin main'; ExpectedBlocked = $false }
        @{ Command = 'git -C "path with spaces" --no-pager -c core.foo=bar reset --hard HEAD~1'; ExpectedBlocked = $true }
        @{ Command = 'git.exe -C "path;with spaces" reset --hard'; ExpectedBlocked = $true }
        @{ Command = 'git reset --har HEAD~1'; ExpectedBlocked = $true }
        @{ Command = 'git reset --ha HEAD~1'; ExpectedBlocked = $true }
        @{ Command = 'git reset --hardx HEAD~1'; ExpectedBlocked = $false }
        @{ Command = 'git reset --hard HEAD~1; git status'; ExpectedBlocked = $true }
        @{ Command = 'git clean -fd'; ExpectedBlocked = $true }
        @{ Command = 'git clean -dfx'; ExpectedBlocked = $true }
        @{ Command = 'git clean -f -d'; ExpectedBlocked = $true }
        @{ Command = 'git clean --force'; ExpectedBlocked = $true }
        @{ Command = 'git clean --for -d'; ExpectedBlocked = $true }
        @{ Command = 'git clean --fo -d'; ExpectedBlocked = $true }
        @{ Command = 'git clean --f -d'; ExpectedBlocked = $true }
        @{ Command = 'git clean --forcex -d'; ExpectedBlocked = $false }
        @{ Command = 'git clean --dr -d'; ExpectedBlocked = $false }
        @{ Command = 'git clean -fdn'; ExpectedBlocked = $false }
        @{ Command = 'git clean -f -n --no-dry-run'; ExpectedBlocked = $true }
        @{ Command = 'git clean -f --no-dry-run -n'; ExpectedBlocked = $false }
        @{ Command = 'git clean --force --no-force -d'; ExpectedBlocked = $false }
        @{ Command = 'git clean --no-force --force -d'; ExpectedBlocked = $true }
        @{ Command = 'git clean --dry-run --no-dry-run --force'; ExpectedBlocked = $true }
        @{ Command = 'git clean --no-dry-run --dry-run --force'; ExpectedBlocked = $false }
        @{ Command = 'git clean -f -e -n'; ExpectedBlocked = $true }
        @{ Command = 'git clean -f --ex -n'; ExpectedBlocked = $true }
        @{ Command = 'git clean -f -e-n'; ExpectedBlocked = $true }
        @{ Command = 'git clean -f -e pattern -n'; ExpectedBlocked = $false }
        @{ Command = 'git clean -fn -e pattern'; ExpectedBlocked = $false }
        @{ Command = 'git clean -f -- -n'; ExpectedBlocked = $true }
        @{ Command = 'git checkout --theirs conflict.txt'; ExpectedBlocked = $false }
        @{ Command = 'git checkout feature'; ExpectedBlocked = $false }
        @{ Command = 'git restore --staged file'; ExpectedBlocked = $false }
        @{ Command = 'echo "git push --force"'; ExpectedBlocked = $false }
        @{ Command = "sh -c 'git reset --hard'"; ExpectedBlocked = $true }
        @{ Command = "bash -lc 'git reset --hard'"; ExpectedBlocked = $true }
        @{ Command = "sh -xc 'git push --force origin main'"; ExpectedBlocked = $true }
        @{ Command = 'powershell -NoProfile -Command "git push --force-w origin main"'; ExpectedBlocked = $true }
        @{ Command = 'pwsh -Command "git clean --for -d"'; ExpectedBlocked = $true }
        @{ Command = 'pwsh -C "git reset --hard"'; ExpectedBlocked = $true }
        @{ Command = 'pwsh -Co "git reset --hard"'; ExpectedBlocked = $true }
        @{ Command = 'pwsh -Com "git reset --hard"'; ExpectedBlocked = $true }
        @{ Command = 'powershell -Com "git push --force origin main"'; ExpectedBlocked = $true }
        @{ Command = 'cmd /d /c "git push --mirror origin"'; ExpectedBlocked = $true }
        @{ Command = 'cmd /d/s/c "git reset --hard"'; ExpectedBlocked = $true }
        @{ Command = 'cmd /s/d/c "git reset --hard"'; ExpectedBlocked = $true }
        @{ Command = 'cmd /d/c "git push --force origin main"'; ExpectedBlocked = $true }
        @{ Command = "sh -c 'echo git reset --hard'"; ExpectedBlocked = $false }
        @{ Command = "bash -lc 'echo git reset --hard'"; ExpectedBlocked = $false }
        @{ Command = 'powershell -Command "Write-Output ''git push --force''"'; ExpectedBlocked = $false }
        @{ Command = 'pwsh -Com "Write-Output ''git reset --hard''"'; ExpectedBlocked = $false }
        @{ Command = 'powershell -ConfigurationName local "git reset --hard"'; ExpectedBlocked = $false }
        @{ Command = 'cmd /c "echo git clean --force -d"'; ExpectedBlocked = $false }
        @{ Command = 'cmd /d/s/c "echo git push --force"'; ExpectedBlocked = $false }
        @{ Command = 'cmd echo /c "git reset --hard"'; ExpectedBlocked = $false }
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
