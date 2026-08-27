[CmdletBinding()]
param(
  [ValidateSet("Fast", "Full")]
  [string]$Mode = "Fast"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:FailureKind = $null
$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Stop-Verification {
  param([Parameter(Mandatory = $true)][string]$Reason)

  $script:FailureKind = "verification"
  throw $Reason
}

function Stop-Precondition {
  param([Parameter(Mandatory = $true)][string]$Reason)

  $script:FailureKind = "precondition"
  throw $Reason
}

function Get-JsonProperty {
  param(
    [Parameter(Mandatory = $true)]$Object,
    [Parameter(Mandatory = $true)][string]$Name
  )

  if ($null -eq $Object) {
    return $null
  }

  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }

  return $property.Value
}

function Read-JsonFile {
  param([Parameter(Mandatory = $true)][string]$RelativePath)

  $path = Join-Path $script:RepoRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Stop-Verification "필수 파일이 없습니다: $RelativePath"
  }

  try {
    return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
  } catch {
    Stop-Verification "JSON 문법을 읽을 수 없습니다: $RelativePath ($($_.Exception.Message))"
  }
}

function Assert-File {
  param([Parameter(Mandatory = $true)][string]$RelativePath)

  $path = Join-Path $script:RepoRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Stop-Verification "필수 파일이 없습니다: $RelativePath"
  }
}

function Assert-TextContains {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [Parameter(Mandatory = $true)][string]$Fragment,
    [Parameter(Mandatory = $true)][string]$Description
  )

  $path = Join-Path $script:RepoRoot $RelativePath
  try {
    $content = Get-Content -LiteralPath $path -Raw
  } catch {
    Stop-Verification "파일을 읽을 수 없습니다: $RelativePath ($($_.Exception.Message))"
  }

  if ($content.IndexOf($Fragment, [System.StringComparison]::Ordinal) -lt 0) {
    Stop-Verification "정적 설정 검사 실패: $RelativePath 에 $Description 이 없습니다."
  }
}

