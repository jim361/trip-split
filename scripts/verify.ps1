[CmdletBinding()]
param(
  [ValidateSet("Fast", "Full")]
  [string]$Mode = "Fast"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:FailureKind = $null
$script:Stage = "startup"
$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$script:Layout = $null
$script:NpmCommand = $null

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

function Get-RepoPath {
  param([Parameter(Mandatory = $true)][string]$RelativePath)

  if ($RelativePath -eq "." -or [string]::IsNullOrWhiteSpace($RelativePath)) {
    return $script:RepoRoot
  }

  return (Join-Path $script:RepoRoot $RelativePath)
}

function Get-RepoRelativePath {
  param([Parameter(Mandatory = $true)][string]$Path)

  $root = [IO.Path]::GetFullPath($script:RepoRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
  $fullPath = [IO.Path]::GetFullPath($Path)
  if ($fullPath.Equals($root, [StringComparison]::OrdinalIgnoreCase)) {
    return "."
  }

  $prefix = $root + [IO.Path]::DirectorySeparatorChar
  if ($fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    return $fullPath.Substring($prefix.Length).Replace([IO.Path]::DirectorySeparatorChar, "/")
  }

  return $fullPath.Replace([IO.Path]::DirectorySeparatorChar, "/")
}

function Get-JsonProperty {
  param(
    [Parameter(Mandatory = $true)]
    [AllowNull()]
    $Object,
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

  $path = Get-RepoPath $RelativePath
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

  $path = Get-RepoPath $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Stop-Verification "필수 파일이 없습니다: $RelativePath"
  }
}

function Assert-OneFile {
  param(
    [Parameter(Mandatory = $true)][string[]]$RelativePaths,
    [Parameter(Mandatory = $true)][string]$Description
  )

  $existing = @($RelativePaths | Where-Object { Test-Path -LiteralPath (Get-RepoPath $_) -PathType Leaf })
  if ($existing.Count -eq 0) {
    Stop-Verification "$Description 파일을 찾을 수 없습니다. 지원 경로: $($RelativePaths -join ", ")"
  }
  if ($existing.Count -gt 1) {
    Stop-Verification "$Description 파일이 여러 경로에서 발견되어 레이아웃을 확정할 수 없습니다: $($existing -join ", ")"
  }

  return $existing[0]
}

function Assert-TextContains {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [Parameter(Mandatory = $true)][string]$Fragment,
    [Parameter(Mandatory = $true)][string]$Description
  )

  $path = Get-RepoPath $RelativePath
  try {
    $content = Get-Content -LiteralPath $path -Raw
  } catch {
    Stop-Verification "파일을 읽을 수 없습니다: $RelativePath ($($_.Exception.Message))"
  }

  if ($content.IndexOf($Fragment, [System.StringComparison]::Ordinal) -lt 0) {
    Stop-Verification "정적 설정 검사 실패: $RelativePath 에 $Description 이 없습니다."
  }
}

function Get-PackageEntry {
  param(
    [Parameter(Mandatory = $true)][string]$RelativeRoot,
    [Parameter(Mandatory = $true)]$Package
  )

  $absoluteRoot = Get-RepoPath $RelativeRoot
  return [pscustomobject]@{
    RelativeRoot = $RelativeRoot
    AbsoluteRoot = $absoluteRoot
    Package      = $Package
    Scripts      = Get-JsonProperty $Package "scripts"
  }
}

function Resolve-Layout {
  $currentLayout = $false
  $futureLayout = $false

  if ((Test-Path -LiteralPath (Get-RepoPath "package.json") -PathType Leaf) -and
      (Test-Path -LiteralPath (Get-RepoPath "functions/package.json") -PathType Leaf)) {
    $currentLayout = $true
  }

  if ((Test-Path -LiteralPath (Get-RepoPath "frontend/package.json") -PathType Leaf) -and
      (Test-Path -LiteralPath (Get-RepoPath "backend/package.json") -PathType Leaf)) {
    $futureLayout = $true
  }

  if ($currentLayout -and $futureLayout) {
    Stop-Verification "레이아웃 탐색이 모호합니다: root/functions와 frontend/backend가 모두 발견되었습니다. 하나만 유지해 주세요."
  }
  if (-not $currentLayout -and -not $futureLayout) {
    Stop-Verification "지원하는 프로젝트 레이아웃을 찾을 수 없습니다. package.json 쌍(root/functions 또는 frontend/backend)이 필요합니다."
  }

  if ($currentLayout) {
    $script:Layout = [pscustomobject]@{
      Name                 = "root-functions"
      FrontendRelativeRoot = "."
      BackendRelativeRoot  = "functions"
      FunctionsSource      = "functions"
      HostingPublic        = "dist"
      FirestoreRules       = "firestore.rules"
      FirestoreIndexes     = "firestore.indexes.json"
      FrontendPackagePath  = "package.json"
      BackendPackagePath   = "functions/package.json"
    }
  } else {
    $script:Layout = [pscustomobject]@{
      Name                 = "frontend-backend"
      FrontendRelativeRoot = "frontend"
      BackendRelativeRoot  = "backend"
      FunctionsSource      = "backend"
      HostingPublic        = "frontend/dist"
      FirestoreRules       = "backend/firestore.rules"
      FirestoreIndexes     = "backend/firestore.indexes.json"
      FrontendPackagePath  = "frontend/package.json"
      BackendPackagePath   = "backend/package.json"
    }
  }

  Write-Host "[LAYOUT] $($script:Layout.Name): frontend=$($script:Layout.FrontendRelativeRoot), backend=$($script:Layout.BackendRelativeRoot)"
}

function Get-ExecutionPackages {
  $frontendPackage = Read-JsonFile $script:Layout.FrontendPackagePath
  $backendPackage = Read-JsonFile $script:Layout.BackendPackagePath

  if ($script:Layout.Name -eq "root-functions") {
    return @(
      (Get-PackageEntry $script:Layout.FrontendRelativeRoot $frontendPackage)
    )
  }

  return @(
    (Get-PackageEntry $script:Layout.FrontendRelativeRoot $frontendPackage),
    (Get-PackageEntry $script:Layout.BackendRelativeRoot $backendPackage)
  )
}

function Get-ScriptTargets {
  param([Parameter(Mandatory = $true)][string]$ScriptName)

  if ($script:Layout.Name -eq "root-functions") {
    $packages = @(Get-ExecutionPackages)
    return @($packages | Where-Object { $null -ne (Get-JsonProperty $_.Scripts $ScriptName) })
  }

  # A future layout can keep root-level orchestration scripts. Prefer a root
  # script for the requested stage when it exists; otherwise run each package
  # that explicitly exposes that stage. This keeps Full mode from skipping a
  # package build just because the root package only wraps core checks.
  $rootPackagePath = Get-RepoPath "package.json"
  if (Test-Path -LiteralPath $rootPackagePath -PathType Leaf) {
    $rootPackage = Read-JsonFile "package.json"
    if ($null -ne (Get-JsonProperty (Get-JsonProperty $rootPackage "scripts") $ScriptName)) {
      return @((Get-PackageEntry "." $rootPackage))
    }
  }

  $packages = @(Get-ExecutionPackages)
  return @($packages | Where-Object { $null -ne (Get-JsonProperty $_.Scripts $ScriptName) })
}

function Assert-PackageFiles {
  param(
    [Parameter(Mandatory = $true)][string]$RelativeRoot,
    [Parameter(Mandatory = $true)][string[]]$RelativePaths
  )

  foreach ($relativePath in $RelativePaths) {
    $path = if ($RelativeRoot -eq ".") { $relativePath } else { Join-Path $RelativeRoot $relativePath }
    Assert-File $path
  }
}

function Invoke-StaticChecks {
  $script:Stage = "static/layout"
  Resolve-Layout

  Write-Host "[SYNTAX] package.json, workspace, Firebase 설정, rules, 테스트 진입점을 확인합니다."

  $package = Read-JsonFile $script:Layout.FrontendPackagePath
  $functionsPackage = Read-JsonFile $script:Layout.BackendPackagePath
  $firebase = Read-JsonFile "firebase.json"
  $firebaseRc = Read-JsonFile ".firebaserc"
  $null = Read-JsonFile ".prettierrc.json"
  $null = Read-JsonFile $script:Layout.FirestoreIndexes

  if ($script:Layout.Name -eq "root-functions") {
    if ((Get-JsonProperty $package "name") -ne "trip-split") {
      Stop-Verification "$($script:Layout.FrontendPackagePath)의 name이 trip-split이 아닙니다."
    }
    $workspaces = Get-JsonProperty $package "workspaces"
    if ($null -eq $workspaces -or $workspaces -notcontains "functions") {
      Stop-Verification "package.json에 functions workspace가 없습니다."
    }
  } else {
    if ((Get-JsonProperty $package "name") -ne "trip-split-frontend") {
      Stop-Verification "$($script:Layout.FrontendPackagePath)의 name이 trip-split-frontend가 아닙니다."
    }
    $rootPackagePath = Get-RepoPath "package.json"
    if (-not (Test-Path -LiteralPath $rootPackagePath -PathType Leaf)) {
      Stop-Verification "frontend/backend 레이아웃에는 root package.json(workspaces)이 필요합니다."
    }
    $rootPackage = Read-JsonFile "package.json"
    if ((Get-JsonProperty $rootPackage "name") -ne "trip-split") {
      Stop-Verification "package.json의 name이 trip-split이 아닙니다."
    }
    $workspaces = Get-JsonProperty $rootPackage "workspaces"
    if ($null -eq $workspaces -or $workspaces -notcontains "frontend" -or $workspaces -notcontains "backend") {
      Stop-Verification "package.json에 frontend와 backend workspace가 모두 필요합니다."
    }
    $rootScripts = Get-JsonProperty $rootPackage "scripts"
    foreach ($scriptName in @("format:check", "lint", "typecheck", "test", "build", "test:emulator")) {
      if ($null -eq (Get-JsonProperty $rootScripts $scriptName)) {
        Stop-Verification "package.json에 필수 script가 없습니다: $scriptName"
      }
    }
  }

  $frontendScripts = Get-JsonProperty $package "scripts"
  $backendScripts = Get-JsonProperty $functionsPackage "scripts"
  $requiredScriptNames = @("format:check", "lint", "typecheck", "test", "build", "test:emulator")
  foreach ($scriptName in $requiredScriptNames) {
    if (@(Get-ScriptTargets $scriptName).Count -eq 0) {
      Stop-Verification "지원하는 실행 패키지에 필수 script가 없습니다: $scriptName"
    }
  }

  if ($script:Layout.Name -eq "root-functions") {
    foreach ($scriptName in @("format:check", "lint", "typecheck", "test", "build", "test:emulator")) {
      if ($null -eq (Get-JsonProperty $frontendScripts $scriptName)) {
        Stop-Verification "package.json에 필수 script가 없습니다: $scriptName"
      }
    }
  }

  $expectedBackendName = if ($script:Layout.Name -eq "root-functions") { "trip-split-functions" } else { "trip-split-backend" }
  if ((Get-JsonProperty $functionsPackage "name") -ne $expectedBackendName) {
    Stop-Verification "$($script:Layout.BackendPackagePath)의 name이 올바르지 않습니다."
  }

  $functionEngines = Get-JsonProperty $functionsPackage "engines"
  if ((Get-JsonProperty $functionEngines "node") -ne "22") {
    Stop-Verification "Functions의 Node engine이 22가 아닙니다."
  }

  foreach ($scriptName in @("build", "typecheck", "test")) {
    if ($null -eq (Get-JsonProperty $backendScripts $scriptName)) {
      Stop-Verification "$($script:Layout.BackendPackagePath)에 필수 script가 없습니다: $scriptName"
    }
  }

  $firebaseFunctions = Get-JsonProperty $firebase "functions"
  if ((Get-JsonProperty $firebaseFunctions "source") -ne $script:Layout.FunctionsSource) {
    Stop-Verification "firebase.json의 Functions source가 $($script:Layout.FunctionsSource)가 아닙니다."
  }
  if ((Get-JsonProperty $firebaseFunctions "runtime") -ne "nodejs22") {
    Stop-Verification "firebase.json의 Functions runtime이 nodejs22가 아닙니다."
  }

  $firestore = Get-JsonProperty $firebase "firestore"
  if ((Get-JsonProperty $firestore "rules") -ne $script:Layout.FirestoreRules) {
    Stop-Verification "firebase.json이 $($script:Layout.FirestoreRules)를 가리키지 않습니다."
  }
  if ((Get-JsonProperty $firestore "indexes") -ne $script:Layout.FirestoreIndexes) {
    Stop-Verification "firebase.json이 $($script:Layout.FirestoreIndexes)를 가리키지 않습니다."
  }

  $hosting = Get-JsonProperty $firebase "hosting"
  if ((Get-JsonProperty $hosting "public") -ne $script:Layout.HostingPublic) {
    Stop-Verification "firebase.json의 Hosting public 디렉터리가 $($script:Layout.HostingPublic)이 아닙니다."
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

  $lockCandidates = @("package-lock.json")
  if ($script:Layout.Name -eq "frontend-backend") {
    $lockCandidates += @("frontend/package-lock.json", "backend/package-lock.json")
  }
  $lockFiles = @($lockCandidates | Where-Object { Test-Path -LiteralPath (Get-RepoPath $_) -PathType Leaf })
  if ($lockFiles.Count -eq 0) {
    Stop-Verification "npm ci에 사용할 package-lock.json을 찾을 수 없습니다."
  }
  foreach ($lockFile in $lockFiles) {
    $lockContent = Get-Content -LiteralPath (Get-RepoPath $lockFile) -Raw
    if ($lockContent -notmatch '"lockfileVersion"\s*:\s*3') {
      Stop-Verification "$lockFile 이 lockfileVersion 3이 아닙니다."
    }
  }

  if ($script:Layout.Name -eq "root-functions") {
    Assert-PackageFiles "." @(
      "tsconfig.json",
      "tsconfig.app.json",
      "tsconfig.node.json",
      "vite.config.ts",
      "eslint.config.js",
      "src/test/setup.ts"
    )
    Assert-PackageFiles "functions" @(
      "tsconfig.json",
      "vitest.config.ts"
    )
    Assert-File "scripts/prepare-pages.mjs"
    $null = Assert-OneFile @("vitest.emulator.config.ts") "Emulator Vitest 설정"
    $null = Assert-OneFile @("tests/emulator/trip-share.emulator.test.ts") "Emulator 테스트"
    foreach ($configPath in @("tsconfig.json", "tsconfig.app.json", "tsconfig.node.json", "functions/tsconfig.json")) {
      $null = Read-JsonFile $configPath
    }
  } else {
    Assert-PackageFiles $script:Layout.FrontendRelativeRoot @(
      "tsconfig.json",
      "tsconfig.app.json",
      "tsconfig.node.json",
      "vite.config.ts",
      "src/test/setup.ts"
    )
    Assert-PackageFiles $script:Layout.BackendRelativeRoot @(
      "tsconfig.json",
      "vitest.config.ts"
    )
    $null = Assert-OneFile @(
      "scripts/prepare-pages.mjs",
      "frontend/scripts/prepare-pages.mjs"
    ) "Pages 준비 스크립트"
    $null = Assert-OneFile @(
      "eslint.config.js",
      "frontend/eslint.config.js"
    ) "ESLint 설정"
    $null = Assert-OneFile @(
      "vitest.emulator.config.ts",
      "frontend/vitest.emulator.config.ts",
      "backend/vitest.emulator.config.ts"
    ) "Emulator Vitest 설정"
    $null = Assert-OneFile @(
      "tests/emulator/trip-share.emulator.test.ts",
      "frontend/tests/emulator/trip-share.emulator.test.ts",
      "backend/tests/emulator/trip-share.emulator.test.ts"
    ) "Emulator 테스트"
    foreach ($configPath in @(
        "frontend/tsconfig.json",
        "frontend/tsconfig.app.json",
        "frontend/tsconfig.node.json",
        "backend/tsconfig.json"
      )) {
      $null = Read-JsonFile $configPath
    }
  }

  Assert-TextContains $script:Layout.FirestoreRules "rules_version = '2';" "rules_version 2"
  Assert-TextContains $script:Layout.FirestoreRules "service cloud.firestore" "Firestore service"
  Assert-TextContains $script:Layout.FirestoreRules "allow read, write: if false;" "shareCodes 차단 규칙"
  Assert-TextContains $script:Layout.FirestoreRules "isTripMember" "멤버십 권한 함수"
  Assert-TextContains ".gitattributes" "* text=auto eol=lf" "플랫폼 공통 LF 규칙"

  Write-Host "[SYNTAX] 통과"
}

function Get-LocalBinary {
  param(
    [Parameter(Mandatory = $true)][string]$PackageRoot,
    [Parameter(Mandatory = $true)][string]$BinaryName
  )

  $current = [IO.Path]::GetFullPath($PackageRoot)
  $repoRoot = [IO.Path]::GetFullPath($script:RepoRoot)
  while ($true) {
    $binRoot = Join-Path $current "node_modules/.bin"
    foreach ($candidateName in @($BinaryName, "$BinaryName.cmd", "$BinaryName.ps1", "$BinaryName.exe")) {
      $candidate = Join-Path $binRoot $candidateName
      if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        return $candidate
      }
    }

    if ($current.Equals($repoRoot, [StringComparison]::OrdinalIgnoreCase)) {
      break
    }
    $parent = Split-Path -Parent $current
    if ([string]::IsNullOrWhiteSpace($parent) -or $parent.Equals($current, [StringComparison]::OrdinalIgnoreCase)) {
      break
    }
    $current = $parent
  }

  return $null
}

function Get-DeclaredBinaries {
  param(
    [Parameter(Mandatory = $true)]$Target,
    [Parameter(Mandatory = $true)][string]$ScriptName
  )

  $scriptValue = Get-JsonProperty $Target.Scripts $ScriptName
  if ($null -eq $scriptValue) {
    return @()
  }

  $scriptText = [string]$scriptValue
  $binaries = @()
  switch ($ScriptName) {
    "format:check" { if ($scriptText -match "(?<![A-Za-z0-9_-])prettier(?:\.cmd)?(?![A-Za-z0-9_-])") { $binaries += "prettier" } }
    "lint" { if ($scriptText -match "(?<![A-Za-z0-9_-])eslint(?:\.cmd)?(?![A-Za-z0-9_-])") { $binaries += "eslint" } }
    "typecheck" { if ($scriptText -match "(?<![A-Za-z0-9_-])tsc(?:\.cmd)?(?![A-Za-z0-9_-])") { $binaries += "tsc" } }
    "test" { if ($scriptText -match "(?<![A-Za-z0-9_-])vitest(?:\.cmd)?(?![A-Za-z0-9_-])") { $binaries += "vitest" } }
    "build" {
      if ($scriptText -match "(?<![A-Za-z0-9_-])vite(?:\.cmd)?(?![A-Za-z0-9_-])") { $binaries += "vite" }
      if ($scriptText -match "(?<![A-Za-z0-9_-])tsc(?:\.cmd)?(?![A-Za-z0-9_-])") { $binaries += "tsc" }
    }
    "test:emulator" { if ($scriptText -match "(?<![A-Za-z0-9_-])firebase(?:\.cmd)?(?![A-Za-z0-9_-])") { $binaries += "firebase" } }
  }

  return @($binaries | Sort-Object -Unique)
}

function Invoke-Preconditions {
  $script:Stage = "prerequisites"
  Write-Host "[PREREQUISITES] Node.js 22, npm, dependencies와 Full 모드의 Java를 확인합니다."
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

  $npmCommand = Get-Command npm -ErrorAction SilentlyContinue
  if ($null -eq $npmCommand) {
    $reasons += "npm이 PATH에 없습니다. Node.js 22 설치를 확인해 주세요."
  } else {
    $script:NpmCommand = if (-not [string]::IsNullOrWhiteSpace($npmCommand.Source)) { $npmCommand.Source } else { $npmCommand.Name }
    & $script:NpmCommand --version 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
      $reasons += "npm 실행 상태를 확인하지 못했습니다."
    }
  }

  $scriptNames = @("format:check", "lint", "typecheck", "test", "build", "test:emulator")
  foreach ($scriptName in $scriptNames) {
    $targets = @(Get-ScriptTargets $scriptName)
    foreach ($target in $targets) {
      $inspectionTargets = @($target)
      if ($script:Layout.Name -eq "frontend-backend" -and $target.RelativeRoot -eq ".") {
        # Root scripts in the split layout delegate to workspace scripts. Add
        # those workspace declarations so backend tsc/vitest requirements are
        # checked even when the root wrapper only says `npm run ...`.
        $inspectionTargets += @(Get-ExecutionPackages)
      }
      $requiredBinaries = @()
      foreach ($inspectionTarget in $inspectionTargets) {
        $requiredBinaries += @(Get-DeclaredBinaries $inspectionTarget $scriptName)
      }
      foreach ($binaryName in @($requiredBinaries | Sort-Object -Unique)) {
        $binary = Get-LocalBinary $target.AbsoluteRoot $binaryName
        if ($null -eq $binary) {
          $reasons += "필수 의존성 실행 파일이 없습니다: $binaryName ($($target.RelativeRoot)/package.json의 $scriptName; 먼저 npm ci 실행)"
        }
      }
    }
  }

  if ($Mode -eq "Full" -and @(Get-ScriptTargets "test:emulator").Count -gt 0) {
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

  if ($reasons.Count -gt 0) {
    Stop-Precondition ($reasons -join [Environment]::NewLine)
  }

  Write-Host "[PREREQUISITES] 통과"
}

function Invoke-NpmScript {
  param(
    [Parameter(Mandatory = $true)][string]$ScriptName,
    [Parameter(Mandatory = $true)]$Target
  )

  $script:Stage = "npm/$ScriptName ($($Target.RelativeRoot))"
  Write-Host "[RUN] npm run $ScriptName ($($Target.RelativeRoot))"
  Push-Location $Target.AbsoluteRoot
  try {
    & $script:NpmCommand run $ScriptName
    $exitCode = $LASTEXITCODE
  } finally {
    Pop-Location
  }

  if ($exitCode -ne 0) {
    Stop-Verification "npm run $ScriptName 실패 ($($Target.RelativeRoot), exit code $exitCode)"
  }
  Write-Host "[PASS] $ScriptName ($($Target.RelativeRoot))"
}

function Invoke-StageScripts {
  param(
    [Parameter(Mandatory = $true)][string]$ScriptName,
    [Parameter(Mandatory = $true)][string]$MissingReason
  )

  $targets = @(Get-ScriptTargets $ScriptName)
  if ($targets.Count -eq 0) {
    Stop-Verification $MissingReason
  }
  foreach ($target in $targets) {
    Invoke-NpmScript $ScriptName $target
  }
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
  Invoke-StageScripts "format:check" "format:check script를 실행할 수 없습니다."
  Invoke-StageScripts "lint" "lint script를 실행할 수 없습니다."
  Invoke-StageScripts "typecheck" "typecheck script를 실행할 수 없습니다."
  Invoke-StageScripts "test" "test script를 실행할 수 없습니다."
  Write-Host "[SEMANTIC] 통과"

  if ($Mode -eq "Full") {
    Write-Host "[BOUNDARY] production build와 Firebase Emulator/rules 테스트를 실행합니다."
    Invoke-StageScripts "build" "Full 검증에 필요한 build script를 실행할 수 없습니다."
    Invoke-StageScripts "test:emulator" "Full 검증에 필요한 test:emulator script를 실행할 수 없습니다."
    Write-Host "[BOUNDARY] 통과"
  } else {
    Write-Host "[BOUNDARY] Fast 모드이므로 build와 test:emulator를 건너뜁니다."
  }

  Write-Host "[SUCCESS] 검증 완료 (Mode=$Mode)"
  $exitCode = 0
} catch {
  if ($script:FailureKind -eq "precondition") {
    Write-Host "[FAIL:2] Stage=$($script:Stage) 전제조건 실패`n$($_.Exception.Message)"
    $exitCode = 2
  } else {
    Write-Host "[FAIL:1] Stage=$($script:Stage) 검증 실패`n$($_.Exception.Message)"
    $exitCode = 1
  }
} finally {
  if ($locationPushed) {
    Pop-Location
  }
}

exit $exitCode
