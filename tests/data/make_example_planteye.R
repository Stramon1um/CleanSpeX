# Genera i dati di esempio sintetici di CleanSpeX (non misure reali).
# 48 vasi su un bench 8 x 6, 3 trattamenti x 2 genotipi x 8 repliche disposti a caso,
# 6 giorni con 2 scansioni al giorno. Contiene apposta:
#  - un effetto bordo (piante sul perimetro del bench più grandi del 15%)
#  - un effetto del genotipo (G2 più alto)
#  - una pianta che si ammala dal quarto giorno (vaso interno, Control x G1)
set.seed(2026)
# Rscript tests/data/make_example_planteye.R tests/data/example_planteye.csv
out <- commandArgs(TRUE)[1]

nx <- 8; ny <- 6
pos <- expand.grid(x = 1:nx, y = 1:ny)
design <- expand.grid(rep = 1:8, genotype = c("G1", "G2"), treatment = c("Control", "Drought", "Salt"),
                      stringsAsFactors = FALSE)
design <- design[sample(nrow(design)), ]
pots <- cbind(pos, design[, c("treatment", "genotype")])
pots$unit <- paste0("1:", pots$x, ":", pots$y)
pots$edge <- pots$x %in% c(1, nx) | pots$y %in% c(1, ny)
# Pianta malata: un Control x G1 all'interno del bench
inner <- which(!pots$edge & pots$treatment == "Control" & pots$genotype == "G1")
if (!length(inner)) stop("nessun Control x G1 interno: cambia il seed")
sick <- pots$unit[inner[1]]
pots$plant_eff <- exp(rnorm(nrow(pots), 0, 0.035))

days  <- seq(as.Date("2026-03-02"), by = "day", length.out = 6)
times <- c("07:00:00", "15:00:00")
rgr   <- c(Control = 0.10, Drought = 0.05, Salt = 0.07)
ndvi_d <- c(Control = 0, Drought = -0.006, Salt = -0.004)
psri_d <- c(Control = 0, Drought = 0.002, Salt = 0.0015)

rows <- list()
for (d in seq_along(days)) for (tm in times) for (i in seq_len(nrow(pots))) {
  p  <- pots[i, ]; t <- d - 1
  g2 <- p$genotype == "G2"
  h  <- 115 * (if (g2) 1.12 else 1) * exp((rgr[[p$treatment]] + if (g2) 0.01 else 0) * t)
  h  <- h * p$plant_eff * (if (p$edge) 1.15 else 1)
  ill <- if (p$unit == sick && d >= 4) c(0.72, 0.58, 0.50)[d - 3] else 1
  h  <- h * ill * exp(rnorm(1, 0, 0.015))
  la <- 34.7 * h * exp(rnorm(1, 0, 0.02))
  db <- h * la / 10.85 * exp(rnorm(1, 0, 0.01))
  ndvi <- 0.62 + 0.012 * t + ndvi_d[[p$treatment]] * t + rnorm(1, 0, 0.008) - (1 - ill) * 0.4
  psri <- -0.05 + psri_d[[p$treatment]] * t + rnorm(1, 0, 0.003) + (1 - ill) * 0.12
  stress <- (if (p$treatment == "Control") 0 else 0.6 * t) + (1 - ill) * 40
  hue <- pmax(0.2, c(4, 14, 57, 25) + c(stress, stress * 0.6, -stress * 1.6, 0) + rnorm(4, 0, 1.2))
  hue <- hue / sum(hue) * 100
  rows[[length(rows) + 1]] <- data.frame(
    unit = p$unit, timestamp = paste(format(days[d]), tm), treatment = p$treatment, genotype = p$genotype,
    `Height mm` = round(h, 1), `Leaf area mm2` = round(la), `Digital biomass` = round(db),
    `NDVI average` = round(ndvi, 3), PSRI = round(psri, 4),
    `Hue [0-20]` = round(hue[1], 2), `Hue [20-40]` = round(hue[2], 2),
    `Hue [40-60]` = round(hue[3], 2), `Hue [60-80]` = round(hue[4], 2),
    check.names = FALSE, stringsAsFactors = FALSE)
}
df <- do.call(rbind, rows)
write.csv(df, out, row.names = FALSE, quote = FALSE)
message("vaso malato: ", sick)
print(table(pots$treatment, pots$genotype))
print(xtabs(~ y + x, data = transform(pots, lab = substr(treatment, 1, 1))))
print(matrix(paste0(substr(pots$treatment, 1, 1), substr(pots$genotype, 2, 2)), nrow = ny, byrow = TRUE))
