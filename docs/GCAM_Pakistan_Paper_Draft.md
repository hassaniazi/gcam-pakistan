# Paper Draft Skeleton: Inter-Model Comparison of Pakistan's Energy-Climate Pathways

---

## Proposed Title

**Structural Uncertainty in Pakistan's Decarbonization Pathways: A GCAM-MESSAGEix Inter-Model Comparison Under Harmonized Policy Scenarios**

Alternative titles:
- *How Model Architecture Shapes Climate Policy Insights: Pakistan's Energy Transition Through Two IAM Lenses*
- *From Current Measures to Net Zero: Comparing Market-Equilibrium and Optimization Perspectives on Pakistan's Energy Future*

---

## Abstract (~250 words)

Pakistan faces the dual challenge of rapidly expanding energy access for 230 million people while meeting increasingly ambitious climate commitments under the Paris Agreement. We present a systematic inter-model comparison of Pakistan's energy-climate pathways using two structurally distinct integrated assessment models — GCAM (recursive dynamic partial equilibrium) and MESSAGEix (linear optimization) — under five harmonized scenarios spanning current policy commitments through net-zero emissions by 2050. Both models share identical scenario assumptions: committed infrastructure projects from Pakistan's IGCEP, the New Energy Vehicle Policy 2025-2030, and NDC emission reduction targets (15-50% below current measures by 2030-2035). We find robust agreement on several macro-level outcomes: coal's declining role in electricity generation, solar energy emerging as the dominant generation source by mid-century, and total system emissions exceeding 500 Mt CO2/yr by 2050 under current measures absent additional policy intervention. However, the models diverge substantially on transition dynamics. GCAM's logit-based market competition preserves fossil fuel infrastructure inertia — projecting 2.7x less transport electrification than MESSAGEix at 2050 (246 vs 652 PJ) — while MESSAGEix's cost-optimization framework enables faster fleet turnover when electrification is cost-competitive. The transport electrification gap represents the single largest inter-model divergence and carries direct implications for grid investment planning, charging infrastructure, and industrial policy sequencing. Under the NDC conditional scenario (50% emission reduction), both models require carbon prices that may exceed Pakistan's institutional capacity to implement, suggesting that conditional NDC targets are achievable only with substantial international financial support — consistent with the intent of conditional pledges under the Paris framework.

---

## 1. Introduction

### Opening paragraph — the Pakistan problem

Pakistan's energy system sits at a critical juncture. The country's 230 million inhabitants consume roughly 4,800 PJ of primary energy annually, with per-capita emissions (~1.1 tCO2) far below the global average — yet total emissions are growing at 5-7% annually, driven by economic development, urbanization, and industrialization. Pakistan's Updated NDC (2021) distinguishes between unconditional commitments (achievable domestically) and conditional targets (requiring international support), creating a layered policy landscape that integrated assessment models must represent with care. Simultaneously, Pakistan is experiencing one of the world's fastest rooftop solar deployments (~28 GW installed by 2025), a phenomenon largely driven by consumer economics rather than government policy, while major hydroelectric and nuclear capacity additions are in the pipeline under the China-Pakistan Economic Corridor (CPEC) framework.

### Why inter-model comparison matters here

Single-model studies provide point estimates of future pathways, but they embed the assumptions of their modeling framework without making those assumptions visible. A market-equilibrium model (GCAM) and a cost-optimization model (MESSAGEix) represent fundamentally different theories of how energy systems evolve. GCAM simulates market behavior through share-weight competition, preserving path dependence and capital stock inertia — it answers "what will markets do given these incentives?" MESSAGEix minimizes total system cost subject to constraints — it answers "what should an omniscient planner do?" The divergence between these answers is itself a finding: it quantifies structural uncertainty that no single model can reveal.

### What this paper contributes

This paper makes three contributions. First, we present the first harmonized multi-model comparison for Pakistan's energy system, using identical scenario assumptions across both models. Second, we decompose inter-model divergences into their structural causes — identifying which differences arise from model architecture vs. input assumptions vs. sectoral representation. Third, we translate modeling results into actionable policy insights, particularly regarding the feasibility of Pakistan's conditional NDC targets and the infrastructure investment implications of transport electrification pathways.

