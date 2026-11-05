# Test delle funzioni dell'app. Si lanciano dalla radice del repository:
#   Rscript tests/run_tests.R
# L'app vive in un unico chunk di CleanSpeX.qmd: qui si carica la parte prima
# della UI, che non dipende da Shiny (serve solo il pacchetto htmltools).

load_app_functions <- function(qmd = "CleanSpeX.qmd") {
  lines <- readLines(qmd, encoding = "UTF-8", warn = FALSE)
  start <- grep("^# ── Palette", lines)[1]
  end   <- grep("^# ── UI ──", lines)[1] - 1
  if (is.na(start) || is.na(end)) stop("Marcatori non trovati in ", qmd)
  eval(parse(text = lines[start:end], encoding = "UTF-8"), envir = globalenv())
}
load_app_functions()

fails <- 0L
ok <- function(label, cond) {
  pass <- isTRUE(cond)
  cat(if (pass) "PASS" else "FAIL", "-", label, "\n")
  if (!pass) fails <<- fails + 1L
}
csv_file <- function(txt) { f <- tempfile(fileext = ".csv"); writeLines(enc2utf8(txt), f, useBytes = TRUE); f }
hdr <- "unit,timestamp,treatment,genotype,Height mm"

# ── Metadati ─────────────────────────────────────────────────────────────────
x <- parse_planteye(csv_file(c(hdr, "1:1:1,2024-03-01,T,001,1", "1:1:2,2024-03-01,F,002,2")))
ok("T/F restano T/F", setequal(x$treatment, c("T", "F")))
ok("il genotipo 001 resta 001", setequal(x$genotype, c("001", "002")))
x <- parse_planteye(csv_file(c(hdr, "1:1:1,2024-03-01,01,A,1", "1:1:2,2024-03-01,02,A,2")))
ok("gli zeri iniziali restano", setequal(x$treatment, c("01", "02")))
x <- parse_planteye(csv_file(c(hdr, "1:1:1,2024-03-01,NA,A,1", "1:1:2,2024-03-01,K,A,2")))
ok("il trattamento NA resta NA", setequal(x$treatment, c("NA", "K")))
ok("il trattamento NA ha un colore", !is.na(make_trt_colors(x$treatment)["NA"]))
x <- parse_planteye(csv_file(c(hdr, "1:1:1,2024-03-01,,A,1", "1:1:2,2024-03-01,K,A,2")))
tc <- make_trt_colors(x$treatment)
ok("trattamento vuoto -> (none) con colore", "(none)" %in% x$treatment && !anyNA(tc[x$treatment]))
sv <- make_bench_svg(unique(x[, c("unit", "treatment", "posA", "posX", "posY")]), tc, unique(x$unit))
ok("nessun fill=NA nella mappa", !grepl('fill="NA"', sv))

# ── Aggregazione ─────────────────────────────────────────────────────────────
dd <- daily_mean_per_plant(parse_planteye(csv_file(c(hdr,
  "1:1:1,2024-03-01,C,A,1.5", "1:1:1,2024-03-01 12:00,C,A,2.5",
  "1:1:2,2024-03-01,C,A,NA",  "1:1:3,2024-03-01,C,A,"))), "Height mm")
ok("media per pianta e giorno", is.numeric(dd$`Height mm`) && dd$`Height mm`[1] == 2)
ok("n_scans e valori mancanti", dd$n_scans[1] == 2 && all(is.na(dd$`Height mm`[2:3])))
a <- agg_trt_day(data.frame(unit = c("a", "b"), date = as.Date("2024-03-01"), treatment = "C", v = c(10, 30)), "v", c("a", "b"))
ok("media ed SE tra piante", a$mean == 20 && abs(a$se - 10) < 1e-9 && a$n == 2)

