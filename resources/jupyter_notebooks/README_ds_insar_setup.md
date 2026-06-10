# DS-InSAR phase-linking notebook — setup

`snap-nb-sar-ds-insar-timeseries.ipynb` runs the modern Distributed-Scatterer InSAR time-series workflow
(PhaseLinking → MultiMasterInSAR → SNAPHU → SBASInversion) entirely inside the SNAP Microwave Toolbox.

The demo input — a small coregistered 12-acquisition Sentinel-1 stack over **Mt Etna** — **downloads
automatically** on first run (~1 GB, cached in `data/`). You do **not** need to stage any data.

## TL;DR

1. **Install SNAP 14** (the bundled installer). Keep the default location.
2. **Install Python 3.13** from python.org (the Microsoft Store "3.10" stub will **not** work; 3.14 is too new).
3. Run the setup script for your OS (one command — see below).
4. Open a **new** terminal and launch Jupyter; open the notebook and Run All.

## Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\setup_ds_insar.ps1
# options:  -SnapHome "D:\esa-snap"   -PyVersion 3.13   -SkipSnaphu
```

Then:
```powershell
py -3.13 -m jupyter lab
```

## macOS / Linux

```bash
bash setup_ds_insar.sh
# env overrides:  SNAP_HOME=/opt/esa-snap  PYTHON=python3.13  SKIP_SNAPHU=1
```

Then:
```bash
export PATH="$PATH:$SNAP_HOME/bin" && python3.13 -m jupyter lab
```

## What the setup script does (so nobody has to do it by hand)

| Step | Why it's needed |
|------|-----------------|
| `pip install esa_snappy jpy numpy matplotlib jupyterlab nbconvert` | the SNAP↔Python bridge + plotting/Jupyter (falls back to SNAP's `snappy-conf` if PyPI install fails) |
| writes **`esa_snappy.ini`** in the `esa_snappy` package dir (`snap_home`, `java_max_mem=6G`) | esa_snappy won't find SNAP without it; the filename **must** equal the package dir name |
| copies **`snapista`** from `esa_snappy/snapista` → top-level `site-packages/snapista` | snapista is bundled inside esa_snappy, **not** on PyPI |
| adds SNAP `bin` to `PATH` | so snapista can find `gpt` |
| builds **SNAPHU** (WSL on Windows, apt/brew/source on Mac/Linux) | phase unwrapping for Parts 3–4 (no native Windows binary exists) |
| preflight: `import esa_snappy, snapista` + `gpt PhaseLinking -h` | fails fast with a clear message if anything is off |

## What runs without SNAPHU

- **Parts 1, 1b, 2** (phase linking, the DS coherence gain, the small-baseline network) need **no SNAPHU**.
- **Parts 3–4** (network unwrapping → velocity + displacement time series) need SNAPHU. If it isn't found,
  those cells **skip automatically** and the rest of the notebook still runs.

### SNAPHU on Windows (Parts 3–4)
SNAPHU has no native Windows build, so it runs through **WSL**. The setup script builds it from source
in WSL (no sudo). If WSL is missing build tools it will tell you to run **once**:
```powershell
wsl -e bash -lc 'sudo apt-get update && sudo apt-get install -y build-essential curl'
```
then re-run `setup_ds_insar.ps1`. The notebook auto-detects the WSL binary at
`~/snaphu-build/snaphu-v2.0.5/bin/snaphu` (override via `SNAPHU_WSL` in the config cell).

## Troubleshooting

- **`gpt PhaseLinking` → "Unknown operator"**: your Microwave Toolbox predates these operators — update it in SNAP (Help → Check for Updates) or install a build with `sar-op-insar`.
- **`import esa_snappy` fails**: confirm `esa_snappy.ini` exists in the package dir and points at your SNAP home with forward slashes.
- **`UnicodeDecodeError` from snapista on Windows**: the notebook already sets `JAVA_TOOL_OPTIONS` for UTF-8; make sure you launched Jupyter from a shell where that env var is inherited (the notebook sets it itself in the config cell).
- **Out-of-memory / disk reading large products**: `java_max_mem=6G` in `esa_snappy.ini` (raise if you have RAM).
