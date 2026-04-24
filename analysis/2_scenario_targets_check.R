# scenario_targets_check.R
# Compare GCAM IAMC output against scenarios_lums.csv targets.
# Works from RStudio (interactive defaults) or CLI:
#   Rscript analysis/scenario_targets_check.R [iamc_xlsx] [scenario1,scenario2,...]
# Output: scenario_targets_comparison.csv with full traceability columns.

# ---- Bootstrap ---------------------------------------------------------------
find_root <- function() {
  for (d in c(getwd(), file.path(getwd(), ".."), file.path(getwd(), "../..")))
    if (dir.exists(file.path(d, "input")) && dir.exists(file.path(d, "exe")))
      return(normalizePath(d))
  stop("Cannot detect project root")
}
ROOT <- find_root()
source(file.path(ROOT, "analysis", "1_config.R"))

# ---- Config -----------------------------------------------------------------
GCAM_IAMC_FILE <- "gcam_output_iamc_ref_cm_rev_standardized.xlsx"
OUTPUT_VERSION <- "v4"   # bump this when output format changes

rp <- function(...) file.path(ROOT, ...)

# ---- GCAM capacity factors (source-traced) -----------------------------------
a23_path <- rp("input/gcamdata/inst/extdata/energy/A23.globaltech_capacity_factor.csv")
if (file.exists(a23_path)) {
  a23 <- read.csv(a23_path, comment.char = "#", stringsAsFactors = FALSE) %>%
    filter(supplysector == "electricity")
  gcf <- function(t) { v <- a23$X1971[a23$technology == t]; if (length(v)) v[1] else NA_real_ }
  GCAM_CF <- tibble(
    iamc_tech = c("Coal", "Gas", "Oil", "Nuclear", "Biomass", "Wind", "Solar", "Hydro"),
    cf        = c(gcf("coal (conv pul)"), gcf("gas (CC)"), gcf("refined liquids (steam/CT)"),
                  gcf("Gen_III"), gcf("biomass (conv)"), 0.35, 0.2596, NA_real_),
    cf_source = c(rep("A23.globaltech_capacity_factor.csv", 5),
                  "electricity_water.xml (Pak)", "electricity_water.xml (Pak)", "fixedOutput (no CF)")
  )
} else {
  GCAM_CF <- tibble(
    iamc_tech = c("Coal", "Gas", "Oil", "Nuclear", "Biomass", "Wind", "Solar", "Hydro"),
    cf        = c(0.85, 0.85, 0.80, 0.90, 0.85, 0.35, 0.2596, NA_real_),
    cf_source = "fallback (A23 not found)"
  )
}
cat("  CFs:", paste0(GCAM_CF$iamc_tech, "=", GCAM_CF$cf, collapse = ", "), "\n")

# EJ_TO_GWA already defined in config.R

# ---- Inputs ------------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 1 && nchar(args[1]) > 0) {
  iamc_path  <- args[1]
  scen_filter <- if (length(args) >= 2) str_split_1(args[2], ",") else NULL
} else {
  iamc_path  <- rp("analysis/query/iamc_format", GCAM_IAMC_FILE)
  scen_filter <- NULL
  cat("  Interactive mode: using default IAMC file\n")
}
stopifnot("IAMC file not found" = file.exists(iamc_path))

lums_path <- c(rp("analysis/scenarios_lums.csv"), "scenarios_lums.csv") %>%
  .[file.exists(.)] %>% .[1]
stopifnot("scenarios_lums.csv not found" = !is.na(lums_path))
cat("  IAMC:", iamc_path, "\n")
cat("  Targets:", lums_path, "\n")

# ---- Technology → IAMC mapping -----------------------------------------------
tech_map <- c(Hydropower = "Hydro", Wind = "Wind", Solar = "Solar",
              Nuclear = "Nuclear", `Nuclear Power` = "Nuclear",
              Bio = "Biomass", RFO = "Oil", Gas = "Gas", Coal = "Coal")

