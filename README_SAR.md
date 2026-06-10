# SAR demo notebooks (`snap-nb-sar-*`)

SAR workflow notebooks are built on the ESA SNAP **Microwave Toolbox**, driven from
Python via **`esa_snappy`** (the SNAP Python API) and **`snapista`** (Python wrapper that
builds and runs SNAP GPF graphs).

| Notebook | Topic | Complexity |
|---|---|---|
| `snap-nb-sar-speckle-filter-showcase` | Compare 9 speckle filters + ENL metric | intermediate |
| `snap-nb-sar-optical-collocation` | Fuse Sentinel-1 backscatter with Sentinel-2 indices | advanced |
| `snap-nb-sar-gslc-insar` | Geocoded SLC (GSLC) and GSLC-based InSAR | advanced |
| `snap-nb-sar-s1-classical-insar-displacement` | Classical S1 InSAR → unwrap → displacement | advanced |
| `snap-nb-sar-s1-etad-insar` | ETAD correction and ETAD-enhanced InSAR | advanced |
| `snap-nb-sar-ds-insar-timeseries` | DS-InSAR time series: Phase Linking (SqueeSAR / EVD / EMI) + SBAS | advanced |
| `snap-nb-sar-rcm-compact-pol` | RCM compact polarimetry (CP-RVI, Stokes, decompositions) | advanced |
| `snap-nb-sar-biomass-polarimetric` | BIOMASS P-band quad-pol processing | advanced |

---

## 1. One-time environment setup

Verified with **SNAP 14**, **Python 3.13** (Windows), **jpy 2.1.0**. Adapt versions/paths to your system.

> **Shortcut:** the steps below are automated by **`setup_ds_insar.ps1`** (Windows) and
> **`setup_ds_insar.sh`** (macOS/Linux) — one command configures `esa_snappy` + `snapista`, installs
> the notebook deps, **and** builds SNAPHU. Despite the name they set up the whole SAR notebook
> environment, not just DS-InSAR (see **`README_ds_insar_setup.md`**). The manual steps below are the
> reference / fallback.

### Prerequisites
- **ESA SNAP** installed with the **Sentinel-1 / Microwave Toolbox** (provides `gpt` and the SAR operators).
  Default Windows location: `C:\Program Files\esa-snap`.
- A real **Python 3.13** install (the Microsoft Store "python3.10" stub does **not** work).
  All commands below use the `py -3.13` launcher.

### Steps

1. **Install the native Java↔Python bridge (`jpy`)** — a prebuilt wheel exists for cp313:
   ```powershell
   py -3.13 -m pip install jpy
   ```

2. **Make sure `esa_snappy` is present and points at SNAP.**
   `esa_snappy` ships with SNAP; configure it for your Python with SNAP's helper:
   ```powershell
   & "C:\Program Files\esa-snap\bin\snappy-conf.bat" (py -3.13 -c "import sys;print(sys.executable)")
   ```
   Then tell `esa_snappy` where SNAP lives by creating a config file named **`esa_snappy.ini`**
   (the filename must match the package dir name) inside the `esa_snappy` package directory:
   ```powershell
   $sp = py -3.13 -c "import sysconfig;print(sysconfig.get_paths()['purelib'])"
   @"
   [DEFAULT]
   snap_home = C:/Program Files/esa-snap
   "@ | Set-Content "$sp\esa_snappy\esa_snappy.ini"
   ```
   (Alternatively set a `SNAP_HOME` environment variable instead of the `.ini`.)

3. **Install `snapista`.** It is **not on PyPI** — it is bundled inside `esa_snappy`. Copy it to a
   top-level package so `import snapista` works:
   ```powershell
   $sp = py -3.13 -c "import sysconfig;print(sysconfig.get_paths()['purelib'])"
   if (-not (Test-Path "$sp\snapista")) { Copy-Item -Recurse "$sp\esa_snappy\snapista" "$sp\snapista" }
   ```

4. **Install the notebook + plotting dependencies:**
   ```powershell
   py -3.13 -m pip install numpy matplotlib jupyterlab nbconvert ipykernel
   ```

5. **Verify:**
   ```powershell
   py -3.13 -c "import esa_snappy; from esa_snappy import ProductIO; from snapista import Graph, Operator, TargetBand, TargetBandDescriptors; print('OK')"
   ```
   Should print `OK` (after the SNAP JVM starts — the first import takes ~30–60 s).

---

## 2. Running a notebook

From **this folder** (`resources/jupyter_notebooks`) so the relative `data/` path resolves:

**Interactive (JupyterLab):**
```powershell
cd "<repo>\resources\jupyter_notebooks"
py -3.13 -m jupyter lab
```
Open the notebook → **Run ▸ Run All Cells** (default `python3` kernel = the 3.13 env above).

