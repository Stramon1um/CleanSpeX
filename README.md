# CleanSpeX
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

CleanSpeX is a free, browser-based application for cleaning, exploring, and exporting spectral phenotyping data acquired with the PlantEye F600 multispectral 3D scanner (Phenospex). The tool is built with R and Shiny and deployed as a static web application via the shinylive and WebR frameworks, meaning it runs entirely within the user's browser without requiring any server-side infrastructure, software installation, or data upload to external services. CleanSpeX addresses a recurring need in spectral phenotyping workflows: the raw PlantEye output file contains multiple daily scans per plant that must be aggregated, and the large number of available parameters requires careful selection before downstream analysis. The application automates per-scan aggregation to daily means, provides an interactive SVG bench map for spatial inspection and pot exclusion, and offers time-series and boxplot visualisations of the cleaned data. Final export is available in wide or long format CSV, filtered to the selected parameters and pot positions. CleanSpeX is available in English, Italian, Spanish, and French.

## License
This project is licensed under the [MIT License](LICENSE).
