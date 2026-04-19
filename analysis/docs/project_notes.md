# GCAM-Pakistan Scenario Project Notes
## MESSAGE-GCAM Inter-Model Comparison for Pakistan Energy Pathways

**Last updated:** 2026-04-14
**Deadline:** April 30, 2026 (special issue)

---

## Team
| Name | Role | Model |
|------|------|-------|
| Hassan Niazi | GCAM modeler | GCAM 8.5 |
| Muhammad Awais | Lead/Coordinator | -- |
| Arfa Yaseen | MESSAGE modeler | MESSAGEix |

## Scenarios

| # | Scenario | Status | Config File | Policy XML(s) |
|---|----------|--------|-------------|---------------|
| 1 | Reference | DONE | configuration_ref.xml | (none) |
| 2 | Current Measures | TODO | configuration_cm.xml | current_measures_pak.xml |
| 3 | NDC Unconditional | TODO | configuration_ndc_unc.xml | current_measures_pak.xml + ndc_unconditional_pak.xml |
| 4 | NDC Conditional | TODO | configuration_ndc_con.xml | current_measures_pak.xml + ndc_conditional_pak.xml |
| 5 | Net Zero | TODO | configuration_nz.xml | current_measures_pak.xml + net_zero_pak.xml |

## Key Reference Numbers (GCAM Reference 2025)

Generation (GWa) - the reliable comparison metric:

| Metric | GCAM Ref (GWa) | CM Target (GWa) | Gap |
|--------|---------------|-----------------|-----|
| Gas generation | 6.86 | 4.955 | +38% over |
| Coal generation | 4.03 | 2.345 | +72% over |
| Oil/RFO generation | 1.94 | 0.341 | +469% over |
| Hydro generation | 3.97 | 4.555 | -13% under |
| Nuclear generation | 1.70 | 2.643 | -36% under |
| Wind generation | 0.76 | 0.450 | +68% over |
| Bio generation | 0.06 | 0.083 | -26% under |
| EV activity (LDV elec) | 1.18 | 0.008 | SCOPE MISMATCH |

Capacity (GW) - using GCAM model CFs from source files:

| Metric | GCAM IAMC (GW) | CM Target (GW) | Gen-implied GW | CF Source |
|--------|---------------|----------------|----------------|-----------|
| Wind capacity | 6.48 | 1.845 | 2.2 GW @ 35% CF | electricity_water.xml |
| Solar capacity | 19.79 | 28.27 | 5.2 GW @ 26% CF | electricity_water.xml |
| Nuclear capacity | 14.73 | 3.262 | 1.9 GW @ 90% CF | A23.globaltech_capacity_factor.csv |
| Bio capacity | 0.35 | 0.278 | 0.1 GW @ 85% CF | A23.globaltech_capacity_factor.csv |
| Hydro capacity | 35.33 | 10.635 | N/A (fixedOutput) | electricity_water.xml (exogenous) |

**IMPORTANT**: GCAM IAMC capacity uses gcamreport's 3-layer blended CFs, NOT the GCAM model CFs from source files. The "gen-implied" column uses GCAM model CFs: thermal/nuclear from `A23.globaltech_capacity_factor.csv`, renewables from `electricity_water.xml` (Pakistan stub). Hydro is fixedOutput (no CF).

**EV SCOPE MISMATCH**: GCAM LDV|Electricity (1.18 GWa) includes all LDV electric (2W/3W e-rickshaws, e-bikes). MESSAGE target (0.008 GWa) likely means 4-wheel passenger EVs only. Clarify with Awais/Arfa.

## Emissions (GCAM Reference, Mt CO2/yr)

| Year | CO2 (all) | CO2 E&IP | Kyoto Gases |
|------|-----------|----------|-------------|
| 2025 | 245.0 | 249.9 | 583.3 |
| 2030 | 295.2 | 306.3 | 681.8 |
| 2035 | 358.5 | 372.0 | 795.2 |

## NDC Targets (relative to Current Measures emissions)

| Scenario | 2030 | 2035 |
|----------|------|------|
| NDC Unconditional | 85% of CM | 83% of CM |
| NDC Conditional | 50% of CM | 50% of CM |

## Conversion Factors
- 1 GWa = 0.03156 EJ = 8.766 TWh
- 1 EJ = 31.71 GWa = 277.78 TWh
- 1 MTC = 3.667 Mt CO2

## Implementation Approach
**Add-on XML files** layered on top of Reference scenario via new config files.
- No R data system changes needed
- No CSV changes needed
- gcam-tuner available as fallback but skipped for simplicity

