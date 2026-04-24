# generate_emission_constraints_v1.R
# Reads CMRev (v1) output, extracts E&IP CO2 and Kyoto Gases, generates
# constraint XMLs for three coverage modes:
#   1. CO2-only (FFICT/UCT) — energy-only or economy-wide CO2
#   2. All-GHG — all Kyoto gases economy-wide (all gases priced)
#   3. GHG-Energy — all Kyoto gases constrained, but only energy gases priced
#      (agricultural CH4/N2O count in target but don't face carbon price)
#
# Usage: Rscript analysis/3_generate_emission_constraints_v1.R
# Output:
#   input/extra/policy/pak_co2_constraint_{ndc_uncond,ndc_cond,netzero}_v1[_ts_const|_ts_decl].xml
#   input/extra/policy/pak_ghg_constraint_{ndc_uncond,ndc_cond,netzero}_v1_ts_const.xml
#   input/extra/policy/pak_linked_ghg_policy.xml          (all gases priced)
#   input/extra/policy/pak_linked_ghg_policy_energy.xml   (energy gases priced only)
#   exe/configuration_*_{ffict,uct,ghg,ghg_energy}_v1_ts_{const,decl}.xml
#   exe/configuration_*_{ffict,uct,ghg,ghg_energy}_v2_ts_{const,decl}.xml  (v2 CM add-ons)
#   analysis/query/iamc_format/emission_constraints_v1_*_trace.csv

# ---- Bootstrap ---------------------------------------------------------------
find_root <- function() {
  for (d in c(getwd(), file.path(getwd(), ".."), file.path(getwd(), "../..")))
    if (dir.exists(file.path(d, "input")) && dir.exists(file.path(d, "exe")))
      return(normalizePath(d))
  stop("Cannot detect project root")
}
ROOT <- find_root()
source(file.path(ROOT, "analysis", "1_config.R"))

# ---- Config ------------------------------------------------------------------
GCAM_FILE <- file.path(ROOT, "output", "gcam_output_iamc_all_v2_standardized.xlsx")

# Which scenario is the CM baseline? CMRev = v1 run
CM_SCENARIO <- GCAM_CM_SCENARIO

# ---- Load CM baseline emissions -------------------------------------------
cat("\n== Loading CM baseline emissions ==\n")
cat("  Source: ", GCAM_FILE, "\n")
gcam <- read_excel(GCAM_FILE)
names(gcam) <- as.character(names(gcam))

eip_var <- "Emissions|CO2|Energy and Industrial Processes"

cm_eip <- gcam %>%
  filter(Region == "Pakistan",
         Scenario == CM_SCENARIO,
         Variable == eip_var)

if (nrow(cm_eip) == 0) stop("Could not find ", eip_var, " for scenario ", CM_SCENARIO)

# Extract values for key years (Mt CO2/yr)
get_yr <- function(yr) as.numeric(cm_eip[[as.character(yr)]][1])

cm_2025 <- get_yr(2025)
cm_2030 <- get_yr(2030)
cm_2035 <- get_yr(2035)
cm_2040 <- get_yr(2040)
cm_2045 <- get_yr(2045)
cm_2050 <- get_yr(2050)

cat("  CM v1 E&IP CO2 (Mt CO2/yr):\n")
for (yr in c(2025, 2030, 2035, 2040, 2045, 2050))
  cat(sprintf("    -> %d: %.2f\n", yr, get_yr(yr)))

# ---- Compute constraints ---------------------------------------------------

# NDC Unconditional: 85% of CM at 2030, 83% at 2035+
ndcu_2030_mtc <- NDCU_2030_MULT * cm_2030 * CO2_TO_MTC
ndcu_2035_mtc <- NDCU_2035_MULT * cm_2035 * CO2_TO_MTC

# NDC Conditional: 50% of CM at 2030, 50% at 2035+
ndcc_2030_mtc <- NDCC_2030_MULT * cm_2030 * CO2_TO_MTC
ndcc_2035_mtc <- NDCC_2035_MULT * cm_2035 * CO2_TO_MTC

# Net Zero: linear from CM 2025 to 0 at 2050
nz_2025_mtc <- cm_2025 * CO2_TO_MTC
nz_steps <- tibble(
  year = seq(2025, 2050, by = 5),
  frac = seq(1, 0, length.out = 6)
)
nz_steps$mtc <- nz_2025_mtc * nz_steps$frac

cat("\n== Computed constraints (MTC) ==\n")
cat(sprintf("  NDCU: 2030=%.3f, 2035+=%.3f\n", ndcu_2030_mtc, ndcu_2035_mtc))
cat(sprintf("  NDCC: 2030=%.3f, 2035+=%.3f\n", ndcc_2030_mtc, ndcc_2035_mtc))
cat(sprintf("  NZ:   2025=%.3f -> 2050=0\n", nz_2025_mtc))

# ---- Write XML helper ------------------------------------------------------
write_constraint_xml <- function(filepath, comment_block, constraints_df) {
  lines <- c(
    '<?xml version="1.0" encoding="UTF-8"?>',
    comment_block,
    '<scenario>',
    '    <world>',
    '        <region name="Pakistan">',
    '            <ghgpolicy name="CO2">',
    '                <market>Pakistan</market>'
  )

  for (i in seq_len(nrow(constraints_df))) {
    lines <- c(lines, sprintf('                <constraint year="%d">%.3f</constraint>',
                               constraints_df$year[i], constraints_df$mtc[i]))
  }

  lines <- c(lines,
    '            </ghgpolicy>',
    '        </region>',
    '    </world>',
    '</scenario>',
    ''
  )

  writeLines(lines, filepath)
  cat("    -> Wrote: ", basename(filepath), "\n")
}

# ---- Build constraint tables -----------------------------------------------
cat("\n== Writing flat-hold constraint XMLs ==\n")
policy_dir <- POLICY_DIR

# NDCU
ndcu_df <- tibble(year = YEARS_ALL) %>%
  mutate(mtc = case_when(
    year < 2030 ~ NA_real_,    # no constraint before 2030
    year == 2030 ~ ndcu_2030_mtc,
    TRUE ~ ndcu_2035_mtc        # 2035+ flat hold
  )) %>%
  filter(!is.na(mtc))

ndcu_comment <- c(
  sprintf('<!-- pak_co2_constraint_ndc_uncond_v1.xml'),
  sprintf('     NDC Unconditional emissions constraint for Pakistan.'),
  sprintf('     Generated from CM v1 (CurrentMeasuresRev) output on %s.', Sys.Date()),
  sprintf('     Units: MTC (million tonnes carbon). Conversion: Mt CO2 * 12/44 = MTC.'),
  sprintf(''),
  sprintf('     CM v1 E&IP (Mt CO2): 2025=%.2f, 2030=%.2f, 2035=%.2f', cm_2025, cm_2030, cm_2035),
  sprintf('     Formula:'),
  sprintf('       2030: %.2f x %.2f x 12/44 = %.3f MTC', NDCU_2030_MULT, cm_2030, ndcu_2030_mtc),
  sprintf('       2035+: %.2f x %.2f x 12/44 = %.3f MTC', NDCU_2035_MULT, cm_2035, ndcu_2035_mtc),
  sprintf('-->')
)

