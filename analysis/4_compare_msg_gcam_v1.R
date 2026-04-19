# compare_msg_gcam.R
# Compares MESSAGEix and GCAM CurrentMeasuresRev (v1) outputs for Pakistan.
# Produces:
#   1. A single-sheet xlsx with Category|Subcategory|Variable|Model|Unit|years|Notes
#   2. Comprehensive ggplot2 figures in analysis/figures/
#
# Usage: Rscript analysis/compare_msg_gcam.R
# Input:
#   - analysis/MESSAGEix-Pakistan_CM.xlsx
#   - output/gcam_output_iamc_all_standardized.xlsx
# Output:
#   - analysis/query/iamc_format/msg_gcam_comparison_all.xlsx
#   - analysis/figures/msg_gcam_*.png

suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(tidyr); library(writexl)
  library(ggplot2); library(patchwork)
})

# ---- Config ----------------------------------------------------------------
find_root <- function() {
  for (d in c(getwd(), file.path(getwd(), ".."), file.path(getwd(), "../.."))) {
    if (dir.exists(file.path(d, "input")) && dir.exists(file.path(d, "exe")))
      return(normalizePath(d))
  }
  warning("Cannot detect project root, using CWD"); getwd()
}
ROOT <- find_root()
cat("Project root:", ROOT, "\n")

MSG_FILE  <- file.path(ROOT, "analysis", "MESSAGEix-Pakistan_CM.xlsx")
GCAM_FILE <- file.path(ROOT, "output", "gcam_output_iamc_all_standardized.xlsx")
OUT_FILE  <- file.path(ROOT, "analysis", "query", "iamc_format", "msg_gcam_comparison_all.xlsx")
FIG_DIR   <- file.path(ROOT, "analysis", "figures")
if (!dir.exists(FIG_DIR)) dir.create(FIG_DIR, recursive = TRUE)

YEARS <- c(2025, 2030, 2035, 2040, 2045, 2050)
YEAR_COLS <- as.character(YEARS)
GCAM_SCENARIO <- "CurrentMeasuresRev"
GCAM_LABEL <- "GCAM 8.6"
MSG_LABEL  <- "MESSAGEix"

# ---- Load data -------------------------------------------------------------
cat("Loading MSG from:", MSG_FILE, "\n")
msg_raw <- read_excel(MSG_FILE)
names(msg_raw) <- as.character(names(msg_raw))
msg <- msg_raw %>%
  filter(Region == "Pakistan") %>%
  select(Variable, Unit, all_of(YEAR_COLS))

cat("Loading GCAM from:", GCAM_FILE, "\n")
gcam_raw <- read_excel(GCAM_FILE)
names(gcam_raw) <- as.character(names(gcam_raw))
gcam <- gcam_raw %>%
  filter(Region == "Pakistan", Scenario == GCAM_SCENARIO) %>%
  select(Variable, Unit, all_of(YEAR_COLS))

# Convert GCAM EJ/yr -> PJ/yr to match MSG
ej_mask <- gcam$Unit == "EJ/yr"
gcam[ej_mask, YEAR_COLS] <- gcam[ej_mask, YEAR_COLS] * 1000
gcam$Unit[ej_mask] <- "PJ/yr"