---

## 2. Methods

### 2.1 Model Descriptions

#### 2.1.1 GCAM

GCAM (Global Change Analysis Model, v8.5) is a recursive dynamic partial-equilibrium model developed at PNNL. For this study: 32 global regions (Pakistan = Region 22), 5-year timesteps (2025-2100), base year 2021. Electricity generation is determined by logit market share competition: technologies compete based on cost and exogenous share-weight parameters reflecting non-cost barriers (permitting, public acceptance, infrastructure availability). Hydro generation is exogenous (fixedOutput in EJ), reflecting dependence on water availability rather than market competition. Transport sector uses a nested logit structure across vehicle categories (2W/3W, 4W, bus, freight) with vintage tracking — existing ICE fleet operates until retirement, and new purchases compete via share-weight logit.

**Pakistan-specific adjustments:** GDP trajectory substituted from India (Pakistan-specific data unavailable in base GCAM), pork demand exclusion, fertilizer consumption scaling, Pakistan-specific renewable capacity factors (wind: 0.35, solar PV: 0.26 from electricity_water.xml).

#### 2.1.2 MESSAGEix

MESSAGEix is a linear programming optimization model. [Arfa to provide model description details.] Key structural difference: MESSAGEix minimizes total system cost subject to technology and emission constraints, yielding normative (cost-optimal) rather than descriptive (market-simulated) results.

### 2.2 Scenario Design and Harmonization

Five scenarios are designed with layered structure:

| Scenario | Emission Target | Basis | Scope |
|---|---|---|---|
| Reference | None | Default GCAM/MSG | Counterfactual |
| Current Measures (CM) | None (capacity targets only) | IGCEP + NEV Policy + CPEC | Committed projects |
| NDC Unconditional | 85% of CM (2030), 83% of CM (2035+) | Updated NDC (2021) | Domestic action |
| NDC Conditional | 50% of CM (2030-2035+) | Updated NDC (2021) | With int'l support |
| Net Zero | Linear to 0 by 2050 | Aspirational | Full decarbonization |

**Harmonization protocol:** Both models use the same capacity pipeline for CM (hydro: Diamer-Basha +4.5 GW, Dasu +4.3 GW; nuclear: C-5 +1.1 GW; solar: +2.67 GW; wind: +0.44 GW), the same NDC multipliers, and the same net-zero trajectory. Emission constraints are applied to CO2 from Energy and Industrial Processes (E&IP). CM capacity targets serve as 2025 hard bounds and 2030+ minimum floors, extended through 2100.

**Data source:** `scenarios_lums.csv` — jointly designed by GCAM and MESSAGEix teams. The "GCAM Share" column provides pre-calculated shares for share-weight calibration.

### 2.3 GCAM Scenario Implementation

All scenario modifications use add-on XML files overlaid on the base GCAM build. Seven CM modules adjust: (1) hydro fixedOutput, (2) solar share-weight, (3) wind share-weight, (4) nuclear share-weight, (5) fossil fuel share-weight reduction, (6) biomass share-weight, (7) transport EV share-weights. Policy scenarios add emission constraint XMLs derived programmatically from CM model output, with CO2-LUC linkage handled via UCT (universal carbon trading, AFOLU included) or FFICT (fossil fuel & industrial only). All constraint values are traceable to the CM baseline via `emission_constraints_v1_all_trace.csv`.

### 2.4 GCAM Calibration (v0-v1 Iteration)

