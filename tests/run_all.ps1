# Run the full local test suite for Windows/PowerShell.
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = "." }
$Root = (Resolve-Path (Join-Path $ScriptDir "..")).Path

Write-Host "### 1) Structure + frontmatter + links" -ForegroundColor Cyan
# 1. Structure check
$RequiredFiles = @(
  "README.md", "CLAUDE.md", "LICENSE", "install.sh", "install-custom.sh", "install.ps1",
  "skill/SKILL.md", "skill/threat-model.md", "skill/verified-deploy.md",
  "skill/authority-hardening.md", "skill/circuit-breakers.md", "skill/monitoring.md",
  "skill/incident-response.md", "skill/recovery-postmortem.md", "skill/resources.md",
  "agents/incident-commander.md", "agents/secops-engineer.md",
  "commands/secops-readiness.md", "commands/setup-monitoring.md", "commands/incident.md",
  "rules/pausable-program.md",
  "templates/SECURITY.txt.template", "templates/incident-runbook.md.template",
  "templates/war-room.md.template", "templates/postmortem.md.template",
  "templates/readiness-scorecard.md.template", "templates/monitoring-worker.js"
)

foreach ($f in $RequiredFiles) {
  $FullPath = Join-Path $Root $f
  if (Test-Path $FullPath) {
    Write-Host "  PASS: exists: $f" -ForegroundColor Green
  } else {
    Write-Host "  FAIL: missing: $f" -ForegroundColor Red
    exit 1
  }
}

# 2. Frontmatter check helper
function Has-Frontmatter {
  param([string]$FilePath, [string]$Key)
  $Lines = Get-Content $FilePath
  if ($Lines[0] -ne "---") { return $false }
  for ($i = 1; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -eq "---") { break }
    if ($Lines[$i] -like "${Key}:*") { return $true }
  }
  return $false
}

if (Has-Frontmatter (Join-Path $Root "skill/SKILL.md") "name") { Write-Host "  PASS: SKILL.md has name" -ForegroundColor Green } else { Write-Host "  FAIL: SKILL.md missing name" -ForegroundColor Red; exit 1 }
if (Has-Frontmatter (Join-Path $Root "skill/SKILL.md") "description") { Write-Host "  PASS: SKILL.md has description" -ForegroundColor Green } else { Write-Host "  FAIL: SKILL.md missing description" -ForegroundColor Red; exit 1 }

$Agents = Get-ChildItem (Join-Path $Root "agents") -Filter *.md
foreach ($a in $Agents) {
  if (Has-Frontmatter $a.FullName "name") { Write-Host "  PASS: $($a.Name) has name" -ForegroundColor Green } else { Write-Host "  FAIL: $($a.Name) missing name" -ForegroundColor Red; exit 1 }
  if (Has-Frontmatter $a.FullName "model") { Write-Host "  PASS: $($a.Name) has model" -ForegroundColor Green } else { Write-Host "  FAIL: $($a.Name) missing model" -ForegroundColor Red; exit 1 }
}

$Commands = Get-ChildItem (Join-Path $Root "commands") -Filter *.md
foreach ($c in $Commands) {
  if (Has-Frontmatter $c.FullName "description") { Write-Host "  PASS: $($c.Name) has description" -ForegroundColor Green } else { Write-Host "  FAIL: $($c.Name) missing description" -ForegroundColor Red; exit 1 }
}

if (Has-Frontmatter (Join-Path $Root "rules/pausable-program.md") "globs") { Write-Host "  PASS: rule has globs" -ForegroundColor Green } else { Write-Host "  FAIL: rule missing globs" -ForegroundColor Red; exit 1 }

# 3. Relative link check helper
Write-Host "Checking relative links..."
$MdFiles = Get-ChildItem $Root -Recurse -Filter *.md | Where-Object { $_.FullName -notlike "*\target\*" }
$FailedLinks = 0
foreach ($md in $MdFiles) {
  $Content = Get-Content $md.FullName -Raw
  $Matches = [regex]::Matches($Content, '\]\(([^)]+)\)')
  foreach ($match in $Matches) {
    $Link = $match.Groups[1].Value
    # Skip web links, anchors and mails
    if ($Link -like "http*" -or $Link -like "mailto:*" -or $Link -like "#*") { continue }
    
    # Strip anchor
    $Target = $Link
    if ($Link.Contains("#")) {
      $Target = $Link.Split("#")[0]
    }
    if ([string]::IsNullOrEmpty($Target)) { continue }
    
    # Check if target exists relative to md file
    $TargetDir = Split-Path -Parent $md.FullName
    $TargetPath = Join-Path $TargetDir $Target
    if (-not (Test-Path $TargetPath)) {
      Write-Host "  FAIL: broken link in $($md.FullName.Replace($Root, '')) -> $Link" -ForegroundColor Red
      $FailedLinks++
    }
  }
}
if ($FailedLinks -eq 0) {
  Write-Host "  PASS: all relative links resolve" -ForegroundColor Green
} else {
  exit 1
}

# 4. Install smoke test in isolated Temp directory
Write-Host ""
Write-Host "### 2) Install smoke test (isolated temp dir)" -ForegroundColor Cyan
$TempDir = Join-Path $env:TEMP ([Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $TempDir | Out-Null

$Installer = Join-Path $Root "install.ps1"
& powershell -File $Installer -Path $TempDir -Yes | Out-Null

$Base = Join-Path $TempDir ".claude"
$SkillFile = Join-Path $Base "skills\solana-secops\SKILL.md"
$AgentFile = Join-Path $Base "agents\incident-commander.md"
$CommandFile = Join-Path $Base "commands\incident.md"
$RuleFile = Join-Path $Base "rules\pausable-program.md"

if ((Test-Path $SkillFile) -and (Test-Path $AgentFile) -and (Test-Path $CommandFile) -and (Test-Path $RuleFile)) {
  Write-Host "  PASS: install.ps1 placed skill, agents, commands, rules" -ForegroundColor Green
} else {
  Write-Host "  FAIL: files not installed properly" -ForegroundColor Red
  Remove-Item -Recurse -Force $TempDir
  exit 1
}

# 5. Idempotency test
Write-Host ""
Write-Host "### 3) Idempotency (re-run install)" -ForegroundColor Cyan
& powershell -File $Installer -Path $TempDir -Yes | Out-Null
if (Test-Path $SkillFile) {
  Write-Host "  PASS: re-running install.ps1 is safe" -ForegroundColor Green
} else {
  Write-Host "  FAIL: idempotent install broke" -ForegroundColor Red
  Remove-Item -Recurse -Force $TempDir
  exit 1
}

# Clean up
Remove-Item -Recurse -Force $TempDir
Write-Host ""
Write-Host "ALL TESTS PASSED" -ForegroundColor Green
