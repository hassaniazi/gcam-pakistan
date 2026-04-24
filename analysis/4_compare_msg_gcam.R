# 4_compare_msg_gcam.R
# Merged from v1, v2, v3. Compares MESSAGEix and GCAM CurrentMeasuresRev for Pakistan.
#
# Provenance:
#   - v1: self-contained, simple figures (5 individual + 1 combined panel)
#   - v2: shared config, CM panel (6 figs) + all-scenarios panel (6 figs)
#   - v3: advanced viz (small multiples, butterfly, shaded divergence, paired dots,
#          diverging bars, annotated gaps) for CM + all-scenarios
#
# All figure versions are kept with distinct output names (v0, v2, v3).
# Dropped from v1: inline config (replaced by shared 1_config.R), duplicate helpers
# Dropped from v2: duplicate code identical to v3 (data loading, registry, helpers)
# Dropped: v2 log_info/log_done calls (not in 1_config.R)
#
# Usage: Rscript analysis/4_compare_msg_gcam.R
# Input:
#   - analysis/MESSAGEix-Pakistan_CM.xlsx
#   - output/gcam_output_iamc_all_standardized.xlsx
# Output:
#   - analysis/query/iamc_format/msg_gcam_comparison_all.xlsx
#   - analysis/figures/msg_gcam_comparison_panel_v0.png  (from v1)
#   - analysis/figures/msg_gcam_cm_panel_v2.png           (from v2)
#   - analysis/figures/msg_gcam_cm_panel_v3.png           (from v3)
#   - analysis/figures/msg_gcam_all_scenarios_panel_v2.png (from v2)
#   - analysis/figures/msg_gcam_all_scenarios_panel_v3.png (from v3)

# ---- Bootstrap ---------------------------------------------------------------
find_root <- function() {
  for (d in c(getwd(), file.path(getwd(), ".."), file.path(getwd(), "../..")))
    if (dir.exists(file.path(d, "input")) && dir.exists(file.path(d, "exe")))
      return(normalizePath(d))
  stop("Cannot detect project root")
}
ROOT <- find_root()
source(file.path(ROOT, "analysis", "1_config.R"))
library(patchwork)

FIG_PREFIX <- "msg_gcam_v2"

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

make_long <- function(df_msg, df_gcam, vars_named) {
  bind_rows(lapply(names(vars_named), function(label) {
    var <- vars_named[[label]]
    bind_rows(
      tibble(Technology = label, Model = MSG_MODEL_LABEL, Year = YEARS, Value = get_ts(df_msg, var)),
      tibble(Technology = label, Model = GCAM_MODEL_LABEL, Year = YEARS, Value = get_ts(df_gcam, var))
    )
  })) %>% mutate(Value = ifelse(is.na(Value), 0, Value))
}

# ---- Build xlsx sheet --------------------------------------------------------
cat("\n== Building comparison table ==\n")

