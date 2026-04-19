# compare_msg_gcam.R
# MSG vs GCAM CurrentMeasuresRev comparison: single-sheet xlsx + panel figure.
#
# Usage: Rscript analysis/compare_msg_gcam.R
# Input:  analysis/MESSAGEix-Pakistan_CM.xlsx, output/gcam_output_iamc_all_standardized.xlsx
# Output: analysis/query/iamc_format/msg_gcam_comparison_all.xlsx
#         analysis/figures/msg_gcam_cm_panel.png

# ---- Bootstrap ---------------------------------------------------------------
# find_root before sourcing config.R
find_root <- function() {
  for (d in c(getwd(), file.path(getwd(), ".."), file.path(getwd(), "../..")))
    if (dir.exists(file.path(d, "input")) && dir.exists(file.path(d, "exe")))
      return(normalizePath(d))
  stop("Cannot detect project root")
}
ROOT <- find_root()
source(file.path(ROOT, "analysis", "config.R"))
library(patchwork)

# ---- Load & normalize data ---------------------------------------------------
cat("\n== Loading data ==\n")

cat("  MSG:  ", MSG_FILE, "\n")
msg_raw <- read_excel(MSG_FILE)
names(msg_raw) <- as.character(names(msg_raw))
msg <- msg_raw %>%
  filter(Region == "Pakistan") %>%
  select(Variable, Unit, all_of(YEAR_COLS))

cat("  GCAM: ", GCAM_IAMC_ALL, "\n")
gcam_raw <- read_excel(GCAM_IAMC_ALL)
names(gcam_raw) <- as.character(names(gcam_raw))
gcam <- gcam_raw %>%
  filter(Region == "Pakistan", Scenario == GCAM_CM_SCENARIO) %>%
  select(Variable, Unit, all_of(YEAR_COLS))

# Convert GCAM EJ/yr -> PJ/yr to match MSG
ej_mask <- gcam$Unit == "EJ/yr"
gcam[ej_mask, YEAR_COLS] <- gcam[ej_mask, YEAR_COLS] * 1000
gcam$Unit[ej_mask] <- "PJ/yr"

cat("  MSG vars: ", nrow(msg), " | GCAM vars: ", nrow(gcam), "\n")

# ---- Variable registry -------------------------------------------------------
# Hand-curated: these are the specific variables that matter for the inter-model
# comparison. Dynamic discovery isn't appropriate here because we need exact
# category/subcategory labels and we want to control which variables appear.
# The order defines the xlsx row order (logical grouping by sector).
var_registry <- list(
  # Electricity generation
  list("Electricity", "Coal",     "Secondary Energy|Electricity|Coal"),
  list("Electricity", "Gas",      "Secondary Energy|Electricity|Gas"),
  list("Electricity", "Oil",      "Secondary Energy|Electricity|Oil"),
  list("Electricity", "Nuclear",  "Secondary Energy|Electricity|Nuclear"),
  list("Electricity", "Hydro",    "Secondary Energy|Electricity|Hydro"),
  list("Electricity", "Solar",    "Secondary Energy|Electricity|Solar"),
  list("Electricity", "Wind",     "Secondary Energy|Electricity|Wind"),
  list("Electricity", "Biomass",  "Secondary Energy|Electricity|Biomass"),
  # Emissions
  list("Emissions", "CO2_Energy",    "Emissions|CO2|Energy"),
  list("Emissions", "CO2_EIP",       "Emissions|CO2|Energy and Industrial Processes"),
  list("Emissions", "CO2_Elec",      "Emissions|CO2|Energy|Supply|Electricity"),
  list("Emissions", "CO2_Industry",  "Emissions|CO2|Energy|Demand|Industry"),
  list("Emissions", "CO2_Transport", "Emissions|CO2|Energy|Demand|Transportation"),
  list("Emissions", "CO2_ResComm",   "Emissions|CO2|Energy|Demand|Residential and Commercial"),
  list("Emissions", "Kyoto_Total",   "Emissions|Kyoto Gases"),
  list("Emissions", "Kyoto_EIP",     "Emissions|Kyoto Gases|Energy and Industrial Processes"),
  # Final energy
  list("Final_Energy", "Total",      "Final Energy"),
  list("Final_Energy", "Industry",   "Final Energy|Industry"),
  list("Final_Energy", "ResComm",    "Final Energy|Residential and Commercial"),
  list("Final_Energy", "Transport",  "Final Energy|Transportation"),
  list("Final_Energy", "Electricity","Final Energy|Electricity"),
  list("Final_Energy", "Gases",      "Final Energy|Gases"),
  list("Final_Energy", "Liquids",    "Final Energy|Liquids"),
  list("Final_Energy", "Coal",       "Final Energy|Solids|Coal"),
  list("Final_Energy", "Biomass",    "Final Energy|Solids|Biomass"),
  list("Final_Energy", "Trn_Elec",   "Final Energy|Transportation|Electricity"),
  list("Final_Energy", "Trn_Liquids","Final Energy|Transportation|Liquids"),
  # Primary energy
  list("Primary_Energy", "Coal",    "Primary Energy|Coal"),
  list("Primary_Energy", "Gas",     "Primary Energy|Gas"),
  list("Primary_Energy", "Oil",     "Primary Energy|Oil"),
  list("Primary_Energy", "Nuclear", "Primary Energy|Nuclear"),
  list("Primary_Energy", "Hydro",   "Primary Energy|Hydro"),
  list("Primary_Energy", "Solar",   "Primary Energy|Solar"),
  list("Primary_Energy", "Wind",    "Primary Energy|Wind"),
  list("Primary_Energy", "Biomass", "Primary Energy|Biomass"),
  # Trade
  list("Trade", "Import_Coal", "Trade|Gross Import|Primary Energy|Coal|Volume"),
  list("Trade", "Import_Gas",  "Trade|Gross Import|Primary Energy|Gas|Volume"),
  list("Trade", "Import_Oil",  "Trade|Gross Import|Primary Energy|Oil|Volume")
)