# ── Date ─────────────────────────────────────────────────────────────────────
p <- parse_pe_date(c("03/04/2024", "03/05/2024"))
ok("data ambigua segnalata", p$ambiguous && p$date[1] == as.Date("2024-04-03"))
p <- parse_pe_date(c("03/15/2024", "03/16/2024"))
ok("formato USA non ambiguo", !p$ambiguous && p$date[1] == as.Date("2024-03-15"))
p <- parse_pe_date(c("25/03/2024", "26/03/2024"))
ok("formato europeo", !p$ambiguous && p$date[1] == as.Date("2024-03-25"))
p <- parse_pe_date(c("2024-03-01 08:00:00", "2024-03-02", "boh"))
ok("una data errata scarta solo la sua riga", identical(is.na(p$date), c(FALSE, FALSE, TRUE)))
ok("formato con i punti", parse_pe_date("15.03.2024")$date == as.Date("2024-03-15"))
ok("formato con i trattini", parse_pe_date("15-03-2024")$date == as.Date("2024-03-15"))
ok("tutte le date errate", all(is.na(parse_pe_date(c("boh", "", "mah"))$date)))
r <- tryCatch({ parse_planteye(csv_file(c(hdr, "1:1:1,boh,C,A,1"))); "nessuno" }, error = function(e) conditionMessage(e))
ok("errore se nessuna data è leggibile", r == "ERR_DATE")
x <- parse_planteye(csv_file(c(hdr, "1:1:1,2024-03-01,C,A,1", "1:1:2,boh,C,A,1")))
ok("righe scartate contate", attr(x, "pe_notes")$bad_dates == 1 && nrow(x) == 1)

# ── Codifica ─────────────────────────────────────────────────────────────────
f <- tempfile(fileext = ".csv")
writeBin(c(charToRaw("unit,timestamp,treatment,Altezza "), as.raw(0xB5), charToRaw("m\n1:1:1,2024-03-01,Contr"),
           as.raw(0xF4), charToRaw("le,1\n")), f)
x <- parse_planteye(f)
ok("file Latin-1", x$treatment == "Contrôle" && "Altezza µm" %in% names(x))
f <- tempfile(fileext = ".csv")
writeBin(c(as.raw(c(0xEF, 0xBB, 0xBF)), charToRaw(enc2utf8("unit,timestamp,treatment,X\n1:1:1,2024-03-01,Contrôle,1\n"))), f)
x <- parse_planteye(f)
ok("BOM e UTF-8", names(x)[1] == "unit" && x$treatment == "Contrôle")

# ── Valori non numerici ──────────────────────────────────────────────────────
x <- parse_planteye(csv_file(c("unit,timestamp,treatment,Height mm,Note",
  "1:1:1,2024-03-01,C,\"1,5\",ciao", "1:1:2,2024-03-01,C,2.5,", "1:1:3,2024-03-01,C,NA,NaN")))
n <- count_non_numeric(x, c("Height mm", "Note", "assente"))
ok("conteggio non numerici", identical(unname(n), c(1L, 1L)) && setequal(names(n), c("Height mm", "Note")))

# ── Unità di misura ──────────────────────────────────────────────────────────
u <- vapply(c("Height mm", "NDVI average", "Digital biomass", "PSRI", "Leaf area mm2", "Height (mm)", "Mass g"), param_unit, "")
ok("solo unità riconosciute", identical(unname(u), c("mm", "", "", "", "mm2", "mm", "g")))

# ── Mappa ────────────────────────────────────────────────────────────────────
pots <- function(s) { m <- do.call(rbind, strsplit(s, ":")); data.frame(unit = s, treatment = "A", posA = m[, 1],
                      posX = as.integer(m[, 2]), posY = as.integer(m[, 3])) }
m <- pots(c("1:2:3", "2:2:3", "10:1:1"))
sv <- make_bench_svg(m, make_trt_colors(m$treatment), m$unit, bench_label = "Bench")
xy <- regmatches(sv, gregexpr('id="v_[^"]+" x="[0-9]+" y="[0-9]+"', sv))[[1]]
ok("vasi di bench diversi non si sovrappongono", !anyDuplicated(sub('.*" x=', "", xy)))
ok("un titolo per bench", all(vapply(c("Bench 1", "Bench 2", "Bench 10"), grepl, TRUE, sv, fixed = TRUE)))
viewbox <- function(sv) as.numeric(strsplit(sub('.*viewBox="([^"]+)".*', "\\1", sv), " ")[[1]])
m1 <- pots(sprintf("1:%d:1", 1:3)); m1$treatment <- c("A", "B", "C")
sv1 <- make_bench_svg(m1, make_trt_colors(m1$treatment), m1$unit)
ok("bench singolo: geometria invariata", identical(viewbox(sv1), c(0, 0, 284, 188)) && !grepl("Bench", sv1))