Initial calibration (v0) was systematically compared against harmonized targets. Key findings: solar share-weight of 3.5 produced 1,149 PJ by 2050 (exceeds grid absorption limits); nuclear share-weight of 2.5 implied ~41 GW capacity (implausible); fossil reductions were too aggressive, causing coal and gas to undershoot existing CPEC infrastructure. v1 corrected: solar 3.5→2.5, nuclear 2.5→1.8 (tapered to 0.8), fossil reduction moderated (coal SW 0.50→0.35 vs v0's 0.35→0.10). v1 results form the basis of all reported scenarios.

---

## 3. Results

### 3.1 Current Measures Baseline: Both Models Agree on the Scale of the Problem

Under current measures, both models project Pakistan's E&IP CO2 emissions growing from ~240 Mt CO2/yr (2025) to ~550-600 Mt CO2/yr (2050) — a 2.5x increase driven by economic growth outpacing clean energy deployment.

**Key paragraph (polished):**

> Under the Current Measures scenario — which incorporates all committed Pakistani energy infrastructure including IGCEP capacity additions, CPEC energy projects, and the 2025 NEV Policy — GCAM projects E&IP CO2 emissions of 596 Mt CO2/yr by 2050, a 2.5-fold increase from the 2025 level of 241 Mt CO2/yr. This growth trajectory persists despite substantial renewable energy deployment (solar becomes the dominant electricity source by 2040) because demand growth in industry, transport, and buildings absorbs clean electricity gains while fossil fuels continue serving non-electric energy needs. The implication is stark: Pakistan's existing policy commitments, while substantial, are fundamentally insufficient to bend the emissions curve downward. Additional policy intervention — whether through the NDC framework or more ambitious targets — is a prerequisite for any emission stabilization, let alone reduction.

### 3.2 Electricity Generation Mix

Both models project a fundamental transformation of Pakistan's electricity supply. Solar, hydro, and nuclear emerge as the three dominant sources, displacing coal and gas. The models agree directionally but differ on pace:

- **Solar:** Both models project solar as the largest single source by 2050. GCAM's logit competition produces aggressive solar growth (share-weight 2.5, reflecting Pakistan's rooftop boom) but grid absorption limits create an effective ceiling.
- **Hydro:** Close agreement — fixedOutput in GCAM, capacity-constrained in MESSAGEix. Planned mega-projects (Diamer-Basha, Dasu) drive growth from ~144 PJ (2025) to ~194 PJ (2050).
- **Gas:** GCAM retains gas longer as a bridge fuel (SW 0.65→0.45); MESSAGEix may exit gas faster when renewables become cost-competitive. This reflects an important real-world tension: Pakistan's LNG import contracts create economic lock-in that market-equilibrium models capture but optimization models may underweight.
- **Coal:** Both project phase-down. GCAM calibration reflects CPEC-committed plants operating through their lifetime but no new construction (SW 0.50→0.35).

### 3.3 Transport Electrification: The Critical Divergence

The transport sector produces the largest inter-model gap: GCAM projects ~246 PJ of transport electricity at 2050 versus MESSAGEix's ~652 PJ — a 2.65x difference.

**Key paragraph (polished):**

> Transport electrification represents the most consequential structural divergence between models. GCAM's logit-based vehicle choice preserves the installed ICE capital stock: existing petrol and diesel vehicles continue operating through their economic lifetime, and new BEV purchases must outcompete ICE in the logit share function. This vintage-tracking mechanism introduces realistic inertia — fleet turnover is gradual because consumers cannot instantaneously swap their existing vehicles. MESSAGEix, by contrast, can more rapidly redirect investment to BEVs when they become cost-optimal, effectively modeling a planner's decision rather than a consumer's decision. Neither representation is wrong; they capture different aspects of the same transition. The policy implication is that GCAM's slower trajectory may better represent the *likely* pace of electrification under current institutional capacity, while MESSAGEix's faster trajectory represents the *achievable* pace under ideal policy execution. Pakistan's grid reliability constraints (load shedding, voltage instability) likely impose a further ceiling that neither model explicitly captures.

**Additional factor:** Scope mismatch in EV definitions. GCAM includes 2W/3W (e-rickshaws, e-bikes) in transport electrification, which provide large vehicle counts but modest energy consumption. MESSAGEix's 0.008 GWa EV target at 2025 likely reflects 4-wheelers only. The 2W/3W sector dominates Pakistan's NEV numerical targets (2.05M of 2.21M total by 2030) but contributes disproportionately less energy than 4W vehicles.

### 3.4 Emission Reduction Scenarios

#### NDC Unconditional (15-17% below CM)

Both models achieve the target, but via different mechanisms. GCAM responds to the CO2 constraint by reducing coal and gas generation and accelerating solar deployment. The implied carbon price is moderate, reflecting the modest ambition of the unconditional target. Emissions stabilize at ~285 Mt CO2/yr (2035+) under the flat-hold constraint variant.