# ---- Helpers -----------------------------------------------------------------
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
  if (m == 0) return(sprintf("MSG=0, GCAM=%.1f", g))
  if (g == 0) return(sprintf("GCAM=0, MSG=%.1f", m))
  ratio <- g / m
  if (ratio > 1.05) sprintf("GCAM %.1fx higher at %d", ratio, YEARS[yr_idx])
  else if (ratio < 0.95) sprintf("MSG %.1fx higher at %d", 1/ratio, YEARS[yr_idx])
  else sprintf("~%.0f%% gap at %d", abs(ratio - 1) * 100, YEARS[yr_idx])
}

# ---- Build xlsx sheet --------------------------------------------------------
cat("\n== Building comparison table ==\n")

rows_list <- list()
for (entry in var_registry) {
  cat_name <- entry[[1]]; sub_name <- entry[[2]]; var_name <- entry[[3]]

  # Try alternative MSG variable name for trade
  msg_var <- var_name
  if (cat_name == "Trade" && !var_name %in% msg$Variable) {
    alt <- sub("Trade\\|Gross Import\\|", "Trade\\|", var_name)
    if (alt %in% msg$Variable) msg_var <- alt
  }

  msg_vals  <- get_ts(msg, msg_var)
  gcam_vals <- get_ts(gcam, var_name)
  unit <- get_unit(gcam, var_name)
  if (is.na(unit)) unit <- get_unit(msg, msg_var)
  note <- make_note(msg_vals, gcam_vals)

  for (info in list(
    list(m = MSG_MODEL_LABEL, v = msg_vals,                    n = ""),
    list(m = GCAM_MODEL_LABEL, v = gcam_vals,                  n = ""),
    list(m = "Difference",  v = gcam_vals - msg_vals,          n = ""),
    list(m = "Diff_%",
         v = ifelse(is.na(msg_vals) | msg_vals == 0, NA,
                    round((gcam_vals - msg_vals) / msg_vals * 100, 1)),
         n = note))) {
    u <- if (info$m == "Diff_%") "%" else unit
    rows_list[[length(rows_list) + 1]] <- tibble(
      Category = cat_name, Subcategory = sub_name, Variable = var_name,
      Model = info$m, Unit = u,
      !!!setNames(as.list(round(info$v, 2)), YEAR_COLS),
      Notes = info$n
    )
  }
}

sheet <- bind_rows(rows_list)

out_file <- file.path(IAMC_FORMAT_DIR, "msg_gcam_comparison_all.xlsx")
write_xlsx(list(Comparison = sheet), out_file)
cat("  Wrote ", nrow(sheet), " rows -> ", out_file, "\n")