legend_items <- function(sv) {
  r <- regmatches(sv, gregexpr('<rect x="[0-9.]+" y="[0-9.]+" width="14"', sv))[[1]]
  data.frame(x = as.numeric(sub('.*x="([0-9.]+)".*', "\\1", r)), y = as.numeric(sub('.*y="([0-9.]+)".*', "\\1", r)))
}
trts <- c("Controllo", "Stress idrico", "Stress salino", "Azoto basso", "Azoto alto")
m2 <- pots(sprintf("1:%d:1", 1:3)); m2$treatment <- trts[1:3]
tc2 <- make_trt_colors(trts)
sv2 <- make_bench_svg(m2, tc2, m2$unit)
li  <- legend_items(sv2)
widths <- 20 + nchar(sort(trts)) * 8
ok("legenda: tutti i trattamenti presenti", nrow(li) == length(trts))
ok("legenda: va a capo su un bench stretto", length(unique(li$y)) > 1)
ok("legenda: nessuna voce oltre il bordo destro", all(li$x + widths <= viewbox(sv2)[3]))
ok("legenda: nessuna voce oltre il fondo", max(li$y) + 14 <= viewbox(sv2)[4])
long <- paste(rep("molto lungo", 6), collapse = " ")
m3 <- pots("1:1:1"); m3$treatment <- long
sv3 <- make_bench_svg(m3, make_trt_colors(long), m3$unit)
ok("legenda: nome lungo accorciato, intero nel tooltip", grepl("…<title>", sv3) && grepl(paste0("<title>", long, "</title>"), sv3, fixed = TRUE))
m4 <- pots("1:1:1"); m4$treatment <- "A&B"
ok("legenda: caratteri speciali protetti", grepl(">A&amp;B<title>", make_bench_svg(m4, make_trt_colors("A&B"), m4$unit), fixed = TRUE))

# ── Selezione dei parametri nei grafici ──────────────────────────────────────
avail <- c("Height mm", "PSRI", "Hue [0-20]")
main  <- c("Height mm", "PSRI", "Non disponibile")
ok("nessuna scelta: solo i principali", identical(resolve_chart_params(NULL, avail, main), c("Height mm", "PSRI")))
ok("selezione vuota rispettata", length(resolve_chart_params(character(0), avail, main)) == 0)
ok("distribuzione selezionabile", identical(resolve_chart_params("Hue [0-20]", avail, main), "Hue [0-20]"))
ok("solo distribuzioni disponibili", identical(resolve_chart_params(NULL, "Hue [0-20]", main), "Hue [0-20]"))

ok("errore se nessun parametro", identical(chart_params_error(character(0)), "ERR_NOPARAM"))
ok("nessun errore al limite", is.null(chart_params_error(rep("p", MAX_CHART_PARAMS))))
ok("errore oltre il limite", identical(chart_params_error(rep("p", MAX_CHART_PARAMS + 1)), "ERR_TOOMANY"))
big <- paste0("p", seq_len(MAX_CHART_PARAMS))
big_df <- do.call(rbind, lapply(big, function(p) data.frame(date = as.Date("2024-03-01"), treatment = "A", mean = 1, se = 0.1, n = 2, param = p)))
big_spec <- list(fun = draw_time_chart, args = list(trt_day_df = big_df, params = big, trt_colors = make_trt_colors("A")))
drawn <- tryCatch({ render_chart_file(big_spec, tempfile(fileext = ".png"), "png"); TRUE }, error = function(e) conditionMessage(e))
ok("il grafico al limite si può generare", drawn)