# ---- Load & map scenario targets to IAMC variables --------------------------
targets <- read_csv(lums_path, show_col_types = FALSE,
                    col_names = c("Scenario", "Sector", "Technology", "Policy_Type",
                                  "Year", "MSG_Impl", "Value", "GCAM_Share"),
                    skip = 1) %>%
  filter(!is.na(Scenario), Scenario != "", !grepl("^Note", Scenario)) %>%
  mutate(across(c(Technology, Policy_Type), str_trim), Year = as.integer(Year),
         GCAM_Share = as.numeric(GCAM_Share)) %>%
  mutate(
    iamc_tech = tech_map[Technology],
    is_ndc    = grepl("times Current Measures", Value, fixed = TRUE),
    ndc_mult  = ifelse(is_ndc, as.numeric(str_extract(Value, "[0-9.]+")), NA_real_),
    target_num = ifelse(is_ndc, NA_real_, suppressWarnings(as.numeric(Value))),
    # Map to primary IAMC variable
    iamc_var = case_when(
      Technology == "Electric Vehicles" ~
        "Final Energy|Transportation|Light-Duty Vehicle|Electricity",
      Technology == "Emissions" ~
        "Emissions|CO2|Energy and Industrial Processes",
      grepl("Annual.*tivit", Policy_Type, ignore.case = TRUE) & Sector == "Power" ~
        paste0("Secondary Energy|Electricity|", iamc_tech),
      grepl("^Total Capacity", Policy_Type) ~
        paste0("Capacity|Electricity|", iamc_tech),
      grepl("Additional Capacity", Policy_Type) ~
        paste0("Capacity Additions|Electricity|", iamc_tech)
    ),
    # Generation variable (for implied-GW on capacity rows)
    gen_var = if_else(grepl("Capacity", Policy_Type) & Sector == "Power" & !is.na(iamc_tech),
                      paste0("Secondary Energy|Electricity|", iamc_tech), NA_character_),
    # Unit conversion: EJ → GWa for generation/EV rows, else 1
    conversion = if_else(
      grepl("Annual.*tivit", Policy_Type, ignore.case = TRUE) |
        Technology == "Electric Vehicles", EJ_TO_GWA, 1.0),
    iamc_raw_unit = if_else(conversion > 1, "EJ",
                     if_else(grepl("Capacity", Policy_Type), "GW", "Mt CO2/yr")),
    target_unit   = if_else(conversion > 1, "GWa",
                     if_else(grepl("Capacity", Policy_Type), "GW", "Mt CO2/yr"))
  ) %>%
  left_join(GCAM_CF, by = "iamc_tech")

# ---- Load IAMC → long format ------------------------------------------------
iamc_wide <- read_excel(iamc_path)
if (!is.null(scen_filter)) iamc_wide <- iamc_wide %>% filter(Scenario %in% scen_filter)
scenarios <- unique(iamc_wide$Scenario)
cat("  Scenarios:", paste(scenarios, collapse = ", "), "\n")

year_cols <- names(iamc_wide)[grepl("^[0-9]{4}$", names(iamc_wide))]
iamc_long <- iamc_wide %>%
  select(Scenario, Variable, all_of(year_cols)) %>%
  pivot_longer(all_of(year_cols), names_to = "year", values_to = "value") %>%
  mutate(year = as.integer(year))

# ---- Resolve NDC target_num from CM baseline --------------------------------
# NDC targets are defined as fractions of CurrentMeasures E&IP emissions.
# If CM scenario is present, compute the absolute target values.
if ("CurrentMeasures" %in% scenarios) {
  cm_eip <- iamc_long %>%
    filter(Scenario == "CurrentMeasures",
           Variable == "Emissions|CO2|Energy and Industrial Processes") %>%
    select(year, cm_eip_mt = value)

  if (nrow(cm_eip) > 0) {
    targets <- targets %>%
      left_join(cm_eip, by = c("Year" = "year")) %>%
      mutate(
        target_num = if_else(is_ndc & !is.na(ndc_mult) & !is.na(cm_eip_mt),
                             ndc_mult * cm_eip_mt,
                             target_num),
        target_unit = if_else(is_ndc & !is.na(ndc_mult) & !is.na(cm_eip_mt),
                              "Mt CO2/yr", target_unit)
      ) %>%
      select(-cm_eip_mt)
    cat("  NDC targets resolved from CM baseline E&IP emissions.\n")
  }
} else {
  cat("  NOTE: CM scenario not present -- NDC targets remain unresolved.\n")
}