# ---- Helper: long-format for plotting ----------------------------------------
make_long <- function(df_msg, df_gcam, vars_named) {
  bind_rows(lapply(names(vars_named), function(label) {
    var <- vars_named[[label]]
    bind_rows(
      tibble(Technology = label, Model = MSG_MODEL_LABEL, Year = YEARS, Value = get_ts(df_msg, var)),
      tibble(Technology = label, Model = GCAM_MODEL_LABEL, Year = YEARS, Value = get_ts(df_gcam, var))
    )
  })) %>% mutate(Value = ifelse(is.na(Value), 0, Value))
}

# ---- Figures: CM comparison panel --------------------------------------------
cat("\n== Generating CM comparison panel ==\n")

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

# P1: Primary Energy by fuel 2050 (grouped bar) — big picture context first
pe_fuels <- c(
  Coal = "Primary Energy|Coal", Gas = "Primary Energy|Gas",
  Oil = "Primary Energy|Oil", Nuclear = "Primary Energy|Nuclear",
  Hydro = "Primary Energy|Hydro", Solar = "Primary Energy|Solar",
  Wind = "Primary Energy|Wind", Biomass = "Primary Energy|Biomass"
)

pe_long <- make_long(msg, gcam, pe_fuels) %>% filter(Year == 2050)

