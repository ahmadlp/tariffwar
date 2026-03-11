# tariffwar

`tariffwar` is a MATLAB package for solving Nash equilibrium tariffs in a multi-country, multi-sector trade model and reporting the welfare effects of a global tariff war.

The repository includes:

- MATLAB package code under `+tariffwar/`
- bundled `.mat` files for WIOD, ICIO, and ITPD in `mat/`
- example scripts in `examples/`
- optional static world-map export alongside the CSV output

You can run the simulator from the bundled data without rebuilding the raw sources.

## What It Covers

| Dataset | Years | Countries | Sectors |
| --- | --- | --- | --- |
| `wiod` | 2000-2014 | 44 | 16 |
| `icio` | 2011-2022 | 81 | 28 |
| `itpd` | 2000-2019 | 135 | 154 |

The package includes eight elasticity specifications:
`IS`, `U4`, `CP`, `BSY`, `GYY`, `Shap`, `FGO`, and `LL`.

## Data Sources

The simulator is built on five underlying data sources. The bundled `mat/` files let users run the package without rebuilding from those raw inputs, but the sources themselves should be cited when results are reported.

| Source | Coverage in `tariffwar` | Citation |
| --- | --- | --- |
| WIOD 2016 Release | 44 countries, 16 sectors, 2000-2014 | Timmer et al. (2015) |
| OECD ICIO Extended 2023 | 81 countries, 28 sectors, 2011-2022 | OECD (2023) |
| USITC ITPD-S R1.1 | 135 countries, 154 sectors, 2000-2019 | Borchert et al. (2022) |
| Teti Global Tariff Database | Bilateral tariffs, 1988-2021 | Teti (2024) |
| World Bank WDI | GDP in constant 2015 US$, 1960-present | World Bank (2024) |

Data-source citations:

- **WIOD 2016 Release.** Timmer, M.P., Dietzenbacher, E., Los, B., Stehrer, R., and de Vries, G.J. (2015). "An Illustrated User Guide to the World Input-Output Database: The Case of Global Automotive Production." *Review of International Economics*, 23(3), 575-605. Data: [doi.org/10.34894/PJ2M1C](https://doi.org/10.34894/PJ2M1C).
- **OECD ICIO Extended 2023.** OECD (2023). Inter-Country Input-Output Tables, 2023 edition. [oecd.org/en/data/datasets/inter-country-input-output-tables.html](https://www.oecd.org/en/data/datasets/inter-country-input-output-tables.html).
- **USITC ITPD-S R1.1.** Borchert, I., Larch, M., Shikher, S., and Yotov, Y.V. (2022). "The International Trade and Production Database for Estimation (ITPD-E)." *International Economics*, 170, 140-166. Data: [usitc.gov/data/gravity/itpds](https://www.usitc.gov/data/gravity/itpds).
- **Teti Global Tariff Database.** Teti, F. (2024). "30+ Years of Trade Policy: Evidence from 160 Countries." ECARES Working Paper 2024-04.
- **World Bank WDI.** World Bank (2024). World Development Indicators. Indicator `NY.GDP.MKTP.KD` (GDP, constant 2015 US$). [data.worldbank.org](https://data.worldbank.org).

## Trade Elasticity Sources

`tariffwar` includes eight elasticity sources. When a source uses a different sector classification, the package maps it into the target dataset through the concordance matrices in `+tariffwar/+concordance/`.

| Abbrev | Source | Native sectors | Classification | Citation |
| --- | --- | --- | --- | --- |
| `IS` | In-sample, dataset-specific | 16 | WIOD-16 | WIOD: Lashkaripour (2021); ICIO/ITPD: Caliendo-Parro-style trilateral estimation in-package |
| `U4` | Uniform elasticity | 1 | Uniform | Simonovska and Waugh (2014) |
| `CP` | Caliendo-Parro | 20 | ISIC Rev. 3 | Caliendo and Parro (2015) |
| `BSY` | Bagwell-Staiger-Yurukoglu | 49 | SITC Rev. 2 | Bagwell, Staiger, and Yurukoglu (2021) |
| `GYY` | Giri-Yi-Yilmazkuday | 19 | OECD / ISIC-based mapping | Giri, Yi, and Yilmazkuday (2021) |
| `Shap` | Shapiro | 13 | HS sections | Shapiro (2016) |
| `FGO` | Fontagne-Guimbard-Orefice | 19 | TiVA | Fontagne, Guimbard, and Orefice (2022) |
| `LL` | Lashkaripour-Lugovskyy | 14 | ISIC Rev. 4 | Lashkaripour and Lugovskyy (2023) |

Notes:

- `IS` is not a generic placeholder. For WIOD it follows the in-sample values reported in Lashkaripour (2021). For ICIO and ITPD it is estimated in the package using the Caliendo-Parro trilateral ratio strategy.
- `U4` is implemented as a uniform trade elasticity of 4, which implies `sigma = 5` in the CES layer used by the solver.

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

This example uses the bundled `mat/` files and bundled GDP lookup. It does not download raw data.

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

This run writes:

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
- Dollar values are `NaN`: the simulator could not find GDP data. The repository includes a bundled GDP lookup under `support/gdp/`; if you removed it, re-download GDP with `tariffwar.io.download_gdp()`.
- A map warning lists omitted countries: that means those codes have no geometry in the local world asset. The solver output is still valid.

## Platform Notes

- macOS: supported and used for development.
- Linux: supported.
- Windows: supported. Python should be on `PATH`. `awk` helps with large tariff-file filtering, but the code falls back to pure MATLAB if `awk` is unavailable.

## Main Entry Points

- `tariffwar.pipeline.run`: the main entry point for quick runs and batch runs.
- `tariffwar.main`: a batch template for full rebuild workflows. It is not the recommended quickstart.

## Reference

The package implements the sufficient-statistics approach in:

Lashkaripour, A. (2021). "The Cost of a Global Tariff War: A Sufficient-Statistics Approach." *Journal of International Economics*, 131, 103489.

Additional elasticity references:

- Bagwell, K., Staiger, R.W., and Yurukoglu, A. (2021). "Multilateral Trade Bargaining: A First Look at the GATT Bargaining Records." *Econometrica*, 89(4), 1723-1764.
- Caliendo, L. and Parro, F. (2015). "Estimates of the Trade and Welfare Effects of NAFTA." *Review of Economic Studies*, 82(1), 1-44.
- Fontagne, L., Guimbard, H., and Orefice, G. (2022). "Tariff-Based Product-Level Trade Elasticities." *Journal of International Economics*, 137, 103593.
- Giri, R., Yi, K.-M., and Yilmazkuday, H. (2021). "Gains from Trade: Does Sectoral Heterogeneity Matter?" *Journal of International Economics*, 129, 103429.
- Lashkaripour, A. and Lugovskyy, V. (2023). "Profits, Scale Economies, and the Gains from Trade and Industrial Policy." *American Economic Review*, 113(10), 2759-2808.
- Shapiro, J.S. (2016). "Trade Costs, CO2, and the Environment." *American Economic Journal: Economic Policy*, 8(4), 220-254.
- Simonovska, I. and Waugh, M.E. (2014). "The Elasticity of Trade: Estimates and Evidence." *Journal of International Economics*, 92(1), 34-50.