# ---- Join: targets × scenarios × IAMC values --------------------------------
result <- targets %>%
  filter(!is.na(iamc_var)) %>%
  crossing(gcam_scenario = scenarios) %>%
  # Join primary variable
  left_join(iamc_long %>% rename(iamc_raw = value),
            by = c("iamc_var" = "Variable", "Year" = "year", "gcam_scenario" = "Scenario")) %>%
  # Join generation variable (for capacity rows)
  left_join(iamc_long %>% select(Scenario, Variable, year, gen_raw = value),
            by = c("gen_var" = "Variable", "Year" = "year", "gcam_scenario" = "Scenario")) %>%
  # Compute everything
  mutate(
    gcam_value     = iamc_raw * conversion,
    gen_GWa        = gen_raw * EJ_TO_GWA,
    gen_implied_GW = if_else(!is.na(gen_GWa) & !is.na(cf), gen_GWa / cf, NA_real_),
    gap_abs   = gcam_value - target_num,
    gap_pct   = if_else(!is.na(target_num) & target_num != 0,
                        gap_abs / target_num * 100, NA_real_),
    direction = case_when(
      is.na(gap_pct) ~ "", gap_pct > 10 ~ "OVER",
      gap_pct < -10 ~ "UNDER", TRUE ~ "~OK"),
    # Traceability: how was gcam_value calculated?
    calc_note = case_when(
      conversion > 1 ~
        sprintf("IAMC '%s' = %.6f EJ * %.5f = %.3f GWa",
                iamc_var, iamc_raw, conversion, gcam_value),
      grepl("^Total Capacity", Policy_Type) & !is.na(cf) ~
        sprintf("IAMC direct = %.2f GW (gcamreport blended CF). Gen = %.6f EJ = %.3f GWa / CF %.4f = %.1f GW implied (%s)",
                iamc_raw, gen_raw, gen_GWa, cf, gen_implied_GW, cf_source),
      grepl("^Total Capacity", Policy_Type) & is.na(cf) ~
        sprintf("IAMC direct = %.2f GW. %s — no implied GW. Gen = %.6f EJ = %.3f GWa",
                iamc_raw, cf_source, gen_raw, gen_GWa),
      grepl("Additional Capacity", Policy_Type) & !is.na(cf) ~
        sprintf("IAMC 'Capacity Additions' = %.4f GW/yr (gcamreport annualizes: total_new_vintage / 5). Gen = %.6f EJ = %.3f GWa. CF = %.4f (%s)",
                iamc_raw, gen_raw, gen_GWa, cf, cf_source),
      grepl("Additional Capacity", Policy_Type) & is.na(cf) ~
        sprintf("IAMC 'Capacity Additions' = %.4f GW/yr. %s. Gen = %.6f EJ = %.3f GWa",
                iamc_raw, cf_source, gen_raw, gen_GWa),
      is_ndc ~
        sprintf("IAMC '%s' = %.1f Mt. Target = x%.2f of CM scenario (need CM run). If CM ≈ this: %.1f Mt",
                iamc_var, gcam_value, ndc_mult, gcam_value * ndc_mult),
      Technology == "Electric Vehicles" ~
        sprintf("IAMC '%s' = %.6f EJ = %.4f GWa. SCOPE MISMATCH: GCAM LDV|Elec includes 2W/3W (e-rickshaws).",
                iamc_var, iamc_raw, gcam_value),
      TRUE ~ sprintf("IAMC '%s' = %.6f → %.4f %s", iamc_var, iamc_raw, gcam_value, target_unit)
    )
  )