p1 <- ggplot(pe_long, aes(x = Technology, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = model_colors) +
  labs(title = "Primary Energy by Fuel — 2050",
       subtitle = "PJ/yr", y = "PJ/yr", x = NULL) +
  theme_gcam() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

# P2: Electricity generation stacked bar (2030 + 2050)
elec_long <- make_long(msg, gcam, elec_vars)
elec_bar <- elec_long %>%
  filter(Year %in% c(2030, 2050)) %>%
  mutate(Technology = factor(Technology, levels = rev(names(tech_colors))))

p2 <- ggplot(elec_bar, aes(x = Model, y = Value, fill = Technology)) +
  geom_bar(stat = "identity", position = "stack", width = 0.7) +
  facet_wrap(~Year, ncol = 2) +
  scale_fill_manual(values = tech_colors) +
  labs(title = "Electricity Generation Mix",
       subtitle = "PJ/yr at 2030 and 2050", y = "PJ/yr", x = NULL) +
  theme_gcam()

# P3: Final energy by sector (2050 grouped bar)
fe_sectors <- c(
  Industry = "Final Energy|Industry",
  "Res & Comm" = "Final Energy|Residential and Commercial",
  Transport = "Final Energy|Transportation"
)
fe_long <- make_long(msg, gcam, fe_sectors) %>% filter(Year == 2050)

p3 <- ggplot(fe_long, aes(x = Technology, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = model_colors) +
  labs(title = "Final Energy by Sector — 2050",
       subtitle = "PJ/yr", y = "PJ/yr", x = NULL) +
  theme_gcam()

# P4: Transport electrification line
trn_elec <- bind_rows(
  tibble(Model = MSG_MODEL_LABEL, Year = YEARS,
         Value = get_ts(msg, "Final Energy|Transportation|Electricity")),
  tibble(Model = GCAM_MODEL_LABEL, Year = YEARS,
         Value = get_ts(gcam, "Final Energy|Transportation|Electricity"))
)

p4 <- ggplot(trn_elec, aes(x = Year, y = Value, color = Model)) +
  geom_line(linewidth = 1.2) + geom_point(size = 2.5) +
  scale_color_manual(values = model_colors) +
  labs(title = "Transport Electrification",
       subtitle = "Final Energy|Transportation|Electricity (PJ/yr)", y = "PJ/yr", x = NULL) +
  theme_gcam()

# P5: CO2 E&IP line
co2_eip <- bind_rows(
  tibble(Model = MSG_MODEL_LABEL, Year = YEARS,
         Value = get_ts(msg, "Emissions|CO2|Energy and Industrial Processes")),
  tibble(Model = GCAM_MODEL_LABEL, Year = YEARS,
         Value = get_ts(gcam, "Emissions|CO2|Energy and Industrial Processes"))
)

p5 <- ggplot(co2_eip, aes(x = Year, y = Value, color = Model)) +
  geom_line(linewidth = 1.2) + geom_point(size = 2.5) +
  scale_color_manual(values = model_colors) +
  labs(title = "CO2 Emissions — Energy & Industry",
       subtitle = "Mt CO2/yr", y = "Mt CO2/yr", x = NULL) +
  theme_gcam()

# P6: Key technology line comparisons (Coal, Gas, Solar gen over time)
key_tech_long <- elec_long %>%
  filter(Technology %in% c("Coal", "Gas", "Solar"))

p6 <- ggplot(key_tech_long, aes(x = Year, y = Value, color = Model, linetype = Technology)) +
  geom_line(linewidth = 1.0) + geom_point(size = 2) +
  scale_color_manual(values = model_colors) +
  scale_linetype_manual(values = c(Coal = "solid", Gas = "dashed", Solar = "dotdash")) +
  labs(title = "Key Generation Technologies Over Time",
       subtitle = "Coal, Gas, Solar — PJ/yr", y = "PJ/yr", x = NULL) +
  theme_gcam() +
  guides(color = guide_legend(order = 1), linetype = guide_legend(order = 2))

# Assemble panel: user's preferred layout (primary first, then elec+fe, then transport+emissions)
# plus the new technology lines panel
p_cm <- p1 / (p2 | p3) / (p4 | p5) / p6 +
  plot_annotation(
    title = "MESSAGEix vs GCAM 8.6 — Pakistan Current Measures Comparison",
    subtitle = paste0("GCAM scenario: ", GCAM_CM_SCENARIO, "  |  Generated: ", Sys.Date()),
    theme = theme(
      plot.title = element_text(size = 16, face = "bold"),
      plot.subtitle = element_text(size = 12, color = "gray30")
    )
  )

cm_panel_file <- file.path(FIG_DIR, "msg_gcam_cm_panel_v2.png")
ggsave(cm_panel_file, p_cm, width = 16, height = 22, dpi = 300)
cat("  CM panel -> ", cm_panel_file, "\n")

# ---- Figures: All-scenarios panel (4 GCAM + MSG CM) --------------------------
cat("\n== Generating all-scenarios panel ==\n")

# Load all GCAM scenarios
gcam_all <- gcam_raw %>%
  filter(Region == "Pakistan") %>%
  select(Scenario, Variable, Unit, all_of(YEAR_COLS))

# EJ -> PJ
ej_mask_all <- gcam_all$Unit == "EJ/yr"
gcam_all[ej_mask_all, YEAR_COLS] <- gcam_all[ej_mask_all, YEAR_COLS] * 1000
gcam_all$Unit[ej_mask_all] <- "PJ/yr"

# Helper: extract time series for a variable across scenarios
get_scenario_ts <- function(var, scenarios) {
  gcam_all %>%
    filter(Variable == var, Scenario %in% scenarios) %>%
    select(Scenario, all_of(YEAR_COLS)) %>%
    pivot_longer(all_of(YEAR_COLS), names_to = "Year", values_to = "Value") %>%
    mutate(Year = as.integer(Year))
}

scens_to_plot <- c("CurrentMeasuresRev", "NDCUncond_EnergyAg",
                   "NDCCond_EnergyAg", "NetZero_EnergyAg")

# S1: CO2 E&IP trajectories (all scenarios + MSG)
co2_all <- get_scenario_ts("Emissions|CO2|Energy and Industrial Processes", scens_to_plot)
co2_msg <- tibble(Scenario = "MESSAGEix_CM", Year = YEARS,
                  Value = get_ts(msg, "Emissions|CO2|Energy and Industrial Processes"))
co2_combined <- bind_rows(co2_all, co2_msg)

s1 <- ggplot(co2_combined, aes(x = Year, y = Value, color = Scenario)) +
  geom_line(linewidth = 1.1) + geom_point(size = 2) +
  scale_color_manual(values = scenario_colors) +
  labs(title = "CO2 Emissions — Energy & Industry",
       subtitle = "All scenarios vs MSG CM (Mt CO2/yr)", y = "Mt CO2/yr", x = NULL) +
  theme_gcam()

# S2: Total electricity generation by scenario
elec_total_all <- get_scenario_ts("Secondary Energy|Electricity", scens_to_plot)
elec_total_msg <- tibble(Scenario = "MESSAGEix_CM", Year = YEARS,
                         Value = get_ts(msg, "Secondary Energy|Electricity"))
elec_combined <- bind_rows(elec_total_all, elec_total_msg)

s2 <- ggplot(elec_combined, aes(x = Year, y = Value, color = Scenario)) +
  geom_line(linewidth = 1.1) + geom_point(size = 2) +
  scale_color_manual(values = scenario_colors) +
  labs(title = "Total Electricity Generation",
       subtitle = "PJ/yr", y = "PJ/yr", x = NULL) +
  theme_gcam()

# S3: Final energy total
fe_total_all <- get_scenario_ts("Final Energy", scens_to_plot)
fe_total_msg <- tibble(Scenario = "MESSAGEix_CM", Year = YEARS,
                       Value = get_ts(msg, "Final Energy"))
fe_combined <- bind_rows(fe_total_all, fe_total_msg)

s3 <- ggplot(fe_combined, aes(x = Year, y = Value, color = Scenario)) +
  geom_line(linewidth = 1.1) + geom_point(size = 2) +
  scale_color_manual(values = scenario_colors) +
  labs(title = "Total Final Energy",
       subtitle = "PJ/yr", y = "PJ/yr", x = NULL) +
  theme_gcam()

# S4: Transport electrification
trn_all <- get_scenario_ts("Final Energy|Transportation|Electricity", scens_to_plot)
trn_msg <- tibble(Scenario = "MESSAGEix_CM", Year = YEARS,
                  Value = get_ts(msg, "Final Energy|Transportation|Electricity"))
trn_combined <- bind_rows(trn_all, trn_msg)

s4 <- ggplot(trn_combined, aes(x = Year, y = Value, color = Scenario)) +
  geom_line(linewidth = 1.1) + geom_point(size = 2) +
  scale_color_manual(values = scenario_colors) +
  labs(title = "Transport Electrification",
       subtitle = "PJ/yr", y = "PJ/yr", x = NULL) +
  theme_gcam()

# S5: Stacked generation at 2050 by scenario (GCAM only)
elec_2050_scens <- gcam_all %>%
  filter(Scenario %in% scens_to_plot,
         Variable %in% elec_vars) %>%
  select(Scenario, Variable, `2050`) %>%
  mutate(Technology = names(elec_vars)[match(Variable, elec_vars)],
         Value = as.numeric(`2050`)) %>%
  mutate(Technology = factor(Technology, levels = rev(names(tech_colors))))

s5 <- ggplot(elec_2050_scens, aes(x = Scenario, y = Value, fill = Technology)) +
  geom_bar(stat = "identity", position = "stack", width = 0.6) +
  scale_fill_manual(values = tech_colors) +
  scale_x_discrete(labels = function(x) gsub("_EnergyAg", "", x)) +
  labs(title = "GCAM Generation Mix at 2050",
       subtitle = "PJ/yr by scenario", y = "PJ/yr", x = NULL) +
  theme_gcam() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))

