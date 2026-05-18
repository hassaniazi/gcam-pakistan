# analysis/1_config.R
# Shared configuration for GCAM-Pakistan analysis scripts.
# Source this file at the top of each script:
#   source(file.path(ROOT, "analysis", "1_config.R"))
# OR let 1_config.R find ROOT itself (works if ROOT is not yet defined).

# ---- Find project root -------------------------------------------------------
if (!exists("ROOT")) {
  find_root <- function() {
    for (d in c(getwd(), file.path(getwd(), ".."), file.path(getwd(), "../.."),
                file.path(getwd(), "../../.."))) {
      if (dir.exists(file.path(d, "input")) && dir.exists(file.path(d, "exe")))
        return(normalizePath(d))
    }
    if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
      sp <- tryCatch(rstudioapi::getSourceEditorContext()$path, error = function(e) NULL)
      if (!is.null(sp)) {
        r <- normalizePath(file.path(dirname(sp), "../.."), mustWork = FALSE)
        if (dir.exists(file.path(r, "input"))) return(r)
      }
    }
    warning("Cannot detect project root, using CWD"); getwd()
  }
  ROOT <- find_root()
}

# ---- Common packages ---------------------------------------------------------
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(readxl)
  library(stringr)
  library(writexl)
})

# ---- Model metadata ----------------------------------------------------------
GCAM_MODEL_LABEL <- "GCAM 8.6"
MSG_MODEL_LABEL  <- "MESSAGEix"

# ---- Standard years -----------------------------------------------------------
YEARS     <- c(2025, 2030, 2035, 2040, 2045, 2050)
YEAR_COLS <- as.character(YEARS)
YEARS_ALL <- seq(2025, 2100, by = 5)

# ---- Conversion factors -------------------------------------------------------
CO2_TO_MTC <- 12 / 44
EJ_TO_GWA  <- 31.70979

# ---- Standard paths (all relative to ROOT) ------------------------------------
GCAM_IAMC_ALL   <- file.path(ROOT, "output", "gcam_output_iamc_all_v2_standardized.xlsx")
MSG_FILE        <- file.path(ROOT, "analysis", "MESSAGEix-Pakistan_CM.xlsx")
POLICY_DIR      <- file.path(ROOT, "input", "extra", "policy")
CM_DIR          <- file.path(ROOT, "input", "extra", "cm")
IAMC_FORMAT_DIR <- file.path(ROOT, "analysis", "query", "iamc_format")
FIG_DIR         <- file.path(ROOT, "analysis", "figures")

if (!dir.exists(FIG_DIR)) dir.create(FIG_DIR, recursive = TRUE)
if (!dir.exists(IAMC_FORMAT_DIR)) dir.create(IAMC_FORMAT_DIR, recursive = TRUE)

# ---- Standard GCAM scenarios -------------------------------------------------
GCAM_SCENARIOS <- c("CurrentMeasuresRev", "NDCCond_EnergyAg", "NDCUncond_EnergyAg", "NetZero_EnergyAg", 
                    "CurrentMeasuresV2", "NDCCond_AllGHG_V2", "NDCUncond_AllGHG_V2", "NetZero_AllGHG_V2", 
                    "CurrentMeasures_V3limitBio", "NDCUncond_AllGHG_V3limitBio", "NDCCond_AllGHG_V3limitBio", "NetZero_AllGHG_V3limitBio")
GCAM_CM_SCENARIO <- "CurrentMeasures_V3limitBio"

# ---- NDC multipliers (from team scenario design) -----------------------------
NDCU_2030_MULT <- 0.85
NDCU_2035_MULT <- 0.83
NDCC_2030_MULT <- 0.50
NDCC_2035_MULT <- 0.50