write_constraint_xml(
  file.path(policy_dir, "pak_co2_constraint_ndc_uncond_v1.xml"),
  ndcu_comment, ndcu_df
)

# NDCC
ndcc_df <- tibble(year = YEARS_ALL) %>%
  mutate(mtc = case_when(
    year < 2030 ~ NA_real_,
    year == 2030 ~ ndcc_2030_mtc,
    TRUE ~ ndcc_2035_mtc
  )) %>%
  filter(!is.na(mtc))

ndcc_comment <- c(
  sprintf('<!-- pak_co2_constraint_ndc_cond_v1.xml'),
  sprintf('     NDC Conditional emissions constraint for Pakistan.'),
  sprintf('     Generated from CM v1 (CurrentMeasuresRev) output on %s.', Sys.Date()),
  sprintf('     Units: MTC (million tonnes carbon). Conversion: Mt CO2 * 12/44 = MTC.'),
  sprintf(''),
  sprintf('     CM v1 E&IP (Mt CO2): 2025=%.2f, 2030=%.2f, 2035=%.2f', cm_2025, cm_2030, cm_2035),
  sprintf('     Formula:'),
  sprintf('       2030: %.2f x %.2f x 12/44 = %.3f MTC', NDCC_2030_MULT, cm_2030, ndcc_2030_mtc),
  sprintf('       2035+: %.2f x %.2f x 12/44 = %.3f MTC', NDCC_2035_MULT, cm_2035, ndcc_2035_mtc),
  sprintf('-->')
)

write_constraint_xml(
  file.path(policy_dir, "pak_co2_constraint_ndc_cond_v1.xml"),
  ndcc_comment, ndcc_df
)

# Net Zero
nz_df <- tibble(year = YEARS_ALL) %>%
  mutate(mtc = case_when(
    year < 2030 ~ NA_real_,  # no constraint before 2030
    year <= 2050 ~ approx(nz_steps$year, nz_steps$mtc, xout = year, rule = 2)$y,
    TRUE ~ 0
  )) %>%
  filter(!is.na(mtc))

nz_comment <- c(
  sprintf('<!-- pak_co2_constraint_netzero_v1.xml'),
  sprintf('     Net Zero emissions constraint for Pakistan.'),
  sprintf('     Generated from CM v1 (CurrentMeasuresRev) output on %s.', Sys.Date()),
  sprintf('     Linear decline from CM v1 2025 E&IP to 0 by 2050, hold at 0 through 2100.'),
  sprintf('     Units: MTC (million tonnes carbon). Conversion: Mt CO2 * 12/44 = MTC.'),
  sprintf(''),
  sprintf('     CM v1 E&IP 2025: %.2f Mt CO2 -> %.3f MTC', cm_2025, nz_2025_mtc),
  sprintf('     Linear 5-step decline:'),
  sprintf('       2030: %.3f x 0.80 = %.3f MTC', nz_2025_mtc, nz_steps$mtc[2]),
  sprintf('       2035: %.3f x 0.60 = %.3f MTC', nz_2025_mtc, nz_steps$mtc[3]),
  sprintf('       2040: %.3f x 0.40 = %.3f MTC', nz_2025_mtc, nz_steps$mtc[4]),
  sprintf('       2045: %.3f x 0.20 = %.3f MTC', nz_2025_mtc, nz_steps$mtc[5]),
  sprintf('       2050: 0'),
  sprintf(''),
  sprintf('     SOLVER NOTE: constraint=0 is very aggressive. If solver fails:'),
  sprintf('       1. Try 1.0 MTC at 2050 (= 3.67 Mt CO2, near-zero)'),
  sprintf('       2. Push zero to 2060, set 2050 = %.3f MTC', nz_2025_mtc * 0.1),
  sprintf('-->')
)

write_constraint_xml(
  file.path(policy_dir, "pak_co2_constraint_netzero_v1.xml"),
  nz_comment, nz_df
)

# ---- Traceability CSV ------------------------------------------------------
trace_dir <- IAMC_FORMAT_DIR
trace <- bind_rows(
  tibble(scenario = "CM_v1_baseline", year = YEARS_ALL[1:6],
         cm_eip_mtco2 = sapply(YEARS_ALL[1:6], get_yr),
         multiplier = NA, constraint_mtc = sapply(YEARS_ALL[1:6], get_yr) * CO2_TO_MTC),
  tibble(scenario = "NDC_Uncond_v1", year = ndcu_df$year,
         cm_eip_mtco2 = sapply(ndcu_df$year, function(y) if(y==2030) cm_2030 else cm_2035),
         multiplier = ifelse(ndcu_df$year == 2030, NDCU_2030_MULT, NDCU_2035_MULT),
         constraint_mtc = ndcu_df$mtc),
  tibble(scenario = "NDC_Cond_v1", year = ndcc_df$year,
         cm_eip_mtco2 = sapply(ndcc_df$year, function(y) if(y==2030) cm_2030 else cm_2035),
         multiplier = ifelse(ndcc_df$year == 2030, NDCC_2030_MULT, NDCC_2035_MULT),
         constraint_mtc = ndcc_df$mtc),
  tibble(scenario = "NetZero_v1", year = nz_df$year,
         cm_eip_mtco2 = cm_2025,
         multiplier = nz_df$mtc / (cm_2025 * CO2_TO_MTC),
         constraint_mtc = nz_df$mtc)
)
trace$constraint_mtco2 <- trace$constraint_mtc / CO2_TO_MTC

trace_file <- file.path(trace_dir, "emission_constraints_v1_trace.csv")
write_csv(trace, trace_file)
cat("  Traceability CSV: ", trace_file, "\n")

# ======================================================================
# TIME-SERIES CONSTRAINT VARIANTS
# ======================================================================
# Instead of flat-hold after 2035, apply multiplier to EACH period's CM value.
# Two variants:
#   ts_const: constant multiplier per period (same % cut, growing absolute cap)
#   ts_decl:  declining multiplier (tightening % cut over time)

cat("\n== Generating time-series constraint variants ==\n")

# Get CM values for all constraint years
cm_vals <- sapply(YEARS_ALL, get_yr)
names(cm_vals) <- as.character(YEARS_ALL)

# ---- ts_const: constant multiplier applied to each period's CM -----------
# NDCU: 0.85 at 2030, 0.83 for 2035+
# NDCC: 0.50 at 2030, 0.50 for 2035+

ndcu_ts_const_df <- tibble(year = YEARS_ALL) %>%
  mutate(
    mult = case_when(year < 2030 ~ NA_real_, year == 2030 ~ NDCU_2030_MULT, TRUE ~ NDCU_2035_MULT),
    mtc  = mult * cm_vals[as.character(year)] * CO2_TO_MTC
  ) %>%
  filter(!is.na(mtc))

