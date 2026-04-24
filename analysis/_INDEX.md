# GCAM-PAK Inter-Model Comparison: Project Index

> MESSAGE-GCAM Pakistan energy-climate pathway comparison.
> Last updated: 2026-04-14

## Quick Reference

| Item | Value |
|------|-------|
| Deadline | April 30, 2026 |
| GCAM version | 8.5 (v8.2 in gcamreport) |
| Region | Pakistan (ID 22) |
| Scenarios | Reference, CurrentMeasures, NDCUncond (×3), NDCCond (×3), NetZero (×3) = 11 total |
| Database | `output/database_basexdb` |

---

## Documentation Files

### Analysis & Scenario Design

| File | Description |
|------|-------------|
| [analysis/docs/project_notes.md](analysis/docs/project_notes.md) | Quick-reference: team info, scenario tracker, key numbers, pipeline, open questions |
| [analysis/scenarios_lums.csv](analysis/scenarios_lums.csv) | Original scenario targets from MESSAGE team (read-only) |
| [analysis/scenarios_lums_gcam.csv](analysis/scenarios_lums_gcam.csv) | Enriched version with GCAM Ref values, gap analysis, traceability columns |
| [analysis/2_scenario_targets_check.R](analysis/2_scenario_targets_check.R) | R script: compares any IAMC output against scenarios_lums.csv targets. Multi-scenario, full traceability. |

### Scenario Implementation Files

| File | Description |
|------|-------------|
| [exe/configuration_ref.xml](exe/configuration_ref.xml) | Reference scenario config (baseline, run to 2100) |
| [exe/configuration_cm.xml](exe/configuration_cm.xml) | Current Measures scenario config (adds CM XMLs, stop-year=2050) |
| [exe/configuration_ndc_uncond_ffict.xml](exe/configuration_ndc_uncond_ffict.xml) | NDCUncond_EnergyOnly: CM + CO2 constraint (energy-only) |
| [exe/configuration_ndc_uncond_uct.xml](exe/configuration_ndc_uncond_uct.xml) | NDCUncond_EnergyAg: CM + CO2 constraint (energy+agriculture) |
| [exe/configuration_ndc_cond_ffict.xml](exe/configuration_ndc_cond_ffict.xml) | NDCCond_EnergyOnly: CM + tighter CO2 constraint (energy-only) |
| [exe/configuration_ndc_cond_uct.xml](exe/configuration_ndc_cond_uct.xml) | NDCCond_EnergyAg: CM + tighter CO2 constraint (energy+agriculture) |
| [exe/configuration_netzero_ffict.xml](exe/configuration_netzero_ffict.xml) | NetZero_EnergyOnly: CM + linear decline to 0 by 2050 (energy-only) |
| [exe/configuration_netzero_uct.xml](exe/configuration_netzero_uct.xml) | NetZero_EnergyAg: CM + linear decline to 0 by 2050 (energy+agriculture) |
| [exe/configuration_ndc_uncond_ghg_v1_ts_const.xml](exe/configuration_ndc_uncond_ghg_v1_ts_const.xml) | NDCUncond_AllGHG: CM + all-GHG constraint (multi-gas economy-wide) |
| [exe/configuration_ndc_cond_ghg_v1_ts_const.xml](exe/configuration_ndc_cond_ghg_v1_ts_const.xml) | NDCCond_AllGHG: CM + tighter all-GHG constraint |
| [exe/configuration_netzero_ghg_v1_ts_const.xml](exe/configuration_netzero_ghg_v1_ts_const.xml) | NetZero_AllGHG: CM + linear all-GHG decline to 0 by 2050 |
| [input/extra/cm/cm_01_hydro.xml](input/extra/cm/cm_01_hydro.xml) | CM: Hydro fixedOutput increase to 0.1437 EJ (4.555 GWa target). **Safest.** |
| [input/extra/cm/cm_02_solar.xml](input/extra/cm/cm_02_solar.xml) | CM: Solar subsector share-weight boost to 3.5 |
| [input/extra/cm/cm_03_wind.xml](input/extra/cm/cm_03_wind.xml) | CM: Wind subsector share-weight reduce to 0.45 |
| [input/extra/cm/cm_04_nuclear.xml](input/extra/cm/cm_04_nuclear.xml) | CM: Nuclear subsector share-weight boost to 2.5 |
| [input/extra/cm/cm_05_fossils.xml](input/extra/cm/cm_05_fossils.xml) | CM: Coal 0.35 / Gas 0.55 / Oil 0.04 share-weights. **Riskiest.** |
| [input/extra/cm/cm_06_bio.xml](input/extra/cm/cm_06_bio.xml) | CM: Biomass share-weight boost to 2.5 |
| [input/extra/cm/cm_07_ev.xml](input/extra/cm/cm_07_ev.xml) | CM: BEV share-weight boost (4W + 2W/3W) |

### Emissions Policy Files