function Invoke-StaticChecks {
  Write-Host "[SYNTAX] package.json, workspace, Firebase 설정, rules, 테스트 진입점을 확인합니다."

  $package = Read-JsonFile "package.json"
  $functionsPackage = Read-JsonFile "functions/package.json"
  $firebase = Read-JsonFile "firebase.json"
  $firebaseRc = Read-JsonFile ".firebaserc"
  $null = Read-JsonFile "tsconfig.json"
  $null = Read-JsonFile "tsconfig.app.json"
  $null = Read-JsonFile "tsconfig.node.json"
  $null = Read-JsonFile "functions/tsconfig.json"
  $null = Read-JsonFile "firestore.indexes.json"
  $null = Read-JsonFile ".prettierrc.json"

  if ((Get-JsonProperty $package "name") -ne "trip-split") {
    Stop-Verification "package.json의 name이 trip-split이 아닙니다."
  }

  $workspaces = Get-JsonProperty $package "workspaces"
  if ($null -eq $workspaces -or $workspaces -notcontains "functions") {
    Stop-Verification "package.json에 functions workspace가 없습니다."
  }

  $scripts = Get-JsonProperty $package "scripts"
  if ($null -eq $scripts) {
    Stop-Verification "package.json에 scripts가 없습니다."
  }

  foreach ($scriptName in @(
      "format:check",
      "lint",
      "typecheck",
      "test",
      "build",
      "test:emulator"
    )) {
    if ($null -eq (Get-JsonProperty $scripts $scriptName)) {
      Stop-Verification "package.json에 필수 script가 없습니다: $scriptName"
    }
  }

  if ((Get-JsonProperty $functionsPackage "name") -ne "trip-split-functions") {
    Stop-Verification "functions/package.json의 name이 올바르지 않습니다."
  }

  $functionEngines = Get-JsonProperty $functionsPackage "engines"
  if ((Get-JsonProperty $functionEngines "node") -ne "22") {
    Stop-Verification "Functions의 Node engine이 22가 아닙니다."
  }

  $functionScripts = Get-JsonProperty $functionsPackage "scripts"
  foreach ($scriptName in @("build", "typecheck", "test")) {
    if ($null -eq (Get-JsonProperty $functionScripts $scriptName)) {
      Stop-Verification "functions/package.json에 필수 script가 없습니다: $scriptName"
    }
  }

  $firebaseFunctions = Get-JsonProperty $firebase "functions"
  if ((Get-JsonProperty $firebaseFunctions "source") -ne "functions") {
    Stop-Verification "firebase.json의 Functions source가 functions가 아닙니다."
  }
  if ((Get-JsonProperty $firebaseFunctions "runtime") -ne "nodejs22") {
    Stop-Verification "firebase.json의 Functions runtime이 nodejs22가 아닙니다."
  }

  $firestore = Get-JsonProperty $firebase "firestore"
  if ((Get-JsonProperty $firestore "rules") -ne "firestore.rules") {
    Stop-Verification "firebase.json이 firestore.rules를 가리키지 않습니다."
  }
  if ((Get-JsonProperty $firestore "indexes") -ne "firestore.indexes.json") {
    Stop-Verification "firebase.json이 firestore.indexes.json을 가리키지 않습니다."
  }

  $hosting = Get-JsonProperty $firebase "hosting"
  if ((Get-JsonProperty $hosting "public") -ne "dist") {
    Stop-Verification "firebase.json의 Hosting public 디렉터리가 dist가 아닙니다."
  }

  $emulators = Get-JsonProperty $firebase "emulators"
  foreach ($expectedPort in @(
      @{ Name = "auth"; Port = 9099 },
      @{ Name = "firestore"; Port = 8080 },
      @{ Name = "functions"; Port = 5001 }
    )) {
    $emulator = Get-JsonProperty $emulators $expectedPort.Name
    if ((Get-JsonProperty $emulator "port") -ne $expectedPort.Port) {
      Stop-Verification "firebase.json의 $($expectedPort.Name) Emulator 포트가 $($expectedPort.Port)이 아닙니다."
    }
  }

  $projects = Get-JsonProperty $firebaseRc "projects"
  if ((Get-JsonProperty $projects "default") -ne "demo-trip-split") {
    Stop-Verification ".firebaserc의 기본 프로젝트가 demo-trip-split이 아닙니다."
  }

  Assert-File "package-lock.json"
  $lockContent = Get-Content -LiteralPath (Join-Path $script:RepoRoot "package-lock.json") -Raw
  if ($lockContent -notmatch '"lockfileVersion"\s*:\s*3') {
    Stop-Verification "package-lock.json이 lockfileVersion 3이 아닙니다."
  }

  foreach ($path in @(
      "vite.config.ts",
      "vitest.emulator.config.ts",
      "functions/vitest.config.ts",
      "eslint.config.js",
      "scripts/prepare-pages.mjs",
      "tests/emulator/trip-share.emulator.test.ts",
      "src/test/setup.ts"
    )) {
    Assert-File $path
  }

  Assert-TextContains "firestore.rules" "rules_version = '2';" "rules_version 2"
  Assert-TextContains "firestore.rules" "service cloud.firestore" "Firestore service"
  Assert-TextContains "firestore.rules" "allow read, write: if false;" "shareCodes 차단 규칙"
  Assert-TextContains "firestore.rules" "isTripMember" "멤버십 권한 함수"
  Assert-TextContains ".gitattributes" "* text=auto eol=lf" "플랫폼 공통 LF 규칙"

  Write-Host "[SYNTAX] 통과"
}