#### NDC Conditional (50% below CM)

This is where the models most clearly reveal their structural differences. A 50% emission cut from current measures requires aggressive fuel switching, rapid electrification, and significant demand-side efficiency gains.

**Key paragraph (polished):**

> The NDC conditional scenario exposes a fundamental tension in Pakistan's climate strategy. Halving E&IP emissions relative to current measures — to approximately 145 Mt CO2/yr by 2030 — requires a pace of decarbonization that approaches European ambition levels from a starting point of far lower per-capita income, weaker institutional capacity, and more constrained fiscal space. The GCAM-implied carbon prices under this scenario are likely to exceed $50-100/tCO2, price levels that would impose significant economic costs on an economy where per-capita GDP remains below $2,000. This finding is precisely consistent with the *conditional* framing of Pakistan's NDC: the pledge is explicitly contingent on international financial and technical support, and our modeling confirms that domestic resources alone are insufficient to achieve it. The policy signal is that conditional NDC targets should be understood as statements of what is physically and technologically achievable with adequate support, not as predictions of autonomous domestic action.

#### Net Zero by 2050

The most extreme scenario. Linear decline from 241 Mt CO2 (2025) to zero by 2050.

**Key paragraph (polished):**

> Net-zero E&IP emissions by 2050 represents a theoretical boundary case for Pakistan's energy system. Achieving it requires near-complete elimination of fossil fuels from electricity, industry, and transport within 25 years — a transformation that no developing economy has demonstrated at scale. GCAM's solver produces a valid solution, but the implied carbon prices and technology deployment rates exceed any historically observed transition. We include this scenario not as a policy recommendation but as a stress test: it reveals the absolute minimum fossil fuel role in Pakistan's 2050 energy mix and identifies which sectors are the last to decarbonize (heavy industry, freight transport). These "last-to-go" sectors are where policy attention and technological innovation will have the highest marginal value.

### 3.5 Primary Energy and Trade Implications

Both models project continued energy import dependence through 2050, with the composition shifting from fossil fuels to clean energy technology and possibly green hydrogen. Coal and oil import volumes decline under all policy scenarios, but natural gas imports persist longer in GCAM (bridge fuel retention) than in MESSAGEix. This has geostrategic implications: Pakistan's LNG import dependency creates exposure to global gas price volatility that climate policy partly mitigates by reducing gas demand.

---

## 4. Discussion

### 4.1 What Convergence Tells Us: Robust Findings

When a market-equilibrium model and an optimization model agree, the finding is structurally robust because it persists across fundamentally different modeling assumptions. Robust findings from this comparison:

1. **Emissions trajectory under CM is unsustainable.** Both models project 2.5x growth by 2050. This is a robust conclusion: Pakistan's existing commitments, however substantial, do not achieve emission stabilization.

2. **Solar dominance in electricity.** Both models project solar as the leading generation source by 2040-2050. This reflects Pakistan's exceptional solar resource (>5.5 kWh/m2/day), rapidly declining PV costs, and the existing consumer-pull (28+ GW rooftop installed by 2025).

3. **Hydro's structural ceiling.** Both models agree hydro plateaus at ~6 GWa (~190 PJ) by 2045-2050, constrained by finite dam sites and environmental/social limits.

4. **Coal phase-down direction.** While the timing and pace differ, both models project coal losing electricity market share throughout the projection period.

### 4.2 What Divergence Tells Us: Structural Uncertainty

The GCAM-MESSAGEix divergences are not model errors — they are the signal. Each divergence identifies a mechanism where the real-world outcome depends on context that neither model fully captures.

**Transport electrification (2.65x gap):** The real-world pace will depend on consumer behavior (GCAM-like inertia) vs. policy push (MESSAGEix-like optimization). Pakistan's grid reliability — specifically, the ability to support widespread EV charging alongside existing load — is the binding constraint that neither model represents. A policy-relevant framing: the 246-652 PJ range defines the *infrastructure planning envelope* — grid planners should prepare for the high end while budgeting for the low end.