| File | Description |
|------|-------------|
| [input/extra/policy/pak_co2_constraint_ndc_uncond.xml](input/extra/policy/pak_co2_constraint_ndc_uncond.xml) | NDC Unconditional: 0.85×CM @2030, 0.83×CM @2035, flat hold |
| [input/extra/policy/pak_co2_constraint_ndc_cond.xml](input/extra/policy/pak_co2_constraint_ndc_cond.xml) | NDC Conditional: 0.50×CM @2030, 0.50×CM @2035, flat hold |
| [input/extra/policy/pak_co2_constraint_netzero.xml](input/extra/policy/pak_co2_constraint_netzero.xml) | Net Zero: linear decline from CM 2025 to 0 MTC at 2050 |
| [input/extra/policy/pak_co2luc_ffict.xml](input/extra/policy/pak_co2luc_ffict.xml) | FFICT link: AFOLU excluded from policy (energy-only) |
| [input/extra/policy/pak_co2luc_uct.xml](input/extra/policy/pak_co2luc_uct.xml) | UCT link: AFOLU faces price + counts in constraint (energy+ag) |

### All-GHG Emissions Policy Files

| File | Description |
|------|-------------|
| [input/extra/policy/pak_ghg_constraint_ndc_uncond_v1_ts_const.xml](input/extra/policy/pak_ghg_constraint_ndc_uncond_v1_ts_const.xml) | NDC Uncond all-GHG: 0.85×CM@2030, 0.83×CM@2035+ (Mt CO2e) |
| [input/extra/policy/pak_ghg_constraint_ndc_cond_v1_ts_const.xml](input/extra/policy/pak_ghg_constraint_ndc_cond_v1_ts_const.xml) | NDC Cond all-GHG: 0.50×CM (Mt CO2e) |
| [input/extra/policy/pak_ghg_constraint_netzero_v1_ts_const.xml](input/extra/policy/pak_ghg_constraint_netzero_v1_ts_const.xml) | Net Zero all-GHG: linear to 0 (Mt CO2e) |
| [input/extra/policy/pak_linked_ghg_policy.xml](input/extra/policy/pak_linked_ghg_policy.xml) | Links CO2, CH4, N2O, F-gases to GHG market (Pakistan-only, all gases priced) |
| [input/extra/policy/pak_linked_ghg_policy_energy.xml](input/extra/policy/pak_linked_ghg_policy_energy.xml) | GHG-Energy variant: AG CH4/N2O count but NOT priced (energy-only instruments) |
| [analysis/docs/gcam_emissions_policy_mechanisms_all.md](analysis/docs/gcam_emissions_policy_mechanisms_all.md) | Reference doc: constraint vs fixedTax, FFICT vs UCT vs All-GHG vs GHG-Energy, units, multi-gas mechanics, solver notes |

### IAMC Pipeline

| File | Description |
|------|-------------|
| [analysis/2_iamc.R](analysis/2_iamc.R) | gcamreport wrapper: generates IAMC-format xlsx from GCAM database |
| [analysis/query/iamc_format/](analysis/query/iamc_format/) | Output directory for IAMC standardized files |
| [analysis/gcamreport/](analysis/gcamreport/) | Local clone of bc3LC/gcamreport (run from inside gcamreport.Rproj) |

### Planning

| File | Description |
|------|-------------|
| [.claude/plans/1_scenario-implementation.md](.claude/plans/1_scenario-implementation.md) | Full implementation plan: situation analysis, gaps, strategy, risk assessment |

---

## Memory Files (Claude project context)

These persist across Claude conversations at `~/.claude/projects/.../memory/`:

| File | Description |
|------|-------------|
| user_hassan.md | User profile: Hassan Niazi, GCAM modeler at PNNL |
| project_intermodel.md | Project context: MESSAGE-GCAM comparison paper, deadline, goals |
| project_scenarios.md | Scenario design: 5 scenarios with targets decoded from scenarios_lums.csv |
| project_ref_baseline.md | GCAM Reference key numbers and gap analysis vs CM targets |
| project_gcam_mechanics.md | Technical: share weights, fixedOutput, CFs, IAMC reporting chain |
| project_workspace.md | Workspace architecture: build structure, paths |
| reference_team.md | Team members, roles, communication channels |
| feedback_approach.md | Decision: use add-on XMLs, skip gcam-tuner |
| feedback_capacity_gw.md | Finding: IAMC capacity GW unreliable; use gen-implied with source CFs |

---

## Pipeline Workflow