function Invoke-Preconditions {
  Write-Host "[PREREQUISITES] Node.js 22, npm.cmd, node_modules와 Full 모드의 Java를 확인합니다."
  $reasons = @()

  $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
  if ($null -eq $nodeCommand) {
    $reasons += "Node.js가 PATH에 없습니다. Node.js 22를 설치해 주세요."
  } else {
    $nodeVersion = (& node --version 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
      $reasons += "Node.js 버전을 읽지 못했습니다."
    } elseif ($nodeVersion -notmatch '^v22\.') {
      $reasons += "Node.js 22가 필요하지만 $nodeVersion 를 사용 중입니다."
    }
  }

  if ($null -eq (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
    $reasons += "npm.cmd가 PATH에 없습니다. Node.js 22 설치를 확인해 주세요."
  }

  if ($Mode -eq "Full") {
    $javaCommand = Get-Command java -ErrorAction SilentlyContinue
    if ($null -eq $javaCommand) {
      $reasons += "Full 모드의 Firebase Emulator에 필요한 Java가 PATH에 없습니다."
    } else {
      & java -version 2>&1 | Out-Null
      if ($LASTEXITCODE -ne 0) {
        $reasons += "Java 실행 상태를 확인하지 못했습니다."
      }
    }
  }

  $nodeModules = Join-Path $script:RepoRoot "node_modules"
  if (-not (Test-Path -LiteralPath $nodeModules -PathType Container)) {
    $reasons += "node_modules가 없습니다. 자동 설치하지 않으므로 먼저 npm ci를 실행해 주세요."
  } else {
    $binDirectory = Join-Path $nodeModules ".bin"
    foreach ($binary in @("prettier.cmd", "eslint.cmd", "tsc.cmd", "vitest.cmd", "vite.cmd", "firebase.cmd")) {
      if (-not (Test-Path -LiteralPath (Join-Path $binDirectory $binary) -PathType Leaf)) {
        $reasons += "필수 의존성 실행 파일이 없습니다: node_modules/.bin/$binary (먼저 npm ci 실행)"
      }
    }
  }

  if ($reasons.Count -gt 0) {
    Stop-Precondition ($reasons -join [Environment]::NewLine)
  }

  Write-Host "[PREREQUISITES] 통과"
}

function Invoke-NpmScript {
  param([Parameter(Mandatory = $true)][string]$ScriptName)

  Write-Host "[RUN] npm.cmd run $ScriptName"
  & npm.cmd run $ScriptName
  $exitCode = $LASTEXITCODE
  if ($exitCode -ne 0) {
    Stop-Verification "npm.cmd run $ScriptName 실패 (exit code $exitCode)"
  }
  Write-Host "[PASS] $ScriptName"
}

$exitCode = 1
$locationPushed = $false

try {
  Push-Location $script:RepoRoot
  $locationPushed = $true

  Write-Host "Trip Split verification (Mode=$Mode)"
  Invoke-StaticChecks
  Invoke-Preconditions

  Write-Host "[SEMANTIC] format, lint, typecheck, unit/UI tests를 실행합니다."
  Invoke-NpmScript "format:check"
  Invoke-NpmScript "lint"
  Invoke-NpmScript "typecheck"
  Invoke-NpmScript "test"
  Write-Host "[SEMANTIC] 통과"

  if ($Mode -eq "Full") {
    Write-Host "[BOUNDARY] production build와 Firebase Emulator/rules 테스트를 실행합니다."
    Invoke-NpmScript "build"
    Invoke-NpmScript "test:emulator"
    Write-Host "[BOUNDARY] 통과"
  } else {
    Write-Host "[BOUNDARY] Fast 모드이므로 build와 test:emulator를 건너뜁니다."
  }

  Write-Host "[SUCCESS] 검증 완료 (Mode=$Mode)"
  $exitCode = 0
} catch {
  if ($script:FailureKind -eq "precondition") {
    Write-Host "[FAIL:2] 전제조건 실패`n$($_.Exception.Message)"
    $exitCode = 2
  } else {
    Write-Host "[FAIL:1] 검증 실패`n$($_.Exception.Message)"
    $exitCode = 1
  }
} finally {
  if ($locationPushed) {
    Pop-Location
  }
}

exit $exitCode