rows_list <- list()
for (entry in var_registry) {
  cat_name <- entry[[1]]; sub_name <- entry[[2]]; var_name <- entry[[3]]

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

# ---- Shared variable vectors -------------------------------------------------
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

pe_fuels <- c(
  Coal = "Primary Energy|Coal", Gas = "Primary Energy|Gas",
  Oil = "Primary Energy|Oil", Nuclear = "Primary Energy|Nuclear",
  Hydro = "Primary Energy|Hydro", Solar = "Primary Energy|Solar",
  Wind = "Primary Energy|Wind", Biomass = "Primary Energy|Biomass"
)

fe_sectors <- c(
  Industry = "Final Energy|Industry",
  "Res & Comm" = "Final Energy|Residential and Commercial",
  Transport = "Final Energy|Transportation"
)

# ==============================================================================
# FIGURE SET V0 (from v1 — simple ggplot2, 5 individual + 1 combined)
# ==============================================================================
cat("\n== Generating v0 figures (from v1) ==\n")

# v0 uses slightly different color palette from v1
v0_tech_colors <- c(
  Coal = "#4d4d4d", Gas = "#1f78b4", Oil = "#a6761d",
  Nuclear = "#e31a1c", Hydro = "#33a02c", Solar = "#ff7f00",
  Wind = "#6a3d9a", Biomass = "#b2df8a"
)

elec_long_v0 <- make_long(msg, gcam, elec_vars)

# Fig 1: Electricity stacked bar 2030+2050
elec_bar_v0 <- elec_long_v0 %>%
  filter(Year %in% c(2030, 2050)) %>%
  mutate(Technology = factor(Technology, levels = rev(names(v0_tech_colors))))

p1_v0 <- ggplot(elec_bar_v0, aes(x = Model, y = Value, fill = Technology)) +
  geom_bar(stat = "identity", position = "stack", width = 0.7) +
  facet_wrap(~Year, ncol = 2) +
  scale_fill_manual(values = v0_tech_colors) +
  labs(title = "Electricity Generation Mix (PJ/yr)",
       subtitle = "MSG vs GCAM v1 — Pakistan Current Measures",
       y = "PJ/yr", x = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", legend.title = element_blank())

# Fig 2: CO2 emissions line
co2_eip_v0 <- bind_rows(
  tibble(Model = MSG_MODEL_LABEL, Year = YEARS,
         Value = get_ts(msg, "Emissions|CO2|Energy and Industrial Processes")),
  tibble(Model = GCAM_MODEL_LABEL, Year = YEARS,
         Value = get_ts(gcam, "Emissions|CO2|Energy and Industrial Processes"))
)

p2_v0 <- ggplot(co2_eip_v0, aes(x = Year, y = Value, color = Model)) +
  geom_line(linewidth = 1.2) + geom_point(size = 2.5) +
  scale_color_manual(values = model_colors) +
  labs(title = "CO2 Emissions — Energy & Industrial Processes",
       subtitle = "Mt CO2/yr — Pakistan Current Measures", y = "Mt CO2/yr", x = NULL) +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", legend.title = element_blank())

# Fig 3: Transport electrification
trn_elec_v0 <- bind_rows(
  tibble(Model = MSG_MODEL_LABEL, Year = YEARS,
         Value = get_ts(msg, "Final Energy|Transportation|Electricity")),
  tibble(Model = GCAM_MODEL_LABEL, Year = YEARS,
         Value = get_ts(gcam, "Final Energy|Transportation|Electricity"))
)

p3_v0 <- ggplot(trn_elec_v0, aes(x = Year, y = Value, color = Model)) +
  geom_line(linewidth = 1.2) + geom_point(size = 2.5) +
  scale_color_manual(values = model_colors) +
  labs(title = "Transport Electrification",
       subtitle = "Final Energy|Transportation|Electricity (PJ/yr)", y = "PJ/yr", x = NULL) +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", legend.title = element_blank())

# Fig 4: Final energy by sector 2050
fe_long_v0 <- make_long(msg, gcam, fe_sectors) %>% filter(Year == 2050)

p4_v0 <- ggplot(fe_long_v0, aes(x = Technology, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = model_colors) +
  labs(title = "Final Energy by Sector — 2050",
       subtitle = "PJ/yr — Pakistan Current Measures", y = "PJ/yr", x = NULL) +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", legend.title = element_blank())

# Fig 5: Primary energy 2050
pe_long_v0 <- make_long(msg, gcam, pe_fuels) %>% filter(Year == 2050)

p5_v0 <- ggplot(pe_long_v0, aes(x = Technology, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = model_colors) +
  labs(title = "Primary Energy by Fuel — 2050",
       subtitle = "PJ/yr — Pakistan Current Measures", y = "PJ/yr", x = NULL) +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", legend.title = element_blank())

# Combined v0 panel
p_combined_v0 <- p5_v0 / (p1_v0 | p4_v0) / (p3_v0 | p2_v0) +
  plot_annotation(
    title = "MESSAGEix vs GCAM 8.6 — Pakistan Current Measures Comparison",
    subtitle = paste("GCAM scenario:", GCAM_CM_SCENARIO, " |  Generated:", Sys.Date()),
    theme = theme(plot.title = element_text(size = 16, face = "bold"),
                  panel.background = element_rect(fill = "white", color = "gray80"))
  )

ggsave(file.path(FIG_DIR, sprintf("%s_cm_panel_v0.png", FIG_PREFIX)), p_combined_v0,
       width = 16, height = 18, dpi = 300, bg = "white")
cat("  v0 panel saved\n")

# ==============================================================================
# FIGURE SET V2 (from v2 — theme_gcam, 6-panel CM + 6-panel all-scenarios)
# ==============================================================================
cat("\n== Generating v2 figures ==\n")

elec_long <- make_long(msg, gcam, elec_vars)

# P1: Primary Energy 2050 grouped bar
pe_long <- make_long(msg, gcam, pe_fuels) %>% filter(Year == 2050)

p1_v2 <- ggplot(pe_long, aes(x = Technology, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = model_colors) +
  labs(title = "Primary Energy by Fuel — 2050", subtitle = "PJ/yr", y = "PJ/yr", x = NULL) +
  theme_gcam() + theme(axis.text.x = element_text(angle = 30, hjust = 1))

# P2: Electricity stacked bar 2030+2050
elec_bar <- elec_long %>%
  filter(Year %in% c(2030, 2050)) %>%
  mutate(Technology = factor(Technology, levels = rev(names(tech_colors))))

p2_v2 <- ggplot(elec_bar, aes(x = Model, y = Value, fill = Technology)) +
  geom_bar(stat = "identity", position = "stack", width = 0.7) +
  facet_wrap(~Year, ncol = 2) +
  scale_fill_manual(values = tech_colors) +
  labs(title = "Electricity Generation Mix", subtitle = "PJ/yr at 2030 and 2050",
       y = "PJ/yr", x = NULL) +
  theme_gcam()

# P3: Final energy by sector 2050
fe_long <- make_long(msg, gcam, fe_sectors) %>% filter(Year == 2050)
p3_v2 <- ggplot(fe_long, aes(x = Technology, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  scale_fill_manual(values = model_colors) +
  labs(title = "Final Energy by Sector — 2050", subtitle = "PJ/yr", y = "PJ/yr", x = NULL) +
  theme_gcam()

# P4: Transport electrification line
trn_elec <- bind_rows(
  tibble(Model = MSG_MODEL_LABEL, Year = YEARS,
         Value = get_ts(msg, "Final Energy|Transportation|Electricity")),
  tibble(Model = GCAM_MODEL_LABEL, Year = YEARS,
         Value = get_ts(gcam, "Final Energy|Transportation|Electricity"))
)
p4_v2 <- ggplot(trn_elec, aes(x = Year, y = Value, color = Model)) +
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
p5_v2 <- ggplot(co2_eip, aes(x = Year, y = Value, color = Model)) +
  geom_line(linewidth = 1.2) + geom_point(size = 2.5) +
  scale_color_manual(values = model_colors) +
  labs(title = "CO2 Emissions — Energy & Industry", subtitle = "Mt CO2/yr",
       y = "Mt CO2/yr", x = NULL) +
  theme_gcam()

# P6: Key technology line comparisons (v2 only — Coal/Gas/Solar over time)
key_tech_long <- elec_long %>% filter(Technology %in% c("Coal", "Gas", "Solar"))
p6_v2 <- ggplot(key_tech_long, aes(x = Year, y = Value, color = Model, linetype = Technology)) +
  geom_line(linewidth = 1.0) + geom_point(size = 2) +
  scale_color_manual(values = model_colors) +
  scale_linetype_manual(values = c(Coal = "solid", Gas = "dashed", Solar = "dotdash")) +
  labs(title = "Key Generation Technologies Over Time",
       subtitle = "Coal, Gas, Solar — PJ/yr", y = "PJ/yr", x = NULL) +
  theme_gcam() +
  guides(color = guide_legend(order = 1), linetype = guide_legend(order = 2))

# CM panel v2
p_cm_v2 <- p1_v2 / (p2_v2 | p3_v2) / (p4_v2 | p5_v2) / p6_v2 +
  plot_annotation(
    title = "MESSAGEix vs GCAM 8.6 — Pakistan Current Measures Comparison",
    subtitle = paste0("GCAM scenario: ", GCAM_CM_SCENARIO, "  |  Generated: ", Sys.Date()),
    theme = theme(
      plot.title = element_text(size = 16, face = "bold"),
      plot.subtitle = element_text(size = 12, color = "gray30")
    )
  )

ggsave(file.path(FIG_DIR, sprintf("%s_cm_panel_v2.png", FIG_PREFIX)), p_cm_v2,
       width = 16, height = 22, dpi = 300, bg = "white")
cat("  v2 CM panel saved\n")

# ==============================================================================
# FIGURE SET V3 (from v3 — advanced viz: small multiples, butterfly, etc.)
# ==============================================================================
cat("\n== Generating v3 figures ==\n")

# P1_v3: Small multiples time series per technology
elec_long$Technology <- factor(elec_long$Technology, levels = names(tech_colors))
elec_end <- elec_long %>% filter(Year == max(YEARS))

p1_v3 <- ggplot(elec_long, aes(x = Year, y = Value, color = Model)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.2, shape = 16) +
  geom_text(data = elec_end,
            aes(label = sprintf("%.0f", Value)),
            hjust = -0.15, size = 2.5, show.legend = FALSE) +
  facet_wrap(~Technology, ncol = 4, scales = "free_y") +
  scale_color_manual(values = model_colors) +
  scale_x_continuous(breaks = c(2025, 2035, 2050), expand = expansion(mult = c(0.02, 0.15))) +
  labs(title = "Electricity Generation by Technology",
       subtitle = "PJ/yr  |  Free y-axis scales to show within-technology patterns",
       y = "PJ/yr") +
  theme_gcam(base_size = 10) +
  theme(axis.title.x = element_blank(), legend.position = "top", legend.justification = "left")

# P2_v3: Butterfly bar at 2050
elec_2050 <- elec_long %>%
  filter(Year == 2050) %>%
  mutate(
    Value_dir = ifelse(Model == MSG_MODEL_LABEL, -Value, Value),
    Technology = factor(Technology, levels = rev(names(tech_colors)))
  )

p2_v3 <- ggplot(elec_2050, aes(x = Technology, y = Value_dir, fill = Technology)) +
  geom_col(width = 0.7) +
  geom_hline(yintercept = 0, color = "grey40", linewidth = 0.4) +
  coord_flip() +
  scale_fill_manual(values = tech_colors, guide = "none") +
  scale_y_continuous(labels = function(x) comma(abs(x)), breaks = pretty) +
  annotate("text", x = 8.6, y = -400, label = "MESSAGEix", fontface = "bold",
           color = model_colors["MESSAGEix"], hjust = 1, size = 3.5) +
  annotate("text", x = 8.6, y = 400, label = "GCAM 8.6", fontface = "bold",
           color = model_colors["GCAM 8.6"], hjust = 0, size = 3.5) +
  labs(title = "Generation Mix at 2050",
       subtitle = "PJ/yr  |  Mirrored comparison", y = "PJ/yr") +
  theme_gcam(base_size = 10) + theme(axis.title.y = element_blank())

# P3_v3: CO2 with shaded divergence
co2_msg_vals <- get_ts(msg, "Emissions|CO2|Energy and Industrial Processes")
co2_gcam_vals <- get_ts(gcam, "Emissions|CO2|Energy and Industrial Processes")
co2_df <- tibble(Year = YEARS, MESSAGEix = co2_msg_vals, GCAM = co2_gcam_vals,
                 upper = pmax(co2_msg_vals, co2_gcam_vals, na.rm = TRUE),
                 lower = pmin(co2_msg_vals, co2_gcam_vals, na.rm = TRUE))
co2_long <- co2_df %>%
  pivot_longer(c(MESSAGEix, GCAM), names_to = "Model", values_to = "Value") %>%
  mutate(Model = ifelse(Model == "GCAM", GCAM_MODEL_LABEL, MSG_MODEL_LABEL))

p3_v3 <- ggplot() +
  geom_ribbon(data = co2_df, aes(x = Year, ymin = lower, ymax = upper),
              fill = "grey85", alpha = 0.6) +
  geom_line(data = co2_long, aes(x = Year, y = Value, color = Model), linewidth = 1.0) +
  geom_point(data = co2_long, aes(x = Year, y = Value, color = Model), size = 2, shape = 16) +
  geom_text(data = co2_long %>% filter(Year == 2050),
            aes(x = Year, y = Value, label = sprintf("%.0f", Value), color = Model),
            hjust = -0.2, size = 3, fontface = "bold", show.legend = FALSE) +
  scale_color_manual(values = model_colors) +
  scale_x_continuous(breaks = YEARS, expand = expansion(mult = c(0.02, 0.10))) +
  labs(title = expression(CO[2]~"Emissions — Energy & Industrial Processes"),
       subtitle = "Mt CO\u2082/yr  |  Shaded area = inter-model divergence",
       y = expression(Mt~CO[2]/yr)) +
  theme_gcam() + theme(legend.position = "top", legend.justification = "left")

# P4_v3: Paired dot plot for final energy at 2050
fe_sectors_v3 <- c(
  Industry = "Final Energy|Industry",
  "Residential\n& Commercial" = "Final Energy|Residential and Commercial",
  Transport = "Final Energy|Transportation"
)
fe_long_v3 <- make_long(msg, gcam, fe_sectors_v3) %>% filter(Year == 2050)

p4_v3 <- ggplot(fe_long_v3, aes(x = Value, y = Technology, color = Model)) +
  geom_line(aes(group = Technology), color = "grey70", linewidth = 0.6) +
  geom_point(size = 3.5, shape = 16) +
  geom_text(aes(label = sprintf("%.0f", Value)),
            vjust = -1, size = 2.8, show.legend = FALSE) +
  scale_color_manual(values = model_colors) +
  scale_x_continuous(labels = comma, expand = expansion(mult = c(0.05, 0.12))) +
  labs(title = "Final Energy by Sector — 2050",
       subtitle = "PJ/yr  |  Connected dots show inter-model gap", x = "PJ/yr") +
  theme_gcam() + theme(axis.title.y = element_blank(),
                        legend.position = "top", legend.justification = "left")

# P5_v3: Transport electrification with annotated gap
trn_msg_vals <- get_ts(msg, "Final Energy|Transportation|Electricity")
trn_gcam_vals <- get_ts(gcam, "Final Energy|Transportation|Electricity")
trn_df <- tibble(Year = YEARS, MESSAGEix = trn_msg_vals, GCAM = trn_gcam_vals)
trn_long <- trn_df %>%
  pivot_longer(c(MESSAGEix, GCAM), names_to = "Model", values_to = "Value") %>%
  mutate(Model = ifelse(Model == "GCAM", GCAM_MODEL_LABEL, MSG_MODEL_LABEL))
gap_2050 <- trn_df$MESSAGEix[trn_df$Year == 2050] - trn_df$GCAM[trn_df$Year == 2050]

p5_v3 <- ggplot(trn_long, aes(x = Year, y = Value, color = Model)) +
  geom_line(linewidth = 1.0) + geom_point(size = 2.5, shape = 16) +
  annotate("segment", x = 2050, xend = 2050,
           y = trn_df$GCAM[trn_df$Year == 2050], yend = trn_df$MESSAGEix[trn_df$Year == 2050],
           linewidth = 0.6, color = "grey40", linetype = "dashed") +
  annotate("text", x = 2050.5, y = mean(c(trn_df$GCAM[6], trn_df$MESSAGEix[6])),
           label = sprintf("\u0394 = %.0f PJ", abs(gap_2050)),
           hjust = 0, size = 3, color = "grey30", fontface = "italic") +
  scale_color_manual(values = model_colors) +
  scale_x_continuous(breaks = YEARS, expand = expansion(mult = c(0.02, 0.12))) +
  labs(title = "Transport Electrification",
       subtitle = "Final Energy|Transportation|Electricity (PJ/yr)", y = "PJ/yr") +
  theme_gcam() + theme(legend.position = "top", legend.justification = "left")

# P6_v3: Primary energy diverging bar (GCAM - MSG)
pe_long_v3 <- make_long(msg, gcam, pe_fuels) %>% filter(Year == 2050)
pe_diff <- pe_long_v3 %>%
  pivot_wider(names_from = Model, values_from = Value) %>%
  mutate(Diff = .data[[GCAM_MODEL_LABEL]] - .data[[MSG_MODEL_LABEL]],
         Direction = ifelse(Diff >= 0, "GCAM higher", "MSG higher")) %>%
  arrange(Diff) %>%
  mutate(Technology = factor(Technology, levels = Technology))

p6_v3 <- ggplot(pe_diff, aes(x = Technology, y = Diff, fill = Direction)) +
  geom_col(width = 0.6) +
  geom_hline(yintercept = 0, color = "grey40", linewidth = 0.4) +
  geom_text(aes(label = sprintf("%+.0f", Diff),
                y = Diff + sign(Diff) * max(abs(Diff)) * 0.04),
            size = 2.8, color = "grey20") +
  coord_flip() +
  scale_fill_manual(values = c("GCAM higher" = "#c0392b", "MSG higher" = "#2471a3")) +
  labs(title = "Primary Energy Difference at 2050",
       subtitle = "GCAM minus MESSAGEix (PJ/yr)  |  Key structural divergences",
       y = "PJ/yr (GCAM \u2212 MSG)") +
  theme_gcam() + theme(axis.title.y = element_blank(),
                        legend.position = "top", legend.justification = "left")

# CM panel v3
p_cm_v3 <- p1_v3 / (p2_v3 | p3_v3) / (p4_v3 | p5_v3) / p6_v3 +
  plot_annotation(
    title = "MESSAGEix vs GCAM 8.6 — Pakistan Current Measures",
    subtitle = paste0("GCAM: ", GCAM_CM_SCENARIO, "  |  ", Sys.Date()),
    caption = "Source: GCAM v8.6 (PNNL) and MESSAGEix-Pakistan (IIASA)  |  Units converted to common PJ/yr basis",
    theme = theme(
      plot.title    = element_text(size = 16, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 11, color = "grey40", hjust = 0),
      plot.caption  = element_text(size = 8, color = "grey50", hjust = 1)
    )
  )

ggsave(file.path(FIG_DIR, sprintf("%s_cm_panel_v3.png", FIG_PREFIX)), p_cm_v3,
       width = 16, height = 22, dpi = 300, bg = "white")
cat("  v3 CM panel saved\n")

# ==============================================================================
# ALL-SCENARIOS PANELS (from v2 and v3)
# ==============================================================================
cat("\n== Generating all-scenarios panels ==\n")

# Load all GCAM scenarios
gcam_all <- gcam_raw %>%
  filter(Region == "Pakistan") %>%
  select(Scenario, Variable, Unit, all_of(YEAR_COLS))

ej_mask_all <- gcam_all$Unit == "EJ/yr"
gcam_all[ej_mask_all, YEAR_COLS] <- gcam_all[ej_mask_all, YEAR_COLS] * 1000
gcam_all$Unit[ej_mask_all] <- "PJ/yr"

get_scenario_ts <- function(var, scenarios) {
  gcam_all %>%
    filter(Variable == var, Scenario %in% scenarios) %>%
    select(Scenario, all_of(YEAR_COLS)) %>%
    pivot_longer(all_of(YEAR_COLS), names_to = "Year", values_to = "Value") %>%
    mutate(Year = as.integer(Year))
}


label_scen <- function(x) scenario_labels[x]

# -- S1: CO2 E&IP
co2_all <- get_scenario_ts("Emissions|CO2|Energy and Industrial Processes", scens_to_plot)
co2_msg_scen <- tibble(Scenario = "MESSAGEix_CM", Year = YEARS,
                       Value = get_ts(msg, "Emissions|CO2|Energy and Industrial Processes"))
co2_combined <- bind_rows(co2_all, co2_msg_scen)

# v2 version (simpler)
s1_v2 <- ggplot(co2_combined, aes(x = Year, y = Value, color = Scenario,
                                   shape = Scenario, linetype = Scenario)) +
  geom_line(linewidth = 1.1) + geom_point(size = 2.5) +
  scale_color_manual(values = scenario_colors) +
  scale_shape_manual(values = scenario_shapes) +
  scale_linetype_manual(values = scenario_linetypes) +
  labs(title = "CO2 Emissions — Energy & Industry",
       subtitle = "All scenarios vs MSG CM (Mt CO2/yr)", y = "Mt CO2/yr", x = NULL) +
  theme_gcam()

# v3 version (end labels)
co2_combined_v3 <- co2_combined %>% mutate(Label = scenario_labels[Scenario])
co2_end <- co2_combined_v3 %>% filter(Year == max(YEARS))

s1_v3 <- ggplot(co2_combined_v3, aes(x = Year, y = Value, color = Scenario,
                                     shape = Scenario, linetype = Scenario)) +
  geom_line(linewidth = 0.9) + geom_point(size = 2) +
  geom_text(data = co2_end, aes(label = Label),
            hjust = -0.05, size = 2.8, show.legend = FALSE, fontface = "bold") +
  scale_color_manual(values = scenario_colors, labels = label_scen, guide = "none") +
  scale_shape_manual(values = scenario_shapes, guide = "none") +
  scale_linetype_manual(values = scenario_linetypes, guide = "none") +
  scale_x_continuous(breaks = YEARS, expand = expansion(mult = c(0.02, 0.28))) +
  labs(title = expression(CO[2]~"Emissions — Energy & Industrial Processes"),
       subtitle = "Mt CO\u2082/yr  |  All GCAM scenarios + MESSAGEix CM baseline",
       y = expression(Mt~CO[2]/yr)) +
  theme_gcam()

# -- S2: Total electricity
elec_total_all <- get_scenario_ts("Secondary Energy|Electricity", scens_to_plot)
elec_total_msg <- tibble(Scenario = "MESSAGEix_CM", Year = YEARS,
                         Value = get_ts(msg, "Secondary Energy|Electricity"))
elec_combined <- bind_rows(elec_total_all, elec_total_msg)

s2_v2 <- ggplot(elec_combined, aes(x = Year, y = Value, color = Scenario,
                                   shape = Scenario, linetype = Scenario)) +
  geom_line(linewidth = 1.1) + geom_point(size = 2.5) +
  scale_color_manual(values = scenario_colors) +
  scale_shape_manual(values = scenario_shapes) +
  scale_linetype_manual(values = scenario_linetypes) +
  labs(title = "Total Electricity Generation", subtitle = "PJ/yr", y = "PJ/yr", x = NULL) +
  theme_gcam()

s2_v3 <- ggplot(elec_combined, aes(x = Year, y = Value, color = Scenario,
                                   shape = Scenario, linetype = Scenario)) +
  geom_line(linewidth = 0.9) + geom_point(size = 2) +
  scale_color_manual(values = scenario_colors, labels = label_scen) +
  scale_shape_manual(values = scenario_shapes, labels = label_scen) +
  scale_linetype_manual(values = scenario_linetypes, labels = label_scen) +
  scale_x_continuous(breaks = YEARS) + scale_y_continuous(labels = comma) +
  labs(title = "Total Electricity Generation", subtitle = "PJ/yr", y = "PJ/yr") +
  theme_gcam() + theme(legend.position = "top", legend.justification = "left")

# -- S3: Final energy total
fe_total_all <- get_scenario_ts("Final Energy", scens_to_plot)
fe_total_msg <- tibble(Scenario = "MESSAGEix_CM", Year = YEARS,
                       Value = get_ts(msg, "Final Energy"))
fe_combined <- bind_rows(fe_total_all, fe_total_msg)

s3_v2 <- ggplot(fe_combined, aes(x = Year, y = Value, color = Scenario,
                                 shape = Scenario, linetype = Scenario)) +
  geom_line(linewidth = 1.1) + geom_point(size = 2.5) +
  scale_color_manual(values = scenario_colors) +
  scale_shape_manual(values = scenario_shapes) +
  scale_linetype_manual(values = scenario_linetypes) +
  labs(title = "Total Final Energy", subtitle = "PJ/yr", y = "PJ/yr", x = NULL) +
  theme_gcam()

s3_v3 <- ggplot(fe_combined, aes(x = Year, y = Value, color = Scenario,
                                 shape = Scenario, linetype = Scenario)) +
  geom_line(linewidth = 0.9) + geom_point(size = 2) +
  scale_color_manual(values = scenario_colors, labels = label_scen) +
  scale_shape_manual(values = scenario_shapes, labels = label_scen) +
  scale_linetype_manual(values = scenario_linetypes, labels = label_scen) +
  scale_x_continuous(breaks = YEARS) + scale_y_continuous(labels = comma) +
  labs(title = "Total Final Energy", subtitle = "PJ/yr", y = "PJ/yr") +
  theme_gcam() + theme(legend.position = "none")

# -- S4: Transport electrification across scenarios
trn_all <- get_scenario_ts("Final Energy|Transportation|Electricity", scens_to_plot)
trn_msg_scen <- tibble(Scenario = "MESSAGEix_CM", Year = YEARS,
                       Value = get_ts(msg, "Final Energy|Transportation|Electricity"))
trn_combined <- bind_rows(trn_all, trn_msg_scen)

s4_v2 <- ggplot(trn_combined, aes(x = Year, y = Value, color = Scenario,
                                   shape = Scenario, linetype = Scenario)) +
  geom_line(linewidth = 1.1) + geom_point(size = 2.5) +
  scale_color_manual(values = scenario_colors) +
  scale_shape_manual(values = scenario_shapes) +
  scale_linetype_manual(values = scenario_linetypes) +
  labs(title = "Transport Electrification",
       subtitle = "PJ/yr", y = "PJ/yr", x = NULL) +
  theme_gcam()

s4_v3 <- ggplot(trn_combined, aes(x = Year, y = Value, color = Scenario,
                                   shape = Scenario, linetype = Scenario)) +
  geom_line(linewidth = 0.9) + geom_point(size = 2) +
  scale_color_manual(values = scenario_colors, labels = label_scen) +
  scale_shape_manual(values = scenario_shapes, labels = label_scen) +
  scale_linetype_manual(values = scenario_linetypes, labels = label_scen) +
  scale_x_continuous(breaks = YEARS) +
  labs(title = "Transport Electrification",
       subtitle = "Final Energy|Transportation|Electricity (PJ/yr)", y = "PJ/yr") +
  theme_gcam() + theme(legend.position = "none")

# -- S5: Stacked gen at 2050 by scenario
elec_2050_scens <- gcam_all %>%
  filter(Scenario %in% scens_to_plot, Variable %in% elec_vars) %>%
  select(Scenario, Variable, `2050`) %>%
  mutate(Technology = names(elec_vars)[match(Variable, elec_vars)],
         Value = as.numeric(`2050`)) %>%
  mutate(Technology = factor(Technology, levels = rev(names(tech_colors))),
         Scenario = factor(Scenario, levels = scens_to_plot))

s5_v2 <- ggplot(elec_2050_scens, aes(x = Scenario, y = Value, fill = Technology)) +
  geom_bar(stat = "identity", position = "stack", width = 0.6) +
  scale_fill_manual(values = tech_colors) +
  scale_x_discrete(labels = function(x) gsub("_EnergyAg", "", x)) +
  labs(title = "GCAM Generation Mix at 2050", subtitle = "PJ/yr by scenario",
       y = "PJ/yr", x = NULL) +
  theme_gcam() + theme(axis.text.x = element_text(angle = 20, hjust = 1))

s5_v3 <- ggplot(elec_2050_scens, aes(x = Scenario, y = Value, fill = Technology)) +
  geom_col(width = 0.65, color = "white", linewidth = 0.2) +
  scale_fill_manual(values = tech_colors) +
  scale_x_discrete(labels = function(x) sapply(x, function(s) scenario_labels[s])) +
  scale_y_continuous(labels = comma) +
  labs(title = "GCAM Generation Mix at 2050", subtitle = "PJ/yr  |  Stacked by technology",
       y = "PJ/yr") +
  theme_gcam() + theme(axis.title.x = element_blank(),
                        axis.text.x = element_text(angle = 25, hjust = 1))

# -- S6: Kyoto Gases
kyoto_all <- get_scenario_ts("Emissions|Kyoto Gases", scens_to_plot)
kyoto_msg <- tibble(Scenario = "MESSAGEix_CM", Year = YEARS,
                    Value = get_ts(msg, "Emissions|Kyoto Gases"))
kyoto_combined <- bind_rows(kyoto_all, kyoto_msg) %>% filter(!is.na(Value))

if (nrow(kyoto_combined) > 0) {
  s6_v2 <- ggplot(kyoto_combined, aes(x = Year, y = Value, color = Scenario,
                                      shape = Scenario, linetype = Scenario)) +
    geom_line(linewidth = 1.1) + geom_point(size = 2.5) +
    scale_color_manual(values = scenario_colors) +
    scale_shape_manual(values = scenario_shapes) +
    scale_linetype_manual(values = scenario_linetypes) +
    labs(title = "Kyoto Gases",
         subtitle = "Mt CO2e/yr (scope differs between models)", y = "Mt CO2e/yr", x = NULL) +
    theme_gcam()

  s6_v3 <- ggplot(kyoto_combined, aes(x = Year, y = Value, color = Scenario,
                                      shape = Scenario, linetype = Scenario)) +
    geom_line(linewidth = 0.9) + geom_point(size = 2) +
    scale_color_manual(values = scenario_colors, labels = label_scen) +
    scale_shape_manual(values = scenario_shapes, labels = label_scen) +
    scale_linetype_manual(values = scenario_linetypes, labels = label_scen) +
    scale_x_continuous(breaks = YEARS) +
    labs(title = "Kyoto Gases",
         subtitle = "Mt CO\u2082e/yr  |  Scope differs between models", y = "Mt CO\u2082e/yr") +
    theme_gcam() + theme(legend.position = "none")
} else {
  s6_v2 <- ggplot() + theme_void() + labs(title = "Kyoto Gases: no data")
  s6_v3 <- s6_v2
}

# All-scenarios panel v2
p_all_v2 <- s1_v2 / (s2_v2 | s3_v2) / (s4_v2 | s5_v2) / s6_v2 +
  plot_annotation(
    title = "GCAM Pakistan: All Scenarios vs MESSAGEix Current Measures",
    subtitle = paste0("Scenarios: CM, NDCUncond, NDCCond, NetZero (UCT)  |  Generated: ", Sys.Date()),
    theme = theme(
      plot.title = element_text(size = 16, face = "bold"),
      plot.subtitle = element_text(size = 12, color = "gray30")
    )
  )

ggsave(file.path(FIG_DIR, sprintf("%s_all_scenarios_panel_v2.png", FIG_PREFIX)), p_all_v2,
       width = 16, height = 24, dpi = 300, bg = "white")
cat("  v2 all-scenarios panel saved\n")

# All-scenarios panel v3
p_all_v3 <- s1_v3 / (s2_v3 | s3_v3) / (s4_v3 | s5_v3) / s6_v3 +
  plot_annotation(
    title = "GCAM Pakistan — Scenario Comparison",
    subtitle = paste0("CM, NDC Uncond/Cond, Net Zero (UCT) + MESSAGEix CM  |  ", Sys.Date()),
    caption = paste0("Source: GCAM v8.6 (PNNL) and MESSAGEix-Pakistan (IIASA)  |  ",
                     "NDC & Net Zero scenarios use CO\u2082 emission constraints on E&IP sector"),
    theme = theme(
      plot.title    = element_text(size = 16, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 11, color = "grey40", hjust = 0),
      plot.caption  = element_text(size = 8, color = "grey50", hjust = 1)
    )
  )

ggsave(file.path(FIG_DIR, sprintf("%s_all_scenarios_panel_v3.png", FIG_PREFIX)), p_all_v3,
       width = 16, height = 24, dpi = 300, bg = "white")
cat("  v3 all-scenarios panel saved\n")

cat("\nDone. Outputs:\n")
cat("  xlsx:   ", out_file, "\n")
cat("  figures: ", FIG_DIR, "\n")
cat("    - msg_gcam_comparison_panel_v0.png  (v1: simple combined)\n")
cat("    - msg_gcam_cm_panel_v2.png          (v2: theme_gcam, 6-panel)\n")
cat("    - msg_gcam_cm_panel_v3.png          (v3: advanced viz, 6-panel)\n")
cat("    - msg_gcam_all_scenarios_panel_v2.png (v2: scenarios overview)\n")
cat("    - msg_gcam_all_scenarios_panel_v3.png (v3: scenarios with end-labels)\n")
