#Requires -Version 5.1
<#
.SYNOPSIS
    Aegis health check — mirrors scripts/doctor.sh for Windows.
.DESCRIPTION
    Reports the status of the Claude CLI, Aegis plugin, rules directory,
    security hooks, and recommended MCPs.
.PARAMETER Project
    Check the project-local .claude/ directory instead of the global ~/.claude/.
.EXAMPLE
    .\scripts\doctor.ps1
    .\scripts\doctor.ps1 -Project
#>
param(
    [switch]$Project
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$AegisRepo     = Join-Path $env:USERPROFILE '.aegis\repo'
$ClaudeDir     = Join-Path $env:USERPROFILE '.claude'
$RulesGlobal   = Join-Path $ClaudeDir 'rules\aegis'
$SettingsGlobal = Join-Path $ClaudeDir 'settings.json'

if ($Project) {
    $RulesTarget    = '.claude\rules\aegis'
    $SettingsTarget = '.claude\settings.json'
} else {
    $RulesTarget    = $RulesGlobal
    $SettingsTarget = $SettingsGlobal
}

$Issues = 0

function Write-Ok   { param($Msg) Write-Host "  [OK]  $Msg" -ForegroundColor Green }
function Write-Warn { param($Msg) Write-Host "  [!]   $Msg" -ForegroundColor Yellow }
function Write-Fail { param($Msg) Write-Host "  [X]   $Msg" -ForegroundColor Red; $script:Issues++ }
function Write-Head { param($Msg) Write-Host "`n$Msg" -ForegroundColor Cyan }

Write-Host "`n Aegis Doctor" -ForegroundColor White
Write-Host " Checking your Aegis installation..."

# ── 1. Claude CLI ─────────────────────────────────────────────────────────────
Write-Head "1. Claude CLI"
$ClaudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if ($ClaudeCmd) {
    $ClaudeVersion = (claude --version 2>$null | Select-Object -First 1) ?? 'version unknown'
    Write-Ok "claude CLI found: $ClaudeVersion"
} else {
    Write-Fail "claude CLI not found — install Claude Code to use Aegis"
}

# ── 2. Plugin registration ────────────────────────────────────────────────────
Write-Head "2. Plugin"
if ($ClaudeCmd) {
    $PluginList = claude plugin list 2>$null
    if ($PluginList -match '(?i)aegis') {
        Write-Ok "aegis plugin is registered"
    } else {
        Write-Fail "aegis plugin not registered — run: cd `"$AegisRepo`"; claude plugin install ."
    }
} else {
    Write-Warn "Skipping plugin check (claude CLI not available)"
}

# ── 3. Rules ──────────────────────────────────────────────────────────────────
Write-Head "3. Rules ($RulesTarget)"
if (Test-Path $RulesTarget -PathType Container) {
    $RuleCount = (Get-ChildItem -Path $RulesTarget -Filter '*.md' -Recurse).Count
    Write-Ok "Rules directory exists — $RuleCount .md files found"

    foreach ($RelPath in @('common\stack-detection.md', 'security\owasp-top10-2025.md')) {
        $Full = Join-Path $RulesTarget $RelPath
        if (Test-Path $Full) {
            Write-Ok "  rules\$RelPath"
        } else {
            Write-Fail "  Missing: $Full"
        }
    }
} else {
    Write-Fail "Rules directory not found at $RulesTarget"
    $Flag = if ($Project) { ' -Project' } else { '' }
    Write-Warn "  Run: .\scripts\install.ps1$Flag"
}

# ── 4. Hooks ──────────────────────────────────────────────────────────────────
Write-Head "4. Hooks ($SettingsTarget)"
if (Test-Path $SettingsTarget) {
    $PythonScript = @'
import json, sys

settings_path = sys.argv[1]
repo_path     = sys.argv[2]

try:
    with open(settings_path, encoding='utf-8') as f:
        settings = json.load(f)
except Exception:
    print("INVALID_JSON")
    sys.exit(1)

hooks = settings.get("hooks", {})
pre   = hooks.get("PreToolUse", [])
aegis_hooks = [
    h["command"]
    for entry in pre
    for h in entry.get("hooks", [])
    if repo_path in h.get("command", "")
]

if aegis_hooks:
    for cmd in aegis_hooks:
        print(f"FOUND:{cmd}")
else:
    print("NOT_FOUND")
'@

    $TmpScript = [System.IO.Path]::GetTempFileName() + '.py'
    try {
        $PythonScript | Set-Content -Path $TmpScript -Encoding UTF8
        $HookOutput = python $TmpScript $SettingsTarget $AegisRepo 2>$null
    } catch {
        $HookOutput = 'ERROR'
    } finally {
        Remove-Item $TmpScript -ErrorAction SilentlyContinue
    }

    if ($HookOutput -eq 'ERROR' -or $HookOutput -match 'INVALID_JSON') {
        Write-Fail "Could not parse $SettingsTarget — may be invalid JSON"
    } elseif ($HookOutput -match 'FOUND:') {
        $HookCount = ($HookOutput -split "`n" | Where-Object { $_ -match '^FOUND:' }).Count
        Write-Ok "$HookCount Aegis hook(s) registered in $SettingsTarget"
    } else {
        Write-Fail "Aegis hooks not found in $SettingsTarget"
        $Flag = if ($Project) { ' -Project' } else { '' }
        Write-Warn "  Run: .\scripts\install.ps1$Flag"
    }
} else {
    Write-Fail "Settings file not found: $SettingsTarget"
}

# ── 5. Recommended MCPs ───────────────────────────────────────────────────────
Write-Head "5. Recommended MCPs"
if ($ClaudeCmd) {
    $McpList = claude mcp list 2>$null
    foreach ($Mcp in @('serena', 'lumen', 'graphify', 'drawio')) {
        if ($McpList -match "(?i)$Mcp") {
            Write-Ok $Mcp
        } else {
            Write-Warn "$Mcp — not configured (see SETUP.md for installation)"
        }
    }
} else {
    Write-Warn "Skipping MCP check (claude CLI not available)"
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host ""
if ($Issues -eq 0) {
    Write-Host " All checks passed. Aegis is ready." -ForegroundColor Green
} else {
    Write-Host " $Issues issue(s) found. See above for remediation steps." -ForegroundColor Red
    exit 1
}