ok("PNG aggiornato con gli stessi vasi, in qualsiasi ordine", !png_is_stale(c("a", "b"), c("b", "a")))
ok("PNG superato se un vaso è escluso", png_is_stale(c("a", "b"), "a"))
ok("PNG superato se nessun vaso è selezionato", png_is_stale(c("a", "b"), NULL))

# ── Traduzioni ───────────────────────────────────────────────────────────────
k <- lapply(TR, names)
ok("stesse chiavi in tutte le lingue", all(vapply(k, setequal, TRUE, k$en)))
for (l in names(TR)) {
  ok(paste("errore selezione vuota tradotto:", l), identical(tr_error("ERR_NOPARAM", TR[[l]]), TR[[l]]$err_noparam))
  ok(paste("errore troppi parametri tradotto:", l), grepl(MAX_CHART_PARAMS, tr_error("ERR_TOOMANY", TR[[l]]), fixed = TRUE))
  ok(paste("nessuna banda di confidenza:", l), !grepl("confiden|confianza|confiance", TR[[l]]$ribbon_sub, ignore.case = TRUE))
}

# ── Palette ──────────────────────────────────────────────────────────────────
ok("3 palette", identical(names(PALETTES), c("npg", "okabe")))
npg <- adjustcolor(PALETTES$npg, alpha.f = 0.8)
ok("npg è quella di prima, anche oltre 10 trattamenti", identical(get_palette("npg", 3), npg[1:3]) && identical(get_palette("npg", 12)[11], npg[1]))
ok("okabe ricomincia oltre 8 trattamenti", identical(get_palette("okabe", 9)[9], get_palette("okabe", 1)))
ok("grigi sempre diversi", all(vapply(c(1, 2, 12), function(n) length(unique(get_palette("gray", n))) == n, TRUE)))
ok("palette sconosciuta: quella predefinita", identical(get_palette("boh", 2), get_palette(DEFAULT_PALETTE, 2)))
tcp <- make_trt_colors(c("B", "A", "B"), "okabe")
ok("colori assegnati per nome e in ordine", identical(names(tcp), c("A", "B")) && identical(unname(tcp), get_palette("okabe", 2)))
ok("predefinita senza argomenti", identical(unname(make_trt_colors("A")), get_palette(DEFAULT_PALETTE, 1)))
yel <- get_palette("okabe", 4)[4]
ok("testo scuro sul giallo", label_color(yel) == "#1A1A1A")
ok("testo bianco sul grigio scuro", label_color(get_palette("gray", 3)[1]) == "#FFFFFF")
ok("testo bianco sul rosso npg", label_color(npg[1]) == "#FFFFFF")
ok("lo sfondo scuro conta", label_color(get_palette("gray", 2)[2]) == "#1A1A1A" && label_color(get_palette("gray", 2)[2], "#1E261D") == "#FFFFFF")
m5 <- pots("1:1:1"); m5$treatment <- "A"
ok("il vaso porta il colore del testo", grepl('data-lbl="#1A1A1A"', make_bench_svg(m5, setNames(yel, "A"), m5$unit), fixed = TRUE))
gp <- tryCatch({ pdf(NULL); for (pl in c("npg", "okabe", "gray")) {
  df_g <- data.frame(unit = c("a", "b"), date = as.Date("2024-03-01"), treatment = c("A", "B"), v = 1:2)
  draw_time_chart(agg_trt_day(df_g, "v", c("a", "b")), "v", make_trt_colors(df_g$treatment, pl))
  draw_boxplot_day(df_g, "v", make_trt_colors(df_g$treatment, pl), selected_date = df_g$date[1])
}; dev.off(); TRUE }, error = function(e) conditionMessage(e))
ok("grafici con tutte le palette", gp)