ndcc_ts_const_df <- tibble(year = YEARS_ALL) %>%
  mutate(
    mult = case_when(year < 2030 ~ NA_real_, year == 2030 ~ NDCC_2030_MULT, TRUE ~ NDCC_2035_MULT),
    mtc  = mult * cm_vals[as.character(year)] * CO2_TO_MTC
  ) %>%
  filter(!is.na(mtc))

# Net Zero ts_const: linear from each period's CM to 0 at 2050
nz_ts_const_df <- tibble(year = YEARS_ALL) %>%
  mutate(mtc = case_when(
    year < 2030 ~ NA_real_,
    year <= 2050 ~ {
      frac <- (2050 - year) / (2050 - 2025)
      frac * cm_vals[as.character(year)] * CO2_TO_MTC
    },
    TRUE ~ 0
  )) %>%
  filter(!is.na(mtc))

write_constraint_xml(
  file.path(policy_dir, "pak_co2_constraint_ndc_uncond_v1_ts_const.xml"),
  c(sprintf('<!-- pak_co2_constraint_ndc_uncond_v1_ts_const.xml'),
    sprintf('     Time-series constant multiplier variant.'),
    sprintf('     Each period: mult x CM_period x 12/44. NDCU: 0.85 (2030), 0.83 (2035+).'),
    sprintf('     Generated %s. -->', Sys.Date())),
  ndcu_ts_const_df
)

write_constraint_xml(
  file.path(policy_dir, "pak_co2_constraint_ndc_cond_v1_ts_const.xml"),
  c(sprintf('<!-- pak_co2_constraint_ndc_cond_v1_ts_const.xml'),
    sprintf('     Time-series constant multiplier variant.'),
    sprintf('     Each period: mult x CM_period x 12/44. NDCC: 0.50 (2030+).'),
    sprintf('     Generated %s. -->', Sys.Date())),
  ndcc_ts_const_df
)

write_constraint_xml(
  file.path(policy_dir, "pak_co2_constraint_netzero_v1_ts_const.xml"),
  c(sprintf('<!-- pak_co2_constraint_netzero_v1_ts_const.xml'),
    sprintf('     Time-series Net Zero: linear fraction of each period CM to 0 at 2050.'),
    sprintf('     Generated %s. -->', Sys.Date())),
  nz_ts_const_df
)

# ---- ts_decl: declining multiplier applied to each period's CM -----------
# Multiplier tightens over time (more ambitious long-term)
NDCU_DECL <- c("2030"=0.85, "2035"=0.83, "2040"=0.80, "2045"=0.77,
               "2050"=0.75, "2055"=0.75, "2060"=0.75, "2065"=0.75,
               "2070"=0.75, "2075"=0.75, "2080"=0.75, "2085"=0.75,
               "2090"=0.75, "2095"=0.75, "2100"=0.75)

NDCC_DECL <- c("2030"=0.50, "2035"=0.50, "2040"=0.48, "2045"=0.45,
               "2050"=0.43, "2055"=0.43, "2060"=0.43, "2065"=0.43,
               "2070"=0.43, "2075"=0.43, "2080"=0.43, "2085"=0.43,
               "2090"=0.43, "2095"=0.43, "2100"=0.43)

ndcu_ts_decl_df <- tibble(year = YEARS_ALL) %>%
  filter(year >= 2030) %>%
  mutate(mtc = NDCU_DECL[as.character(year)] * cm_vals[as.character(year)] * CO2_TO_MTC)

ndcc_ts_decl_df <- tibble(year = YEARS_ALL) %>%
  filter(year >= 2030) %>%
  mutate(mtc = NDCC_DECL[as.character(year)] * cm_vals[as.character(year)] * CO2_TO_MTC)

# Net Zero ts_decl: same as ts_const for NZ (already declining to 0)
nz_ts_decl_df <- nz_ts_const_df

write_constraint_xml(
  file.path(policy_dir, "pak_co2_constraint_ndc_uncond_v1_ts_decl.xml"),
  c(sprintf('<!-- pak_co2_constraint_ndc_uncond_v1_ts_decl.xml'),
    sprintf('     Time-series declining multiplier variant.'),
    sprintf('     NDCU: 0.85(2030) -> 0.83(2035) -> 0.80(2040) -> 0.77(2045) -> 0.75(2050+).'),
    sprintf('     Each period: mult x CM_period x 12/44.'),
    sprintf('     Generated %s. -->', Sys.Date())),
  ndcu_ts_decl_df
)

write_constraint_xml(
  file.path(policy_dir, "pak_co2_constraint_ndc_cond_v1_ts_decl.xml"),
  c(sprintf('<!-- pak_co2_constraint_ndc_cond_v1_ts_decl.xml'),
    sprintf('     Time-series declining multiplier variant.'),
    sprintf('     NDCC: 0.50(2030) -> 0.50(2035) -> 0.48(2040) -> 0.45(2045) -> 0.43(2050+).'),
    sprintf('     Each period: mult x CM_period x 12/44.'),
    sprintf('     Generated %s. -->', Sys.Date())),
  ndcc_ts_decl_df
)

write_constraint_xml(
  file.path(policy_dir, "pak_co2_constraint_netzero_v1_ts_decl.xml"),
  c(sprintf('<!-- pak_co2_constraint_netzero_v1_ts_decl.xml'),
    sprintf('     Time-series Net Zero (same as ts_const for NZ).'),
    sprintf('     Generated %s. -->', Sys.Date())),
  nz_ts_decl_df
)

# ---- Generate config files for TS variants --------------------------------
cat("\n== Generating config files for TS variants ==\n")

config_dir <- file.path(ROOT, "exe")

# For each (scenario, carbon_mode, ts_variant), create a config by
# swapping the constraint XML in the base UCT/FFICT v1 config.
scenarios <- list(
  list(base = "ndc_uncond", label_uct = "NDCUncond_EnergyAg", label_ffict = "NDCUncond_EnergyOnly"),
  list(base = "ndc_cond",   label_uct = "NDCCond_EnergyAg",   label_ffict = "NDCCond_EnergyOnly"),
  list(base = "netzero",    label_uct = "NetZero_EnergyAg",    label_ffict = "NetZero_EnergyOnly")
)

for (scen in scenarios) {
  for (mode in c("uct", "ffict")) {
    src_file <- file.path(config_dir, sprintf("configuration_%s_%s_v1.xml", scen$base, mode))
    if (!file.exists(src_file)) { cat("[!] SKIP (missing): ", src_file, "\n"); next }
    src_lines <- readLines(src_file)

    label <- if (mode == "uct") scen$label_uct else scen$label_ffict

    for (ts_var in c("ts_const", "ts_decl")) {
      new_lines <- src_lines
      # Replace constraint XML path
      old_constraint <- sprintf("pak_co2_constraint_%s_v1.xml", scen$base)
      new_constraint <- sprintf("pak_co2_constraint_%s_v1_%s.xml", scen$base, ts_var)
      new_lines <- gsub(old_constraint, new_constraint, new_lines, fixed = TRUE)

      # Replace scenario name to include TS variant
      ts_suffix <- toupper(gsub("_", "", ts_var))  # TSCONST or TSDECL
      old_name <- sprintf('"scenarioName">%s<', label)
      new_name <- sprintf('"scenarioName">%s_%s<', label, ts_suffix)
      new_lines <- gsub(old_name, new_name, new_lines, fixed = TRUE)

      # Replace header comment
      old_header <- sprintf("configuration_%s_%s_v1.xml", scen$base, mode)
      new_header <- sprintf("configuration_%s_%s_v1_%s.xml", scen$base, mode, ts_var)
      new_lines <- gsub(old_header, new_header, new_lines, fixed = TRUE)

      dst_file <- file.path(config_dir, new_header)
      writeLines(new_lines, dst_file)
      cat("    -> Created: ", basename(dst_file), "\n")
    }
  }
}

