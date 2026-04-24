# git clone https://github.com/bc3LC/gcamreport.git
# open gcamreport/gcamreport.Rproj
# devtools::load_all(".", reset = TRUE)
#
# ran into a few issues: https://github.com/bc3LC/gcamreport/issues/63


# NOTE:change scenarios names, proj file

scen <- c("Reference", "CurrentMeasures", "CurrentMeasuresRev", "CurrentMeasuresV2", 
          "NDCCond_EnergyAg", "NDCUncond_EnergyAg", "NetZero_EnergyAg",
          "NDCCond_AllGHG_V2", "NDCUncond_AllGHG_V2", "NetZero_AllGHG_V2")
prj.name <- "gcam_output_iamc_all_v2.dat"


# ---- Bootstrap: find project root, load config, load gcamreport -------------
find_root <- function() {
  for (d in c(getwd(), file.path(getwd(), ".."), file.path(getwd(), "../.."),
              file.path(getwd(), "../../..")))
    if (dir.exists(file.path(d, "input")) && dir.exists(file.path(d, "exe")))
      return(normalizePath(d))
  stop("Cannot detect project root (need input/ + exe/ dirs)")
}
ROOT <- find_root()
source(file.path(ROOT, "analysis", "1_config.R"))

# Load gcamreport package from local clone
gcamreport_path <- file.path(ROOT, "analysis", "gcamreport")
stopifnot("gcamreport/ not found — git clone it into analysis/" = dir.exists(gcamreport_path))
devtools::load_all(gcamreport_path, reset = TRUE, quiet = TRUE)
cat("  gcamreport loaded from:", gcamreport_path, "\n")

# ---- Scenario batches --------------------------------------------------------
# Run one batch at a time to avoid memory issues.
# Uncomment the batch you want to run. Each writes its own output files.
# After generating, the post-process block filters to Pakistan and copies
# to analysis/query/iamc_format/.

# -- Batch 2: NDC Unconditional (energy-only + energy+ag)
# scen <- c("NDCUncond_EnergyOnly", "NDCUncond_EnergyAg")
# prj.name <- "gcam_output_iamc_ndc_uncond.dat"

# -- Batch 3: NDC Conditional (energy-only + energy+ag)
# scen <- c("NDCCond_EnergyOnly", "NDCCond_EnergyAg")
# prj.name <- "gcam_output_iamc_ndc_cond.dat"

# -- Batch 4: Net Zero (energy-only + energy+ag)
# scen <- c("NetZero_EnergyOnly", "NetZero_EnergyAg")
# prj.name <- "gcam_output_iamc_netzero.dat"

GCAM_version <- "v7.1"  # must match gcamreport's food_items_map (not actual GCAM version)
dbpath <- file.path(ROOT, "output")
dbname <- "database_basexdb"

# list available variables in the package
avail_vars <- as.data.frame(sort(available_variables()))

# vars to generate: collected from MESSAGEix var list
# desired_vars = c('Resource*')
# desired_vars = c('Resource|Extraction*')
desired_vars = c('Resource*',
                 'Primary Energy*',
                 'Final Energy*',
                 'Secondary Energy*',
                 'Emissions*',
                 # 'Carbon Sequestration*',
                 'Capacity*',
                 'Capacity Additions*',
                 # 'Cumulative Capacity*',
                 'Capital Cost*',
                 # 'OM Cost*',
                 # 'Lifetime*',
                 # 'Efficiency*',
                 # 'Useful Energy*'
                 'Trade*',
                 'Investment*',
                 'Water Consumption*',
                 'Water Withdrawal*'
                 # 'Price*'
                 # 'Cost*'
)

# main report generation function
generate_report(db_path = dbpath, db_name = dbname, scenarios = scen,
                prj_name = prj.name, final_year = 2100,
                desired_regions = c('Pakistan', 'China'),
                desired_variables = desired_vars,
                save_output = TRUE, launch_ui = FALSE)
# NOTE: launch_ui = FALSE because the Shiny app path is resolved relative to
# the working directory, not the package install path. When running via
# devtools::load_all() from outside the gcamreport dir, it can't find
# inst/gcamreport_ui. Set to TRUE only if running from inside gcamreport/.

# ---- Post-process: filter to Pakistan & copy to iamc_format/ ----------------
# gcamreport requires >=2 regions to avoid internal errors, so we request
# c('Pakistan', 'China') above. Here we filter the output to Pakistan only
# and write clean copies to analysis/query/iamc_format/ for downstream scripts.

out_dir <- IAMC_FORMAT_DIR

# Determine the base filename (matches prj.name pattern)
base <- sub("\\.dat$", "", prj.name)  # e.g. "gcam_output_iamc_ref_cm"

REGION_TO_FILTER <- "Pakistan"

# --- CSV ---
csv_src <- file.path(dbpath, paste0(base, "_standardized.csv"))
if (file.exists(csv_src)) {
  df_csv <- read.csv(csv_src, stringsAsFactors = FALSE, check.names = FALSE)
  df_pak <- df_csv[df_csv$Region == REGION_TO_FILTER, ]
  # Fix Model column: gcamreport writes "GCAM 7.1" but we want "GCAM 8.6"
  if ("Model" %in% names(df_pak)) df_pak$Model <- GCAM_MODEL_LABEL
  csv_dst <- file.path(out_dir, paste0(base, "_standardized.csv"))
  write.csv(df_pak, csv_dst, row.names = FALSE)
  cat("  Wrote", nrow(df_pak), "rows (Pakistan only) ->", csv_dst, "\n")
}

# --- Excel ---
xlsx_src <- file.path(dbpath, paste0(base, "_standardized.xlsx"))
if (file.exists(xlsx_src)) {
  sheets <- excel_sheets(xlsx_src)
  pak_sheets <- lapply(sheets, function(s) {
    d <- read_excel(xlsx_src, sheet = s)
    if ("Region" %in% names(d)) d <- d[d$Region == REGION_TO_FILTER, ]
    # Fix Model column in each sheet
    if ("Model" %in% names(d)) d$Model <- GCAM_MODEL_LABEL
    d
  })
  names(pak_sheets) <- sheets
  xlsx_dst <- file.path(out_dir, paste0(base, "_standardized.xlsx"))
  write_xlsx(pak_sheets, xlsx_dst)
  cat("  Wrote Pakistan-only Excel ->", xlsx_dst, "\n")
}

cat("\nDone.\n")