# ── File di esempio, dalla lettura ai grafici ────────────────────────────────
ex_file <- "tests/data/example_planteye.csv"
ok("dati incorporati uguali al file di test", identical(EXAMPLE_PLANTEYE, readLines(ex_file, encoding = "UTF-8")))
ex <- parse_planteye(ex_file)
pr <- classify_params(ex)
ok("esempio: parametri riconosciuti", length(pr$main) == 5 && length(pr$dist) == 4)
dd <- daily_mean_per_plant(ex, pr$all)
ok("esempio: una riga per pianta e giorno", nrow(dd) == 12 * 6 && all(dd$n_scans == 2))
ok("esempio: nessun avviso", length(count_non_numeric(ex, pr$all)) == 0 && attr(ex, "pe_notes")$bad_dates == 0)
tc <- make_trt_colors(ex$treatment)
tp <- c("Height mm", "PSRI", "Hue [0-20]")
drawn <- tryCatch({
  pdf(NULL)
  draw_time_chart(agg_trt_day(dd, tp, unique(dd$unit)), tp, tc)
  draw_boxplot_day(dd, tp, tc, selected_date = dd$date[1], show_jitter = TRUE)
  dev.off(); TRUE
}, error = function(e) conditionMessage(e))
ok("esempio: grafici con un parametro di distribuzione", drawn)

# ── Formati di salvataggio ───────────────────────────────────────────────────
starts_with <- function(f, what) identical(readBin(f, "raw", length(what)), what)
d_dl <- dd[, c("unit", "date", "treatment", "Height mm", "Hue [0-20]")]
d_dl$treatment[d_dl$treatment == "Control"] <- "Contr\u00f4le \u20ac"
names(d_dl)[4] <- "Altezza \u00b5m\u00b2"
pars <- names(d_dl)[4:5]; tc_dl <- make_trt_colors(d_dl$treatment)
specs <- list(
  chart = list(fun = draw_time_chart, args = list(trt_day_df = agg_trt_day(d_dl, pars, unique(d_dl$unit)), params = pars, trt_colors = tc_dl)),
  box   = list(fun = draw_boxplot_day, args = list(daily_df = d_dl, params = pars, trt_colors = tc_dl, selected_date = d_dl$date[1], show_jitter = TRUE)))
for (nm in names(specs)) {
  f_png <- tempfile(fileext = ".png"); render_chart_file(specs[[nm]], f_png, "png")
  ok(paste("PNG valido:", nm), starts_with(f_png, as.raw(c(0x89, 0x50, 0x4E, 0x47))) && dev.cur() == 1)
  warns <- character(0); f_pdf <- tempfile(fileext = ".pdf")
  withCallingHandlers(render_chart_file(specs[[nm]], f_pdf, "pdf"),
                      warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") })
  ok(paste("PDF valido, accenti e simboli senza avvisi:", nm), starts_with(f_pdf, charToRaw("%PDF")) && !length(warns) && dev.cur() == 1)
  f_svg <- tempfile(fileext = ".svg")
  r <- tryCatch({ render_chart_file(specs[[nm]], f_svg, "svg"); "ok" }, error = conditionMessage)
  ok(paste("SVG valido oppure errore chiaro senza cairo:", nm), dev.cur() == 1 &&
       (r == "ERR_EXPORT" || (r == "ok" && any(grepl("<svg", readLines(f_svg, 5))))))
}
r <- tryCatch({ render_chart_file(list(fun = function(...) stop("boh"), args = list(params = "a")), tempfile(), "pdf"); "ok" }, error = conditionMessage)
ok("un errore nel disegno non lascia device aperti", r == "boh" && dev.cur() == 1)
ok("errore di formato tradotto", all(vapply(TR, function(l) identical(tr_error("ERR_EXPORT", l), l$err_export), TRUE)))
ok("chart_to_b64 produce testo", is.character(chart_to_b64(specs$box, "pdf")) && startsWith(chart_to_b64(specs$box, "pdf"), "JVBER"))
ok("un tipo MIME per formato", identical(names(CHART_MIME), c("png", "pdf", "svg")))

lg <- pivot_long_pe(dd, pr$all)
ok("esempio: formato long", nrow(lg) == nrow(dd) * length(pr$all))

cat("\nFalliti:", fails, "\n")
if (fails > 0) quit(status = 1)
