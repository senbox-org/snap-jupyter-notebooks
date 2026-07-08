<#
  setup_ds_insar.ps1  -  one-shot environment setup for the SNAP DS-InSAR phase-linking notebook
  (snap-nb-sar-ds-insar-timeseries.ipynb) on Windows.

  Prereqs you install yourself first:
    * SNAP 14 (the installer)            -> default C:\Program Files\esa-snap
    * Python 3.13 (python.org)           -> the 'py' launcher must work: `py -3.13 --version`
    * (optional, for Parts 3-4) WSL with Ubuntu + build tools (build-essential, curl)

  Then just run:   powershell -ExecutionPolicy Bypass -File .\setup_ds_insar.ps1
  Options:  -SnapHome "D:\esa-snap"   -PyVersion 3.13   -SkipSnaphu
#>
[CmdletBinding()]
param(
  [string]$SnapHome  = 'C:\Program Files\esa-snap',
  [string]$PyVersion = '3.13',
  [switch]$SkipSnaphu
)
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[setup] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[warn]  $m" -ForegroundColor Yellow }
function Die ($m){ Write-Host "[error] $m" -ForegroundColor Red; exit 1 }

# 1) SNAP -------------------------------------------------------------------
$gpt = Join-Path $SnapHome 'bin\gpt.exe'
if (-not (Test-Path $gpt)) { Die "SNAP not found at '$SnapHome' (no bin\gpt.exe). Install SNAP 14 or pass -SnapHome." }
Info "SNAP found: $SnapHome"

# 2) Python 3.13 ------------------------------------------------------------
try { $pyv = (& py "-$PyVersion" --version) 2>&1 } catch { $pyv = $null }
if (-not $pyv) { Die "Python $PyVersion not found. Install it from python.org (NOT the Microsoft Store stub) so 'py -$PyVersion' works." }
Info "Python: $pyv"

# 3) Python packages --------------------------------------------------------
Info "installing Python packages (esa_snappy, jpy, numpy, matplotlib, jupyterlab, nbconvert) ..."
& py "-$PyVersion" -m pip install --upgrade pip | Out-Null
& py "-$PyVersion" -m pip install esa_snappy jpy numpy matplotlib jupyterlab nbconvert
if ($LASTEXITCODE -ne 0) {
  Warn "pip install of esa_snappy failed; falling back to SNAP's snappy-conf ..."
  $pyExe = (& py "-$PyVersion" -c "import sys;print(sys.executable)")
  & "$SnapHome\bin\snappy-conf.bat" "$pyExe"
  & py "-$PyVersion" -m pip install jpy numpy matplotlib jupyterlab nbconvert
}

# 4) locate site-packages + esa_snappy --------------------------------------
$sp  = (& py "-$PyVersion" -c "import sysconfig;print(sysconfig.get_paths()['purelib'])").Trim()
$esa = Join-Path $sp 'esa_snappy'
if (-not (Test-Path $esa)) { Die "esa_snappy not found in site-packages ($esa)." }

# 5) esa_snappy.ini  (filename MUST equal the package dir name) -------------
$ini     = Join-Path $esa 'esa_snappy.ini'
$snapFwd = $SnapHome -replace '\\','/'
"[DEFAULT]`nsnap_home = $snapFwd`njava_max_mem = 6G`n" | Set-Content -Path $ini -Encoding ASCII
Info "wrote $ini  (snap_home=$snapFwd, java_max_mem=6G)"

# 6) snapista (bundled inside esa_snappy, NOT on PyPI) -> top-level ----------
$bundled = Join-Path $esa 'snapista'
$top     = Join-Path $sp  'snapista'
if (Test-Path $bundled) {
  if (-not (Test-Path $top)) { Copy-Item $bundled $top -Recurse; Info "copied snapista -> $top" }
  else { Info "snapista already present at top-level" }
} else { Warn "bundled snapista not found at $bundled (the 'import snapista' will fail)" }

# 7) PATH: add SNAP bin so snapista finds gpt (user scope + current session)
$bin = Join-Path $SnapHome 'bin'
$userPath = [Environment]::GetEnvironmentVariable('Path','User')
if ($userPath -notlike "*$bin*") {
  [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $bin), 'User')
  Info "added '$bin' to user PATH (effective in new shells)"
} else { Info "SNAP bin already on user PATH" }
if ($env:Path -notlike "*$bin*") { $env:Path += ";$bin" }

# 8) SNAPHU via WSL (optional; enables Parts 3-4) ---------------------------
if (-not $SkipSnaphu) {
  if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Info "building SNAPHU in WSL (no sudo; one-time) ..."
    $build = @'
set -e
for t in gcc make curl tar; do command -v "$t" >/dev/null 2>&1 || MISS="$MISS $t"; done
if [ -n "$MISS" ]; then echo "MISSING_TOOLS:$MISS"; exit 3; fi
PREFIX="$HOME/snaphu-build"; VER=2.0.5; T="snaphu-v$VER.tar.gz"
mkdir -p "$PREFIX"; cd "$PREFIX"
[ -f "$T" ] || curl -fsSL -o "$T" "https://web.stanford.edu/group/radar/softwareandlinks/sw/snaphu/$T"
tar xzf "$T"; cd "snaphu-v$VER/src"; make CFLAGS="-O3 -Wall" >/dev/null 2>&1 || true
if [ -x ../bin/snaphu ]; then echo "SNAPHU_OK $PREFIX/snaphu-v$VER/bin/snaphu"; else echo BUILD_FAILED; exit 4; fi
'@ -replace "`r",""
    $out = ($build | wsl -e bash -s) 2>&1
    if ($out -match 'SNAPHU_OK') { Info "SNAPHU built: ~/snaphu-build/snaphu-v2.0.5/bin/snaphu" }
    elseif ($out -match 'MISSING_TOOLS') {
      Warn "WSL is missing build tools. Run ONCE in WSL, then re-run this script:"
      Warn "    wsl -e bash -lc 'sudo apt-get update && sudo apt-get install -y build-essential curl'"
    } else { Warn "SNAPHU build failed ($out). Parts 3-4 will auto-skip; Parts 1-2 still run." }
  } else {
    Warn "WSL not found -> SNAPHU unavailable. Notebook Parts 3-4 auto-skip; Parts 1-2 run fine."
    Warn "To enable later: install WSL (`wsl --install`), then re-run this script."
  }
}

# 9) preflight --------------------------------------------------------------
Info "preflight checks ..."
& py "-$PyVersion" -c "import esa_snappy, snapista; print('  esa_snappy + snapista import OK')"
& "$gpt" PhaseLinking -h *> $null
if ($LASTEXITCODE -eq 0) { Info "gpt PhaseLinking resolves OK" }
else { Warn "gpt PhaseLinking did NOT resolve - update the Microwave Toolbox in SNAP." }

Write-Host ""
Info "DONE.  Open a NEW terminal (for PATH), then:"
Write-Host "         py -$PyVersion -m jupyter lab" -ForegroundColor Green
Info "and run snap-nb-sar-ds-insar-timeseries.ipynb (the stack auto-downloads on first run)."
