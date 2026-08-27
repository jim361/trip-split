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

    # Inspect each shell command segment. Newlines are treated as command separators.
    $segments = $Command -replace '[\r\n]+', ';'
    $gitCommandPattern = '(?i)(?:^|(?<=[\s;&|({]))git(?:\.exe)?\s+(?<verb>push|reset|clean)\b(?<args>[^;&|)}]*)'

    foreach ($match in [regex]::Matches($segments, $gitCommandPattern)) {
        $verb = $match.Groups['verb'].Value.ToLowerInvariant()
        $args = $match.Groups['args'].Value.Trim()

        switch ($verb) {
            'push' {
                if ([regex]::IsMatch($args, '(?i)(?:^|\s)--force(?:-with-lease)?(?=\s|$|=)')) {
                    return 'Blocked destructive Git command: git push with --force or --force-with-lease.'
                }
            }
            'reset' {
                if ([regex]::IsMatch($args, '(?i)(?:^|\s)--hard(?=\s|$)')) {
                    return 'Blocked destructive Git command: git reset --hard.'
                }
            }
            'clean' {
                $shortForce = [regex]::IsMatch($args, '(?i)(?:^|\s)-[a-z]*f[a-z]*(?=\s|$)')
                $shortDirectory = [regex]::IsMatch($args, '(?i)(?:^|\s)-[a-z]*d[a-z]*(?=\s|$)')
                $longForce = [regex]::IsMatch($args, '(?i)(?:^|\s)--force(?=\s|$)')
                $longDirectory = [regex]::IsMatch($args, '(?i)(?:^|\s)--directory(?=\s|$)')

                if (($shortForce -or $longForce) -and ($shortDirectory -or $longDirectory)) {
                    return 'Blocked destructive Git command: git clean -fd (force plus directory flags).'
                }
            }
        }
    }

    return $null
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
        @{ Command = 'git push --force-with-lease'; ExpectedBlocked = $true }
        @{ Command = 'git reset --hard HEAD~1'; ExpectedBlocked = $true }
        @{ Command = 'git clean -fd'; ExpectedBlocked = $true }
        @{ Command = 'git clean -dfx'; ExpectedBlocked = $true }
        @{ Command = 'git clean -f -d'; ExpectedBlocked = $true }
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
        $reason = Get-DangerousCommandReason -Command $testCase.Command
        $blocked = $null -ne $reason
        $passed = if ($null -eq $testCase.ExpectedBlocked) { $true } else { $blocked -eq $testCase.ExpectedBlocked }
        [ordered]@{
            command = $testCase.Command
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
