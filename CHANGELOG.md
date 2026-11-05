# Changelog

## Unreleased

### Data integrity
- **Final export always matches the selection.** In v1.1, pots excluded after generating the final file were still in the downloaded CSV. Changing the pots or the wide/long format now discards the generated file, which has to be generated again.
- **Metadata are kept exactly as written.** In v1.1, treatments `T`/`F` became `TRUE`/`FALSE`, `01` became `1`, genotype `001` became `1` and a treatment named `NA` became empty.
- Pots with an empty treatment are shown as `(none)`. In v1.1 they had an invalid colour in the map and no line in the chart.
- Values that are not valid numbers (e.g. the decimal comma in `1,5`) are counted in a warning. In v1.1 they silently became missing.
- One unreadable date no longer rejects the whole file: those rows are excluded and counted in a warning.
- A warning appears when dates could be read as either `DD/MM/YYYY` or `MM/DD/YYYY`.
- Files that are not UTF-8 are read as Latin-1. In v1.1 they stopped with a technical error.

### Bench map and charts
- Pots with the same `x:y` but a different `a` no longer overlap: each value of `a` has its own block in the map.
- The time-series chart with a single day shows a point and an SE bar. In v1.1 it was empty.
- The unit on the Y axis is shown only for recognised units. In v1.1 `NDVI average` was labelled `[average]`.
- Step 6 shows the number of parameters. In v1.1 it showed the number of columns, including identifiers.

### Privacy
- Google Analytics loads only after consent. In v1.1 `gtag.js` was requested from Google before the visitor answered the cookie banner.
- Montserrat is no longer loaded from Google Fonts: the page title and navigation bar use the system font.

### New
- **Example data:** a link in step 1 loads a synthetic data set, so the app can be tried without a file.
- **Download as PDF and SVG** as well as PNG, for both charts, always matching the chart on screen.
- **Three color palettes** for the bench map and the charts: NPG (default), colorblind-friendly Okabe-Ito and grayscale, the same as CleanRhizo. The map changes at once; a chart already generated keeps its colors until it is generated again.

### Interface
- A chart already generated shows a warning when the selected pots change, until it is generated again or the same pots are selected. The files stay available for comparison.
- Excluded pots have a dashed border, and pot labels switch to dark text on light colors, so the map stays readable with every palette.
- Deselecting every parameter now gives a clear message. In v1.1, step 3 and the charts silently fell back to the main parameters.
- Distribution parameters kept in step 2 can be drawn in the charts. They are off by default and shown with a dashed border.
- Charts are limited to 40 parameters at a time, with a clear message. Above about 42, the image exceeds the size PNG files can reach here and the app stopped with a technical error.
- The data preview shows the first selected parameters, including distribution ones. In v1.1 it showed only the first main parameters of the file.
- The bench map legend wraps onto more rows instead of being cut off on small benches; very long treatment names are shortened, with the full name in a tooltip.
- The file name stays in the upload field after changing language.
- The ±SE band is described as the standard error, not as a confidence band, and the jitter points as plants, not measurements.

### Repository
- New test script (`tests/run_tests.R`), run on GitHub Actions.
- Removed unused code.

## v1.1 (2026-10-18)

### Statistics
- **One row per plant and day, always.** Daily means are now computed per pot (`unit`) and date only. In v1.0 the grouping also included `sensor`: when the same pot was read by more than one sensor head, each plant appeared twice per day and the SE was computed with an inflated *n* (pseudoreplication). Readings from different sensors are now averaged as technical replicates, and a note is shown when this happens.
- New column `n_scans` with the number of scans averaged for each plant and day.
- Number of plants per treatment (*n*) shown in the time-series legend and under each box of the boxplot.
- French interface: the standard error is now labelled `ES` (erreur standard) instead of `ET`, which in French denotes the standard deviation.

### Reading the PlantEye file
- Empty metadata columns (e.g. no `genotype` assigned) no longer make all data disappear. In v1.0 such a column was read as logical `NA` and the aggregation silently returned zero rows.
- Dates are read from ISO (`YYYY-MM-DD`) as well as `DD/MM/YYYY` and `DD.MM.YYYY` timestamps.
- A UTF-8 byte order mark at the start of the file is handled.
- Clear error messages (in all 4 languages) for missing required columns (`unit`, `timestamp`, `treatment`), unreadable dates, `unit` values without a bench position, and selections without numeric data.

### Charts
- Parameters with negative values (e.g. PSRI) are drawn correctly. In v1.0 the Y axis was forced to start at 0, which inverted the axis and clipped the SE ribbon for negative means; the boxplot range was also computed incorrectly for negative values.
- Date ticks adapt to the length of the experiment (in v1.0 one tick every 7 days, so short experiments showed a single date).
- The Y-axis unit is taken from the parameter name only when the name has more than one word (in v1.0 a name such as `PSRI` was shown as `[PSRI]`).
- Colours are recycled when there are more than 10 treatments.

### Interface
- Changing language no longer resets the user's choices: selected parameters, pots excluded in the bench map, chart parameters, date range, SE ribbon, jitter and long-format toggles are all kept.
- The bench map follows dark mode.
- Pot labels in the map turn grey when the pot is excluded and white again when it is re-included.
- The counter of selected parameters (step 2) now updates when parameters are toggled.
- Error messages are shown in the step where they occur. In v1.0 only the status badge turned red, without explanation (e.g. when no pot was selected).
- Charts, boxplot and final export consistently require at least one selected pot.
- Dates in the preview tables are shown as dates (v1.0 showed the number of days since 1970); preview values are shown with 3 decimals.
- The "select at least one pot" error disappears as soon as a pot is selected again.
- Status badge shows "Final file ready" after the final export (it showed "Chart ready").
- Typo fixed in the French description ("le phénotypage").
- Version shown in the footer: v.1.1.

### Export
- The parameter count in the summary no longer includes an identifier column (it was off by one).
- CSV: fields are quoted only when they contain commas, quotes or line breaks (in v1.0 a treatment name with a comma shifted the columns).
- The final export contains the same columns as the cleaned file, restricted to the selected pots.

### Repository
- README rewritten: link to the app, DOI badge, workflow, input format, replicates, output files, how to cite.
- `CHANGELOG.md` added.
- `CITATION.cff` added: GitHub shows a "Cite this repository" button and Zenodo reads the citation metadata from it.
- `_quarto.yml`: only `CleanSpeX.qmd` is rendered, so README and CHANGELOG do not become pages of the site.

## v1.0 (2026-10-12)
- First public release. DOI: [10.5281/zenodo.23317334](https://doi.org/10.5281/zenodo.23317334)
