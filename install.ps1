<#
.SYNOPSIS
    Solana SecOps Skill Installer for Windows
.DESCRIPTION
    Installs the Solana SecOps skill, agents, commands, and rules.
.PARAMETER Personal
    Install to User Profile ($Home\.claude)
.PARAMETER Project
    Install to current project directory (.\.claude)
.PARAMETER Path
    Install to custom path (<Path>\.claude)
.PARAMETER Yes
    Skip confirmation prompts
#>
param(
    [switch]$Personal,
    [switch]$Project,
    [string]$Path,
    [switch]$Yes,
    [switch]$Help
)

if ($Help) {
    Write-Host "Solana SecOps Skill - Installer"
    Write-Host ""
    Write-Host "Usage: .\install.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Personal     Install to global user profile (~/.claude)"
    Write-Host "  -Project      Install to current project directory (./.claude)"
    Write-Host "  -Path <dir>   Install to custom directory (<dir>/.claude)"
    Write-Host "  -Yes          Skip confirmation prompt"
    Write-Host "  -Help         Show this help message"
    exit 0
}

# Define base path
$BaseDir = ""
if ($Personal) {
    $BaseDir = Join-Path $Home ".claude"
} elseif ($Project) {
    $BaseDir = Join-Path (Get-Location).Path ".claude"
} elseif ($Path) {
    $BaseDir = Join-Path $Path ".claude"
} else {
    if ($Yes) {
        $BaseDir = Join-Path $Home ".claude"
    } else {
        Write-Host "Where should the skill be installed?"
        Write-Host "  1) Personal  ($Home\.claude) - available across all projects"
        Write-Host "  2) Project   (.\.claude) - current directory only"
        $Choice = Read-Host "Choose [1/2] (default 1)"
        if ($Choice -eq "2") {
            $BaseDir = Join-Path (Get-Location).Path ".claude"
        } else {
            $BaseDir = Join-Path $Home ".claude"
        }
    }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = "." }
$SourceDir = Join-Path $ScriptDir "skill"
$TemplatesSource = Join-Path $ScriptDir "templates"

$SkillsDir = Join-Path $BaseDir "skills"
$SkillPath = Join-Path $SkillsDir "solana-secops"
$TemplatesPath = Join-Path $SkillsDir "solana-secops-templates"
$AgentsDir = Join-Path $BaseDir "agents"
$CommandsDir = Join-Path $BaseDir "commands"
$RulesDir = Join-Path $BaseDir "rules"

Write-Host ""
Write-Host "Installing to: $BaseDir" -ForegroundColor Cyan
Write-Host "  * Skill    -> $SkillPath"
Write-Host "  * Agents   -> $AgentsDir"
Write-Host "  * Commands -> $CommandsDir"
Write-Host "  * Rules    -> $RulesDir"
Write-Host ""

if (-not $Yes) {
    $Confirm = Read-Host "Proceed with installation? [Y/n]"
    if ($Confirm -eq "n") {
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Create directories
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
New-Item -ItemType Directory -Force -Path $AgentsDir | Out-Null
New-Item -ItemType Directory -Force -Path $CommandsDir | Out-Null
New-Item -ItemType Directory -Force -Path $RulesDir | Out-Null

# Copy skill
Write-Host "Installing solana-secops skill..." -ForegroundColor Cyan
if (Test-Path $SkillPath) {
    Remove-Item -Recurse -Force $SkillPath
}
New-Item -ItemType Directory -Force -Path $SkillPath | Out-Null
Copy-Item -Recurse -Force (Join-Path $SourceDir "*") $SkillPath

# Copy templates alongside the skill
Write-Host "Installing templates..." -ForegroundColor Cyan
if (Test-Path $TemplatesPath) {
    Remove-Item -Recurse -Force $TemplatesPath
}
New-Item -ItemType Directory -Force -Path $TemplatesPath | Out-Null
Copy-Item -Recurse -Force (Join-Path $TemplatesSource "*") $TemplatesPath

# Copy agents
Write-Host "Installing agents..." -ForegroundColor Cyan
Copy-Item -Force (Join-Path $ScriptDir "agents\*.md") $AgentsDir

# Copy commands
Write-Host "Installing commands..." -ForegroundColor Cyan
Copy-Item -Force (Join-Path $ScriptDir "commands\*.md") $CommandsDir

# Copy rules
Write-Host "Installing rules..." -ForegroundColor Cyan
Copy-Item -Force (Join-Path $ScriptDir "rules\*.md") $RulesDir

Write-Host ""
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host ""