# ---- Generate v2 config files for TS variants --------------------------------
# Same as above but templates from v2 base configs (which use v2 CM add-ons)
cat("\n== Generating v2 config files for TS variants ==\n")

for (scen in scenarios) {
  for (mode in c("uct", "ffict")) {
    src_file <- file.path(config_dir, sprintf("configuration_%s_%s_v2.xml", scen$base, mode))
    if (!file.exists(src_file)) { cat("[!] SKIP (missing): ", src_file, "\n"); next }
    src_lines <- readLines(src_file)

    label <- if (mode == "uct") scen$label_uct else scen$label_ffict

    for (ts_var in c("ts_const", "ts_decl")) {
      new_lines <- src_lines
      old_constraint <- sprintf("pak_co2_constraint_%s_v1.xml", scen$base)
      new_constraint <- sprintf("pak_co2_constraint_%s_v1_%s.xml", scen$base, ts_var)
      new_lines <- gsub(old_constraint, new_constraint, new_lines, fixed = TRUE)

      ts_suffix <- toupper(gsub("_", "", ts_var))
      old_name <- sprintf('"scenarioName">%s_V2<', label)
      new_name <- sprintf('"scenarioName">%s_V2_%s<', label, ts_suffix)
      new_lines <- gsub(old_name, new_name, new_lines, fixed = TRUE)

      old_header <- sprintf("configuration_%s_%s_v2.xml", scen$base, mode)
      new_header <- sprintf("configuration_%s_%s_v2_%s.xml", scen$base, mode, ts_var)
      new_lines <- gsub(old_header, new_header, new_lines, fixed = TRUE)

      dst_file <- file.path(config_dir, new_header)
      writeLines(new_lines, dst_file)
      cat("    -> Created: ", basename(dst_file), "\n")
    }
  }
}

# ---- Extended traceability CSV with TS variants ---------------------------
trace_ts <- bind_rows(
  trace,
  tibble(scenario = "NDC_Uncond_v1_ts_const", year = ndcu_ts_const_df$year,
         cm_eip_mtco2 = cm_vals[as.character(ndcu_ts_const_df$year)],
         multiplier = ndcu_ts_const_df$mult,
         constraint_mtc = ndcu_ts_const_df$mtc),
  tibble(scenario = "NDC_Cond_v1_ts_const", year = ndcc_ts_const_df$year,
         cm_eip_mtco2 = cm_vals[as.character(ndcc_ts_const_df$year)],
         multiplier = ndcc_ts_const_df$mult,
         constraint_mtc = ndcc_ts_const_df$mtc),
  tibble(scenario = "NDC_Uncond_v1_ts_decl", year = ndcu_ts_decl_df$year,
         cm_eip_mtco2 = cm_vals[as.character(ndcu_ts_decl_df$year)],
         multiplier = NDCU_DECL[as.character(ndcu_ts_decl_df$year)],
         constraint_mtc = ndcu_ts_decl_df$mtc),
  tibble(scenario = "NDC_Cond_v1_ts_decl", year = ndcc_ts_decl_df$year,
         cm_eip_mtco2 = cm_vals[as.character(ndcc_ts_decl_df$year)],
         multiplier = NDCC_DECL[as.character(ndcc_ts_decl_df$year)],
         constraint_mtc = ndcc_ts_decl_df$mtc)
)
trace_ts$constraint_mtco2 <- trace_ts$constraint_mtc / CO2_TO_MTC

trace_file_ts <- file.path(trace_dir, "emission_constraints_v1_all_trace.csv")
write_csv(trace_ts, trace_file_ts)
cat("  Extended traceability CSV: ", trace_file_ts, "\n")

cat("\n== Summary (CO2-only constraints) ==\n")
cat("  3 flat-hold constraint XMLs (original v1)\n")
cat("  6 time-series constraint XMLs (3 ts_const + 3 ts_decl)\n")
cat("  12 config files (3 scenarios x 2 modes x 2 TS variants)\n")
cat("  2 traceability CSVs\n")

# ======================================================================
# ALL-GHG CONSTRAINTS (Kyoto Gases)
# ======================================================================
# Pakistan's NDC applies to ALL GHGs, not just CO2.
# This section creates:
#   1. GHG constraint XMLs using <ghgpolicy name="GHG"> (units: Mt CO2e)
#   2. A Pakistan-only linked-GHG-policy XML linking individual gases
#      (CO2, CH4, N2O, F-gases) to the GHG market via GWP demand-adjust
#   3. Config files for each scenario under all-GHG coverage
#
# The GHG market works differently from the CO2-only approach:
#   - CO2-only: <ghgpolicy name="CO2"> constrains fossil+industrial CO2 (MTC units)
#   - All-GHG:  <ghgpolicy name="GHG"> creates an umbrella market; each gas is
#     linked via <linked-ghg-policy> with demand-adjust = GWP100 factor.
#     The constraint is in Mt CO2e. The solver finds one GHG price; each gas
#     sees an effective price = GHG_price × price-adjust.

cat("\n")
cat("======================================================================\n")
cat("  ALL-GHG CONSTRAINTS (Kyoto Gases)\n")
cat("======================================================================\n")

# ---- Load CM Kyoto Gases baseline -------------------------------------------
GCAM_ALL_FILE <- GCAM_IAMC_ALL
if (!file.exists(GCAM_ALL_FILE)) {
  # Try CSV fallback
  GCAM_ALL_FILE <- sub("\\.xlsx$", ".csv", GCAM_ALL_FILE)
}

cat("\n== Loading CM Kyoto Gases baseline ==\n")
cat("  Source: ", GCAM_ALL_FILE, "\n")

if (grepl("\\.xlsx$", GCAM_ALL_FILE)) {
  gcam_all <- read_excel(GCAM_ALL_FILE)
} else {
  gcam_all <- read_csv(GCAM_ALL_FILE, show_col_types = FALSE)
}
names(gcam_all) <- as.character(names(gcam_all))

kyoto_var <- "Emissions|Kyoto Gases"

cm_kyoto <- gcam_all %>%
  filter(Region == "Pakistan",
         Scenario == CM_SCENARIO,
         Variable == kyoto_var)

if (nrow(cm_kyoto) == 0) stop("Could not find ", kyoto_var, " for scenario ", CM_SCENARIO)