# ---- Ref → CM gap-change analysis -------------------------------------------
# For each target row, compare Reference gap to CurrentMeasures gap.
# Shows whether CM moved the needle in the right direction.
if (all(c("Reference", "CurrentMeasures") %in% scenarios)) {
  # Build a join key that uniquely identifies each target row
  result <- result %>%
    mutate(.target_key = paste(Scenario, Sector, Technology, Policy_Type, Year, iamc_var, sep = "||"))

  ref_gaps <- result %>%
    filter(gcam_scenario == "Reference") %>%
    select(.target_key, ref_gcam_value = gcam_value, ref_gap_abs = gap_abs, ref_gap_pct = gap_pct)

  cm_gaps <- result %>%
    filter(gcam_scenario == "CurrentMeasures") %>%
    select(.target_key, cm_gcam_value = gcam_value, cm_gap_abs = gap_abs, cm_gap_pct = gap_pct)

  gap_compare <- inner_join(ref_gaps, cm_gaps, by = ".target_key") %>%
    mutate(
      # Did the absolute gap shrink?
      gap_change_pct = cm_gap_pct - ref_gap_pct,
      gap_closed     = abs(cm_gap_pct) < abs(ref_gap_pct),
      cm_vs_ref = case_when(
        is.na(ref_gap_pct) | is.na(cm_gap_pct) ~ "N/A",
        abs(cm_gap_pct) < abs(ref_gap_pct) & abs(cm_gap_pct) <= 10 ~ "CLOSED (on target)",
        abs(cm_gap_pct) < abs(ref_gap_pct) ~ "CLOSING",
        abs(cm_gap_pct) == abs(ref_gap_pct) ~ "UNCHANGED",
        TRUE ~ "WIDENING"
      )
    )

  result <- result %>%
    left_join(gap_compare, by = ".target_key") %>%
    select(-.target_key)

  cat("\n  Ref → CM gap summary:\n")
  gap_summary <- gap_compare %>%
    filter(!is.na(cm_vs_ref), cm_vs_ref != "N/A") %>%
    count(cm_vs_ref) %>%
    arrange(desc(n))
  for (i in seq_len(nrow(gap_summary))) {
    cat(sprintf("    %s: %d targets\n", gap_summary$cm_vs_ref[i], gap_summary$n[i]))
  }
  cat("\n")
} else {
  result <- result %>%
    mutate(ref_gcam_value = NA_real_, ref_gap_abs = NA_real_, ref_gap_pct = NA_real_,
           cm_gcam_value = NA_real_, cm_gap_abs = NA_real_, cm_gap_pct = NA_real_,
           gap_change_pct = NA_real_, gap_closed = NA, cm_vs_ref = NA_character_)
  cat("NOTE: Need both Reference and CurrentMeasures scenarios for gap-change analysis.\n")
}

# ---- Write CSV ---------------------------------------------------------------
out <- result %>%
  select(
    gcam_scenario, target_scenario = Scenario, Sector, Technology, Policy_Type, Year,
    MSG_Impl, Value, target_num, target_unit, GCAM_Share,
    iamc_var, iamc_raw, iamc_raw_unit, conversion, gcam_value,
    gen_var, gen_raw_EJ = gen_raw, gen_GWa, cf, cf_source, gen_implied_GW,
    is_ndc, ndc_mult, gap_abs, gap_pct, direction,
    ref_gcam_value, ref_gap_pct, cm_gcam_value, cm_gap_pct,
    gap_change_pct, cm_vs_ref, calc_note
  )

out_path <- file.path(dirname(iamc_path),
                      paste0("scenario_targets_comparison_", OUTPUT_VERSION, ".csv"))
write_csv(out, out_path)
cat("  CSV written:", out_path, "\n")