# S6: Kyoto Gases (if available)
kyoto_all <- get_scenario_ts("Emissions|Kyoto Gases", scens_to_plot)
kyoto_msg <- tibble(Scenario = "MESSAGEix_CM", Year = YEARS,
                    Value = get_ts(msg, "Emissions|Kyoto Gases"))
kyoto_combined <- bind_rows(kyoto_all, kyoto_msg) %>% filter(!is.na(Value))

if (nrow(kyoto_combined) > 0) {
  s6 <- ggplot(kyoto_combined, aes(x = Year, y = Value, color = Scenario)) +
    geom_line(linewidth = 1.1) + geom_point(size = 2) +
    scale_color_manual(values = scenario_colors) +
    labs(title = "Kyoto Gases",
         subtitle = "Mt CO2e/yr (scope differs between models)", y = "Mt CO2e/yr", x = NULL) +
    theme_gcam()
} else {
  s6 <- ggplot() + theme_void() + labs(title = "Kyoto Gases: no data")
}

# Assemble all-scenarios panel
p_all <- s1 / (s2 | s3) / (s4 | s5) / s6 +
  plot_annotation(
    title = "GCAM Pakistan: All Scenarios vs MESSAGEix Current Measures",
    subtitle = paste0("Scenarios: CM, NDCUncond, NDCCond, NetZero (UCT)  |  Generated: ", Sys.Date()),
    theme = theme(
      plot.title = element_text(size = 16, face = "bold"),
      plot.subtitle = element_text(size = 12, color = "gray30")
    )
  )

all_panel_file <- file.path(FIG_DIR, "msg_gcam_all_scenarios_panel_v2.png")
ggsave(all_panel_file, p_all, width = 16, height = 24, dpi = 300)
log_info("All-scenarios panel -> ", all_panel_file)

log_done()
