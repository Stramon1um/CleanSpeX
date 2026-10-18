# CleanSpeX 🧹

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23317333.svg)](https://doi.org/10.5281/zenodo.23317333)
[![Launch app](https://img.shields.io/badge/Launch-CleanSpeX-3A6B35)](https://www.mauromaver.eu/CleanSpeX/)

**▶ Use it online: <https://www.mauromaver.eu/CleanSpeX/>**

CleanSpeX is a free, browser-based application for cleaning, exploring, and exporting spectral phenotyping data acquired with the [PlantEye F600](https://phenospex.com/products/plant-phenotyping/planteye-f600-multispectral-3d-scanner-for-plants/) multispectral 3D scanner (Phenospex). The tool is built with R and Shiny and deployed as a static web application via the shinylive and WebR frameworks, meaning it runs entirely within the user's browser without requiring any server-side infrastructure, software installation, or data upload to external services.

CleanSpeX addresses a recurring need in spectral phenotyping workflows: the raw PlantEye output file contains multiple scans per plant and per day that must be aggregated, and the large number of available parameters requires careful selection before downstream analysis. The application automates per-scan aggregation to daily means, provides an interactive bench map for spatial inspection and pot exclusion, and offers time-series and boxplot visualisations of the cleaned data. Final export is available in wide or long format CSV, filtered to the selected parameters and pots. CleanSpeX is available in English, Italian, Spanish, and French.

## Privacy

Your data never leave your computer. The file you load is processed locally by R compiled to WebAssembly (WebR); nothing is sent to a server. The first launch may take a few seconds while the R environment loads.

## Workflow

1. **Load** the `.csv` file exported from PlantEye.
2. **Select parameters** to keep. Main parameters are preselected; distribution parameters (colour bins such as `Hue [0-20]`) can be added with one click.
3. **Process**: all scans of the same pot on the same day are averaged, giving one row per plant and day. Download the cleaned file.
4. **Inspect the bench map**: pots are drawn at their position on the bench and coloured by treatment. Click a pot to exclude it from charts and export (e.g. a dead plant or a border effect); click again to include it.
5. **Explore** with a time-series chart (daily mean ± SE per treatment, adjustable date range, optional SE ribbon) and a boxplot for a single scan day (optional individual points). Both are downloadable as PNG at 300 dpi.
6. **Export** the final dataset in wide or long format (`parameter`, `value`), restricted to the selected pots.

## Biological vs technical replicates

The experimental unit is the **pot** (one plant per pot, identified by `unit`). Repeated scans of the same pot on the same day, including readings of the same pot by different sensor heads, are **technical replicates**: CleanSpeX averages them first, so each plant contributes exactly one value per day. The column `n_scans` reports how many scans were averaged.

In the charts, mean, SE and *n* (shown in the legend and under each box) are computed across **plants** of the same treatment, i.e. across biological replicates. The charts are meant for quick quality control and are not a substitute for proper statistical analysis; for repeated measures over time, consider a mixed model with plant as a random effect.

## Input file

A comma-separated `.csv` exported from the PlantEye/Phenospex software, with one row per scan:

| Column | Required | Content |
|---|---|---|
| `unit` | yes | pot identifier in the form `a:x:y`; `x` and `y` give the column and row on the bench |
| `timestamp` | yes | date and time of the scan (`YYYY-MM-DD hh:mm:ss`; `DD/MM/YYYY` and `DD.MM.YYYY` are also accepted) |
| `treatment` | yes | treatment name |
| `sensor`, `genotype`, `g_alias` | no | metadata; empty columns are fine |
| any other column | | treated as a parameter; names containing `[...]` are treated as distribution bins |

The unit shown on the Y axis is taken from the last word of the parameter name (e.g. `Height mm` gives `[mm]`). A UTF-8 byte order mark at the start of the file is handled.

## Output

| File | Content |
|---|---|
| `<name>_clean.csv` | daily mean per plant for the selected parameters, with `n_scans` |
| `<name>_final.csv` | final dataset restricted to the selected pots, wide or long format |
| `<name>_chart.png` | time-series chart, 300 dpi |
| `<name>_boxplot.png` | boxplot for the selected day, 300 dpi |

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