# Extract Kyoto Gases values (Mt CO2e/yr) for all model years
get_kyoto_yr <- function(yr) as.numeric(cm_kyoto[[as.character(yr)]][1])

cm_kyoto_vals <- sapply(YEARS_ALL, get_kyoto_yr)
names(cm_kyoto_vals) <- as.character(YEARS_ALL)

cat("  CM Kyoto Gases (Mt CO2e/yr):\n")
for (yr in c(2025, 2030, 2035, 2040, 2045, 2050))
  cat(sprintf("    -> %d: %.2f\n", yr, get_kyoto_yr(yr)))

# ---- Also extract CM E&IP CO2 for FFICT-only constraints --------------------
# (Already loaded above as cm_eip, reuse cm_vals for FFICT)

# ---- Compute GHG constraints ------------------------------------------------
# Units: Mt CO2e (the linked-ghg-policy demand-adjust factors handle per-gas conversion)
# NDC Unconditional: 0.85 of CM at 2030, 0.83 at 2035+
# NDC Conditional:   0.50 of CM at 2030, 0.50 at 2035+
# Net Zero:          linear from CM 2025 → 0 at 2050

cat("\n== Computing GHG constraints (Mt CO2e) ==\n")

# NDCU GHG: time-series constant multiplier
# NOTE: NDCU_2035_MULT * 0.8 because the scenario wasn't solving for more relaxed constraints post-2070 (counterintuitively because net zero solves) 
ghg_ndcu_ts_const_df <- tibble(year = YEARS_ALL) %>%
  mutate(
    mult = case_when(year < 2030 ~ NA_real_, year == 2030 ~ NDCU_2030_MULT, year > 2070 ~ NDCU_2035_MULT * 0.95, TRUE ~ NDCU_2035_MULT),
    mtco2e = mult * cm_kyoto_vals[as.character(year)]
  ) %>%
  filter(!is.na(mtco2e))

# NDCC GHG: time-series constant multiplier
ghg_ndcc_ts_const_df <- tibble(year = YEARS_ALL) %>%
  mutate(
    mult = case_when(year < 2030 ~ NA_real_, year == 2030 ~ NDCC_2030_MULT, TRUE ~ NDCC_2035_MULT),
    mtco2e = mult * cm_kyoto_vals[as.character(year)]
  ) %>%
  filter(!is.na(mtco2e))

# Net Zero GHG: linear from CM 2025 → 0 at 2050
ghg_nz_2025 <- get_kyoto_yr(2025)
ghg_nz_ts_const_df <- tibble(year = YEARS_ALL) %>%
  mutate(mtco2e = case_when(
    year < 2030 ~ NA_real_,
    year <= 2050 ~ {
      frac <- (2050 - year) / (2050 - 2025)
      frac * cm_kyoto_vals[as.character(year)]
    },
    TRUE ~ 0
  )) %>%
  filter(!is.na(mtco2e))

cat(sprintf("  NDCU GHG: 2030=%.1f, 2035=%.1f, 2050=%.1f Mt CO2e\n",
            ghg_ndcu_ts_const_df$mtco2e[1], ghg_ndcu_ts_const_df$mtco2e[2],
            ghg_ndcu_ts_const_df$mtco2e[which(ghg_ndcu_ts_const_df$year == 2050)]))
cat(sprintf("  NDCC GHG: 2030=%.1f, 2035=%.1f, 2050=%.1f Mt CO2e\n",
            ghg_ndcc_ts_const_df$mtco2e[1], ghg_ndcc_ts_const_df$mtco2e[2],
            ghg_ndcc_ts_const_df$mtco2e[which(ghg_ndcc_ts_const_df$year == 2050)]))
cat(sprintf("  NZ GHG:   2030=%.1f -> 2050=%.1f Mt CO2e\n",
            ghg_nz_ts_const_df$mtco2e[1],
            ghg_nz_ts_const_df$mtco2e[which(ghg_nz_ts_const_df$year == 2050)]))

# ---- Write GHG constraint XML helper ----------------------------------------
write_ghg_constraint_xml <- function(filepath, comment_block, constraints_df) {
  lines <- c(
    '<?xml version="1.0" encoding="UTF-8"?>',
    comment_block,
    '<scenario>',
    '    <world>',
    '        <region name="Pakistan">',
    '            <ghgpolicy name="GHG">',
    '                <market>Pakistan</market>'
  )

  for (i in seq_len(nrow(constraints_df))) {
    lines <- c(lines, sprintf('                <constraint year="%d">%.3f</constraint>',
                               constraints_df$year[i], constraints_df$mtco2e[i]))
  }

  lines <- c(lines,
    '            </ghgpolicy>',
    '        </region>',
    '    </world>',
    '</scenario>',
    ''
  )

  writeLines(lines, filepath)
  cat("    -> Wrote: ", basename(filepath), "\n")
}

# ---- Write GHG constraint XMLs ----------------------------------------------
cat("\n== Writing GHG constraint XMLs ==\n")

# NDCU GHG
write_ghg_constraint_xml(
  file.path(policy_dir, "pak_ghg_constraint_ndc_uncond_v1_ts_const.xml"),
  c(sprintf('<!-- pak_ghg_constraint_ndc_uncond_v1_ts_const.xml'),
    sprintf('     NDC Unconditional ALL-GHG constraint for Pakistan.'),
    sprintf('     Applies to total Kyoto Gases (CO2 + CH4 + N2O + F-gases).'),
    sprintf('     Time-series: mult x CM_period Kyoto Gases.'),
    sprintf('     NDCU: 0.85 (2030), 0.83 (2035+).'),
    sprintf('     NOTE: post-2070 multiplier is 0.83 * 0.95 = 0.79 to ensure solvability.'),
    sprintf('     Units: Mt CO2e. Linked gases convert via GWP demand-adjust.'),
    sprintf('     CM baseline: %s (%s).', CM_SCENARIO, basename(GCAM_ALL_FILE)),
    sprintf('     Generated %s.', Sys.Date()),
    sprintf(''),
    sprintf('     REQUIRES: pak_linked_ghg_policy.xml loaded AFTER this file.'),
    sprintf('     Unlike CO2-only constraints, this uses <ghgpolicy name="GHG"> which'),
    sprintf('     creates a multi-gas market. Individual gases are linked via demand-adjust'),
    sprintf('     (GWP100) so the constraint binds on total CO2-equivalent emissions.'),
    sprintf('-->')),
  ghg_ndcu_ts_const_df
)

# NDCC GHG
write_ghg_constraint_xml(
  file.path(policy_dir, "pak_ghg_constraint_ndc_cond_v1_ts_const.xml"),
  c(sprintf('<!-- pak_ghg_constraint_ndc_cond_v1_ts_const.xml'),
    sprintf('     NDC Conditional ALL-GHG constraint for Pakistan.'),
    sprintf('     Time-series: mult x CM_period Kyoto Gases. NDCC: 0.50 (2030+).'),
    sprintf('     Units: Mt CO2e.'),
    sprintf('     Generated %s. -->', Sys.Date())),
  ghg_ndcc_ts_const_df
)

