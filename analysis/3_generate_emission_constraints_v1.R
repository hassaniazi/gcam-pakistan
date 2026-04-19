# generate_emission_constraints_v1.R
# Reads CMRev (v1) output, extracts E&IP CO2, generates constraint XMLs.
#
# Usage: Rscript analysis/generate_emission_constraints_v1.R
# Output:
#   input/extra/policy/pak_co2_constraint_{ndc_uncond,ndc_cond,netzero}_v1[_ts_const|_ts_decl].xml
#   analysis/query/iamc_format/emission_constraints_v1_trace.csv
#   exe/configuration_*_v1_ts_{const,decl}.xml

# ---- Bootstrap ---------------------------------------------------------------
find_root <- function() {
  for (d in c(getwd(), file.path(getwd(), ".."), file.path(getwd(), "../..")))
    if (dir.exists(file.path(d, "input")) && dir.exists(file.path(d, "exe")))
      return(normalizePath(d))
  stop("Cannot detect project root")
}
ROOT <- find_root()
source(file.path(ROOT, "analysis", "config.R"))

# ---- Config ------------------------------------------------------------------
GCAM_FILE <- file.path(ROOT, "output", "gcam_output_iamc_ref_cm_rev_standardized.xlsx")

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

cat("\n== Summary ==\n")
cat("  3 flat-hold constraint XMLs (original v1)\n")
cat("  6 time-series constraint XMLs (3 ts_const + 3 ts_decl)\n")
cat("  12 config files (3 scenarios x 2 modes x 2 TS variants)\n")
cat("  2 traceability CSVs\n")
cat("\n")
cat("  Next: ./gcam.exe -C configuration_<scenario>_<mode>_v1[_ts].xml\n")
cat("  Then: Rscript analysis/query/iamc.R\n")
cat("\nDone.\n")