```
Step  What                          Command / File                                  Output
─────────────────────────────────────────────────────────────────────────────────────────────
1.    Edit CM add-on XMLs           input/extra/cm/cm_*.xml                         (hand-edit share-weights)
2.    Run GCAM                      cd exe && ./run-gcam.command                    output/database_basexdb
                                    (or: ./gcam.exe -C configuration_cm.xml)
3.    Generate IAMC output          Rscript analysis/query/iamc.R                   output/*_standardized.{csv,xlsx,RData}
                                    Reads database_basexdb, runs gcamreport,        + filtered Pakistan-only copies in
                                    filters to Pakistan, writes to iamc_format/     analysis/query/iamc_format/
4.    Compare vs targets            Rscript analysis/scenario_targets_check.R       analysis/query/iamc_format/scenario_targets_comparison_v3.csv
                                    Reads iamc xlsx + scenarios_lums.csv,           Console prints gap tables + Ref→CM verdict
                                    computes gaps, Ref→CM delta                     + CM→NDC emissions comparison
5.    Iterate                       Adjust cm_*.xml share-weights based on          Go to step 2
                                    gap_pct and cm_vs_ref columns

Emissions Scenarios (after CM is tuned):
6.    Update constraint values      input/extra/policy/pak_co2_constraint_*.xml     Update MTC values from fresh CM E&IP
7.    Run NDC/NetZero               cd exe && ./gcam.exe -C configuration_ndc_*.xml output/database_basexdb
                                    Run each config: ndc_uncond_ffict, _uct,        (all scenarios co-located in same db)
                                    ndc_cond_ffict, _uct, netzero_ffict, _uct
8.    Generate IAMC (batched)       Rscript analysis/query/iamc.R                   Uncomment the relevant batch in iamc.R
                                    Run once per batch (Ref+CM, NDC Uncond,         (4 batches to avoid memory issues)
                                    NDC Cond, Net Zero)
9.    Compare all scenarios         Rscript analysis/scenario_targets_check.R       Cross-scenario emissions comparison,
                                    Best: run against xlsx with all scenarios       carbon prices, FFICT-vs-UCT delta

Run priority (easiest → hardest for solver):
  NDCUncond_EnergyOnly → NDCUncond_EnergyAg → NDCCond_EnergyOnly →
  NDCCond_EnergyAg → NetZero_EnergyOnly → NetZero_EnergyAg

Handoffs:
  Step 2 → 3:  GCAM writes database_basexdb; iamc.R reads it.
  Step 3 → 4:  iamc.R writes *_standardized.xlsx to iamc_format/; scenario_targets_check.R reads it.
  Step 4 → 1:  Use gap_pct, cm_vs_ref columns to decide which XMLs need tuning.
  Step 5 → 6:  Once CM is finalized, read CM E&IP to compute MTC constraint values.

Notes:
  - iamc.R requests c('Pakistan','China') from gcamreport (needs >=2 regions),
    then post-filters to Pakistan only before writing to iamc_format/.
  - scenario_targets_check.R auto-detects scenarios in the xlsx and computes
    Ref→CM gap-change when both Reference and CurrentMeasures are present.
  - NDC targets (defined as fractions of CM) are auto-resolved when CM is in the data.
  - Output version controlled by OUTPUT_VERSION constant at top of scenario_targets_check.R.
  - Constraint XMLs use placeholder values from CM iteration 1. Update after tuned CM run.
```

---

## Key Technical Notes

- **Share weights** are the primary tuning lever. Higher = more generation. 0 = shut off.
- **fixedOutput** (hydro only) is exogenous generation in EJ — no model coupling risk.
- **IAMC Capacity (GW)** uses gcamreport's blended CFs — unreliable for comparison. Use generation (EJ/GWa).
- **Capacity Additions** in IAMC is annualized (total_new_vintage / 5yr). MESSAGE target may mean total.
- **Nuclear baseline** drops share-weight from 1.0 to 0.075 by 2035 — this is why Ref underproduces nuclear.
- **Model solving priority**: if CM fails, remove add-ons bottom-up (cm_06 → cm_05 → ... → cm_01).
- **Interpolation rules `delete="1"`**: ALL-OR-NOTHING — clears the entire interpolation rule vector, then adds the tagged rule (C++ source: `subsector.cpp:126-146`). Use ONE `delete="1"` per subsector. Best practice: use explicit share-weight values with `fillout="1"` instead.
- **Model years**: 1975, 1990, 2005, 2010, 2015, 2020, 2025, 2030, ..., 2100 (5yr steps after 2020). Defined in `input/gcamdata/R/constants.R`.
- **EV scope mismatch**: GCAM LDV|Electricity includes 2W/3W (e-rickshaws). MESSAGE target likely 4W only.
- **GCAM debug skill**: `.claude/skills/gcam-debug.md` — project-agnostic debug reference.

---

## CM Scenario Gap Summary (Reference vs. Current Measures Targets)

| Target | GCAM Ref | CM Target | Gap | Module |
|--------|----------|-----------|-----|--------|
| Gas gen (GWa) | 6.86 | 4.96 | +38% OVER | cm_05 |
| Coal gen (GWa) | 4.03 | 2.35 | +72% OVER | cm_05 |
| Oil gen (GWa) | 1.94 | 0.34 | +469% OVER | cm_05 |
| Hydro gen (GWa) | 3.97 | 4.56 | -13% UNDER | cm_01 |
| Nuclear gen (GWa) | 1.70 | 2.64 | -36% UNDER | cm_04 |
| Wind gen (GWa) | 0.76 | 0.45 | +68% OVER | cm_03 |
| Solar cap (GW) | 5.2 impl | 28.27 | -82% UNDER | cm_02 |
| Bio gen (GWa) | 0.06 | 0.08 | -26% UNDER | cm_06 |