**Headless (one command, also repopulates saved outputs):**
```powershell
py -3.13 -m nbconvert --to notebook --execute --inplace --ExecutePreprocessor.timeout=600 snap-nb-sar-speckle-filter-showcase.ipynb
```

**VS Code:** open the `.ipynb`, pick the Python 3.13 interpreter as the kernel, Run All.

### Notes
- **No `SNAP_HOME` needed** once `esa_snappy.ini` is set.
- **Internet required on first run** — several notebooks **auto-download their demo data** (a small
  Etna or Santorini scene) from public S3 and cache it under `data/` (see §3); `Apply-Orbit-File`
  fetches precise orbits and `Copernicus 30m` DEM tiles are pulled on demand (all cached afterwards).
- Each notebook writes intermediate products to `results/` and saves its GPF graph XML to `graphs/`.

---

## 3. Input data

Notebooks get their input one of three ways:

- **Bundled** — a small subset committed in `data/`, read directly (runs out of the box, no account).
- **Auto-downloaded from public S3** — the InSAR notebooks pull a small Etna/Santorini demo scene on
  first run and cache it under `data/` (no account, just internet). Set `STACK_URL=''` / edit the
  `fetch_cached(...)` URL in the *Configure input paths* cell to point at your own data instead.
- **Provide yourself** — large/paired/restricted products you download (e.g. the
  [Copernicus Browser](https://dataspace.copernicus.eu/browser/), registration required), place under
  `data/`, and point the config cell at.

| Notebook | Input needed | How it's provided |
|---|---|---|
| speckle-filter-showcase | one S1 GRD (SM/IW) | ✅ **bundled** small SM **HH** GRDH subset in `data/` |
| ds-insar-timeseries | coregistered S1 SLC stack (+ SNAPHU for Parts 3–4) | ⬇️ **auto** — 12-acquisition Etna stack from S3 |
| gslc-insar | SLC pair | ⬇️ **auto** — Part 1: Envisat ASAR Stripmap pair (Santorini); Part 2 (S1 IW, set `RUN_IW=True`): Etna pair |
| s1-classical-insar-displacement | S1 SLC pair (+ SNAPHU for Parts 3–4) | ⬇️ **auto** — Etna S1 IW pair from S3 (~8 GB) |
| s1-etad-insar | S1 SLC pair **+** matching ETAD | ⬇️ **auto** S1 pair from S3; ❌ provide the `*_ETA_*` products yourself |
| optical-collocation | one S1 GRD **+** one S2 L2A | ❌ provide both |
| rcm-compact-pol | RCM compact-pol product (`*MCP*`, [NRCan EODMS](https://eodms-sgdot.nrcan-rncan.gc.ca/)) | ❌ provide one |
| biomass-polarimetric | BIOMASS L1 SCS quad-pol (`BIO_S2_SCS__1S_*`) | ❌ provide one |

To use your own scene in the speckle notebook, drop any Sentinel-1 GRD into `data/` and set
`grd_product` / `polarisation` in the config cell. A scene with both a homogeneous patch (water,
bare field) and structured features (urban, roads) gives the most informative ENL / edge comparison.

### SNAPHU (phase unwrapping)

`ds-insar-timeseries` and `s1-classical-insar-displacement` unwrap with external
[SNAPHU](https://web.stanford.edu/group/radar/softwareandlinks/sw/snaphu/), which has **no native
Windows build**. The cells that need it **skip automatically** if it isn't found, so the rest of each
notebook still runs. The `setup_ds_insar.*` scripts build it for you (WSL on Windows; brew/apt/source
on macOS/Linux). The **ds-insar** notebook then auto-detects it — a `snaphu` on `PATH`, a macOS/Linux
source build, or a WSL build; for the **classical** notebook put `snaphu` on `PATH` (or set `SNAPHU_BIN`).
See `README_ds_insar_setup.md`.

---

## 4. Troubleshooting

- **`ModuleNotFoundError: jpyutil`** → `jpy` not installed for this Python (`py -3.13 -m pip install jpy`).
- **`Can't find SNAP distribution directory`** → `esa_snappy.ini` missing/wrong (step 2) or `SNAP_HOME` unset.
- **`ModuleNotFoundError: snapista`** → the bundled copy wasn't promoted to top-level site-packages (step 3).
- **`Band 'X' not found`** in a plot cell → the product's polarisation/band names differ; check the
  printed `Bands:` list and adjust the `polarisation` / `find_band(...)` arguments.
- **Slow first import / first run** → the SNAP JVM start, orbit download and DEM download are one-time.
- **`UnicodeDecodeError` from `snapista`'s `Graph.run()`** (Windows) → snapista decodes `gpt`'s console output as UTF-8, but `gpt` emits cp1252. Fix (already applied in the GSLC notebook): before any graph runs, `os.environ.setdefault('JAVA_TOOL_OPTIONS', '-Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8')` so the `gpt` subprocess emits UTF-8. The processing itself completes regardless — only the console decode fails.
