# Changelog

## v1.1 (in preparation)

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