# ---- Console summary per scenario -------------------------------------------
for (scen in scenarios) {
  s <- result %>% filter(gcam_scenario == scen)
  cat(strrep("=", 80), "\n")
  cat("SCENARIO:", scen, "\n")
  cat(strrep("=", 80), "\n")

  # Generation (GWa)
  gen <- s %>% filter(grepl("Annual.*tivit", Policy_Type, ignore.case = TRUE),
                      Sector == "Power", Year == 2025) %>%
    arrange(desc(target_num))
  if (nrow(gen) > 0) {
    total_ej <- iamc_long %>%
      filter(Scenario == scen, Variable == "Secondary Energy|Electricity", year == 2025) %>%
      pull(value)
    cat(sprintf("\n  Generation 2025 (total: %.3f GWa = %.6f EJ):\n",
                total_ej * EJ_TO_GWA, total_ej))
    cat(sprintf("    %-12s %8s %8s %8s %8s   %s\n",
                "Tech", "Target", "GCAM", "Gap%", "Dir", "Raw EJ"))
    for (i in seq_len(nrow(gen))) {
      r <- gen[i, ]
      cat(sprintf("    %-12s %8.3f %8.3f %+7.0f%% %-5s  %.6f EJ\n",
                  r$Technology, r$target_num, r$gcam_value, r$gap_pct, r$direction, r$iamc_raw))
    }
  }

  # Total Capacity (GW)
  cap <- s %>% filter(grepl("^Total Capacity", Policy_Type), Year == 2025)
  if (nrow(cap) > 0) {
    cat("\n  Total Capacity 2025 (GW):\n")
    cat(sprintf("    %-12s %8s %8s %8s   %s\n",
                "Tech", "Target", "IAMC_GW", "Gap%", "Implied GW (gen/CF)"))
    for (i in seq_len(nrow(cap))) {
      r <- cap[i, ]
      impl <- if (!is.na(r$gen_implied_GW)) sprintf("%.1f GW (%.3f GWa / %.2f CF)", r$gen_implied_GW, r$gen_GWa, r$cf) else r$cf_source
      cat(sprintf("    %-12s %8.3f %8.2f %+7.0f%% %-5s  %s\n",
                  r$Technology, r$target_num, r$gcam_value, r$gap_pct, r$direction, impl))
    }
  }

  # Additional Capacity (GW)
  add <- s %>% filter(grepl("Additional Capacity", Policy_Type))
  if (nrow(add) > 0) {
    cat("\n  Additional Capacity (GW) — IAMC 'Capacity Additions' (annualized rate):\n")
    cat(sprintf("    %-12s %4s %8s %8s %8s %-5s  %s\n",
                "Tech", "Year", "Target", "IAMC", "Gap%", "Dir", "Note"))
    for (i in seq_len(nrow(add))) {
      r <- add[i, ]
      note <- sprintf("gcamreport = total_vintage / 5yr")
      cat(sprintf("    %-12s %4d %8.3f %8.4f %+7.0f%% %-5s  %s\n",
                  r$Technology, r$Year, r$target_num, r$gcam_value, r$gap_pct, r$direction, note))
    }
    cat("    NOTE: IAMC Capacity Additions is annualized (GW/yr). MESSAGE target may be total new GW.\n")
    cat("    If MESSAGE means total: multiply IAMC value by 5 for comparison.\n")
  }

  # EV
  ev <- s %>% filter(Technology == "Electric Vehicles")
  if (nrow(ev) > 0) {
    cat("\n  EV Activity (GWa):\n")
    for (i in seq_len(nrow(ev))) {
      r <- ev[i, ]
      cat(sprintf("    %d  Target: %.4f  GCAM: %.4f GWa  (%.6f EJ)  SCOPE MISMATCH\n",
                  r$Year, r$target_num, r$gcam_value, r$iamc_raw))
    }
  }

  # NDC Emissions
  em <- s %>% filter(is_ndc)
  if (nrow(em) > 0) {
    cat("\n  NDC Emissions (Mt CO2/yr E&IP):\n")
    for (i in seq_len(nrow(em))) {
      r <- em[i, ]
      if (!is.na(r$target_num)) {
        cat(sprintf("    %s %d: %.1f Mt  target=%.1f Mt (x%.2f CM)  gap=%+.1f%%  %s\n",
                    r$Scenario, r$Year, r$gcam_value, r$target_num, r$ndc_mult,
                    ifelse(is.na(r$gap_pct), 0, r$gap_pct),
                    ifelse(is.na(r$direction), "", r$direction)))
      } else {
        cat(sprintf("    %s %d: %.1f Mt (x%.2f = %.1f Mt target; CM not in this batch)\n",
                    r$Scenario, r$Year, r$gcam_value, r$ndc_mult, r$gcam_value * r$ndc_mult))
      }
    }
  }
  cat("\n")
}