# ---- Variable registry (Category | Subcategory | Variable) -----------------
# Define all variables to compare with their categories.
# Use GCAM variable names; MSG uses same IAMC convention.
var_registry <- tribble(
  ~Category,         ~Subcategory,     ~Variable,
  "Electricity",     "Coal",           "Secondary Energy|Electricity|Coal",
  "Electricity",     "Gas",            "Secondary Energy|Electricity|Gas",
  "Electricity",     "Oil",            "Secondary Energy|Electricity|Oil",
  "Electricity",     "Nuclear",        "Secondary Energy|Electricity|Nuclear",
  "Electricity",     "Hydro",          "Secondary Energy|Electricity|Hydro",
  "Electricity",     "Solar",          "Secondary Energy|Electricity|Solar",
  "Electricity",     "Wind",           "Secondary Energy|Electricity|Wind",
  "Electricity",     "Biomass",        "Secondary Energy|Electricity|Biomass",
  "Emissions",       "CO2_Energy",     "Emissions|CO2|Energy",
  "Emissions",       "CO2_EIP",        "Emissions|CO2|Energy and Industrial Processes",
  "Emissions",       "CO2_Elec",       "Emissions|CO2|Energy|Supply|Electricity",
  "Emissions",       "CO2_Industry",   "Emissions|CO2|Energy|Demand|Industry",
  "Emissions",       "CO2_Transport",  "Emissions|CO2|Energy|Demand|Transportation",
  "Emissions",       "CO2_ResComm",    "Emissions|CO2|Energy|Demand|Residential and Commercial",
  "Emissions",       "Kyoto_Total",    "Emissions|Kyoto Gases",
  "Emissions",       "Kyoto_EIP",      "Emissions|Kyoto Gases|Energy and Industrial Processes",
  "Final_Energy",    "Total",          "Final Energy",
  "Final_Energy",    "Industry",       "Final Energy|Industry",
  "Final_Energy",    "ResComm",        "Final Energy|Residential and Commercial",
  "Final_Energy",    "Transport",      "Final Energy|Transportation",
  "Final_Energy",    "Electricity",    "Final Energy|Electricity",
  "Final_Energy",    "Gases",          "Final Energy|Gases",
  "Final_Energy",    "Liquids",        "Final Energy|Liquids",
  "Final_Energy",    "Coal",           "Final Energy|Solids|Coal",
  "Final_Energy",    "Biomass",        "Final Energy|Solids|Biomass",
  "Final_Energy",    "Trn_Elec",       "Final Energy|Transportation|Electricity",
  "Final_Energy",    "Trn_Liquids",    "Final Energy|Transportation|Liquids",
  "Primary_Energy",  "Coal",           "Primary Energy|Coal",
  "Primary_Energy",  "Gas",            "Primary Energy|Gas",
  "Primary_Energy",  "Oil",            "Primary Energy|Oil",
  "Primary_Energy",  "Nuclear",        "Primary Energy|Nuclear",
  "Primary_Energy",  "Hydro",          "Primary Energy|Hydro",
  "Primary_Energy",  "Solar",          "Primary Energy|Solar",
  "Primary_Energy",  "Wind",           "Primary Energy|Wind",
  "Primary_Energy",  "Biomass",        "Primary Energy|Biomass",
  "Trade",           "Import_Coal",    "Trade|Gross Import|Primary Energy|Coal|Volume",
  "Trade",           "Import_Gas",     "Trade|Gross Import|Primary Energy|Gas|Volume",
  "Trade",           "Import_Oil",     "Trade|Gross Import|Primary Energy|Oil|Volume"
)

# ---- Build single-sheet comparison table -----------------------------------
get_ts <- function(df, var) {
  row <- df %>% filter(Variable == var)
  if (nrow(row) == 0) return(rep(NA_real_, length(YEARS)))
  as.numeric(row[1, YEAR_COLS])
}

get_unit <- function(df, var) {
  row <- df %>% filter(Variable == var)
  if (nrow(row) == 0) return(NA_character_)
  as.character(row$Unit[1])
}

make_note <- function(msg_vals, gcam_vals, yr_idx = length(YEARS)) {
  m <- msg_vals[yr_idx]; g <- gcam_vals[yr_idx]
  if (is.na(m) && is.na(g)) return("Both NA")
  if (is.na(m)) return("MSG: NA")
  if (is.na(g)) return("GCAM: NA")
  if (m == 0 && g == 0) return("Both zero")
  if (m == 0) return(paste0("MSG=0, GCAM=", round(g, 1)))
  if (g == 0) return(paste0("GCAM=0, MSG=", round(m, 1)))
  ratio <- g / m
  if (ratio > 1.05) {
    return(sprintf("GCAM %.1fx higher at %d", ratio, YEARS[yr_idx]))
  } else if (ratio < 0.95) {
    return(sprintf("MSG %.1fx higher at %d", 1/ratio, YEARS[yr_idx]))
  } else {
    return(sprintf("~%.0f%% gap at %d", abs(ratio - 1) * 100, YEARS[yr_idx]))
  }
}