**Gas bridge fuel duration:** GCAM's longer gas retention reflects LNG contract lock-in and capital stock inertia. MESSAGEix's faster gas exit reflects least-cost logic. The real-world resolution depends on whether Pakistan can renegotiate or absorb take-or-pay LNG contracts — a political-economic question that models can bracket but not resolve.

**Near-term fossil emissions:** GCAM's higher near-term fossil consumption reflects market inertia. MESSAGEix's lower near-term emissions reflect optimization under full foresight. The actual trajectory likely falls between these bounds, with early-year inertia (GCAM-like) gradually yielding to planned transitions (MESSAGEix-like) as policy institutions strengthen.

### 4.3 Policy Implications for Pakistan

**For the NDC process:** The unconditional target (15% below CM) is achievable with moderate policy intervention — both models solve without difficulty. The conditional target (50% below CM) requires carbon prices that exceed Pakistan's institutional capacity to implement domestically, confirming the conditional framing's validity.

**For electricity planning:** Both models agree on the solar-hydro-nuclear trio as the backbone of future supply. Investment priorities should focus on grid modernization (solar integration, transmission from hydro sites in the north) rather than new fossil fuel capacity.

**For transport policy:** The NEV Policy's targets (50-90% EV sales share by 2030-2040) are ambitious but the models diverge on their energy-system impact. Pakistan should focus on 2W/3W electrification first (large fleet numbers, lower grid impact per vehicle, immediate consumer economics) while building charging infrastructure for 4W adoption.

**For international climate finance:** The conditional NDC gap ($-implied investment need) provides a concrete basis for Green Climate Fund and bilateral climate finance negotiations. The difference between unconditional and conditional scenarios quantifies the incremental cost of international support.

### 4.4 Limitations

1. **GDP projection:** Pakistan uses an India-derived trajectory, which may not capture Pakistan-specific economic dynamics (IMF programs, remittance dependency, political instability impacts on investment).

2. **Grid representation:** Neither model explicitly represents Pakistan's grid reliability challenges (load shedding, transmission losses ~15-18%, distribution system constraints). This likely causes both models to overestimate clean energy integration pace.

3. **Informal economy:** Pakistan's substantial informal sector (~30-40% of GDP) affects energy demand patterns in ways that formal IAM demand modules may not capture.

4. **Single-year harmonization:** Targets were harmonized on key metrics (capacity, emissions) but not on all input assumptions (technology costs, discount rates, resource potentials). Residual input differences contribute to some inter-model divergence.

5. **AFOLU/land-use:** UCT mode provides a small AFOLU offset (~11-18 Mt CO2/yr sink) for energy sector emissions. The size and persistence of this sink is uncertain and dependent on land-use change trajectories not harmonized between models.

---

## 5. Conclusions

### Key concluding paragraph (polished):

> This study demonstrates that Pakistan's energy-climate future is bounded by two complementary modeling perspectives that, despite their structural differences, converge on several critical findings: current policy commitments are insufficient to stabilize emissions; solar energy will dominate electricity generation by mid-century regardless of additional policy; and the conditional NDC target represents an aspiration achievable only with international support. Where the models diverge — most notably on transport electrification pace and gas-to-renewables transition timing — the divergence itself is informative for policy: it quantifies the structural uncertainty that Pakistan's energy planners must design for. We recommend that infrastructure investment decisions target the high end of the transport electrification range while planning for the lower-end pace, and that NDC negotiation strategy leverage the quantified gap between unconditional and conditional scenarios as the basis for climate finance requests.

---

## 6. Figure Concepts

### Figure 1: CO2 E&IP Emissions — All Scenarios + MSG CM
**Type:** Multi-line time series plot (2025-2050)
**Lines:** Reference (grey), CM (red), NDC Uncond (orange), NDC Cond (purple), Net Zero (green), MSG CM (blue dashed)
**Purpose:** Central result: the full scenario fan showing Pakistan's emissions range from "do nothing new" (600+ Mt CO2) to net-zero (0) by 2050
**Annotations:** Mark NDC target years (2030, 2035); shade the NDCU-NDCC gap as "international support zone"
**Size:** Full-width (single column), ~8x5 inches