# ---- Shared theme for ggplot2 ------------------------------------------------
if (requireNamespace("ggplot2", quietly = TRUE)) {
  library(ggplot2)
  library(scales)

  # Publication-quality theme — clean, minimal, academic
  theme_gcam <- function(base_size = 11, base_family = "") {
    theme_minimal(base_size = base_size, base_family = base_family) %+replace%
      theme(
        # Text hierarchy
        plot.title        = element_text(size = base_size + 3, face = "bold",
                                         hjust = 0, margin = margin(b = 4)),
        plot.subtitle     = element_text(size = base_size, color = "grey40",
                                         hjust = 0, margin = margin(b = 8)),
        plot.caption      = element_text(size = base_size - 2, color = "grey50",
                                         hjust = 1, margin = margin(t = 8)),
        # Axes
        axis.title        = element_text(size = base_size - 1, color = "grey30"),
        axis.title.y      = element_text(margin = margin(r = 8)),
        axis.text         = element_text(size = base_size - 1, color = "grey30"),
        axis.line.x       = element_line(color = "grey40", linewidth = 0.4),
        axis.ticks.x      = element_line(color = "grey40", linewidth = 0.3),
        axis.ticks.length = unit(3, "pt"),
        # Grid: horizontal only, subtle
        panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3),
        panel.grid.major.x = element_blank(),
        panel.grid.minor   = element_blank(),
        # Panel
        panel.border       = element_rect(color = "grey80", fill = NA, linewidth = 0.4),
        panel.spacing      = unit(1.2, "lines"),
        # Strip (facets)
        strip.text         = element_text(face = "bold", size = base_size,
                                           margin = margin(b = 4, t = 4)),
        strip.background   = element_rect(fill = "grey96", color = NA),
        # Legend
        legend.position    = "bottom",
        legend.title       = element_blank(),
        legend.text        = element_text(size = base_size - 1),
        legend.key.size    = unit(14, "pt"),
        legend.margin      = margin(t = 4),
        # Margins
        plot.margin        = margin(12, 12, 8, 8)
      )
  }

  # Technology palette — muted, colorblind-considerate
  tech_colors <- c(
    Coal    = "#636363",
    Gas     = "#3182bd",
    Oil     = "#a6611a",
    Nuclear = "#d6604d",
    Hydro   = "#1b7837",
    Solar   = "#e6ab02",
    Wind    = "#7570b3",
    Biomass = "#66c2a5"
  )

  # Model comparison — high-contrast, clean pair
  model_colors <- c("GCAM 8.6" = "#c0392b", "MESSAGEix" = "#2471a3")

  # Scenario palette — ordered by ambition level
  scenario_colors <- c(
    Reference          = "#bdbdbd",
    CurrentMeasuresV2 = "#000000",
    NDCUncond_EnergyAg = "#e67e22",
    NDCCond_EnergyAg   = "#8e44ad",
    NetZero_EnergyAg   = "#27ae60",
    NDCUncond_AllGHG_V2 = "#e67e22",
    NDCCond_AllGHG_V2  = "#8e44ad",
    NetZero_AllGHG_V2   = "#27ae60",
    MESSAGEix_CM       = "#000000"
  )

  # Clean scenario labels for display
  scenario_labels <- c(
    Reference          = "Reference",
    CurrentMeasuresV2 = "Current Measures",
    NDCUncond_EnergyAg = "NDC Unconditional",
    NDCCond_EnergyAg   = "NDC Conditional",
    NetZero_EnergyAg   = "Net Zero",
    NDCCond_AllGHG_V2  = "NDC Conditional (All GHG)",
    NDCUncond_AllGHG_V2 = "NDC Unconditional (All GHG)",
    NetZero_AllGHG_V2   = "Net Zero (All GHG)",
    MESSAGEix_CM       = "MESSAGEix CM"
  )

  # Scenario shapes for points (solid = CO2/EnergyAg, hollow = AllGHG variants)
  scenario_shapes <- c(
    Reference          = 16,  # solid circle
    CurrentMeasuresV2 = 17,  # solid triangle
    NDCUncond_EnergyAg = 15,  # solid square
    NDCCond_EnergyAg   = 17,  # solid triangle
    NetZero_EnergyAg   = 18,  # solid diamond
    NDCUncond_AllGHG_V2 = 0,  # hollow square
    NDCCond_AllGHG_V2  = 2,   # hollow triangle
    NetZero_AllGHG_V2   = 5,  # hollow diamond
    MESSAGEix_CM       = 4    # x
  )

  # Scenario linetypes (solid = CO2/EnergyAg, dashed = AllGHG variants)
  scenario_linetypes <- c(
    Reference          = "dotted",
    CurrentMeasuresV2 = "solid",
    NDCUncond_EnergyAg = "solid",
    NDCCond_EnergyAg   = "solid",
    NetZero_EnergyAg   = "solid",
    NDCUncond_AllGHG_V2 = "dashed",
    NDCCond_AllGHG_V2  = "dashed",
    NetZero_AllGHG_V2   = "dashed",
    MESSAGEix_CM       = "solid"
  )

  scens_to_plot <- c(GCAM_CM_SCENARIO, 
                   "NDCUncond_EnergyAg", "NDCCond_EnergyAg", "NetZero_EnergyAg",
                   "NDCUncond_AllGHG_V2", "NDCCond_AllGHG_V2", "NetZero_AllGHG_V2",
                   "CurrentMeasures_V3limitBio", "NDCUncond_AllGHG_V3limitBio", "NDCCond_AllGHG_V3limitBio", "NetZero_AllGHG_V3limitBio")

}


cat("1_config.R loaded. ROOT:", ROOT, "\n")