# Net Zero GHG
write_ghg_constraint_xml(
  file.path(policy_dir, "pak_ghg_constraint_netzero_v1_ts_const.xml"),
  c(sprintf('<!-- pak_ghg_constraint_netzero_v1_ts_const.xml'),
    sprintf('     Net Zero ALL-GHG constraint for Pakistan.'),
    sprintf('     Linear decline: fraction of each period CM Kyoto Gases to 0 at 2050.'),
    sprintf('     Units: Mt CO2e.'),
    sprintf('     Generated %s.', Sys.Date()),
    sprintf(''),
    sprintf('     SOLVER NOTE: constraint=0 for ALL GHGs is extremely aggressive.'),
    sprintf('     If solver fails, try near-zero (e.g., 10 Mt CO2e) at 2050.'),
    sprintf('-->')),
  ghg_nz_ts_const_df
)

# ---- Write Pakistan linked-GHG-policy XML -----------------------------------
cat("\n== Writing Pakistan linked-GHG-policy XML ==\n")

# GWP / price-adjust values from input/policy/linked_ghg_policy.xml (USA block)
# These are the standard GCAM values for linking individual gases to the GHG market.
ghg_link_path <- file.path(policy_dir, "pak_linked_ghg_policy.xml")

ghg_link_gases <- list(
  list(name = "CO2",      price_adj = "1",             demand_adj = "3.666666667",  price_unit = "1990$/tC",        output_unit = "MtC"),
  list(name = "CO2_FUG",  price_adj = "1",             demand_adj = "3.666667",     price_unit = "1990$/tC",        output_unit = "MTC"),
  list(name = "CH4",      price_adj = "5.727272727",    demand_adj = "21",           price_unit = "1990$/GgCH4",     output_unit = "TgCH4"),
  list(name = "N2O",      price_adj = "84.54545454",    demand_adj = "310",          price_unit = "1990$/GgN2o",     output_unit = "TgN2O"),
  list(name = "C2F6",     price_adj = "0",             demand_adj = "9.2",          price_unit = "1990$/MgC2F6",    output_unit = "GgC2F6"),
  list(name = "CF4",      price_adj = "0",             demand_adj = "6.5",          price_unit = "1990$/MgCF4",     output_unit = "GgCF4"),
  list(name = "HFC125",   price_adj = "0",             demand_adj = "2.8",          price_unit = "1990$/MgHFC125",  output_unit = "GgHFC125"),
  list(name = "HFC134a",  price_adj = "0",             demand_adj = "1.3",          price_unit = "1990$/MgHFC134a", output_unit = "GgHFC134a"),
  list(name = "HFC245fa", price_adj = "0",             demand_adj = "1.03",         price_unit = "1990$/MgHFC245fa",output_unit = "GgHFC245fa"),
  list(name = "SF6",      price_adj = "0",             demand_adj = "23.9",         price_unit = "1990$/MgSF6",     output_unit = "GgSF6"),
  list(name = "CH4_AWB",  price_adj = "5.727272727",    demand_adj = "21",           price_unit = "1990$/GgCH4",     output_unit = "TgCH4"),
  list(name = "CH4_AGR",  price_adj = "5.727272727",    demand_adj = "21",           price_unit = "1990$/GgCH4",     output_unit = "TgCH4"),
  list(name = "N2O_AWB",  price_adj = "84.54545454",    demand_adj = "310",          price_unit = "1990$/GgN2o",     output_unit = "TgN2O"),
  list(name = "N2O_AGR",  price_adj = "84.54545454",    demand_adj = "310",          price_unit = "1990$/GgN2o",     output_unit = "TgN2O")
)

ghg_link_lines <- c(
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<!-- pak_linked_ghg_policy.xml',
  '     Pakistan-only linked-GHG-policy: links all Kyoto gases to the GHG market.',
  '     Pattern: same as input/policy/linked_ghg_policy.xml but Pakistan-only,',
  '     with <market>Pakistan</market> instead of <market>global</market>.',
  '',
  '     Each gas is linked to the "GHG" policy with:',
  '       demand-adjust = GWP100 factor (converts gas emissions to CO2e for constraint)',
  '       price-adjust  = GWP/CO2_price_ratio (converts GHG price to effective gas price)',
  '',
  '     Gases with price-adjust > 0 (CO2, CH4, N2O, AG variants) face the carbon price',
  '     and will be abated. F-gases (price-adjust=0) are counted but not actively priced.',
  '',
  '     WARNING: Must be loaded AFTER the <ghgpolicy name="GHG"> constraint XML.',
  sprintf('     Generated %s.', Sys.Date()),
  '-->',
  '<scenario>',
  '    <world>',
  '        <region name="Pakistan">'
)

for (g in ghg_link_gases) {
  ghg_link_lines <- c(ghg_link_lines,
    sprintf('            <linked-ghg-policy name="%s">', g$name),
    sprintf('                <price-adjust fillout="1" year="1975">%s</price-adjust>', g$price_adj),
    sprintf('                <demand-adjust fillout="1" year="1975">%s</demand-adjust>', g$demand_adj),
    '                <market>Pakistan</market>',
    '                <linked-policy>GHG</linked-policy>',
    sprintf('                <price-unit>%s</price-unit>', g$price_unit),
    sprintf('                <output-unit>%s</output-unit>', g$output_unit),
    '            </linked-ghg-policy>'
  )
}

ghg_link_lines <- c(ghg_link_lines,
  '        </region>',
  '    </world>',
  '</scenario>',
  ''
)

writeLines(ghg_link_lines, ghg_link_path)
cat("    -> Wrote: ", basename(ghg_link_path), "\n")

# ---- Write Pakistan linked-GHG-policy (energy-only) XML -----------------------
# Energy-only multi-gas: same structure as above, but agricultural CH4/N2O variants
# have price-adjust=0 so they DON'T face the carbon price. They still count toward
# the constraint (demand-adjust > 0) but only energy-sector gases are actively abated.
# This is "economy-wide target, energy-sector instruments only."
cat("\n== Writing Pakistan linked-GHG-policy (energy-only) XML ==\n")

ghg_link_energy_path <- file.path(policy_dir, "pak_linked_ghg_policy_energy.xml")

# Same gas list but zero price-adjust for AG variants
ghg_link_gases_energy <- ghg_link_gases
for (i in seq_along(ghg_link_gases_energy)) {
  if (ghg_link_gases_energy[[i]]$name %in% c("CH4_AWB", "CH4_AGR", "N2O_AWB", "N2O_AGR")) {
    ghg_link_gases_energy[[i]]$price_adj <- "0"
  }
}