rows_list <- list()
for (i in seq_len(nrow(var_registry))) {
  cat_name <- var_registry$Category[i]
  sub_name <- var_registry$Subcategory[i]
  var_name <- var_registry$Variable[i]

  # For trade, MSG may use a slightly different variable name
  msg_var <- var_name
  if (cat_name == "Trade" && !var_name %in% msg$Variable) {
    # Try without "Gross Import|"
    alt <- sub("Trade\\|Gross Import\\|", "Trade\\|", var_name)
    if (alt %in% msg$Variable) msg_var <- alt
  }

  msg_vals  <- get_ts(msg, msg_var)
  gcam_vals <- get_ts(gcam, var_name)
  unit <- get_unit(gcam, var_name)
  if (is.na(unit)) unit <- get_unit(msg, msg_var)
  note <- make_note(msg_vals, gcam_vals)

  # MSG row
  rows_list[[length(rows_list) + 1]] <- tibble(
    Category = cat_name, Subcategory = sub_name, Variable = var_name,
    Model = MSG_LABEL, Unit = unit,
    !!!setNames(as.list(round(msg_vals, 2)), YEAR_COLS),
    Notes = ""
  )
  # GCAM row
  rows_list[[length(rows_list) + 1]] <- tibble(
    Category = cat_name, Subcategory = sub_name, Variable = var_name,
    Model = GCAM_LABEL, Unit = unit,
    !!!setNames(as.list(round(gcam_vals, 2)), YEAR_COLS),
    Notes = ""
  )
  # Difference row
  diff_vals <- gcam_vals - msg_vals
  rows_list[[length(rows_list) + 1]] <- tibble(
    Category = cat_name, Subcategory = sub_name, Variable = var_name,
    Model = "Difference", Unit = unit,
    !!!setNames(as.list(round(diff_vals, 2)), YEAR_COLS),
    Notes = ""
  )
  # Diff % row
  pct_vals <- ifelse(is.na(msg_vals) | msg_vals == 0, NA,
                     round((gcam_vals - msg_vals) / msg_vals * 100, 1))
  rows_list[[length(rows_list) + 1]] <- tibble(
    Category = cat_name, Subcategory = sub_name, Variable = var_name,
    Model = "Diff_%", Unit = "%",
    !!!setNames(as.list(pct_vals), YEAR_COLS),
    Notes = note
  )
}

sheet <- bind_rows(rows_list)

cat("Writing xlsx to:", OUT_FILE, "\n")
write_xlsx(list(Comparison = sheet), OUT_FILE)
cat("Wrote", nrow(sheet), "rows to single sheet.\n")

# ---- Figures ---------------------------------------------------------------
cat("Generating figures...\n")

# Color palette
tech_colors <- c(
  Coal = "#4d4d4d", Gas = "#1f78b4", Oil = "#a6761d",
  Nuclear = "#e31a1c", Hydro = "#33a02c", Solar = "#ff7f00",
  Wind = "#6a3d9a", Biomass = "#b2df8a"
)

model_colors <- c("GCAM 8.6" = "#e41a1c", "MESSAGEix" = "#377eb8")

# Helper: create long-format data for a set of variables
make_long <- function(df_msg, df_gcam, vars_named) {
  rows <- lapply(names(vars_named), function(label) {
    var <- vars_named[[label]]
    bind_rows(
      tibble(Technology = label, Model = MSG_LABEL, Year = YEARS, Value = get_ts(df_msg, var)),
      tibble(Technology = label, Model = GCAM_LABEL, Year = YEARS, Value = get_ts(df_gcam, var))
    )
  })
  bind_rows(rows) %>% mutate(Value = ifelse(is.na(Value), 0, Value))
}

# --- Figure 1: Electricity generation stacked bar (2030 + 2050) ---
elec_vars <- c(
  Coal = "Secondary Energy|Electricity|Coal",
  Gas = "Secondary Energy|Electricity|Gas",
  Oil = "Secondary Energy|Electricity|Oil",
  Nuclear = "Secondary Energy|Electricity|Nuclear",
  Hydro = "Secondary Energy|Electricity|Hydro",
  Solar = "Secondary Energy|Electricity|Solar",
  Wind = "Secondary Energy|Electricity|Wind",
  Biomass = "Secondary Energy|Electricity|Biomass"
)

elec_long <- make_long(msg, gcam, elec_vars)
elec_bar <- elec_long %>%
  filter(Year %in% c(2030, 2050)) %>%
  mutate(Technology = factor(Technology, levels = rev(names(tech_colors))))