## Open Questions
1. **EV scope mismatch**: GCAM LDV|Elec includes 2W/3W, MESSAGE target likely 4W only. Clarify.
2. **Solar 28.27 GW in 2025**: Real-world Pakistan installed solar was ~2-3 GW in 2024. Is this 2025 target correct? Includes planned?
3. **Capacity GW definition**: GCAM IAMC capacity =/= real-world installed capacity. Use generation for comparison. Capacity script uses GCAM model CFs from A23.globaltech_capacity_factor.csv (thermal/nuclear) and electricity_water.xml (renewables). Note: gcamreport's L223 has Pakistan wind=0.43, but model XML has 0.35; we use the XML value.
4. Net Zero target year and pathway -- needs team discussion
5. "Energy, Waste, IPP" sector mapping in GCAM -> using `Emissions|CO2|Energy and Industrial Processes`
6. "Extend minimums to last model year" -- same absolute GW or same generation share?

## Analysis Pipeline
1. Create add-on XML + config file for scenario
2. Run GCAM: `cd exe && ./gcam.exe -C configuration_<scenario>.xml`
3. Run IAMC format: `cd analysis/gcamreport && Rscript ../query/iamc.R` (update scenario name)
4. **Run targets check**: `Rscript analysis/scenario_targets_check.R <iamc_xlsx> <scenario_name>`
5. Review `scenario_targets_<name>.csv` output and printed comparison

## File Locations
- Scenario design: `analysis/scenarios_lums.csv`
- Enriched comparison: `analysis/scenarios_lums_gcam.csv`
- Targets check script: `analysis/scenario_targets_check.R`
- Team chat: `teamchat.txt`
- Reference output: `analysis/query/iamc_format/gcam_output_iamc_standardized_share_v1.xlsx`
- Targets check output: `analysis/query/iamc_format/scenario_targets_Reference.csv`
- Query results: `analysis/query/gcam_output/*.csv`
- Policy XMLs: `input/policy/`
- GCAM configs: `exe/configuration_*.xml`
- IAMC script: `analysis/query/iamc.R`
- Full plan: `.claude/plans/scenario-implementation.md`

# Final changes
Files inside ../input/extra/cm

| File | What it does | Risk |
|------|--------------|------|
| cm_01_hydro.xml | Increase fixedOutput from 0.1252→0.1437 EJ (targets 4.555 GWa) | None — exogenous |
| cm_02_solar.xml | Boost subsector share-weight to 2.5 (2025-2050) | Low |
| cm_03_wind.xml | Reduce subsector share-weight to 0.6 (then recover to 1.0 by 2035) | Low |
| cm_04_nuclear.xml | Override baseline drop (1.0→0.075) with flat 1.5 | Medium |
| cm_05_fossil_reduce.xml | Coal→0.6, Gas→0.72, Oil→0.18 share-weights | Highest |
| cm_06_bio.xml | Small boost to 1.3 | Negligible |

# Last fine tuning exercise (after v2 results)
Here's my analysis of the v2 results and the tuning plan:

Generation 2025 (GWa) — the core comparison:

| Tech | Target | Ref | CM | Ref Gap% | CM Gap% | Verdict | Action |
|------|--------|-----|----|----------|---------|---------|--------|
| Hydro | 4.555 | 3.969 | 4.556 | -13% | +0% | CLOSED | None needed |
| Coal | 2.345 | 4.028 | 3.747 | +72% | +60% | CLOSING | More aggressive |
| Gas | 4.955 | 6.861 | 6.420 | +38% | +30% | CLOSING | More aggressive |
| Oil/RFO | 0.341 | 1.937 | 1.780 | +469% | +423% | CLOSING | Much more aggressive |
| Nuclear | 2.643 | 1.703 | 1.948 | -36% | -26% | | CLOSING | Needs bigger boost |
| Wind | 0.450 | 0.756 | 0.580 | +68% | +29% | CLOSING | Needs more reduction |
| Bio | 0.083 | 0.062 | 0.049 | -26% | -41% | WIDENING | Needs much bigger boost |
| Solar cap | 28.27 | 19.79 | 23.40 | -30% | -17% | CLOSING | Needs more boost |

Now applying aggressive tuning. The math for each:

- Coal: 0.6 → got 3.747 vs 2.345 target. Ratio: 2.345/3.747 × 0.6 = 0.375. Going 0.35.
- Gas: 0.72 → got 6.420 vs 4.955. Ratio: 4.955/6.420 × 0.72 = 0.556. Going 0.55.
- Oil: 0.18 → got 1.780 vs 0.341. Ratio: 0.341/1.780 × 0.18 = 0.034. Going 0.04.
- Nuclear: 1.5 → got 1.948 vs 2.643. Ratio: 2.643/1.948 × 1.5 = 2.035. Going 2.5 (aggressive).
- Wind: 0.6 → got 0.580 vs 0.450. Ratio: 0.450/0.580 × 0.6 = 0.466. Going 0.45.
- Bio: 1.3 → got 0.049 vs 0.083. Ratio: 0.083/0.049 × 1.3 = 2.20. Going 2.5 (aggressive to compensate for fossil crowding).
- Solar: 2.5 → capacity 23.4 vs 28.27 (-17%). Ratio: 28.27/23.4 × 2.5 = 3.02. Going 3.5 (aggressive).