# ---- Ref → CM cross-scenario comparison ------------------------------------
if (all(c("Reference", "CurrentMeasures") %in% scenarios)) {
  cat(strrep("=", 80), "\n")
  cat("REF -> CM GAP CHANGE (did Current Measures close or widen the gap?)\n")
  cat(strrep("=", 80), "\n")

  gen_cmp <- result %>%
    filter(gcam_scenario == "CurrentMeasures",
           grepl("Annual.*tivit", Policy_Type, ignore.case = TRUE),
           Sector == "Power", Year == 2025,
           !is.na(cm_vs_ref)) %>%
    arrange(desc(abs(gap_change_pct)))

  if (nrow(gen_cmp) > 0) {
    cat("\n  Generation 2025 (GWa):\n")
    cat(sprintf("    %-12s %8s %8s %8s %8s %8s  %s\n",
                "Tech", "Target", "Ref", "CM", "Ref_Gap%", "CM_Gap%", "Verdict"))
    for (i in seq_len(nrow(gen_cmp))) {
      r <- gen_cmp[i, ]
      cat(sprintf("    %-12s %8.3f %8.3f %8.3f %+7.0f%% %+7.0f%%  %s\n",
                  r$Technology, r$target_num, r$ref_gcam_value, r$cm_gcam_value,
                  r$ref_gap_pct, r$cm_gap_pct, r$cm_vs_ref))
    }
  }

  cap_cmp <- result %>%
    filter(gcam_scenario == "CurrentMeasures",
           grepl("^Total Capacity", Policy_Type), Year == 2025,
           !is.na(cm_vs_ref)) %>%
    arrange(desc(abs(gap_change_pct)))

  if (nrow(cap_cmp) > 0) {
    cat("\n  Total Capacity 2025 (GW):\n")
    cat(sprintf("    %-12s %8s %8s %8s %8s %8s  %s\n",
                "Tech", "Target", "Ref", "CM", "Ref_Gap%", "CM_Gap%", "Verdict"))
    for (i in seq_len(nrow(cap_cmp))) {
      r <- cap_cmp[i, ]
      cat(sprintf("    %-12s %8.3f %8.2f %8.2f %+7.0f%% %+7.0f%%  %s\n",
                  r$Technology, r$target_num, r$ref_gcam_value, r$cm_gcam_value,
                  r$ref_gap_pct, r$cm_gap_pct, r$cm_vs_ref))
    }
  }

  ev_cmp <- result %>%
    filter(gcam_scenario == "CurrentMeasures",
           Technology == "Electric Vehicles", !is.na(cm_vs_ref))
  if (nrow(ev_cmp) > 0) {
    cat("\n  EV Activity (GWa):\n")
    for (i in seq_len(nrow(ev_cmp))) {
      r <- ev_cmp[i, ]
      cat(sprintf("    %d  Target: %.4f  Ref: %.4f  CM: %.4f  %s\n",
                  r$Year, r$target_num, r$ref_gcam_value, r$cm_gcam_value, r$cm_vs_ref))
    }
  }
  cat("\n")
}

# ---- CM → NDC/NetZero emissions comparison ----------------------------------
# Compare E&IP CO2 and carbon prices across all scenarios present in the data.
# Shows how much each constrained scenario reduces emissions relative to CM.

ndc_scens <- intersect(scenarios, c("NDCUncond_EnergyOnly", "NDCUncond_EnergyAg",
                                    "NDCCond_EnergyOnly", "NDCCond_EnergyAg",
                                    "NetZero_EnergyOnly", "NetZero_EnergyAg"))

