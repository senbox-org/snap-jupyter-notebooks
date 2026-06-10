#!/usr/bin/env bash
# setup_ds_insar.sh - one-shot environment setup for the SNAP DS-InSAR phase-linking notebook
# (snap-nb-sar-ds-insar-timeseries.ipynb) on macOS / Linux.
#
# Prereqs you install yourself first:
#   * SNAP 14 (the installer)
#   * Python 3.13 (python3.13 on PATH, or pass PYTHON=...)
#
# Usage:   bash setup_ds_insar.sh
#   env overrides:  SNAP_HOME=/opt/esa-snap  PYTHON=python3.13  SKIP_SNAPHU=1
set -euo pipefail
info(){ printf '\033[36m[setup]\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m[warn]\033[0m  %s\n' "$*"; }
die (){ printf '\033[31m[error]\033[0m %s\n' "$*"; exit 1; }

PYTHON="${PYTHON:-python3.13}"
command -v "$PYTHON" >/dev/null 2>&1 || PYTHON=python3
command -v "$PYTHON" >/dev/null 2>&1 || die "Python 3.13 not found. Install it and/or set PYTHON=..."
info "Python: $($PYTHON --version 2>&1)"

# 1) locate SNAP -------------------------------------------------------------
if [ -z "${SNAP_HOME:-}" ]; then
  for c in "$HOME/esa-snap" /opt/esa-snap /usr/local/esa-snap /Applications/esa-snap "$HOME/snap"; do
    [ -x "$c/bin/gpt" ] && SNAP_HOME="$c" && break
  done
fi
[ -n "${SNAP_HOME:-}" ] && [ -x "$SNAP_HOME/bin/gpt" ] || die "SNAP not found. Set SNAP_HOME=/path/to/esa-snap (must contain bin/gpt)."
info "SNAP found: $SNAP_HOME"

# 2) Python packages ---------------------------------------------------------
info "installing Python packages (esa_snappy, jpy, numpy, matplotlib, jupyterlab, nbconvert) ..."
"$PYTHON" -m pip install --upgrade pip >/dev/null
if ! "$PYTHON" -m pip install esa_snappy jpy numpy matplotlib jupyterlab nbconvert; then
  warn "pip install of esa_snappy failed; falling back to SNAP's snappy-conf ..."
  "$SNAP_HOME/bin/snappy-conf" "$($PYTHON -c 'import sys;print(sys.executable)')"
  "$PYTHON" -m pip install jpy numpy matplotlib jupyterlab nbconvert
fi

# 3) esa_snappy.ini + snapista ----------------------------------------------
SP="$("$PYTHON" -c 'import sysconfig;print(sysconfig.get_paths()["purelib"])')"
ESA="$SP/esa_snappy"
[ -d "$ESA" ] || die "esa_snappy not found in site-packages ($ESA)."
printf '[DEFAULT]\nsnap_home = %s\njava_max_mem = 6G\n' "$SNAP_HOME" > "$ESA/esa_snappy.ini"
info "wrote $ESA/esa_snappy.ini"
if [ -d "$ESA/snapista" ] && [ ! -d "$SP/snapista" ]; then
  cp -r "$ESA/snapista" "$SP/snapista"; info "copied snapista -> $SP/snapista"
else info "snapista already present (or bundled copy missing)"; fi

# 4) SNAPHU (native; enables Parts 3-4) -------------------------------------
if [ -z "${SKIP_SNAPHU:-}" ] && ! command -v snaphu >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    warn "installing snaphu via apt (needs sudo) ..."; sudo apt-get update -qq && sudo apt-get install -y snaphu || warn "apt snaphu failed"
  elif command -v brew >/dev/null 2>&1; then
    warn "installing snaphu via brew ..."; brew install snaphu || warn "brew snaphu failed"
  else
    warn "no apt/brew; building snaphu from source (no sudo) ..."
    P="$HOME/snaphu-build"; V=2.0.5; mkdir -p "$P"; cd "$P"
    [ -f "snaphu-v$V.tar.gz" ] || curl -fsSL -o "snaphu-v$V.tar.gz" "https://web.stanford.edu/group/radar/softwareandlinks/sw/snaphu/snaphu-v$V.tar.gz"
    tar xzf "snaphu-v$V.tar.gz"; ( cd "snaphu-v$V/src" && make CFLAGS="-O3 -Wall" >/dev/null 2>&1 ) || true
    if [ -x "$P/snaphu-v$V/bin/snaphu" ]; then
      warn "built $P/snaphu-v$V/bin/snaphu - add it to PATH, or set SNAPHU_BIN in the notebook to this path."
    else warn "snaphu source build failed; Parts 3-4 will auto-skip."; fi
    cd - >/dev/null
  fi
fi
command -v snaphu >/dev/null 2>&1 && info "snaphu on PATH: $(command -v snaphu)" || warn "snaphu not on PATH (Parts 3-4 auto-skip unless you set SNAPHU_BIN)."

# 5) PATH hint + preflight ---------------------------------------------------
case ":$PATH:" in *":$SNAP_HOME/bin:"*) :;; *) warn "Add SNAP bin to PATH so snapista finds gpt:  export PATH=\"\$PATH:$SNAP_HOME/bin\"";; esac
info "preflight ..."
PATH="$PATH:$SNAP_HOME/bin" "$PYTHON" -c "import esa_snappy, snapista; print('  esa_snappy + snapista import OK')"
if "$SNAP_HOME/bin/gpt" PhaseLinking -h >/dev/null 2>&1; then info "gpt PhaseLinking resolves OK"; else warn "gpt PhaseLinking did NOT resolve - update the Microwave Toolbox."; fi

echo
info "DONE.  Run:  export PATH=\"\$PATH:$SNAP_HOME/bin\" && $PYTHON -m jupyter lab"
info "then open snap-nb-sar-ds-insar-timeseries.ipynb (the stack auto-downloads on first run)."
