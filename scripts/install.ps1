<#
.SYNOPSIS
    Aegis plugin installer for Windows (PowerShell).

.DESCRIPTION
    Clones/updates the Aegis repo, installs the plugin, copies rules,
    and merges hooks into Claude Code settings.

.PARAMETER Project
    Install at project level (current directory) instead of user level (~/.claude).

.EXAMPLE
    .\scripts\install.ps1
    .\scripts\install.ps1 -Project
#>

[CmdletBinding()]
param(
    [switch]$Project
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoUrl   = "https://github.com/JottaPMarson/Aegis-System-.git"
$AegisDir  = Join-Path $env:USERPROFILE ".aegis"
$AegisRepo = Join-Path $AegisDir "repo"
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

if ($Project) {
    $RulesTarget    = Join-Path (Get-Location) ".claude\rules\aegis"
    $SettingsTarget = Join-Path (Get-Location) ".claude\settings.json"
    Write-Host "`nAegis installer — project mode ($(Get-Location))" -ForegroundColor Cyan
} else {
    $RulesTarget    = Join-Path $ClaudeDir "rules\aegis"
    $SettingsTarget = Join-Path $ClaudeDir "settings.json"
    Write-Host "`nAegis installer — user mode" -ForegroundColor Cyan
}

function Write-Ok   ($msg) { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Warn ($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Step ($msg) { Write-Host "`n-- $msg" -ForegroundColor White }
function Write-Fail ($msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red; exit 1 }

# ── Prerequisites ─────────────────────────────────────────────────────────────
Write-Step "Checking prerequisites"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Fail "git is required. Install Git for Windows and retry."
}
Write-Ok "git: $(git --version)"

if (-not (Get-Command python3 -ErrorAction SilentlyContinue) -and
    -not (Get-Command python  -ErrorAction SilentlyContinue)) {
    Write-Fail "python3 is required. Install Python 3 and retry."
}
$PythonBin = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { "python" }
Write-Ok "python: $( & $PythonBin --version )"

$ClaudeBin = $null
if (Get-Command claude -ErrorAction SilentlyContinue) {
    $ClaudeBin = "claude"
    Write-Ok "claude CLI: $(claude --version 2>$null | Select-Object -First 1)"
} else {
    Write-Warn "claude CLI not found — plugin step will show manual instructions."
}

# ── Step 1: Clone / update repo ───────────────────────────────────────────────
Write-Step "Step 1/5 — Clone/update repo -> $AegisRepo"

New-Item -ItemType Directory -Force -Path $AegisDir | Out-Null

if (Test-Path (Join-Path $AegisRepo ".git")) {
    Write-Host "  Repo exists, pulling latest..."
    try { git -C $AegisRepo pull --ff-only; Write-Ok "Repo updated" }
    catch { Write-Warn "git pull failed. Using existing repo as-is." }
} else {
    git clone $RepoUrl $AegisRepo
    Write-Ok "Repo cloned to $AegisRepo"
}

# ── Step 2: Install plugin ────────────────────────────────────────────────────
Write-Step "Step 2/5 — Register plugin with Claude Code"

if ($ClaudeBin) {
    try {
        Push-Location $AegisRepo
        & claude plugin install . 2>$null
        Write-Ok "Plugin installed via 'claude plugin install .'"
    } catch {
        Write-Warn "Plugin registration failed or not yet supported in this Claude Code version."
        Write-Warn "To install manually: cd $AegisRepo; claude plugin install ."
    } finally {
        Pop-Location
    }
} else {
    Write-Warn "Claude CLI not available. Install the plugin manually:"
    Write-Warn "  cd $AegisRepo; claude plugin install ."
}

# ── Step 3: Copy rules ────────────────────────────────────────────────────────
Write-Step "Step 3/5 — Copy rules -> $RulesTarget"

New-Item -ItemType Directory -Force -Path $RulesTarget | Out-Null
$SourceRules = Join-Path $AegisRepo "rules"
Copy-Item -Recurse -Force "$SourceRules\*" $RulesTarget
$RuleCount = (Get-ChildItem -Recurse -Filter "*.md" $RulesTarget).Count
Write-Ok "Rules copied ($RuleCount .md files) -> $RulesTarget"

# ── Step 4: Merge hooks ───────────────────────────────────────────────────────
Write-Step "Step 4/5 — Merge hooks -> $SettingsTarget"

$HooksPath = Join-Path $AegisRepo "hooks\hooks.json"
$MergeScript = @"
import json, sys, pathlib

settings_path = sys.argv[1]
hooks_path    = sys.argv[2]
repo_path     = sys.argv[3]

try:
    with open(settings_path) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

with open(hooks_path) as f:
    raw = f.read().replace('`${CLAUDE_PLUGIN_ROOT}', repo_path)
aegis_hooks = json.loads(raw)

if 'hooks' not in settings:
    settings['hooks'] = {}

merged = skipped = 0
for event_type, hook_entries in aegis_hooks.items():
    if event_type not in settings['hooks']:
        settings['hooks'][event_type] = []
    for entry in hook_entries:
        matcher = entry.get('matcher')
        for hook in entry.get('hooks', []):
            cmd = hook.get('command', '')
            already = any(
                h.get('command') == cmd
                for e in settings['hooks'][event_type]
                if e.get('matcher') == matcher
                for h in e.get('hooks', [])
            )
            if already:
                skipped += 1
                continue
            target = next((e for e in settings['hooks'][event_type]
                           if e.get('matcher') == matcher), None)
            if target is None:
                target = {'matcher': matcher, 'hooks': []}
                settings['hooks'][event_type].append(target)
            target['hooks'].append(hook)
            merged += 1

out = pathlib.Path(settings_path)
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(settings, indent=2) + '\n')
print(f'Hooks: {merged} merged, {skipped} already present.')
"@

$TempScript = [System.IO.Path]::GetTempFileName() + ".py"
$MergeScript | Set-Content -Path $TempScript -Encoding UTF8
try {
    & $PythonBin $TempScript $SettingsTarget $HooksPath $AegisRepo
    Write-Ok "Hooks merged into $SettingsTarget"
} finally {
    Remove-Item $TempScript -ErrorAction SilentlyContinue
}

# ── Step 5: Health check ──────────────────────────────────────────────────────
Write-Step "Step 5/5 — Running health check"

$DoctorScript = Join-Path $AegisRepo "scripts\doctor.ps1"
if (Test-Path $DoctorScript) {
    if ($Project) { & $DoctorScript -Project } else { & $DoctorScript }
} else {
    Write-Warn "doctor.ps1 not found at $DoctorScript — skipping."
}

Write-Host "`nInstallation complete." -ForegroundColor Green
Write-Host "To verify at any time: $AegisRepo\scripts\doctor.ps1`n"