### Figure 2: Electricity Generation Mix — GCAM vs MSG at 2030 and 2050
**Type:** Side-by-side stacked bar charts (one pair per year)
**Fuels:** Coal, Gas, Oil, Nuclear, Hydro, Solar, Wind, Biomass (using tech_colors palette)
**Purpose:** Visual story of the generation transition + inter-model agreement/divergence on mix composition
**Size:** Full-width, ~10x5 inches

### Figure 3: Transport Electrification Divergence
**Type:** Dual-panel: (a) Line plot of Final Energy|Transportation|Electricity for both models under CM; (b) Component breakdown showing 2W/3W vs 4W vs Bus vs Freight at 2050
**Purpose:** The paper's key divergence story — make the 2.65x gap visually compelling and explain the scope mismatch
**Annotations:** Mark NEV Policy milestones (2030: 30-50% sales targets; 2040: 90% target)
**Size:** Full-width, ~10x5 inches

### Figure 4: Primary Energy Mix — 2050 Cross-Model Comparison
**Type:** Grouped bar chart, fuels on x-axis, model as fill
**Purpose:** Big-picture energy system comparison showing fossil vs clean shares
**Key insight to highlight:** Gas persistence in GCAM vs earlier exit in MSG
**Size:** Half-width, ~5x4 inches

### Figure 5: Scenario Fan — Electricity, Final Energy, and Emissions
**Type:** 3-panel (or 2x2) small multiples, each showing all GCAM scenarios for one variable, with MSG CM overlay
**Variables:** (a) Total electricity generation, (b) Final energy total, (c) CO2 E&IP, (d) Transport electrification
**Purpose:** Comprehensive scenario comparison in compact format
**Size:** Full-width, ~10x8 inches

### Figure 6: Generation Mix at 2050 Across GCAM Scenarios
**Type:** Stacked bar chart, one bar per scenario (CM, NDCU, NDCC, NZ)
**Purpose:** How the electricity mix shifts as emission ambition increases — coal/gas shrink, solar/nuclear grow
**Key insight:** Net Zero scenario mix is essentially the "GCAM vision of Pakistan's decarbonized grid"
**Size:** Half-width, ~5x4 inches

### Figure 7 (SI candidate): Implied Carbon Prices by Scenario
**Type:** Bar chart or line plot of carbon price trajectories under NDCU, NDCC, Net Zero
**Purpose:** Quantify the cost of ambition. The conditional NDC price vs unconditional price gap = cost of international support
**Size:** Half-width

### Figure 8 (SI candidate): Capacity Factor and Reporting Methodology
**Type:** Table or schematic showing GCAM's generation → capacity reporting chain (internal CF vs gcamreport blended CF vs reality)
**Purpose:** Methodological transparency. Explain why IAMC "Capacity GW" values are unreliable and generation-based metrics should be preferred
**Size:** SI figure/table

---

## 7. Supplementary Information Suggestions

1. **Complete scenario target table:** Full `scenarios_lums.csv` as SI Table S1, with GW, GWa, EJ, and conversion factors
2. **Emission constraint traceability:** Full `emission_constraints_v1_all_trace.csv` showing CM baseline → multiplier → constraint for every year and every scenario variant (flat-hold, ts_const, ts_decl)
3. **Add-on XML parameter table:** All share-weights and fixedOutput values used in CM add-on XMLs (cm_01 through cm_07), with v0→v1→v2 iteration history
4. **GCAM capacity factor source table:** Technology-by-technology CFs from A23.globaltech_capacity_factor.csv and electricity_water.xml, with explanation of gcamreport's reporting methodology discrepancy
5. **Variable-by-variable comparison spreadsheet:** The full `msg_gcam_comparison_all.xlsx` content as SI, showing every IAMC variable compared between models with difference and % difference
6. **Constraint variant sensitivity:** Comparison of flat-hold vs ts_const vs ts_decl emission pathways, showing how constraint shape affects technology choice and carbon price
7. **EV scope reconciliation:** Detailed mapping of GCAM transport subsectors to MESSAGEix categories, explaining the 2W/3W inclusion and its energy implications
8. **Pakistan-specific GCAM adjustments:** Documentation of GDP substitution, pork exclusion, fertilizer scaling, and other Pakistan-specific modifications to the global GCAM