if (length(ndc_scens) > 0) {
  cat(strrep("=", 80), "\n")
  cat("EMISSIONS SCENARIO COMPARISON (E&IP CO2, Mt CO2/yr)\n")
  cat(strrep("=", 80), "\n")

  eip_var <- "Emissions|CO2|Energy and Industrial Processes"
  co2_price_var <- "Price|Carbon"

  # Gather baseline values (Ref and CM if present)
  baseline_scens <- intersect(scenarios, c("Reference", "CurrentMeasures"))
  all_scens <- c(baseline_scens, ndc_scens)

  # E&IP emissions by scenario and year
  eip_all <- iamc_long %>%
    filter(Variable == eip_var, Scenario %in% all_scens) %>%
    select(Scenario, year, eip_mt = value)

  # Carbon prices by scenario and year
  co2_price <- iamc_long %>%
    filter(Variable == co2_price_var, Scenario %in% all_scens) %>%
    select(Scenario, year, co2_price = value)

  # Get CM baseline for reduction % calculation
  cm_base <- eip_all %>%
    filter(Scenario == "CurrentMeasures") %>%
    select(year, cm_eip = eip_mt)

  report_years <- c(2025, 2030, 2035, 2040, 2045, 2050)

  # ---- E&IP Emissions table ----
  cat("\n  E&IP CO2 emissions (Mt CO2/yr):\n")
  hdr <- sprintf("    %-28s", "Scenario")
  for (yr in report_years) hdr <- paste0(hdr, sprintf(" %8d", yr))
  cat(hdr, "\n")
  cat("    ", strrep("-", 28 + 9 * length(report_years)), "\n")

  for (scen in all_scens) {
    row <- sprintf("    %-28s", scen)
    for (yr in report_years) {
      v <- eip_all %>% filter(Scenario == scen, year == yr) %>% pull(eip_mt)
      row <- paste0(row, if (length(v) && !is.na(v)) sprintf(" %8.1f", v) else sprintf(" %8s", "—"))
    }
    cat(row, "\n")
  }

  # ---- Reduction from CM ----
  if ("CurrentMeasures" %in% scenarios && nrow(cm_base) > 0) {
    cat("\n  Reduction from CurrentMeasures (%):\n")
    hdr <- sprintf("    %-28s", "Scenario")
    for (yr in report_years) hdr <- paste0(hdr, sprintf(" %8d", yr))
    cat(hdr, "\n")
    cat("    ", strrep("-", 28 + 9 * length(report_years)), "\n")

    for (scen in ndc_scens) {
      row <- sprintf("    %-28s", scen)
      for (yr in report_years) {
        v <- eip_all %>% filter(Scenario == scen, year == yr) %>% pull(eip_mt)
        cm_v <- cm_base %>% filter(year == yr) %>% pull(cm_eip)
        if (length(v) && length(cm_v) && !is.na(v) && !is.na(cm_v) && cm_v > 0) {
          pct <- (1 - v / cm_v) * 100
          row <- paste0(row, sprintf(" %+7.1f%%", pct))
        } else {
          row <- paste0(row, sprintf(" %8s", "—"))
        }
      }
      cat(row, "\n")
    }
  }

  # ---- Carbon prices ----
  if (nrow(co2_price) > 0) {
    cat("\n  Carbon price (1990$/tC):\n")
    hdr <- sprintf("    %-28s", "Scenario")
    for (yr in report_years) hdr <- paste0(hdr, sprintf(" %8d", yr))
    cat(hdr, "\n")
    cat("    ", strrep("-", 28 + 9 * length(report_years)), "\n")

    for (scen in all_scens) {
      row <- sprintf("    %-28s", scen)
      for (yr in report_years) {
        v <- co2_price %>% filter(Scenario == scen, year == yr) %>% pull(co2_price)
        row <- paste0(row, if (length(v) && !is.na(v) && v != 0) sprintf(" %8.1f", v) else sprintf(" %8s", "—"))
      }
      cat(row, "\n")
    }
  }

  # ---- FFICT vs UCT comparison ----
  ffict_uct_pairs <- list(
    c("NDCUncond_EnergyOnly", "NDCUncond_EnergyAg"),
    c("NDCCond_EnergyOnly", "NDCCond_EnergyAg"),
    c("NetZero_EnergyOnly", "NetZero_EnergyAg")
  )

  has_pair <- FALSE
  for (pair in ffict_uct_pairs) {
    if (all(pair %in% scenarios)) {
      if (!has_pair) {
        cat("\n  FFICT vs UCT (E&IP emissions difference, Mt CO2/yr):\n")
        cat("    (Positive = UCT has higher E&IP, offset by AFOLU sink)\n")
        hdr <- sprintf("    %-20s", "Pair")
        for (yr in report_years) hdr <- paste0(hdr, sprintf(" %8d", yr))
        cat(hdr, "\n")
        cat("    ", strrep("-", 20 + 9 * length(report_years)), "\n")
        has_pair <- TRUE
      }
      label <- sub("_EnergyOnly", "", pair[1])
      row <- sprintf("    %-20s", label)
      for (yr in report_years) {
        ffict_v <- eip_all %>% filter(Scenario == pair[1], year == yr) %>% pull(eip_mt)
        uct_v   <- eip_all %>% filter(Scenario == pair[2], year == yr) %>% pull(eip_mt)
        if (length(ffict_v) && length(uct_v) && !is.na(ffict_v) && !is.na(uct_v)) {
          row <- paste0(row, sprintf(" %+8.1f", uct_v - ffict_v))
        } else {
          row <- paste0(row, sprintf(" %8s", "—"))
        }
      }
      cat(row, "\n")
    }
  }
  cat("\n")
}
