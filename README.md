# CleanSpeX 🧹

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23317333.svg)](https://doi.org/10.5281/zenodo.23317333)
[![Launch app](https://img.shields.io/badge/Launch-CleanSpeX-3A6B35)](https://www.mauromaver.eu/CleanSpeX/)

**▶ Use it online: <https://www.mauromaver.eu/CleanSpeX/>**

CleanSpeX is a free, browser-based application for cleaning, exploring, and exporting spectral phenotyping data acquired with the [PlantEye F600](https://phenospex.com/products/plant-phenotyping/planteye-f600-multispectral-3d-scanner-for-plants/) multispectral 3D scanner (Phenospex). The tool is built with R and Shiny and deployed as a static web application via the shinylive and WebR frameworks, meaning it runs entirely within the user's browser without requiring any server-side infrastructure, software installation, or data upload to external services.

CleanSpeX addresses a recurring need in spectral phenotyping workflows: the raw PlantEye output file contains multiple scans per plant and per day that must be aggregated, and the large number of available parameters requires careful selection before downstream analysis. The application automates per-scan aggregation to daily means, provides an interactive bench map for spatial inspection, outlier flagging and pot exclusion, and offers time-series and boxplot visualisations of the cleaned data by treatment, genotype or both. Final export is available in wide or long format CSV, filtered to the selected parameters and pots. CleanSpeX is available in English, Italian, Spanish, and French.

## Privacy

Your data never leave your computer. The file you load is processed locally by R compiled to WebAssembly (WebR); nothing is sent to a server. The first launch may take a few seconds while the R environment loads.

The website uses Google Analytics to count visits only if you accept cookies in the banner; without consent the page sends no requests to Google. Analytics never receives your data file.

## Workflow

1. **Load** the `.csv` file exported from PlantEye, or try the app with the built-in synthetic example data.
2. **Select parameters** to keep. Main parameters are preselected; distribution parameters (colour bins such as `Hue [0-20]`) can be added with one click. At least one parameter is needed.
3. **Process**: all scans of the same pot on the same day are averaged, giving one row per plant and day. Download the cleaned file.
4. **Inspect the bench map**: pots are drawn at their position on the bench and coloured by group. Click a pot to exclude it from charts and export (e.g. a dead plant or a border effect); click again to include it. Three color palettes are available for the map and the charts: NPG, colorblind-friendly Okabe-Ito and grayscale.
   - **Group by** treatment, genotype or treatment × genotype, when the file has at least two genotypes. The choice applies to the map, the charts and the outlier check.
   - **Color pots by** group, by the value of a parameter on a chosen day, or by the **deviation from the group**: the value minus the mean of its group on that day, computed on the selected pots. The deviation removes the treatment effect and leaves the effect of position, so border effects and gradients across the bench become visible. The pot border keeps the group color.
   - **Possible outliers** of the chosen parameter are flagged with `!` on the map and listed under it (see [Outliers](#outliers)). They are only flagged: excluding a pot is always your choice.
5. **Explore** with a time-series chart (daily mean ± SE per group, adjustable date range, optional SE ribbon) and a boxplot for a single scan day (optional individual points, one per plant). Main parameters are drawn by default; distribution parameters kept in step 2 can be switched on, up to 40 parameters per chart. Both are downloadable as PNG (300 dpi), PDF or SVG, always matching the chart on screen. A chart does not update by itself: a warning appears if the selected pots or the grouping change after it was generated.
6. **Export** the final dataset in wide or long format (`parameter`, `value`), restricted to the selected pots. Changing the pots or the format discards the generated file, so it has to be generated again.

## Biological vs technical replicates

The experimental unit is the **pot** (one plant per pot, identified by `unit`). Repeated scans of the same pot on the same day, including readings of the same pot by different sensor heads, are **technical replicates**: CleanSpeX averages them first, so each plant contributes exactly one value per day. The column `n_scans` reports how many scans were averaged.

In the charts, mean, SE and *n* (shown in the legend and under each box) are computed across **plants** of the same group (treatment, genotype or treatment × genotype), i.e. across biological replicates. The charts are meant for quick quality control and are not a substitute for proper statistical analysis; for repeated measures over time, consider a mixed model with plant as a random effect.

## Outliers

For the parameter chosen in the map, CleanSpeX looks for two kinds of possible outliers among the selected pots, separately for each group and scan day:

- **unusual value**: the plant is far from the median of its group on that day;
- **unusual change from the previous day**: the change since the previous scan day differs from the change of the other plants of the group (e.g. a plant that suddenly shrinks).

The distance is a robust z-score (Iglewicz and Hoaglin): the deviation from the group median divided by 1.4826 × MAD of the deviations of all pots on that day. A pot is flagged when |z| > 3.5. The scale is pooled across groups because the MAD of 4–8 plants alone is too unstable. For parameters that are always positive (e.g. height, leaf area) the check works on the logarithm, i.e. on relative deviations, so that small and large plants are compared fairly. Groups with fewer than 3 selected plants and days with fewer than 8 values are not checked.

The check is a quality-control aid, not a statistical test: look at the plants before excluding them.

## Input file

A comma-separated `.csv` exported from the PlantEye/Phenospex software, with one row per scan:

| Column | Required | Content |
|---|---|---|
| `unit` | yes | pot identifier in the form `a:x:y`; `x` and `y` give the column and row on the bench. Different values of `a` are drawn as separate blocks in the map |
| `timestamp` | yes | date and time of the scan (`YYYY-MM-DD hh:mm:ss`; `DD/MM/YYYY`, `DD.MM.YYYY` and `DD-MM-YYYY` are also accepted). `MM/DD/YYYY` is used only when the dates cannot be `DD/MM/YYYY`; a warning appears when both readings are possible. Rows without a readable date are excluded and counted in a warning |
| `treatment` | yes | treatment name, kept exactly as written (`T`, `01`, `NA`). Empty values are shown as `(none)` |
| `genotype` | no | genotype; with two or more genotypes the map, charts and outlier check can be grouped by genotype or by treatment × genotype. Empty values are shown as `(none)` |
| `sensor`, `g_alias` | no | metadata; empty columns are fine. `g_alias` is kept in the exported files |
| any other column | | treated as a parameter; names containing `[...]` are treated as distribution bins. Decimals must use a dot: values that are not valid numbers (e.g. `1,5`) become missing and are counted in a warning |

The unit shown on the Y axis is taken from the last word of the parameter name when it is a recognised unit such as `mm`, `cm2` or `g` (e.g. `Height mm` gives `[mm]`, while `NDVI average` shows no unit). A UTF-8 byte order mark at the start of the file is handled; files that are not UTF-8 are read as Latin-1.

## Output

| File | Content |
|---|---|
| `<name>_clean.csv` | daily mean per plant for the selected parameters, with `genotype`, `g_alias` (when present) and `n_scans` |
| `<name>_final.csv` | final dataset restricted to the selected pots, wide or long format |
| `<name>_chart.png` / `.pdf` / `.svg` | time-series chart (PNG at 300 dpi) |
| `<name>_boxplot.png` / `.pdf` / `.svg` | boxplot for the selected day (PNG at 300 dpi) |

CSV files use `,` as separator and `.` as decimal mark; fields are quoted only when they contain commas, quotes or line breaks.

## How to cite

If you use CleanSpeX in your research, please cite it:

> Maver, M. (2026). *CleanSpeX: a browser-based tool for PlantEye spectral phenotyping data cleaning and exploration*. Zenodo. <https://doi.org/10.5281/zenodo.23317333>

```bibtex
@software{maver_cleanspex_2026,
  author    = {Maver, Mauro},
  title     = {CleanSpeX: a browser-based tool for PlantEye spectral phenotyping data cleaning and exploration},
  year      = {2026},
  publisher = {Zenodo},
  doi       = {10.5281/zenodo.23317333},
  url       = {https://doi.org/10.5281/zenodo.23317333}
}
```

The DOI above always resolves to the latest version. Version 1.0 has its own DOI: [10.5281/zenodo.23317334](https://doi.org/10.5281/zenodo.23317334).

## Run or build locally

The whole app lives in `CleanSpeX.qmd` (a single `shinylive-r` chunk). To rebuild the site you need [Quarto](https://quarto.org) and the R packages `shinylive`, `shiny` and `bslib`:

```bash
quarto render      # writes the static site to docs/
quarto preview     # local preview (WebR needs a web server, not file://)
```

The site in `docs/` is published with GitHub Pages.

The functions behind the app are tested with a plain R script, which needs only the `htmltools` package and also runs on GitHub Actions:

```bash
Rscript tests/run_tests.R
```

`tests/data/example_planteye.csv` holds the built-in example data: invented values for 48 pots (3 treatments × 2 genotypes × 8 plants, placed at random on an 8 × 6 bench) and 6 days, not a real PlantEye export. Plants on the border of the bench are 15% larger and one plant (`1:6:3`) gets sick from the fourth day, so the deviation map and the outlier check have something to show. It is generated by `tests/data/make_example_planteye.R`.

## Related apps

CleanSpeX is part of a small family of browser-based tools for plant phenotyping data:

- [CleanRhizo](https://www.mauromaver.eu/CleanRhizo/) ([repository](https://github.com/Stramon1um/CleanRhizo)): WinRhizo root morphology data
- [CleanEX](https://www.mauromaver.eu/CleanEX/) ([repository](https://github.com/Stramon1um/CleanEX)): Dualex leaf optical data

## Changes

See [CHANGELOG.md](CHANGELOG.md).

## Contact

Mauro Maver, University of Verona ([mauromaver.eu](https://www.mauromaver.eu), ORCID [0000-0002-8162-3618](https://orcid.org/0000-0002-8162-3618)).
Bug reports and suggestions: [GitHub issues](https://github.com/Stramon1um/CleanSpeX/issues) or [email](mailto:mauro.maver@univr.it).

## License

This project is licensed under the [MIT License](LICENSE).
