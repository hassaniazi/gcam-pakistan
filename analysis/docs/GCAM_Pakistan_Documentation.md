# GCAM-Pakistan Inter-Model Comparison Study: Complete Technical Documentation

**Project:** Multi-Model Comparison of Pakistan's Energy-Climate Pathways  
**Models:** GCAM 8.5 (Pakistan Region) vs MESSAGEix-Pakistan  
**Team:** Hassan Niazi (GCAM, LUMS/PNNL), Arfa Yaseen (MESSAGEix), Muhammad Awais (Coordinator)  
**Date:** April 2026  
**Target:** Special issue submission, April 30, 2026 deadline

---

## Table of Contents

1. [Study Overview and Motivation](#1-study-overview-and-motivation)
2. [Model Descriptions](#2-model-descriptions)
3. [Scenario Design and Harmonization](#3-scenario-design-and-harmonization)
4. [GCAM Technical Implementation](#4-gcam-technical-implementation)
5. [Current Measures (CM) Scenario — In Depth](#5-current-measures-cm-scenario--in-depth)
6. [NDC and Net Zero Scenarios — Emission Constraints](#6-ndc-and-net-zero-scenarios--emission-constraints)
7. [Carbon Trading Modes: UCT vs FFICT](#7-carbon-trading-modes-uct-vs-ffict)
8. [Key Results: GCAM Scenarios](#8-key-results-gcam-scenarios)
9. [Inter-Model Comparison: GCAM vs MESSAGEix](#9-inter-model-comparison-gcam-vs-messageix)
10. [Transport Sector Deep Dive](#10-transport-sector-deep-dive)
11. [Technical Caveats and Known Limitations](#11-technical-caveats-and-known-limitations)
12. [Workspace Architecture and Reproducibility](#12-workspace-architecture-and-reproducibility)
13. [File Inventory](#13-file-inventory)
14. [Glossary](#14-glossary)

---

## 1. Study Overview and Motivation

This study compares energy-climate pathways for Pakistan using two independent Integrated Assessment Models (IAMs): GCAM and MESSAGEix. The comparison uses **harmonized scenario assumptions** — identical policy targets, capacity pipelines, and emission reduction fractions — to isolate differences attributable to model structure rather than input assumptions.

Pakistan is a compelling case for IAM comparison because:
- It is a large developing economy (~230 million people) with rapidly growing energy demand
- Its energy system is in transition: heavy fossil fuel reliance (gas, oil, coal) alongside aggressive renewable targets
- Pakistan's NDC under the Paris Agreement includes both unconditional and conditional pledges
- The country is pursuing ambitious electrification targets, particularly in transport (NEV Policy 2025-2030)
- Large planned hydro and nuclear capacity additions create structural shifts in generation mix

The harmonized approach allows the research community to understand:
- How different model structures (optimization vs market equilibrium) represent Pakistan's energy system
- Where models converge (robust findings) and where they diverge (structural uncertainty)
- How sensitive Pakistan's emissions trajectory is to policy ambition levels
- What the implied carbon prices and technology trade-offs are under different scenarios

---

## 2. Model Descriptions

### 2.1 GCAM (Global Change Analysis Model)

- **Version:** GCAM 8.5 (labeled "GCAM 8.6" in outputs for journal convention)
- **Type:** Recursive dynamic partial-equilibrium model
- **Temporal resolution:** 5-year timesteps (2025, 2030, 2035, ..., 2100)
- **Spatial resolution:** 32 global regions; Pakistan is Region ID 22
- **Pakistan-specific customizations:**
  - GDP data substituted from India trajectory (adjusted for Pakistan's economic outlook)
  - Pork exclusion from food demand system (cultural/religious)
  - Fertilizer consumption scaling for agricultural sector
  - Renewable capacity factors from Pakistan-specific data in `electricity_water.xml`

**Electricity sector mechanism:** Technologies compete via a **logit market share** function. Each technology's share is determined by its cost competitiveness and an exogenous **share-weight** parameter that represents non-cost barriers, policy preferences, and market dynamics. Higher share-weight = larger market share for a given cost. Hydro is modeled as **fixedOutput** (exogenous generation in EJ) since dam output depends on water availability, not market competition.

**Emissions mechanism:** CO2 emissions are endogenous — they emerge from fossil fuel consumption across all sectors. Policy scenarios impose **emission constraints** (in MTC = million tonnes carbon) via `<ghgpolicy>` elements. GCAM solves for the carbon price that achieves the constraint.

### 2.2 MESSAGEix

- **Type:** Linear programming optimization model
- **Coverage:** Pakistan-specific build by Arfa Yaseen
- **Key difference:** MESSAGEix minimizes total system cost subject to constraints, while GCAM simulates market behavior via share-weight competition. This fundamental difference drives many of the structural divergences in results.

---

## 3. Scenario Design and Harmonization

Five harmonized scenarios were designed collaboratively. The scenarios are layered: each builds on the one before.

### 3.1 Reference (Baseline)

**Meaning:** No new policies beyond what was in place as of the GCAM base year (2021). The economy and energy system evolve according to default GCAM assumptions (GDP growth, population, technology costs, resource availability).

**Purpose:** Counterfactual baseline. "What would happen if Pakistan did nothing new?"

**GCAM implementation:** Unmodified GCAM 8.5 for Pakistan. No add-on XMLs.

### 3.2 Current Measures (CM)

**Meaning:** All policies and infrastructure projects that are currently committed, funded, or under construction as of 2025. This includes IGCEP (Indicative Generation Capacity Expansion Plan) projects, the NEV Policy, and committed CPEC energy investments.

**Purpose:** "Where is Pakistan heading with existing commitments?" This is the central scenario for the inter-model comparison. Both GCAM and MESSAGEix implement the same CM targets.

**Harmonized targets (from `scenarios_lums.csv`):**

| Technology | 2025 Hard Bound | 2030 Minimum Additions | Notes |
|---|---|---|---|
| Hydro | 10.635 GW / 4.555 GWa | +5.96 GW (Diamer-Basha, Dasu) | fixedOutput in EJ in GCAM |
| Wind | 1.845 GW / 0.45 GWa | +0.436 GW | Share-weight |
| Solar | 28.27 GW (rooftop boom) | +2.674 GW | Share-weight |
| Nuclear | 3.262 GW / 2.643 GWa | — | 2035: +1.1 GW (C-5) |
| Biomass | 0.278 GW / 0.083 GWa | — | Share-weight |
| Gas | 4.955 GWa | — | Reduced share-weight (bridge fuel) |
| Coal | 2.345 GWa | — | Reduced share-weight (CPEC, no new) |
| Oil/RFO | 0.341 GWa | — | Reduced share-weight |
| EVs | 0.008 GWa (4W only) | 0.33 GWa total by 2030 | NEV Policy targets |

**Important:** All minimum bounds for wind, solar, nuclear, hydro, and EVs are extended to the last model year (2100), meaning committed capacity is never retired below the minimum.

### 3.3 NDC Unconditional

**Meaning:** Pakistan's unconditional NDC pledge under the Paris Agreement — emission reductions that Pakistan commits to achieving regardless of international support.

**Implementation:** CO2 E&IP emissions constrained to **85% of CM at 2030** and **83% of CM at 2035+**.

**Formula:** `constraint_MTC = multiplier × CM_EIP_MtCO2 × (12/44)`

With CM v1 values:
- 2030: 0.85 × 288.99 × 12/44 = **66.994 MTC** (= 245.6 Mt CO2)
- 2035+: 0.83 × 343.39 × 12/44 = **77.730 MTC** (= 284.8 Mt CO2)

### 3.4 NDC Conditional

**Meaning:** Pakistan's conditional NDC pledge — more ambitious reductions contingent on international financial and technical support.

**Implementation:** CO2 E&IP emissions constrained to **50% of CM at 2030** and **50% of CM at 2035+**.

- 2030: 0.50 × 288.99 × 12/44 = **39.408 MTC** (= 144.5 Mt CO2)
- 2035+: 0.50 × 343.39 × 12/44 = **46.826 MTC** (= 171.7 Mt CO2)

**Policy implication:** This is a very aggressive target. Achieving it would require massive investment, technology transfer, and likely significant imported clean energy technology. The implied carbon price from GCAM reveals the cost of this ambition.

### 3.5 Net Zero

**Meaning:** Pakistan achieves net-zero CO2 emissions from energy and industrial processes by 2050.

**Implementation:** Linear decline from CM 2025 E&IP to zero at 2050, held at zero through 2100.

- Starting point: 241.26 Mt CO2 (2025) → 65.799 MTC
- Linear 5-step decline:
  - 2030: 0.80 × 65.799 = **52.639 MTC**
  - 2035: 0.60 × 65.799 = **39.480 MTC**
  - 2040: 0.40 × 65.799 = **26.320 MTC**
  - 2045: 0.20 × 65.799 = **13.160 MTC**
  - 2050: **0 MTC**
  - 2055–2100: **0 MTC**

**Policy implication:** Net Zero by 2050 for a developing economy like Pakistan is extremely ambitious. This scenario stress-tests the model and reveals the theoretical limits of decarbonization within Pakistan's economic and technological constraints.

### 3.6 Constraint Variants

Three variants were generated for each policy scenario to test sensitivity to how the constraint evolves over time:

1. **Flat-hold (v1):** Constraint locks at the 2035 value and holds flat through 2100. This is the "NDC target met once and maintained" interpretation.

2. **Time-series constant (ts_const):** The multiplier (e.g., 0.83 for NDCU) is applied to each period's CM value separately. Since CM emissions grow over time, the absolute cap also grows — but always at the same percentage below CM. More permissive than flat-hold in later years.

3. **Time-series declining (ts_decl):** The multiplier itself tightens over time (e.g., NDCU goes from 0.85 → 0.83 → 0.80 → 0.77 → 0.75). More ambitious long-term than either flat or ts_const.

---

## 4. GCAM Technical Implementation

### 4.1 Implementation Philosophy: Add-on XMLs

All scenario modifications use **add-on XML files** loaded via `<ScenarioComponent>` entries in configuration files. No changes were made to the GCAM R data system, CSVs, or base XMLs. This approach was chosen for:

- **Speed:** No data system rebuild required (saves ~30 minutes per change)
- **Transparency:** Each XML file documents exactly what it changes
- **Reversibility:** Scenarios can be composed by including/excluding XMLs
- **Traceability:** Every numeric value can be traced to source data

### 4.2 Add-on XML Architecture

Each scenario is implemented as a layered stack of XML modifications:

```
Reference (base GCAM)
  + cm_01_hydro_v1.xml        → fixedOutput for Pakistan hydro generation
  + cm_02_solar_v1.xml         → solar share-weight (SW=2.5)
  + cm_03_wind_v1.xml          → wind share-weight (SW=0.45→1.0)
  + cm_04_nuclear_v1.xml       → nuclear share-weight (SW=1.8→0.8)
  + cm_05_fossils_v1.xml → coal/gas/oil share-weight reductions
  + cm_06_bio_v1.xml           → biomass share-weight (SW=2.5)
  + cm_07_ev_v1.xml            → EV/BEV share-weights across transport modes
  = Current Measures (CM) scenario

  CM + pak_co2_constraint_ndc_uncond_v1.xml + pak_co2luc_uct.xml = NDC Unconditional (UCT)
  CM + pak_co2_constraint_ndc_cond_v1.xml   + pak_co2luc_uct.xml = NDC Conditional (UCT)
  CM + pak_co2_constraint_netzero_v1.xml    + pak_co2luc_uct.xml = Net Zero (UCT)
```

### 4.3 Current Measures Add-on Details

#### cm_01_hydro_v1.xml — Hydroelectric Generation
Hydro is modeled via `fixedOutput` (exogenous generation in EJ), not share-weight competition. The v1 trajectory reflects Pakistan's planned mega-projects:

| Year | fixedOutput (EJ) | Implied GWa | Notes |
|---|---|---|---|
| 2025 | 0.1437 | 4.55 | Matches current operational capacity |
| 2030 | 0.1550 | 4.91 | +Tarbela 5th Extension online |
| 2035 | 0.1750 | 5.55 | +Dasu Phase 1 (~2.1 GW) |
| 2040 | 0.1900 | 6.02 | +Diamer-Basha (~4.5 GW partial) |
| 2045 | 0.1940 | 6.15 | Near plateau |
| 2050 | 0.1940 | 6.15 | Plateau (no further major sites) |
| 2055–2100 | 0.197–0.224 | Gradual +3 EJ/5yr | Marginal small hydro |

#### cm_02_solar_v1.xml — Solar Generation
- Share-weight: **2.5** (2025–2040+, fillout)
- v0 had SW=3.5 which produced 1,149 PJ by 2050 — unrealistically high given grid absorption limits
- v1 reduces to 2.5 targeting 700–900 PJ by 2050
- Reflects Pakistan's consumer-led rooftop solar boom (28.27 GW by 2025 per NEPRA data) but acknowledges grid integration constraints

#### cm_03_wind_v1.xml — Wind Generation
- Share-weight: 0.45 (2025) → 0.6 (2030) → 0.8 (2035) → 1.0 (2040+, fillout)
- Unchanged from v0 — wind tuning was already reasonable
- Wind is a smaller contributor than solar in Pakistan; Sindh corridor is the main wind resource area

#### cm_04_nuclear_v1.xml — Nuclear Generation
- Share-weight: 1.8 (2025) → 1.5 (2030) → 1.2 (2035) → 1.0 (2040) → 0.8 (2050+)
- v0 had SW=2.5 producing 295 PJ by 2050 (~41 GW — implausible)
- v1 targets ~150–200 PJ by 2050 (~5–6 GWa), reflecting realistic pipeline:
  - Operational: K-2, K-3 (2.2 GW), Chashma C-1 to C-4 (1.3 GW) = ~3.5 GW
  - Under discussion: C-5 (1.1 GW), possibly 1–2 more Chinese units
  - Realistic CM ceiling: ~6–8 GW by 2050
- GCAM baseline suppresses nuclear SW from 1.0 down to 0.075 by 2035, so values >1 are needed just to maintain current share

#### cm_05_fossils_v1.xml — Fossil Fuel Reduction
Reduces share-weights for coal, gas, and oil to reflect the phase-down in new fossil capacity:

| Fuel | 2025 SW | 2050 SW | v0 comparison | Rationale |
|---|---|---|---|---|
| Coal | 0.50 | 0.35 | v0 was 0.35→0.10 (too aggressive) | CPEC coal committed but no new builds |
| Gas | 0.65 | 0.45 | v0 was 0.55→0.30 | Gas remains key bridge fuel (LNG terminals) |
| Oil/RFO | 0.06 | 0.03 | v0 was 0.04→0.01 | Oil/RFO already declining |

v0 was too aggressive and caused coal/gas to undershoot current infrastructure commitments. v1 moderates the reduction.

#### cm_06_bio_v1.xml — Biomass Generation
- Share-weight: **2.5** (2025–2040+, fillout)
- Unchanged from v0; biomass is a small sector, underperforming even with SW=2.5 (49 PJ vs 83 PJ target)
- Crowded out by solar/wind boost; high SW partially compensates

#### cm_07_ev_v1.xml — Electric Vehicle Policy
Implements Pakistan's NEV (New Energy Vehicle) Policy 2025-2030 across all transport subsectors:

| Category | Representative Vehicle | 2030 Target | GCAM BEV Share-Weight |
|---|---|---|---|
| 2W/3W | e-bikes, e-rickshaws | 50% new sales | 2.0→5.0 (2030)→8.0 (2040+) |
| 4W (Car, Mini, Large) | Electric cars | 30% new sales | 1.0→4.0 (2030)→7.0 (2040+) |
| Bus | Electric transit | 50% new sales | 1.0→4.0 (2030)→7.0 (2040+) |
| Light truck (freight) | Electric delivery | 30% new sales | 0.5→3.0 (2030)→5.0 (2040+) |

**Important scope note:** GCAM's `Final Energy|Transportation|LDV|Electricity` includes 2W/3W (e-rickshaws), which dominate Pakistan's NEV numbers (2.05M of 2.21M total target by 2030). MESSAGEix's EV target of 0.008 GWa likely covers 4W only.

### 4.4 Iteration History (v0 → v1 → v2)

- **v0 (initial):** First calibration attempt. Solar too high (SW=3.5), nuclear too high (SW=2.5), fossil reduction too aggressive. Results diverged significantly from targets.
- **v1 (current working version):** Moderated all share-weights based on v0 results. Solar 3.5→2.5, nuclear 2.5→1.8, fossil less aggressive. This is the version used for all 6 scenario runs in the final output.
- **v2 (transport enhancement, NOT YET RUN):** Added ICE suppression in transport (`cm_07_ev_v2.xml`) to address the persistent transport electrification gap vs MESSAGEix. Also includes `cm_02_solar_v2.xml` and `cm_05_fossils_v2.xml` with further tuning.

---

## 5. Current Measures (CM) Scenario — In Depth

### 5.1 CM v1 Emission Trajectory

The CM v1 scenario (named `CurrentMeasuresRev` in outputs) produces the following E&IP CO2 trajectory:

| Year | E&IP CO2 (Mt CO2/yr) |
|---|---|
| 2025 | 241.3 |
| 2030 | 289.0 |
| 2035 | 343.4 |
| 2040 | 414.0 |
| 2045 | 504.0 |
| 2050 | 596.0 |

This is the baseline from which all NDC and Net Zero constraints are derived. Emissions grow because Pakistan's economy and energy demand are growing faster than clean energy deployment can offset fossil fuel consumption.

### 5.2 Reference vs CM Comparison

Key differences between Reference and CM scenarios:

- **Hydro:** Reference has hydro at 3.97 GWa (below 4.56 target); CM forces it to 4.55 GWa via fixedOutput
- **Solar/Wind:** CM significantly boosts renewables via higher share-weights
- **Fossil fuels:** Reference over-produces coal (+72%), gas (+38%), and oil (+469%) relative to CM targets; CM share-weight reductions bring these down
- **Nuclear:** Reference underproduces nuclear (-36%); CM share-weight boost partially corrects
- **Transport:** CM introduces EV policy targets; Reference has minimal electrification

---

## 6. NDC and Net Zero Scenarios — Emission Constraints

### 6.1 Constraint Generation Process

All emission constraint XMLs were **programmatically generated** from CM v1 output using `analysis/generate_emission_constraints_v1.R`. This ensures:

1. Full traceability: every constraint value links back to the CM baseline
2. Consistency: no manual transcription errors
3. Reproducibility: re-running the script with updated CM output regenerates all constraints

The script also generates a **traceability CSV** (`emission_constraints_v1_all_trace.csv`) with columns: scenario, year, CM E&IP value, multiplier, constraint in MTC, and constraint in Mt CO2.

### 6.2 How GCAM Implements Emission Constraints

GCAM's emission constraint mechanism works as follows:

1. A `<ghgpolicy name="CO2">` element defines the constraint in MTC per year
2. The `<market>Pakistan</market>` tag ensures the constraint is Pakistan-specific (not global)
3. GCAM's solver finds the **carbon price** ($/tC) that makes the constraint bind
4. This carbon price is applied to all CO2-emitting activities, making them more expensive
5. The model then re-optimizes all sector choices — electricity generation, fuel switching, transport mode, industrial processes — to achieve the target

### 6.3 The CO2-LUC Linkage: UCT vs FFICT

A critical design choice is whether agriculture/forestry/land-use (AFOLU) CO2 counts toward the constraint:

- **UCT (Universal Carbon Tax/Trading):** AFOLU CO2 counts. Since Pakistan's AFOLU sector is a net CO2 **sink** (~11–18 Mt/yr), the energy+industry sector can emit slightly more than the constraint because the AFOLU sink provides offset.
  - Scenario name suffix: `_EnergyAg`
  - Uses: `pak_co2luc_uct.xml` (price-adjust=1.0, demand-adjust=1.0)

- **FFICT (Fossil Fuel & Industrial Carbon Tax):** AFOLU CO2 excluded. The constraint applies only to energy and industrial CO2. No offset from land-use.
  - Scenario name suffix: `_EnergyOnly`
  - Uses: `pak_co2luc_ffict.xml` (price-adjust=0.0, demand-adjust=0.0)

**WARNING:** The CO2-LUC XML must be loaded **AFTER** the ghgpolicy constraint XML in the configuration file.

---

## 7. Carbon Trading Modes: UCT vs FFICT

For this study, the **6 scenarios run** in the final output (`gcam_output_iamc_all_standardized.xlsx`) use **UCT mode** (EnergyAg):

1. Reference
2. CurrentMeasures (v0)
3. CurrentMeasuresRev (v1 = CM)
4. NDCCond_EnergyAg
5. NDCUncond_EnergyAg
6. NetZero_EnergyAg

FFICT configs were also generated but serve as sensitivity variants. The key difference in results: UCT scenarios have slightly higher allowed E&IP emissions (offset by the AFOLU sink), so they produce lower carbon prices for the same constraint.

---

## 8. Key Results: GCAM Scenarios

### 8.1 Emissions Trajectories (CO2 E&IP, Mt CO2/yr)

| Year | Reference | CM (v1) | NDCU | NDCC | Net Zero |
|---|---|---|---|---|---|
| 2025 | 249.9 | 241.3 | ~241 | ~241 | ~241 |
| 2030 | 306.3 | 289.0 | 245.6 | 144.5 | ~193 |
| 2035 | 372.0 | 343.4 | 284.8 | 171.7 | ~119 |
| 2040 | — | 414.0 | ~285 | ~172 | ~65 |
| 2045 | — | 504.0 | ~285 | ~172 | ~16 |
| 2050 | — | 596.0 | ~285 | ~172 | 0 |

- **NDC Unconditional** reduces 2030 emissions by ~15% relative to CM, then holds at ~285 Mt CO2 through 2100
- **NDC Conditional** achieves a dramatic ~50% cut from CM levels — roughly halving Pakistan's emissions trajectory
- **Net Zero** reaches zero E&IP CO2 by 2050 — the most extreme transformation scenario

### 8.2 Electricity Generation Mix Evolution

Under CM v1, the electricity mix evolves from fossil-dominated to renewable-led:
- **Solar:** Grows from a small share in 2025 to the single largest generation source by 2050, reflecting Pakistan's massive rooftop solar boom
- **Hydro:** Steady growth as mega-projects (Dasu, Diamer-Basha) come online
- **Gas:** Declines as share-weights reduce and renewables become cheaper
- **Coal:** Gradual phase-out from CPEC plants reaching end-of-life
- **Nuclear:** Modest growth reflecting committed Chinese-built reactors

Under policy scenarios, the model further suppresses fossil fuels and accelerates clean energy to meet the constraint.

---

## 9. Inter-Model Comparison: GCAM vs MESSAGEix

### 9.1 Methodology

The comparison uses the IAMC standard reporting format. GCAM outputs are converted to PJ/yr (from EJ/yr) to match MESSAGEix units. Both models report for Pakistan at 5-year intervals (2025–2050). All comparisons reference the **Current Measures** scenario as the baseline.

The detailed comparison is in `analysis/query/iamc_format/msg_gcam_comparison_all.xlsx` with difference and percentage-difference columns.

### 9.2 Areas of Convergence (Where Models Agree)

**Total electricity generation trajectory:** Both models broadly agree on Pakistan's total electricity output growth trajectory, reflecting shared assumptions about GDP growth and electrification.

**Hydro generation:** Both models treat hydro as largely capacity-constrained. Given the same planned projects, hydro output is similar.

**Nuclear trajectory:** Both models project modest nuclear growth, limited by the known pipeline of Chinese-built reactors.

**Coal phase-down direction:** Both models agree coal loses market share over time — the direction is the same even if the pace differs.

### 9.3 Key Divergences and Their Causes

#### 9.3.1 Transport Electrification — The Largest Gap

**Finding:** GCAM produces ~246 PJ transport electricity by 2050; MESSAGEix produces ~652 PJ. This is a **2.65x difference** and the single largest inter-model discrepancy.

**Why this happens:**
1. **Scope mismatch:** GCAM's transport electrification includes 2W/3W vehicles (e-rickshaws, e-bikes) which are energy-efficient; MESSAGEix may model transport differently
2. **Model structure:** GCAM uses share-weight competition where ICE vehicles have embedded capital stock and consumer preference inertia; MESSAGEix as an optimization model can more aggressively switch to EVs if they are cost-optimal
3. **Technology representation:** GCAM has detailed vintage tracking — existing ICE fleet continues operating until retirement; MESSAGEix may allow faster fleet turnover
4. **Charging infrastructure:** GCAM doesn't explicitly model grid constraints on EV charging; the share-weight approach may not capture the full policy push

**v2 (not yet run)** attempts to address this gap by adding ICE suppression share-weights alongside the BEV boost.

> **Real-world implication:** The true electrification trajectory likely falls between the models. Pakistan's grid infrastructure is a binding constraint that neither model fully captures — rolling blackouts and load shedding limit the pace of EV adoption regardless of policy targets.

#### 9.3.2 Solar Generation Scale

GCAM projects aggressive solar growth, potentially exceeding MESSAGEix. This reflects GCAM's share-weight mechanism responding to Pakistan's real-world rooftop solar surge (28+ GW by 2025 — one of the fastest deployments globally), but the absolute numbers require careful interpretation given grid absorption limits.

#### 9.3.3 Gas as Bridge Fuel

GCAM tends to keep gas as a significant bridge fuel longer than MESSAGEix. This is because:
- GCAM's logit competition preserves existing capital stock (LNG terminals, gas plants)
- MESSAGEix can more abruptly switch away from gas if renewables are cheaper
- Pakistan's gas sector involves long-term take-or-pay LNG contracts that create economic inertia GCAM partially captures through share-weights

#### 9.3.4 Fossil Fuel Emissions

GCAM generally projects higher fossil fuel emissions than MESSAGEix in near-term periods (2025–2035). This reflects:
- GCAM's Reference scenario significantly over-produces coal (+72%) and gas (+38%) relative to reality
- Even with CM share-weight reductions, the inertia of the logit system slows transitions
- MESSAGEix, as an optimizer, can achieve target mixes more rapidly

#### 9.3.5 Primary Energy Mix

At 2050, the primary energy comparison reveals structural differences:
- GCAM tends to maintain a larger fossil fuel footprint in primary energy even when electricity generation has shifted
- This is because GCAM captures non-electricity fossil uses (industrial heat, feedstocks) that respond more slowly to carbon pricing
- MESSAGEix may have different industrial sector representation

### 9.4 Interpreting the Differences

The GCAM-MESSAGEix differences are **not** model errors — they represent genuine structural uncertainty in how Pakistan's energy system will evolve. Key findings:

1. **Where you see convergence, the finding is robust.** Both models agreeing on a trend (e.g., coal phase-down, solar dominance) strengthens confidence.

2. **Where you see divergence, look for the structural cause.** Transport is the biggest gap, driven by model architecture (logit competition vs cost optimization), not input mismatch.

3. **The range between models is policy-relevant.** Telling policymakers "transport electrification will deliver 246–652 PJ by 2050" is more honest than either point estimate.

4. **Optimization models (MESSAGEix) tend to be more responsive** to cost signals and policy levers. Market equilibrium models (GCAM) tend to show more inertia and path dependence. Both are valid representations of different aspects of the real system.

---

## 10. Transport Sector Deep Dive

Transport electrification deserves special attention because:

1. It is Pakistan's most ambitious policy target (NEV Policy 2025-2030)
2. It shows the largest inter-model divergence
3. It has major implications for grid planning and investment

### 10.1 Pakistan's NEV Policy Targets

| Category | 2030 Fleet Target | 2030 Sales Share | 2040 Sales Share |
|---|---|---|---|
| 2W/3W | 2.05 million | 50% | 90% |
| 4-wheelers | 99,000 | 30% | 90% |
| Buses | 2,238 | 50% | 90% |
| Trucks | 2,996 | 30% | 90% |

**2W/3W dominate by volume** — e-rickshaws and e-bikes are already proliferating in Pakistani cities. The 4W market is nascent but growing from a very low base.

### 10.2 GCAM Implementation

The EV add-on (`cm_07_ev_v1.xml`) modifies BEV share-weights across 4 GCAM transport supply sectors:
- `trn_pass_road_LDV_4W` (Car, Large Car and Truck, Mini Car)
- `trn_pass_road_LDV` (2W and 3W)
- `trn_pass_road` (Bus)
- `trn_freight_road` (Light truck)

**Key limitation:** GCAM share-weights are not penetration percentages. They make BEV more competitive in the logit competition, but ICE vehicles retain their embedded capital stock and consumer preference. The model's response is structurally less aggressive than a direct penetration target.

### 10.3 Persistent Transport Gap

Even with aggressive BEV share-weights in v1, GCAM produces ~246 PJ transport electricity vs MESSAGEix's ~652 PJ. This is because:

- GCAM's vintage tracking preserves the existing ICE fleet
- Share-weight competition is about new investments, not retrofitting
- The 2W/3W sector (which GCAM does electrify aggressively) is energy-efficient, so large fleet numbers translate to modest PJ
- Heavy transport (trucks, buses) has high energy density per vehicle but low BEV adoption in GCAM

**v2 approach (not yet run):** In addition to boosting BEV share-weights, v2 *suppresses* ICE share-weights to accelerate the transition. This is conceptually equivalent to a ban or phase-out policy for new ICE vehicle sales.

---

## 11. Technical Caveats and Known Limitations

### 11.1 IAMC Capacity (GW) Is NOT Real-World Installed Capacity

**Critical finding**: GCAM's IAMC `Capacity|Electricity|*` (GW) values are unreliable for real-world comparison. The reason:

`gcamreport` (the R package that converts GCAM output to IAMC format) divides total generation by a **3-layer blended capacity factor** system:
1. Global GCAM CFs (from `A23.globaltech_capacity_factor.csv`)
2. Regional overrides
3. IEA-calibrated values for existing vintages

This produces absurd values: e.g., Gas shows 274 GW, Oil shows 178 GW capacity for Pakistan.

**Rule:** Always compare using generation (GWa or EJ), which is the raw GCAM output. For capacity GW comparisons, back-calculate from generation using the **source model CFs**:

| Technology | Source | Capacity Factor |
|---|---|---|
| Coal | A23.globaltech_capacity_factor.csv | 0.85 |
| Gas CC | A23.globaltech_capacity_factor.csv | 0.85 |
| Gas steam | A23.globaltech_capacity_factor.csv | 0.80 |
| Oil | A23.globaltech_capacity_factor.csv | 0.80 |
| Nuclear | A23.globaltech_capacity_factor.csv | 0.90 |
| Biomass | A23.globaltech_capacity_factor.csv | 0.85 |
| Wind | electricity_water.xml (Pakistan) | 0.35 |
| Solar PV | electricity_water.xml (Pakistan) | 0.2596 |
| CSP | electricity_water.xml (Pakistan) | 0.2671 |
| Hydro | fixedOutput (no CF; exogenous) | N/A |

**Note:** gcamreport's L223 mapping has Pakistan wind CF = 0.43, which differs from the model XML (0.35). Use the XML value for consistency.

### 11.2 EV Scope Mismatch Between Models

GCAM's `Final Energy|Transportation|LDV|Electricity` includes 2W/3W (e-rickshaws). MESSAGEix's EV target of 0.008 GWa likely covers 4W only. This creates an apples-to-oranges comparison in transport electrification unless both models' scopes are explicitly harmonized.

### 11.3 Solver Sensitivity

- **Net Zero at 2050 (constraint=0):** Very aggressive. If the solver fails, fallback options include:
  1. Setting 2050 to 1.0 MTC (= 3.67 Mt CO2, near-zero but not mathematical zero)
  2. Pushing zero to 2060 and setting 2050 = 6.58 MTC (10% of 2025)
- **NDC Conditional (50% cut):** Also aggressive and may produce very high carbon prices
- **Share-weight interactions:** Boosting renewables while suppressing fossils can create solver instabilities if the total electricity supply becomes insufficient. The v1 calibration was designed to avoid this.

### 11.4 Unit Conventions

| Quantity | GCAM Internal | IAMC Output | Conversion |
|---|---|---|---|
| Generation | EJ | EJ/yr or PJ/yr | 1 EJ = 1000 PJ |
| Capacity | GWa (effective) | GW (nameplate) | GW = GWa / CF |
| Emissions (constraint) | MTC | Mt CO2/yr | Mt CO2 = MTC × 44/12 |
| Time | 5-year periods | IAMC standard years | 2025, 2030, ..., 2100 |
| GWa to EJ | — | — | 1 GWa = 0.03156 EJ |

### 11.5 Pakistan-Specific Model Adjustments

GCAM's Pakistan representation inherits several global assumptions that may not perfectly suit the country:

- **GDP:** Substituted from India's trajectory (Pakistan-specific data unavailable in GCAM base data)
- **Food system:** Pork excluded (religious/cultural)
- **Fertilizer:** Scaled for Pakistan's agricultural intensity
- **Renewable CFs:** Pakistan-specific wind (0.35) and solar PV (0.2596) CFs are set in `electricity_water.xml`, reflecting local wind/solar resource quality

---

## 12. Workspace Architecture and Reproducibility

### 12.1 Directory Structure

```
gcam-pak/
├── exe/                           # Configuration files & GCAM executable
│   ├── configuration_ref.xml      # Reference scenario
│   ├── configuration_cm_v1.xml    # Current Measures v1
│   ├── configuration_{scenario}_{mode}_v1[_ts].xml  # Policy scenarios
│   └── gcam.exe                   # GCAM executable
├── input/
│   ├── gcamdata/                  # R data system (not modified)
│   │   ├── inst/extdata/          # Source CSVs
│   │   ├── R/                     # R processing chunks
│   │   └── xml/                   # Generated base XMLs
│   └── extra/
│       ├── cm/                    # Current Measures add-on XMLs (v0, v1, v2)
│       └── policy/                # Emission constraint + CO2-LUC XMLs
├── output/
│   ├── database_basexdb/          # Raw GCAM output database
│   ├── gcam_output_iamc_all_standardized.xlsx  # Final IAMC-format output (all scenarios)
│   ├── gcam_output_iamc_ref_cm_rev_standardized.xlsx  # Ref + CM v1 subset
│   └── gcam_output_iamc_*.csv/.RData  # Alternative formats
├── analysis/
│   ├── config.R                   # Shared configuration (paths, constants, theme)
│   ├── compare_msg_gcam.R         # MSG vs GCAM comparison script
│   ├── generate_emission_constraints_v1.R  # Programmatic constraint generation
│   ├── scenario_targets_check.R   # Verify scenario outputs against targets
│   ├── MESSAGEix-Pakistan_CM.xlsx # MESSAGEix CM results (from Arfa)
│   ├── query/                     # IAMC reporting pipeline
│   │   ├── iamc.R                 # gcamreport-based IAMC extraction
│   │   └── iamc_format/           # Generated comparison spreadsheets
│   └── figures/                   # Generated visualization panels
└── docs/                          # This documentation
```

### 12.2 Reproduction Steps

To reproduce all results from scratch:

```bash
# 1. Run GCAM scenarios (each takes ~20-40 min)
cd exe
./gcam.exe -C configuration_ref.xml
./gcam.exe -C configuration_cm_v1.xml
./gcam.exe -C configuration_ndc_uncond_uct_v1.xml
./gcam.exe -C configuration_ndc_cond_uct_v1.xml
./gcam.exe -C configuration_netzero_uct_v1.xml

# 2. Extract IAMC-format outputs from BaseX database
cd ../analysis
Rscript query/iamc.R

# 3. Generate comparison tables and panel figures
Rscript compare_msg_gcam.R

# 4. (Optional) Regenerate emission constraints from CM output
Rscript generate_emission_constraints_v1.R

# 5. (Optional) Check scenario targets
Rscript scenario_targets_check.R
```

### 12.3 Key Configuration Conventions

- **Scenario naming:**
  - `Reference` — unmodified GCAM
  - `CurrentMeasures` — v0 CM (deprecated)
  - `CurrentMeasuresRev` — v1 CM (current)
  - `NDCUncond_EnergyAg` — NDC Unconditional (UCT mode)
  - `NDCCond_EnergyAg` — NDC Conditional (UCT mode)
  - `NetZero_EnergyAg` — Net Zero (UCT mode)
  - `*_EnergyOnly` — FFICT mode variants

- **Color scheme (for figures):**
  - Reference: grey (#bdbdbd)
  - Current Measures: red (#c0392b)
  - NDC Unconditional: orange (#e67e22)
  - NDC Conditional: purple (#8e44ad)
  - Net Zero: green (#27ae60)
  - MESSAGEix CM: blue (#2471a3)

---

## 13. File Inventory

### 13.1 Configuration Files (exe/)

| File | Scenario | Carbon Mode | Variant |
|---|---|---|---|
| configuration_ref.xml | Reference | — | — |
| configuration_cm_v1.xml | Current Measures | — | v1 |
| configuration_ndc_uncond_uct_v1.xml | NDC Unconditional | UCT | flat |
| configuration_ndc_cond_uct_v1.xml | NDC Conditional | UCT | flat |
| configuration_netzero_uct_v1.xml | Net Zero | UCT | flat |
| configuration_ndc_uncond_ffict_v1.xml | NDC Unconditional | FFICT | flat |
| configuration_ndc_cond_ffict_v1.xml | NDC Conditional | FFICT | flat |
| configuration_netzero_ffict_v1.xml | Net Zero | FFICT | flat |
| configuration_*_v1_ts_const.xml | All policy | UCT/FFICT | ts_const |
| configuration_*_v1_ts_decl.xml | All policy | UCT/FFICT | ts_decl |

### 13.2 Add-on XMLs (input/extra/cm/)

| File | Technology | Key Parameters |
|---|---|---|
| cm_01_hydro_v1.xml | Hydro | fixedOutput: 0.144 EJ (2025) → 0.194 EJ (2050) |
| cm_02_solar_v1.xml | Solar | share-weight: 2.5 (constant) |
| cm_03_wind_v1.xml | Wind | share-weight: 0.45→1.0 |
| cm_04_nuclear_v1.xml | Nuclear | share-weight: 1.8→0.8 |
| cm_05_fossils_v1.xml | Coal/Gas/Oil | SW: Coal 0.50→0.35, Gas 0.65→0.45, Oil 0.06→0.03 |
| cm_06_bio_v1.xml | Biomass | share-weight: 2.5 (constant) |
| cm_07_ev_v1.xml | Transport EVs | BEV SW: 2W/3W up to 8.0, 4W up to 7.0 |

### 13.3 Policy XMLs (input/extra/policy/)

| File | Scenario | Type |
|---|---|---|
| pak_co2_constraint_ndc_uncond_v1.xml | NDCU | flat (67.0/77.7 MTC) |
| pak_co2_constraint_ndc_cond_v1.xml | NDCC | flat (39.4/46.8 MTC) |
| pak_co2_constraint_netzero_v1.xml | NZ | linear → 0 by 2050 |
| pak_co2_constraint_*_v1_ts_const.xml | All | time-series constant mult |
| pak_co2_constraint_*_v1_ts_decl.xml | All | time-series declining mult |
| pak_co2luc_uct.xml | All | UCT linkage (AFOLU included) |
| pak_co2luc_ffict.xml | All | FFICT linkage (AFOLU excluded) |

### 13.4 Analysis Scripts

| File | Purpose |
|---|---|
| config.R | Shared constants, paths, ggplot theme, color palettes |
| compare_msg_gcam.R | MSG vs GCAM comparison: xlsx + panel figures |
| generate_emission_constraints_v1.R | Constraint XML + config generation from CM output |
| scenario_targets_check.R | Verify scenario results against numeric targets |
| query/iamc.R | GCAM BaseX → IAMC format via gcamreport |

### 13.5 Output Files

| File | Description |
|---|---|
| gcam_output_iamc_all_standardized.xlsx | All 6 scenarios, IAMC format |
| msg_gcam_comparison_all.xlsx | Detailed variable-by-variable comparison |
| emission_constraints_v1_all_trace.csv | Full constraint traceability |
| msg_gcam_cm_panel_v2.png | CM comparison 6-panel visualization |
| msg_gcam_all_scenarios_panel_v2.png | All-scenario 6-panel visualization |

---

## 14. Glossary

| Term | Definition |
|---|---|
| **IAMC** | Integrated Assessment Modeling Consortium — standard reporting format for IAM outputs |
| **E&IP** | Energy and Industrial Processes — the scope of CO2 emissions typically covered by climate policy |
| **MTC** | Million Tonnes Carbon — GCAM's internal emission unit. Convert: Mt CO2 × 12/44 = MTC |
| **GWa** | Gigawatt-average — 1 GWa = 8760 GWh/yr = 0.03156 EJ. A unit of generation, not capacity. |
| **Share-weight** | GCAM parameter controlling technology competitiveness in the logit market share function |
| **fixedOutput** | GCAM mechanism for exogenous (non-market) generation (used for hydro) |
| **UCT** | Universal Carbon Tax/Trading — AFOLU CO2 included in the emission constraint |
| **FFICT** | Fossil Fuel and Industrial Carbon Tax — AFOLU CO2 excluded from constraint |
| **Logit** | Discrete choice model used by GCAM for technology/fuel competition |
| **Vintage** | In GCAM, a cohort of capital installed in a specific period; operates until retirement |
| **ScenarioComponent** | XML element in GCAM config that loads an add-on XML overlay |
| **fillout** | GCAM XML attribute that extends a value to all subsequent periods |
| **nocreate** | GCAM XML attribute indicating "modify existing element, don't create new" |
| **gcamreport** | R package that converts raw GCAM output to IAMC-format variables |
| **NEV Policy** | Pakistan's New Energy Vehicle Policy 2025-2030 |
| **IGCEP** | Indicative Generation Capacity Expansion Plan — Pakistan's official power sector roadmap |
| **CPEC** | China-Pakistan Economic Corridor — includes coal and other energy investments |
| **NDC** | Nationally Determined Contribution — Paris Agreement emission pledges |

---

*Document generated April 2026. For questions, contact Hassan Niazi (hniazi).*