ghg_link_energy_lines <- c(
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<!-- pak_linked_ghg_policy_energy.xml',
  '     Pakistan-only linked-GHG-policy: ENERGY-ONLY pricing variant.',
  '     All gases count toward the GHG constraint (demand-adjust > 0),',
  '     but agricultural CH4/N2O variants (CH4_AWB, CH4_AGR, N2O_AWB, N2O_AGR)',
  '     have price-adjust = 0 so they do NOT face the carbon price.',
  '     This means only energy-sector gases are actively abated.',
  '',
  '     Use case: "economy-wide target, energy-sector instruments"',
  '     Effect: higher carbon prices than all-GHG (since cheap ag abatement is off)',
  '             but lower than CO2-only FFICT (since energy CH4/N2O abatement helps).',
  '',
  '     WARNING: Must be loaded AFTER the <ghgpolicy name="GHG"> constraint XML.',
  sprintf('     Generated %s.', Sys.Date()),
  '-->',
  '<scenario>',
  '    <world>',
  '        <region name="Pakistan">'
)

for (g in ghg_link_gases_energy) {
  ghg_link_energy_lines <- c(ghg_link_energy_lines,
    sprintf('            <linked-ghg-policy name="%s">', g$name),
    sprintf('                <price-adjust fillout="1" year="1975">%s</price-adjust>', g$price_adj),
    sprintf('                <demand-adjust fillout="1" year="1975">%s</demand-adjust>', g$demand_adj),
    '                <market>Pakistan</market>',
    '                <linked-policy>GHG</linked-policy>',
    sprintf('                <price-unit>%s</price-unit>', g$price_unit),
    sprintf('                <output-unit>%s</output-unit>', g$output_unit),
    '            </linked-ghg-policy>'
  )
}

ghg_link_energy_lines <- c(ghg_link_energy_lines,
  '        </region>',
  '    </world>',
  '</scenario>',
  ''
)

writeLines(ghg_link_energy_lines, ghg_link_energy_path)
cat("    -> Wrote: ", basename(ghg_link_energy_path), "\n")

# ---- Generate config files for GHG variants ----------------------------------
cat("\n== Generating config files for All-GHG variants ==\n")

ghg_scenarios <- list(
  list(base = "ndc_uncond", label = "NDCUncond_AllGHG"),
  list(base = "ndc_cond",   label = "NDCCond_AllGHG"),
  list(base = "netzero",    label = "NetZero_AllGHG")
)

for (scen in ghg_scenarios) {
  # Use existing FFICT ts_const config as template
  src_file <- file.path(config_dir, sprintf("configuration_%s_ffict_v1_ts_const.xml", scen$base))
  if (!file.exists(src_file)) {
    cat("[!] SKIP (missing template): ", src_file, "\n")
    next
  }
  src_lines <- readLines(src_file)

  new_lines <- src_lines

  # Replace CO2 constraint XML → GHG constraint XML
  old_constraint <- sprintf("pak_co2_constraint_%s_v1_ts_const.xml", scen$base)
  new_constraint <- sprintf("pak_ghg_constraint_%s_v1_ts_const.xml", scen$base)
  new_lines <- gsub(old_constraint, new_constraint, new_lines, fixed = TRUE)

  # Replace CO2_LUC FFICT link → linked GHG policy
  new_lines <- gsub("pak_co2luc_ffict.xml", "pak_linked_ghg_policy.xml", new_lines, fixed = TRUE)

  # Update comment references
  new_lines <- gsub("co2_constraint", "ghg_constraint", new_lines, fixed = TRUE)
  new_lines <- gsub("co2luc_link", "ghg_link", new_lines, fixed = TRUE)
  new_lines <- gsub("CO2_LUC link", "Linked GHG policy", new_lines, fixed = TRUE)
  new_lines <- gsub("Emissions policy: [A-Za-z_]+", sprintf("Emissions policy: %s", scen$label),
                     new_lines)

  # Replace scenario name
  # Find the existing scenarioName and replace
  old_scen_pattern <- '"scenarioName">[^<]+'
  new_lines <- gsub(old_scen_pattern, sprintf('"scenarioName">%s', scen$label), new_lines)

  # Replace header comment
  old_header <- sprintf("configuration_%s_ffict_v1_ts_const.xml", scen$base)
  new_header <- sprintf("configuration_%s_ghg_v1_ts_const.xml", scen$base)
  new_lines <- gsub(old_header, new_header, new_lines, fixed = TRUE)

  # Update the block comment about FFICT/EnergyOnly
  new_lines <- gsub("NDC[A-Za-z]*_EnergyOnly", scen$label, new_lines)
  new_lines <- gsub("EnergyOnly", "AllGHG", new_lines)

  dst_file <- file.path(config_dir, new_header)
  writeLines(new_lines, dst_file)
  cat("    -> Created: ", basename(dst_file), "\n")
}

# ---- Generate v2 config files for All-GHG variants ----------------------------
cat("\n== Generating v2 config files for All-GHG variants ==\n")

for (scen in ghg_scenarios) {
  src_file <- file.path(config_dir, sprintf("configuration_%s_ffict_v2_ts_const.xml", scen$base))
  if (!file.exists(src_file)) {
    cat("[!] SKIP (missing template): ", src_file, "\n"); next
  }
  src_lines <- readLines(src_file)
  new_lines <- src_lines

  old_constraint <- sprintf("pak_co2_constraint_%s_v1_ts_const.xml", scen$base)
  new_constraint <- sprintf("pak_ghg_constraint_%s_v1_ts_const.xml", scen$base)
  new_lines <- gsub(old_constraint, new_constraint, new_lines, fixed = TRUE)
  new_lines <- gsub("pak_co2luc_ffict.xml", "pak_linked_ghg_policy.xml", new_lines, fixed = TRUE)
  new_lines <- gsub("co2_constraint", "ghg_constraint", new_lines, fixed = TRUE)
  new_lines <- gsub("co2luc_link", "ghg_link", new_lines, fixed = TRUE)
  new_lines <- gsub("CO2_LUC link", "Linked GHG policy", new_lines, fixed = TRUE)
  new_lines <- gsub("Emissions policy: [A-Za-z_]+", sprintf("Emissions policy: %s", scen$label),
                     new_lines)
  v2_label <- paste0(scen$label, "_V2")
  old_scen_pattern <- '"scenarioName">[^<]+'
  new_lines <- gsub(old_scen_pattern, sprintf('"scenarioName">%s', v2_label), new_lines)
  new_lines <- gsub("NDC[A-Za-z]*_EnergyOnly", scen$label, new_lines)
  new_lines <- gsub("EnergyOnly", "AllGHG", new_lines)

  old_header <- sprintf("configuration_%s_ffict_v2_ts_const.xml", scen$base)
  new_header <- sprintf("configuration_%s_ghg_v2_ts_const.xml", scen$base)
  new_lines <- gsub(old_header, new_header, new_lines, fixed = TRUE)

  dst_file <- file.path(config_dir, new_header)
  writeLines(new_lines, dst_file)
  cat("    -> Created: ", basename(dst_file), "\n")
}

# ---- Generate config files for GHG-Energy variants ----------------------------
cat("\n== Generating config files for GHG-Energy (energy-only pricing) variants ==\n")

ghg_energy_scenarios <- list(
  list(base = "ndc_uncond", label = "NDCUncond_GHGEnergy"),
  list(base = "ndc_cond",   label = "NDCCond_GHGEnergy"),
  list(base = "netzero",    label = "NetZero_GHGEnergy")
)

