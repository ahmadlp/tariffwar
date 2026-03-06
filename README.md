# Tariff War: Nash Equilibrium Tariffs in a Multi-Country, Multi-Sector Trade Model

This MATLAB package computes the welfare cost of a global tariff war in which every country simultaneously sets its optimal tariff. It implements the computationally efficient sufficient-statistics methodology developed in Proposition 2 of [Lashkaripour (2021)](#references), which characterizes Nash equilibrium tariffs as the solution to a system of 3*N* nonlinear equations in wages, incomes, and tariffs. The package supports three international trade datasets covering 44 to 135 countries, 16 to 154 sectors, and years 2000--2022. Eight alternative sources of sectoral trade elasticities are included, along with an in-sample estimation procedure. Prebuilt data files allow immediate analysis after cloning.

---

## Quick Start

```matlab
addpath('..')                                    % add parent of +tariffwar to MATLAB path
tariffwar.pipeline.run('wiod', 2014, 'IS')       % single dataset-year-elasticity
tariffwar.main                                    % full grid: all datasets x years x elasticities
```

**Output:** `results/results.csv` with country-level welfare changes (percent and dollars).

**Prerequisites:** MATLAB R2016b or later with the Optimization Toolbox. See [Prerequisites](#prerequisites) for data-rebuild dependencies.

---

## Methodology

The analysis follows **Proposition 2** of Lashkaripour (2021), which derives a sufficient-statistics characterization of Nash equilibrium tariffs in a multi-country, multi-sector CES trade model. Each country *i* simultaneously chooses a uniform tariff *t_i* to maximize national welfare, taking all other countries' tariffs as given. The equilibrium is the fixed point of this best-response mapping.

### System of equations

The solver finds the root of a system of 3*N* equations in 3*N* unknowns, stacked as *X* = [*w&#x302;*; *Y&#x302;*; *t*], where *w&#x302;* and *Y&#x302;* denote proportional changes in wages and incomes (hat algebra) and *t* is the vector of optimal tariff levels.

**Equation 6 -- Market clearing (wage income).** Total export revenue of country *i*, net of tariffs collected by importers, equals its wage bill:

> *w&#x302;_i* &middot; *R_i* = &sum;_j &sum;_k &lambda;'_jik &middot; *e_ik* &middot; *Y&#x302;_j* &middot; *Y_j* / (1 + *t_jik*)

where &lambda;'_jik is the updated bilateral trade share (CES demand), *e_ik* is the Cobb-Douglas expenditure weight, and *R_i* is initial wage revenue. The last equation (*i* = *N*) is replaced by a world-wage normalization: &sum;_i *R_i* (*w&#x302;_i* - 1) = 0.

**Equation 7 -- Budget constraint (national income).** National income equals wage income plus tariff revenue:

> *Y&#x302;_i* &middot; *Y_i* = *w&#x302;_i* &middot; *R_i* + &sum;_j &sum;_k [*t_jik* / (1 + *t_jik*)] &middot; &lambda;'_jik &middot; *e_ik* &middot; *Y&#x302;_j* &middot; *Y_j*

**Equation 14 -- Optimal tariff (first-order condition).** The Nash tariff equates the marginal benefit of terms-of-trade improvement to the marginal cost of trade distortion:

> *t_i* = 1 + 1 / &sum;_k (&sigma;_k - 1) &middot; &omega;_ik

where &sigma;_k is the CES elasticity of substitution in sector *k* and &omega;_ik is a trade-weighted inverse supply elasticity measuring how foreign exporters' trade shares respond to country *i*'s tariff.

### Welfare computation

Welfare changes are computed via hat algebra. The real-income change for country *i* is:

> *W&#x302;_i* = *Y&#x302;_i* / *P&#x302;_i*

where the aggregate price index *P&#x302;_i* is a Cobb-Douglas aggregate of sectoral CES price indices:

> *P&#x302;_i* = &prod;_k [&sum;_j &lambda;_jik &middot; (*t&#x302;_jik* &middot; *w&#x302;_j*)^(1 - &sigma;_k)]^(*e_ik* / (1 - &sigma;_k))

The welfare gain is reported as 100 &middot; (*W&#x302;_i* - 1) percent.

### Solver

The system is solved with MATLAB's `fsolve` using the Levenberg-Marquardt algorithm. On failure, the solver retries up to three times with random scalar initial guesses. A stall monitor terminates runs early when the residual norm stops decreasing. The balanced-trade pre-processing step (zero-deficit counterfactual) uses `trust-region-dogleg` with `levenberg-marquardt` as fallback. See [Convergence Strategy](#convergence-strategy) for details.

---

## In-Sample Elasticity Estimation

The in-sample (`IS`) elasticity source estimates sector-level trade elasticities directly from the data using the **trilateral ratio identification strategy** of [Caliendo and Parro (2015)](#references). This approach differences out all bilateral fixed effects (trade costs, multilateral resistance) by forming ratios of trade flows across ordered country triplets.

### Identification

For each sector *k* and each ordered country triplet (*i* < *j* < *n*):

- **Dependent variable:** *Y* = log(*X_ij* &middot; *X_jn* &middot; *X_ni* / *X_ji* &middot; *X_nj* &middot; *X_in*)
- **Regressor:** *X* = log(*t_ij* &middot; *t_jn* &middot; *t_ni* / *t_ji* &middot; *t_nj* &middot; *t_in*)

where *X_ij* is the bilateral trade flow from *i* to *j* and *t_ij* = 1 + tariff rate imposed by *j* on imports from *i*.

### Estimation

The trade elasticity &epsilon;_k = -&beta;_k is recovered from OLS:

- Country fixed effects via Frisch-Waugh-Lovell (FWL) projection, no constant term
- HC1 (heteroskedasticity-consistent) robust standard errors
- Observations pooled across all available years for each dataset

### Sample construction

1. **Sector aggregation.** Native sectors are aggregated to the 16-sector WIOD classification (trade flows summed, tariffs averaged) before estimation.
2. **Country trimming.** Countries below the 2.5th percentile of total imports are excluded.
3. **Outlier trimming.** Observations outside the [1st, 99th] percentile of *Y* are dropped.
4. **Minimum observations.** Sectors with fewer than 30 valid trilateral observations receive a fallback value of &epsilon; = 4.0.
5. **Services.** The services sector is assigned &epsilon; = 5.0 (WIOD) or &epsilon; = 4.0 (ICIO, ITPD) because tariffs on services are typically zero, precluding identification.

### Dataset-specific notes

- **WIOD:** Elasticities are taken directly from Table 1 of [Lashkaripour (2021)](#references), who estimates them on WIOD 2000--2014 using the same trilateral method.
- **ICIO:** Estimation pools ICIO Extended 2011--2022. Sectors with low tariff variation (computers, electrical, machinery, transport, other manufacturing) are pooled and receive the fallback.
- **ITPD:** Estimation pools ITPD-S 2000--2019. Agriculture and mining are pooled due to overlapping HS classifications.

---

## Data Sources

The package uses five publicly available data sources. Raw data is downloaded automatically by `tariffwar.io.download_all()` and stored in `raw_data/` (gitignored). Prebuilt `.mat` files in `mat/` allow analysis without downloading raw data.

| Dataset | Countries | Sectors | Years | Size |
|---------|-----------|---------|-------|------|
| WIOD 2016 Release | 44 (43 + RoW) | 16 (15 goods + 1 services) | 2000--2014 | ~877 MB |
| OECD ICIO Extended 2023 | 81 | 28 (27 goods + 1 services) | 2011--2022 | ~500 MB |
| USITC ITPD-S R1.1 | 135 (filtered from 246) | 154 (153 goods + 1 services) | 2000--2019 | ~1 GB |
| Teti Global Tariff Database | bilateral | ISIC Rev. 3.3 | 1988--2021 | ~240 KB |
| World Bank WDI | 189+ | GDP (constant 2015 USD) | 1960--present | ~2 MB |

### Citations

- **WIOD 2016 Release.** Timmer, M.P., Dietzenbacher, E., Los, B., Stehrer, R., and de Vries, G.J. (2015). "An Illustrated User Guide to the World Input-Output Database: The Case of Global Automotive Production." *Review of International Economics*, 23(3), 575--605. Data: [doi.org/10.34894/PJ2M1C](https://doi.org/10.34894/PJ2M1C).

- **OECD ICIO Extended 2023.** OECD (2023). Inter-Country Input-Output Tables, 2023 edition. [oecd.org/en/data/datasets/inter-country-input-output-tables.html](https://www.oecd.org/en/data/datasets/inter-country-input-output-tables.html).

- **USITC ITPD-S R1.1.** Borchert, I., Larch, M., Shikher, S., and Yotov, Y.V. (2022). "The International Trade and Production Database for Estimation (ITPD-E)." *International Economics*, 170, 140--166. Data: [usitc.gov/data/gravity/itpds](https://www.usitc.gov/data/gravity/itpds).

- **Teti Global Tariff Database.** Teti, F. (2024). "30+ Years of Trade Policy: Evidence from 160 Countries." ECARES Working Paper 2024-04.

- **World Bank WDI.** World Bank (2024). World Development Indicators. Indicator NY.GDP.MKTP.KD (GDP, constant 2015 US$). [data.worldbank.org](https://data.worldbank.org).

---

## Trade Elasticity Sources

The package includes eight sources of sectoral trade elasticities, selectable by abbreviation or full name. When the source classification differs from the target dataset, a concordance matrix maps elasticities to the appropriate sectors (infrastructure in `+concordance/`).

| Abbrev | Source | Sectors | Classification |
|--------|--------|---------|----------------|
| `IS` | In-sample (dataset-specific); see [In-Sample Estimation](#in-sample-elasticity-estimation) | 16 | WIOD-16 |
| `U4` | Simonovska and Waugh (2014) | 1 (uniform &sigma; = 4) | -- |
| `CP` | Caliendo and Parro (2015) | 20 | ISIC Rev. 3 |
| `BSY` | Bagwell, Staiger, and Yurukoglu (2021) | 49 | SITC Rev. 2 |
| `GYY` | Giri, Yi, and Yilmazkuday (2021) | 19 | OECD |
| `Shap` | Shapiro (2016) | 13 | HS sections |
| `FGO` | Fontagn&eacute;, Guimbard, and Orefice (2022) | 19 | TiVA |
| `LL` | Lashkaripour and Lugovskyy (2023) | 14 | ISIC Rev. 4 |

Full citations are in the [References](#references) section.

---

## Code Structure

```
+tariffwar/
|-- main.m                       One-click runner: download -> build -> analyze
|-- defaults.m                   Solver defaults and paths
|-- mat/                         Prebuilt .mat files (analysis works immediately)
|-- raw_data/                    Downloaded external data (gitignored)
|   |-- wiod/                    WIOD CSV files
|   |-- icio/                    ICIO CSV files
|   |-- itpd/                    ITPD-S CSV files
|   |-- tariffs/                 Teti GTD tariff data
|   |-- gdp/                     World Bank GDP data
|   |-- metadata/                Sector aggregation and country list
|-- results/                     Analysis output (generated by pipeline.run)
|
|-- +pipeline/                   Analysis engine
|   |-- run.m                    Load -> balance -> solve -> welfare -> CSV
|   |-- build_all.m              Build .mat files from raw CSVs
|
|-- +solver/                     Nash equilibrium solver
|   |-- nash_equilibrium.m       3N-unknown system via fsolve (retry logic)
|   |-- nash_equations.m         Equations 6, 7, 14 from Lashkaripour (2021)
|   |-- balanced_trade_equations.m  Balanced-trade (D=0) system
|   |-- solver_options.m         Builds optimoptions struct
|   |-- stall_monitor.m          OutputFcn for stall detection
|
|-- +welfare/                    Welfare computation
|   |-- welfare_gains.m          Hat-algebra welfare (percent changes)
|
|-- +data/                       Data processing
|   |-- balance_trade.m          Balanced-trade solver (2N unknowns)
|   |-- compute_derived_cubes.m  Trade shares, income, revenue, expenditure
|   |-- build_cubes_wiod.m       WIOD CSV -> cube
|   |-- build_cubes_icio.m       ICIO CSV -> cube
|   |-- build_cubes_itpd.m       ITPD-S CSV -> cube
|   |-- compute_cubes.m          Z, F, R matrices -> cube
|   |-- inventory_correct.m      Leontief INV=0 correction (WIOD)
|   |-- aggregate_sectors.m      Sector aggregation
|
|-- +io/                         File I/O and download
|   |-- load_data.m              Load prebuilt .mat files
|   |-- load_gdp.m               Load GDP data
|   |-- download_all.m           Master download (idempotent)
|   |-- download_wiod.m          WIOD 2016 Release
|   |-- download_icio.m          OECD ICIO Extended 2023
|   |-- download_itpd.m          USITC ITPD-S R1.1
|   |-- download_tariffs.m       Teti GTD (browser-based)
|   |-- download_gdp.m           World Bank WDI (API)
|   |-- robust_download.m        CDN anti-bot handling
|
|-- +elasticity/                 Trade elasticity infrastructure
|   |-- registry.m               Master registry (8 sources)
|   |-- estimate_cp2014.m        In-sample CP2014 trilateral gravity
|   |-- patch_insample.m         Utility: patch .mat files with IS sigma
|   |-- +sources/                Individual elasticity implementations (8 files)
|
|-- +concordance/                Sector-mapping matrices (10 files)
|-- +tariff/                     Tariff data readers
```

### Key data structures

All core arrays are **N x N x S** cubes where dimension 1 = exporter *j*, dimension 2 = importer *i*, dimension 3 = sector *k*.

| Variable | Description |
|----------|-------------|
| `Xjik_3D` | Bilateral trade flow (*j* exports to *i* in sector *k*) |
| `tjik_3D` | Applied tariff rate (*i* charges on imports from *j* in sector *k*) |
| `lambda_jik3D` | Trade share: *X_jik* / &sum;_j *X_jik*. Sums to 1 over *j* |
| `Yi3D` | Total expenditure of importer *i* (replicated to N x N x S) |
| `Ri3D` | Wage revenue of exporter *j* (replicated to N x N x S) |
| `e_ik3D` | Expenditure share of sector *k* in country *i*. Sums to 1 over *k* |
| `sigma_k3D` | CES elasticity of substitution (&sigma; = &epsilon; + 1) |

---

## Prerequisites

### Analysis (using prebuilt data)

- MATLAB R2016b or later
- Optimization Toolbox (`fsolve`)

### Rebuilding from raw data

In addition to the above:

- **Python 3** with `pandas`, `pyxlsb`, and `py7zr`:
  ```
  pip install pandas pyxlsb py7zr
  ```
- Internet connection for data download (~2.5 GB total)
- Tariff data (Teti GTD) requires a manual browser download from Dropbox

### Platform support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS | Fully supported | Primary development platform |
| Linux | Fully supported | All dependencies available via package manager |
| Windows | Supported | Python must be on PATH; `awk` recommended for fast ITPD/tariff processing (available via Git for Windows) |

---

## API Reference

### `tariffwar.pipeline.run(datasets, years, elasticities, ...)`

Main entry point. Accepts scalar or array/cell inputs. Years without a prebuilt `.mat` file are silently skipped.

```matlab
tariffwar.pipeline.run('wiod', 2014, 'IS')
tariffwar.pipeline.run({'wiod','icio'}, 2000:2022, {'IS','U4','CP'})
tariffwar.pipeline.run('wiod', 2014, 'IS', 'Algorithm', 'trust-region-dogleg')
```

**Year coverage** (prebuilt `.mat` files in `mat/`):

| Dataset | Years | *N* | *S* |
|---------|-------|-----|-----|
| `wiod` | 2000--2014 | 44 | 16 |
| `icio` | 2011--2022 | 81 | 28 |
| `itpd` | 2000--2019 | 135 | 154 |

**Name-value options:**

| Option | Default | Description |
|--------|---------|-------------|
| `'Algorithm'` | `'levenberg-marquardt'` | `fsolve` algorithm for Nash solver |
| `'MaxIter'` | `50` | Max iterations per attempt |
| `'TolFun'` | `1e-6` | Function tolerance |
| `'TolX'` | `1e-8` | Step tolerance |
| `'T0_scale'` | `[0.9, 1.1, 1.25]` | Initial guess scaling [*w&#x302;*, *Y&#x302;*, *t*] |
| `'max_retries'` | `3` | Retry attempts with random initial guess |
| `'output_file'` | `results/results.csv` | CSV output path |

---

## Convergence Strategy

### Nash equilibrium: initial-guess retry

The Nash solver uses Levenberg-Marquardt with 1 + `max_retries` attempts. On failure, it retries with random scalar initial guesses:

| Attempt | Initial guess |
|---------|---------------|
| 1 | Default from `T0_scale` |
| 2--4 | Random: *w&#x302;* ~ U(0.7, 1.3), *Y&#x302;* ~ U(0.7, 1.3), *t* ~ U(1.1, 1.5) |

Each scalar is drawn once and applied uniformly to all *N* countries. The attempt with the best exit flag (or smallest residual on ties) is returned.

### Balanced trade: algorithm-switch retry

| Attempt | Algorithm | Initial guess |
|---------|-----------|---------------|
| 1 | `trust-region-dogleg` | Ones |
| 2 | `levenberg-marquardt` | Random scalar |

### Stall monitor

Both solvers use an `OutputFcn` that kills the solver when progress stalls:

1. **Initial gate:** After `stall_window` iterations, the residual must have dropped by at least 1000x from the initial value.
2. **Sliding window:** Each subsequent iteration must show at least 10% improvement relative to `stall_window` iterations ago.

---

## Validated Results

| Dataset | Elasticity | *N* | *S* | Time | Exitflag | Mean welfare |
|---------|-----------|-----|-----|------|----------|--------------|
| WIOD 2014 | IS | 44 | 16 | 2.1 s | 1 | -2.41% |
| WIOD 2014 | U4 | 44 | 16 | 2.0 s | 1 | -2.42% |
| ICIO 2019 | IS | 81 | 28 | 95.8 s | 1 | -3.18% |
| ICIO 2019 | U4 | 81 | 28 | 31.9 s | 4 | -1.31% |
| ITPD-S 2019 | U4 | 135 | 154 | 395 s | 3 | -2.27% |

WIOD 2014 with in-sample elasticities reproduces Table 1 of Lashkaripour (2021). Exit flag 1 = converged; 3 = residual small but last step ineffective; 4 = step smaller than tolerance.

---

## References

Bagwell, K., Staiger, R.W., and Yurukoglu, A. (2021). "Multilateral Trade Bargaining: A First Look at the GATT Bargaining Records." *Econometrica*, 89(4), 1723--1764.

Borchert, I., Larch, M., Shikher, S., and Yotov, Y.V. (2022). "The International Trade and Production Database for Estimation (ITPD-E)." *International Economics*, 170, 140--166.

Caliendo, L. and Parro, F. (2015). "Estimates of the Trade and Welfare Effects of NAFTA." *Review of Economic Studies*, 82(1), 1--44.

Fontagn&eacute;, L., Guimbard, H., and Orefice, G. (2022). "Tariff-Based Product-Level Trade Elasticities." *Journal of International Economics*, 137, 103593.

Giri, R., Yi, K.-M., and Yilmazkuday, H. (2021). "Gains from Trade: Does Sectoral Heterogeneity Matter?" *Journal of International Economics*, 129, 103429.

Lashkaripour, A. (2021). "The Cost of a Global Tariff War: A Sufficient-Statistics Approach." *Journal of International Economics*, 131, 103489.

Lashkaripour, A. and Lugovskyy, V. (2023). "Profits, Scale Economies, and the Gains from Trade and Industrial Policy." *American Economic Review*, 113(10), 2759--2808.

Shapiro, J.S. (2016). "Trade Costs, CO2, and the Environment." *American Economic Journal: Economic Policy*, 8(4), 220--254.

Simonovska, I. and Waugh, M.E. (2014). "The Elasticity of Trade: Estimates and Evidence." *Journal of International Economics*, 92(1), 34--50.

Teti, F. (2024). "30+ Years of Trade Policy: Evidence from 160 Countries." ECARES Working Paper 2024-04.

Timmer, M.P., Dietzenbacher, E., Los, B., Stehrer, R., and de Vries, G.J. (2015). "An Illustrated User Guide to the World Input-Output Database: The Case of Global Automotive Production." *Review of International Economics*, 23(3), 575--605.