p1 <- ggplot(elec_bar, aes(x = Model, y = Value, fill = Technology)) +
  geom_bar(stat = "identity", position = "stack", width = 0.7) +
  facet_wrap(~Year, ncol = 2) +
  scale_fill_manual(values = tech_colors) +
  labs(title = "Electricity Generation Mix (PJ/yr)",
       subtitle = "MSG vs GCAM v1 — Pakistan Current Measures",
       y = "PJ/yr", x = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", legend.title = element_blank())

# --- Figure 2: CO2 emissions line plot ---
co2_eip <- bind_rows(
  tibble(Model = MSG_LABEL, Year = YEARS,
         Value = get_ts(msg, "Emissions|CO2|Energy and Industrial Processes")),
  tibble(Model = GCAM_LABEL, Year = YEARS,
         Value = get_ts(gcam, "Emissions|CO2|Energy and Industrial Processes"))
)

p2 <- ggplot(co2_eip, aes(x = Year, y = Value, color = Model)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = model_colors) +
  labs(title = "CO2 Emissions — Energy & Industrial Processes",
       subtitle = "Mt CO2/yr — Pakistan Current Measures",
       y = "Mt CO2/yr", x = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", legend.title = element_blank())


# --- Figure 3: Transport electrification ---
trn_elec <- bind_rows(
  tibble(Model = MSG_LABEL, Year = YEARS,
         Value = get_ts(msg, "Final Energy|Transportation|Electricity")),
  tibble(Model = GCAM_LABEL, Year = YEARS,
         Value = get_ts(gcam, "Final Energy|Transportation|Electricity"))
)

p3 <- ggplot(trn_elec, aes(x = Year, y = Value, color = Model)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = model_colors) +
  labs(title = "Transport Electrification",
       subtitle = "Final Energy|Transportation|Electricity (PJ/yr)",
       y = "PJ/yr", x = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", legend.title = element_blank())


# --- Figure 4: Final energy by sector (2050 grouped bar) ---
fe_sectors <- c(
  Industry = "Final Energy|Industry",
  "Res & Comm" = "Final Energy|Residential and Commercial",
  Transport = "Final Energy|Transportation"
)

fe_long <- make_long(msg, gcam, fe_sectors) %>% filter(Year == 2050)

p4 <- ggplot(fe_long, aes(x = Technology, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = model_colors) +
  labs(title = "Final Energy by Sector — 2050",
       subtitle = "PJ/yr — Pakistan Current Measures",
       y = "PJ/yr", x = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", legend.title = element_blank())


# --- Figure 5: Primary energy grouped bar (2050) ---
pe_fuels <- c(
  Coal = "Primary Energy|Coal",
  Gas = "Primary Energy|Gas",
  Oil = "Primary Energy|Oil",
  Nuclear = "Primary Energy|Nuclear",
  Hydro = "Primary Energy|Hydro",
  Solar = "Primary Energy|Solar",
  Wind = "Primary Energy|Wind",
  Biomass = "Primary Energy|Biomass"
)

pe_long <- make_long(msg, gcam, pe_fuels) %>% filter(Year == 2050)

p5 <- ggplot(pe_long, aes(x = Technology, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = model_colors) +
  labs(title = "Primary Energy by Fuel — 2050",
       subtitle = "PJ/yr — Pakistan Current Measures",
       y = "PJ/yr", x = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", legend.title = element_blank())


# --- Combined multi-panel figure ---
# make p5 first, then ele p1, then final p4, then transport, then emissions
p_combined <- p5 / (p1 | p4) / (p3 | p2) &
  # p_combined <- (p1 | p2) / (p3 | p4) / p5 +
  plot_annotation(
    title = "MESSAGEix vs GCAM 8.6 — Pakistan Current Measures Comparison",
    subtitle = paste("GCAM scenario:", GCAM_SCENARIO, " |  Generated:", Sys.Date()),
    theme = theme(plot.title = element_text(size = 16, face = "bold"),
                  # draw a gray border around the panels
                  panel.background = element_rect(fill = "white", color = "gray80")
    )
  )

ggsave(file.path(FIG_DIR, "msg_gcam_comparison_panel_v0.png"), p_combined,
       width = 16, height = 18, dpi = 300)

cat("\nDone. Outputs:\n")
cat("  xlsx:", OUT_FILE, "\n")
cat("  figures:", FIG_DIR, "\n")