---

## 8. Key Paragraphs for the Paper

### On the value of inter-model comparison for developing countries:

> Inter-model comparison studies in integrated assessment have traditionally focused on globally harmonized scenario exercises (SSPs, EMF) or on advanced economies where data availability supports detailed calibration. Developing countries — which collectively drive the largest share of future emissions growth — remain underrepresented in this literature. Pakistan is a critical case: a large, rapidly growing economy with a complex energy system spanning imported LNG, domestic coal, large hydro, consumer-driven solar, and nascent electrification. Applying two structurally distinct IAMs to this system reveals insights that neither model alone can provide — particularly about the role of capital stock inertia, consumer behavior, and institutional capacity in determining transition pace.

### On why market equilibrium and optimization models disagree on transport:

> The 2.65x transport electrification gap between GCAM and MESSAGEix is not a calibration failure — it is a structural finding about the nature of vehicle fleet transitions. GCAM's vintage-tracking logit preserves the existing ICE capital stock: a motorcycle purchased in 2025 continues operating for its economic lifetime regardless of subsequent BEV cost reductions. In aggregate, this produces a fleet transition that is slower than cost-optimal but closer to observed fleet turnover rates in developing countries. MESSAGEix's optimization can direct all new investment to BEVs once they become cost-competitive, achieving the NEV Policy's sales-share targets more closely but assuming a level of coordinated investment and consumer responsiveness that Pakistan's current market structure does not guarantee.

### On the conditional NDC as a negotiation instrument:

> Our finding that the conditional NDC requires carbon prices exceeding Pakistan's domestic institutional capacity to implement is not a criticism of the target — it is precisely what the conditional framework is designed to communicate. Pakistan's conditional NDC pledge signals: "this is physically and technologically achievable with adequate financial and technical support." The quantified gap between unconditional and conditional scenarios — in terms of both emission reductions and implied carbon prices — provides a concrete, model-based foundation for Pakistan's climate finance negotiations. International partners can use this gap to size their support commitments, while Pakistan can use it to demonstrate that ambitious targets are technically credible, not aspirational rhetoric.

### On Pakistan's rooftop solar phenomenon:

> Pakistan's rooftop solar deployment — estimated at 28+ GW installed by 2025, much of it consumer-financed and off-grid or behind-the-meter — is one of the fastest solar adoption rates globally but remains largely invisible in formal energy statistics and planning documents. Both GCAM and MESSAGEix capture this phenomenon indirectly (through generation shares rather than installed capacity), but neither model fully represents the grid-integration challenges it creates: reverse power flows, voltage regulation in distribution networks designed for one-way power, and the erosion of utility revenue models. GCAM's share-weight approach can approximate this market pull, but the real constraint on Pakistan's solar future is not deployment cost but grid absorption capacity.

### On what "Current Measures" means for a developing country:

> The Current Measures scenario for Pakistan differs qualitatively from its counterpart in advanced economy studies. Where a European CM scenario might represent incremental policy evolution, Pakistan's includes transformational commitments: 8.7 GW of new large hydro, a fleet-wide NEV policy targeting 90% electric vehicle sales by 2040, and the retirement of oil-fired generation within a decade. These are not "business as usual" — they are ambitious national development goals. That these committed measures still produce a 2.5x increase in CO2 emissions by 2050 illustrates the scale of Pakistan's development-climate dilemma: even successful execution of all existing plans does not stabilize emissions.

---

## 9. Suggested Methods Supplement: Reproducibility

For full reproducibility, the GCAM-Pakistan analysis code is organized as:

```
analysis/
  config.R              — shared constants, paths, ggplot2 theme
  compare_msg_gcam.R    — inter-model comparison (xlsx + figures)
  generate_emission_constraints_v1.R — programmatic constraint generation
  scenario_targets_check.R — verification script
  query/iamc.R          — GCAM BaseX → IAMC format
```

All emission constraints are derived programmatically from CM model output, not manually specified. The full trace from CM baseline → multiplier → MTC constraint → model input is recorded in `emission_constraints_v1_all_trace.csv`.

---

*Draft skeleton prepared April 2026. For internal team use — not for circulation.*
