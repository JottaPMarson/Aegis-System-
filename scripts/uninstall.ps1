<#
.SYNOPSIS
    Aegis plugin uninstaller for Windows (PowerShell).

.DESCRIPTION
    Reverses the install: unregisters the plugin, removes rules,
    removes Aegis hooks from settings, and optionally removes the local repo.
    Does NOT touch external MCPs (Serena, Lumen, Graphify, drawio-mcp-server).

.PARAMETER Project
    Reverse a project-level install (current directory) instead of user-level.

.EXAMPLE
    .\scripts\uninstall.ps1
    .\scripts\uninstall.ps1 -Project
#>

[CmdletBinding()]
param(
    [switch]$Project
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AegisDir  = Join-Path $env:USERPROFILE ".aegis"
$AegisRepo = Join-Path $AegisDir "repo"
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

if ($Project) {
    $RulesTarget    = Join-Path (Get-Location) ".claude\rules\aegis"
    $SettingsTarget = Join-Path (Get-Location) ".claude\settings.json"
    Write-Host "`nAegis uninstaller — project mode" -ForegroundColor Cyan
} else {
    $RulesTarget    = Join-Path $ClaudeDir "rules\aegis"
    $SettingsTarget = Join-Path $ClaudeDir "settings.json"
    Write-Host "`nAegis uninstaller — user mode" -ForegroundColor Cyan
}

function Write-Ok   ($msg) { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Warn ($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Step ($msg) { Write-Host "`n-- $msg" -ForegroundColor White }

$PythonBin = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { "python" }

# ── Step 1: Unregister plugin ─────────────────────────────────────────────────
Write-Step "Step 1/4 — Unregister plugin"

if (Get-Command claude -ErrorAction SilentlyContinue) {
    $pluginList = claude plugin list 2>$null
    if ($pluginList -match "aegis") {
        try { claude plugin uninstall aegis 2>$null; Write-Ok "Plugin unregistered" }
        catch { Write-Warn "Plugin unregistration failed. Try: claude plugin uninstall aegis" }
    } else {
        Write-Warn "aegis plugin not registered — skipping"
    }
} else {
    Write-Warn "claude CLI not found. Uninstall manually: claude plugin uninstall aegis"
}

# ── Step 2: Remove rules ──────────────────────────────────────────────────────
Write-Step "Step 2/4 — Remove rules ($RulesTarget)"

if (Test-Path $RulesTarget) {
    Remove-Item -Recurse -Force $RulesTarget
    Write-Ok "Removed $RulesTarget"
} else {
    Write-Warn "Rules directory not found — skipping"
}

# ── Step 3: Remove Aegis hooks ────────────────────────────────────────────────
Write-Step "Step 3/4 — Remove Aegis hooks from $SettingsTarget"

if (Test-Path $SettingsTarget) {
    $RemoveScript = @"
import json, sys, pathlib

settings_path = sys.argv[1]
repo_path     = sys.argv[2]

try:
    with open(settings_path) as f:
        settings = json.load(f)
except Exception:
    print('Settings missing or invalid — skipping.')
    sys.exit(0)

removed = 0
hooks = settings.get('hooks', {})
for event_type in list(hooks.keys()):
    cleaned = []
    for entry in hooks[event_type]:
        remaining = [h for h in entry.get('hooks', [])
                     if repo_path not in h.get('command', '')]
        removed += len(entry.get('hooks', [])) - len(remaining)
        if remaining:
            e2 = dict(entry); e2['hooks'] = remaining; cleaned.append(e2)
    if cleaned:
        hooks[event_type] = cleaned
    else:
        del hooks[event_type]

if not hooks and 'hooks' in settings:
    del settings['hooks']

pathlib.Path(settings_path).write_text(json.dumps(settings, indent=2) + '\n')
print(f'Removed {removed} Aegis hook(s).')
"@
    $TempScript = [System.IO.Path]::GetTempFileName() + ".py"
    $RemoveScript | Set-Content -Path $TempScript -Encoding UTF8
    try {
        & $PythonBin $TempScript $SettingsTarget $AegisRepo
        Write-Ok "Hooks removed from $SettingsTarget"
    } finally {
        Remove-Item $TempScript -ErrorAction SilentlyContinue
    }
} else {
    Write-Warn "Settings file not found — skipping hook removal"
}

# ── Step 4: Optionally remove local repo ─────────────────────────────────────
Write-Step "Step 4/4 — Local repo ($AegisRepo)"

if (Test-Path $AegisRepo) {
    $confirm = Read-Host "  Remove $AegisRepo? This deletes local customizations. [y/N]"
    if ($confirm -match "^[yY]") {
        Remove-Item -Recurse -Force $AegisRepo
        # Remove ~/.aegis if empty
        if ((Get-ChildItem $AegisDir -Force | Measure-Object).Count -eq 0) {
            Remove-Item -Force $AegisDir
        }
        Write-Ok "Removed $AegisRepo"
    } else {
        Write-Ok "Kept $AegisRepo (skipped)"
    }
} else {
    Write-Warn "Repo directory not found — skipping"
}

Write-Host "`nUninstall complete." -ForegroundColor Green
Write-Host "External MCPs (Serena, Lumen, Graphify, drawio) were not modified.`n"