# Emission scenario questions

Q: The constraint values are based on CM iteration 1 E&IP emissions (294.30 Mt at 2030). Do you want me to create the files now with these values (you can recompute after running tuned CM), or wait until after the tuned CM run to use fresh numbers?
A: Wait for tuned CM run - Run tuned CM first, extract new E&IP values, then create constraint files with exact numbers.

Q: For the Net Zero post-2035 trajectory, I proposed linear decline from CM 2025 (244.5 Mt) to 0 at 2050. Any preference?
A: Linear to 0 at 2050 (Recommended) - Simple, defensible. 20% reduction per 5-year step from 2025 baseline.

Q: For NDC post-2035, I proposed flat hold at the 2035 absolute level. Continuing the NDC fraction extrapolation would allow GROWING absolute emissions since CM grows fast. Is flat hold correct?
A: Flat hold at 2035 level (Recommended) - Pakistan meets NDC and maintains effort. Conservative and defensible.

# round 1 comparison notes
Critical divergences:

- Coal+Gas: MSG is 2.5x higher by 2050 (2,172 vs 871 PJ). Your CM fossil share-weights (coal 0.35, gas 0.55) over-suppress relative to committed CPEC/LNG projects.
- Nuclear: GCAM grows to 295 PJ by 2050 (SW=2.5 drives ~30 reactors); MSG caps at 112 PJ (4.5 GW). GCAM is geopolitically implausible.
- Solar: GCAM 1,149 vs MSG 613 PJ by 2050 — GCAM grows too fast.
- Kyoto Gases: GCAM 1,194 vs MSG 860 Mt CO2e. But GCAM's CO2 is lower — the gap is ~600 Mt of non-CO2 from agriculture that MSG doesn't model. This is the biggest risk to the paper's "below 2C" claim.
- Transport electrification: MSG 652 vs GCAM 198 PJ — GCAM needs stronger EV policy.

Recommended XML changes (Section 6 table):

| File                  | Current SW | Proposed SW | Why |
|-----------------------|------------|-------------|-----|
| cm_04_nuclear.xml     | 2.5        | 1.2→0.5     | Cap at planned plants |
| cm_05_fossil (coal)   | 0.35       | 0.55        | Too aggressively suppressed |
| cm_05_fossil (gas)    | 0.55       | 0.70        | Same |
| cm_02_solar.xml       | 3.5        | 2.0–2.5     | Outpacing MSG by 2x |
| cm_07_ev.xml          | current    | Increase significantly | 3.3x gap vs MSG |




# Transport Policy – NEV / EV Adoption Targets

## Table 2: NEV Adoption Targets (2025–2030)

| Type                | 2025-26 | 2026-27 | 2027-28 | 2028-29 | 2029-30 | Total     |
|---------------------|--------:|--------:|--------:|--------:|--------:|----------:|
| 2-Wheelers          | 116,053 | 246,728 | 393,408 | 557,590 | 740,898 | 2,054,676 |
| 3-Wheelers          |   3,171 |   6,644 |  10,442 |  14,588 |  19,106 |    53,950 |
| 4-Wheelers          |   5,947 |  12,369 |  19,296 |  26,758 |  34,785 |    99,155 |
| Buses, vans etc.    |     144 |     291 |     443 |     599 |     760 |     2,238 |
| Trucks, vans, LCVs  |     186 |     382 |     588 |     806 |   1,034 |     2,996 |
| **Total vehicles**  | **125,415** | **266,415** | **424,178** | **600,340** | **796,582** | **2,213,015** |

---

## EV Penetration Targets

| Category              | Medium Term Targets (5-years) | Long Term Targets (2030) | Ultimate Targets (2040) |
|----------------------|-------------------------------|--------------------------|--------------------------|
| Two & Three Wheelers | Target - 500,000<br>Achieved - 50,000 |                          |                          |
| Buses                | Target - 1,000<br>Achieved - 200      |                          |                          |
| Four-Wheelers        | Target - 100,000<br>Achieved - 3,000  |                          |                          |
| Trucks               | Target - 1,000<br>Achieved - <10      |                          |                          |
|                      |                                       | 50% of new sales in 2/3W and Buses<br>30% of new sales in 4W (Cars) & Trucks | 90% of all new vehicle sales |

---

## Table 1: EV Policy 2019 – EV Adoption Targets and Achieved Numbers

---

## Public Charging Infrastructure Targets

| Type                     | 2025-26 | 2026-27 | 2027-28 | 2028-29 | 2029-30 | Total |
|--------------------------|--------:|--------:|--------:|--------:|--------:|------:|
| Public Charging Stations |     240 |     380 |     550 |     800 |   1,030 | 3,000 |