for (scen in ghg_energy_scenarios) {
  # Template from the all-GHG config we just created
  src_file <- file.path(config_dir, sprintf("configuration_%s_ghg_v1_ts_const.xml", scen$base))
  if (!file.exists(src_file)) {
    cat("[!] SKIP (missing template): ", src_file, "\n"); next
  }
  src_lines <- readLines(src_file)

  new_lines <- src_lines

  # Replace linked policy: all-GHG → energy-only variant
  new_lines <- gsub("pak_linked_ghg_policy.xml", "pak_linked_ghg_policy_energy.xml",
                     new_lines, fixed = TRUE)

  # Update scenario name
  old_scen_pattern <- '"scenarioName">[^<]+'
  new_lines <- gsub(old_scen_pattern, sprintf('"scenarioName">%s', scen$label), new_lines)

  # Update header comment
  old_header <- sprintf("configuration_%s_ghg_v1_ts_const.xml", scen$base)
  new_header <- sprintf("configuration_%s_ghg_energy_v1_ts_const.xml", scen$base)
  new_lines <- gsub(old_header, new_header, new_lines, fixed = TRUE)

  # Update descriptive comments
  new_lines <- gsub("AllGHG", "GHGEnergy", new_lines, fixed = TRUE)
  new_lines <- gsub("Linked GHG policy", "Linked GHG policy (energy-only pricing)", new_lines, fixed = TRUE)

  dst_file <- file.path(config_dir, new_header)
  writeLines(new_lines, dst_file)
  cat("    -> Created: ", basename(dst_file), "\n")
}

# ---- Generate v2 config files for GHG-Energy variants ----------------------------
cat("\n== Generating v2 config files for GHG-Energy (energy-only pricing) variants ==\n")

for (scen in ghg_energy_scenarios) {
  src_file <- file.path(config_dir, sprintf("configuration_%s_ghg_v2_ts_const.xml", scen$base))
  if (!file.exists(src_file)) {
    cat("[!] SKIP (missing template): ", src_file, "\n"); next
  }
  src_lines <- readLines(src_file)
  new_lines <- src_lines

  new_lines <- gsub("pak_linked_ghg_policy.xml", "pak_linked_ghg_policy_energy.xml",
                     new_lines, fixed = TRUE)
  v2_label <- paste0(scen$label, "_V2")
  old_scen_pattern <- '"scenarioName">[^<]+'
  new_lines <- gsub(old_scen_pattern, sprintf('"scenarioName">%s', v2_label), new_lines)

  old_header <- sprintf("configuration_%s_ghg_v2_ts_const.xml", scen$base)
  new_header <- sprintf("configuration_%s_ghg_energy_v2_ts_const.xml", scen$base)
  new_lines <- gsub(old_header, new_header, new_lines, fixed = TRUE)
  new_lines <- gsub("AllGHG", "GHGEnergy", new_lines, fixed = TRUE)
  new_lines <- gsub("Linked GHG policy", "Linked GHG policy (energy-only pricing)", new_lines, fixed = TRUE)

  dst_file <- file.path(config_dir, new_header)
  writeLines(new_lines, dst_file)
  cat("    -> Created: ", basename(dst_file), "\n")
}

# ---- Extended traceability CSV with GHG variants -----------------------------
cat("\n== Updating traceability CSV with GHG variants ==\n")

ghg_trace <- bind_rows(
  trace_ts,
  tibble(scenario = "NDC_Uncond_v1_ghg_ts_const", year = ghg_ndcu_ts_const_df$year,
         cm_eip_mtco2 = cm_kyoto_vals[as.character(ghg_ndcu_ts_const_df$year)],
         multiplier = ghg_ndcu_ts_const_df$mult,
         constraint_mtc = ghg_ndcu_ts_const_df$mtco2e),
  tibble(scenario = "NDC_Cond_v1_ghg_ts_const", year = ghg_ndcc_ts_const_df$year,
         cm_eip_mtco2 = cm_kyoto_vals[as.character(ghg_ndcc_ts_const_df$year)],
         multiplier = ghg_ndcc_ts_const_df$mult,
         constraint_mtc = ghg_ndcc_ts_const_df$mtco2e),
  tibble(scenario = "NetZero_v1_ghg_ts_const", year = ghg_nz_ts_const_df$year,
         cm_eip_mtco2 = cm_kyoto_vals[as.character(ghg_nz_ts_const_df$year)],
         multiplier = ghg_nz_ts_const_df$mtco2e / cm_kyoto_vals[as.character(ghg_nz_ts_const_df$year)],
         constraint_mtc = ghg_nz_ts_const_df$mtco2e)
)
# Note: for GHG rows, cm_eip_mtco2 actually holds Mt CO2e (Kyoto Gases), and
# constraint_mtc holds Mt CO2e (not MTC). Column names retained for compatibility.
ghg_trace$constraint_mtco2 <- ghg_trace$constraint_mtc / CO2_TO_MTC

ghg_trace_file <- file.path(trace_dir, "emission_constraints_v1_all_with_ghg_trace.csv")
write_csv(ghg_trace, ghg_trace_file)
cat("  Extended traceability CSV (with GHG): ", ghg_trace_file, "\n")

# ---- Final summary ----------------------------------------------------------
cat("\n== Final Summary ==\n")
cat("  CO2-only constraints:\n")
cat("    3 flat-hold XMLs + 6 time-series XMLs + 12 config files\n")
cat("  All-GHG constraints:\n")
cat("    3 GHG constraint XMLs (ndc_uncond, ndc_cond, netzero)\n")
cat("    1 linked-GHG-policy XML (pak_linked_ghg_policy.xml)\n")
cat("    3 config files (configuration_*_ghg_v1_ts_const.xml)\n")
cat("  GHG-Energy (energy-only pricing):\n")
cat("    1 linked-GHG-policy XML (pak_linked_ghg_policy_energy.xml)\n")
cat("    3 config files (configuration_*_ghg_energy_v1_ts_const.xml)\n")
cat("  V2 configs (use v2 CM add-ons: solar, fossils, ev):\n")
cat("    12 CO2-only configs (configuration_*_{ffict,uct}_v2_{ts_const,ts_decl}.xml)\n")
cat("    3 GHG configs (configuration_*_ghg_v2_ts_const.xml)\n")
cat("    3 GHG-Energy configs (configuration_*_ghg_energy_v2_ts_const.xml)\n")
cat("  Traceability: 3 CSVs (original, extended, extended+GHG)\n")
cat("\n")
cat("  Run order (easiest -> hardest for solver):\n")
cat("    CO2-only FFICT:   ./gcam.exe -C configuration_<scen>_ffict_v1_ts_const.xml\n")
cat("    GHG-Energy:       ./gcam.exe -C configuration_<scen>_ghg_energy_v1_ts_const.xml\n")
cat("    All-GHG:          ./gcam.exe -C configuration_<scen>_ghg_v1_ts_const.xml\n")
cat("    (For v2 CM: replace v1 with v2 in the above commands)\n")
cat("  Then: Rscript analysis/query/iamc.R\n")
cat("\nDone.\n")
