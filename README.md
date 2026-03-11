# tariffwar

`tariffwar` is a MATLAB package for solving Nash equilibrium tariffs in a multi-country, multi-sector trade model and reporting the welfare effects of a global tariff war. It ships with prebuilt `.mat` files for WIOD, ICIO and ITPD, so a new user can run the simulator in minutes without downloading raw data.

The package now has two entry paths:

- Quickstart: run the simulator from bundled data and write `results/results.csv`.
- Optional map export: add `'save_map', true` to save a static world welfare map alongside the CSV.

## What It Covers

| Dataset | Years | Countries | Sectors |
| --- | --- | --- | --- |
| `wiod` | 2000-2014 | 44 | 16 |
| `icio` | 2011-2022 | 81 | 28 |
| `itpd` | 2000-2019 | 135 | 154 |

The package includes eight elasticity specifications:
`IS`, `U4`, `CP`, `BSY`, `GYY`, `Shap`, `FGO`, and `LL`.

## Install Or Download

Clone the repository or download the ZIP, then open the repository root in MATLAB. The folder name does not matter.

```bash
git clone <repo-url> tariffwar
cd tariffwar
```

MATLAB needs the repository root on the path:

```matlab
addpath(pwd)
```

## One-Minute Quickstart

This path uses the bundled `mat/` files and bundled GDP lookup. It does not download raw data.

```matlab
addpath(pwd)
results = tariffwar.pipeline.run('wiod', 2014, 'IS', 'Display', 'off');
```

Or run the checked-in example:

```matlab
run(fullfile('examples', 'quickstart.m'))
```

On a recent machine, `wiod` / `2014` / `IS` finishes in a few seconds.

## Expected Output

The quickstart writes:

- `results/results.csv`

For a single run, the returned struct also includes:

- `results.csv_file`
- `results.pct_change`
- `results.dollar_change`
- `results.countries`
- `results.exitflag`
- `results.map_file`
- `results.map_files`

The CSV schema is:

```text
Country,Year,Dataset,Elasticity,Percent_Change,Dollar_Change,Real_GDP,Exitflag
```

`Exitflag = 1` is a clean solve. Other non-zero values can still indicate an acceptable numerical solution.

## Optional World Map Export

Add `'save_map', true` to export a static choropleth that matches the dashboard-style `% welfare change` view. The CSV still gets written.

```matlab
addpath(pwd)
results = tariffwar.pipeline.run('wiod', 2014, 'IS', ...
    'Display', 'off', ...
    'save_map', true);
```

Or run:

```matlab
run(fullfile('examples', 'quickstart_with_map.m'))
```

This writes:

- `results/results.csv`
- `results/maps/welfare_map_wiod_2014_IS.png`

You can choose a different map directory:

```matlab
tariffwar.pipeline.run('wiod', 2014, 'IS', ...
    'Display', 'off', ...
    'save_map', true, ...
    'map_output_dir', fullfile(pwd, 'my_maps'));
```

Small territories and aggregate codes without map geometry, such as `ROW`, are omitted with a warning. The simulation still completes.

## Batch Example

Run more than one dataset, year or elasticity in one call:

```matlab
addpath(pwd)
results = tariffwar.pipeline.run( ...
    {'wiod', 'icio'}, ...
    [2014, 2019], ...
    {'IS', 'U4'}, ...
    'Display', 'off', ...
    'save_map', true);
```

Years without a bundled `.mat` file are skipped.

Each completed run appends rows to `results/results.csv`. If map export is on, each run also writes a deterministic PNG:

```text
results/maps/welfare_map_<dataset>_<year>_<elasticity>.png
```

`results.map_files` lists the saved map paths.

## Rebuild From Raw Data

You only need this path if you want to rebuild the bundled `.mat` files from source data.

### Requirements

- MATLAB R2016b or later
- Optimization Toolbox
- Python 3 with:

```bash
pip install pandas pyxlsb py7zr
```

- Internet access for the public datasets
- A manual browser download for the Teti tariff archive

### Rebuild Workflow

```matlab
addpath(pwd)
tariffwar.io.download_all()
tariffwar.pipeline.build_all('dataset', 'all', 'verbose', true)
```

Notes:

- `raw_data/` is gitignored and is not needed for the quickstart.
- `tariffwar.io.download_all()` is idempotent. It skips files that already exist.
- The Teti tariff download opens a browser window because Dropbox blocks programmatic download.

## Troubleshooting

- `tariffwar.pipeline.run` not found: make sure MATLAB is in the repository root when you call `addpath(pwd)`. Do not add the inner `+tariffwar/` folder directly.
- `Optimization Toolbox` missing: `fsolve` is required for both the balanced-trade step and the Nash solver.
- Dollar values are `NaN`: the simulator could not find GDP data. The public quickstart includes a bundled GDP lookup under `support/gdp/`; if you removed it, re-download GDP with `tariffwar.io.download_gdp()`.
- A map warning lists omitted countries: that means those codes have no geometry in the local world asset. The solver output is still valid.

## Platform Notes

- macOS: supported and used for development.
- Linux: supported.
- Windows: supported. Python should be on `PATH`. `awk` helps with large tariff-file filtering, but the code falls back to pure MATLAB if `awk` is unavailable.

## Main Entry Points

- `tariffwar.pipeline.run`: the public entry point for quick runs and batch runs.
- `tariffwar.main`: a batch template for full rebuild workflows. It is not the recommended quickstart.

## Reference

The package implements the sufficient-statistics approach in:

Lashkaripour, A. (2021). "The Cost of a Global Tariff War: A Sufficient-Statistics Approach." *Journal of International Economics*, 131, 103489.
