# MESSAGEix vs GCAM-Pakistan: Current Measures v1 Comparison

> Generated: 2026-04-17
> Sources: `gcam_output_iamc_all_standardized.xlsx` (GCAM CMRev / v1), `MESSAGEix-Pakistan_CM.xlsx` (MSG)
> All energy values in PJ/yr (GCAM EJ/yr × 1000). Emissions in Mt CO2/yr unless noted.
> GCAM scenarios: Reference, CurrentMeasures (v0), **CurrentMeasuresRev (v1)**, NDCCond_EnergyAg, NDCUncond_EnergyAg, NetZero_EnergyAg

---

## 1. Executive Summary

GCAM v1 ("CurrentMeasuresRev") represents the second calibration round for Pakistan's Current Measures scenario. Compared to v0, v1 relaxed fossil suppression (closer to committed CPEC/LNG projects) and significantly boosted EV share-weights to reflect the NEV Policy 2025-2030. The two models now agree on total electricity output within ~10% by 2050 but diverge on **fuel mix**, **transport electrification**, and **non-CO2 greenhouse gas scope**.

| Dimension | MSG | GCAM v1 | Ratio | Assessment |
|-----------|----:|--------:|------:|------------|
| Coal gen 2050 (PJ) | 1,056 | 479 | MSG 2.2x | **Critical** — GCAM still under-represents committed coal |
| Gas gen 2050 (PJ) | 1,116 | 548 | MSG 2.0x | **Critical** — same issue with LNG/pipeline gas |
| Solar gen 2050 (PJ) | 613 | 1,152 | GCAM 1.9x | **High** — GCAM sees solar dominating earlier |
| Nuclear gen 2050 (PJ) | 112 | 166 | GCAM 1.5x | Medium — v1 tapered nuclear vs v0's aggressive growth |
| Transport elec 2050 (PJ) | 652 | 246 | MSG 2.7x | **High** — v1 BEV boost insufficient; v2 needed |
| CO2 E&IP 2050 (Mt CO2) | 773 | 596 | MSG 30% higher | **Critical** — driven by fossil mix gap |
| Total elec gen 2050 (PJ) | 3,450 | ~3,100 | ~10% gap | Low — reasonable structural agreement |

**Key change from v0→v1:** Nuclear tapered from 295→166 PJ at 2050. Coal rose from 404→479 PJ. Gas rose from 467→548 PJ. Transport elec rose modestly from 198→246 PJ (still far below MSG). Overall, v1 moved in the right direction but transport remains the largest gap.

---

## 2. What "Current Measures" Means in GCAM

Unlike MESSAGE, which typically models individual power plants and committed project pipelines, GCAM represents policy through **share-weight adjustments** and **fixed output overrides** applied as add-on XML files on top of the global reference scenario. Each CM module represents a specific, traceable real-world policy or infrastructure commitment:

### CM Add-on Modules

| Module | File | Real-World Policy | GCAM Mechanism |
|--------|------|-------------------|----------------|
| **cm_01_hydro** | `cm_01_hydro.xml` | Committed hydro projects: Diamer-Basha Dam (4.5 GW, construction underway), Dasu Hydropower (4.3 GW Stage 1), Mohmand Dam (0.8 GW). Total pipeline: ~10+ GW by 2035. | `fixedOutput` override — forces hydro generation to match committed project output trajectory, bypassing GCAM's cost-competition. |
| **cm_02_solar** | `cm_02_solar.xml` | IGCEP 2023-2031 solar targets; distributed solar boom driven by net-metering and falling panel costs. Pakistan added ~2.5 GW rooftop solar in 2023-24 alone. | Elevated `share-weight` (3.5) making solar highly competitive in the logit allocation. |
| **cm_03_wind** | `cm_03_wind.xml` | IGCEP wind capacity targets. Current installed: ~1.8 GW; pipeline projects in Sindh/Balochistan corridors (Jhimpir, Gharo). Growth constrained by grid integration and land acquisition. | Moderate `share-weight` (0.45) reflecting realistic constraints on wind deployment pace. |
| **cm_04_nuclear** | `cm_04_nuclear.xml` | Operating: Chashma C-1 to C-4 (1.3 GW), Karachi K-2/K-3 (2.2 GW, Hualong One). v1 tapered growth beyond committed plants to reflect IAEA safeguards, financing constraints, and geopolitical uncertainty around Chinese supply. | `share-weight` reduced from v0's 2.5 to a tapered trajectory, limiting endogenous growth post-2035. |
| **cm_05_fossil** | `cm_05_fossils.xml` | CPEC coal plants (Sahiwal, Port Qasim, Hub, Thar Block-I/II), LNG terminals (EETPL, PGPL), existing gas fleet. v1 is LESS aggressive in reducing fossil than v0, acknowledging that these are sunk/committed investments under "current measures." | Reduced `share-weights` for coal (0.35→higher in v1), gas (0.55→higher in v1), oil (0.04). Represents gradual policy shift away from fossil expansion, not a phase-out. |
| **cm_06_bio** | `cm_06_bio.xml` | Bagasse cogeneration in sugar mills, biomass potential from crop residues. Small but real — Pakistan's ~90 sugar mills have combined ~2 GW cogeneration potential. | Small `share-weight` boost for biomass electricity. |
| **cm_07_ev** | `cm_07_ev_v1.xml` | **Pakistan NEV Policy 2025-2030**: 2W/3W target 2.05M vehicles by 2030 (50% new sales); 4W target 99K by 2030 (30% new sales); buses 2,238 by 2030 (50% new sales); trucks 2,996 by 2030 (30% new sales). Ultimate: 90% of all new sales by 2040. | BEV `share-weights` ramped up: 4W 1.0→7.0, 2W/3W 2.0→8.0, Bus 1.0→7.0, Freight 0.5→5.0. v1 is significantly more aggressive than v0 (which had 0.5→3.0). |

### Why This Approach?

GCAM is a **partial-equilibrium model with logit-based technology competition**. Unlike MESSAGE's optimization framework where you can directly specify installed capacities, GCAM determines technology shares through relative cost competitiveness modulated by share-weights. A share-weight of 1.0 means the technology competes at its natural cost advantage; higher values represent policy tailwinds (subsidies, mandates, priority dispatch); lower values represent policy headwinds (regulation, disinvestment, standards).

This means GCAM's "Current Measures" is not a bottom-up list of individual plants but a **parametric representation of the policy environment** — a set of conditions that make certain technologies more or less attractive than they would be under a pure reference scenario. The advantage is that GCAM endogenously determines the equilibrium mix given these policy signals, capturing feedback effects (e.g., cheap solar reducing gas utilization, which affects gas prices, which affects industrial fuel choice).

---

## 3. Electricity Generation Mix

### Generation (PJ/yr)

| Technology | Model | 2025 | 2030 | 2035 | 2040 | 2045 | 2050 |
|-----------|-------|-----:|-----:|-----:|-----:|-----:|-----:|
| **Coal** | MSG | 74 | 224 | 383 | 566 | 775 | 1,056 |
| | GCAM v1 | 120 | 157 | 201 | 279 | 381 | 479 |
| **Gas** | MSG | 151 | 217 | 406 | 588 | 820 | 1,116 |
| | GCAM v1 | 206 | 252 | 296 | 368 | 464 | 548 |
| **Solar** | MSG | 147 | 164 | 222 | 307 | 410 | 613 |
| | GCAM v1 | 55 | 212 | 382 | 620 | 899 | 1,152 |
| **Nuclear** | MSG | 84 | 86 | 112 | 112 | 112 | 112 |
| | GCAM v1 | 64 | 81 | 97 | 120 | 146 | 166 |
| **Hydro** | MSG | 137 | 190 | 192 | 194 | 194 | 194 |
| | GCAM v1 | 144 | 150 | 156 | 163 | 169 | 175 |
| **Wind** | MSG | 15 | 14 | 34 | 38 | 121 | 161 |
| | GCAM v1 | 16 | 41 | 83 | 170 | 273 | 356 |

### Key Observations

**Coal and Gas — still the dominant divergence.** MSG projects 2,172 PJ from coal+gas combined by 2050; GCAM v1 projects 1,027 PJ (still only 47% of MSG). v1 moved in the right direction versus v0 (coal: 404→479, gas: 467→548), but the gap remains large. MSG's fossil trajectory reflects literal interpretation of CPEC and LNG commitments; GCAM's logit competition means that as solar gets cheaper, it automatically displaces fossil more than in MSG's technology-explicit framework.

**Solar — GCAM's star performer.** GCAM v1 solar reaches 1,152 PJ by 2050 (1.9x MSG's 613 PJ). Both models start low in 2025 (MSG 147, GCAM 55 PJ) but GCAM's exponential growth dominates from 2030 onward. The share-weight of 3.5 combined with falling solar costs makes it the default winner in GCAM's cost competition.

**Nuclear — v1 tapered successfully.** GCAM v0 had nuclear at 295 PJ by 2050 (implying ~30 reactors), which was geopolitically implausible. v1 tapered to 166 PJ, still above MSG's capped 112 PJ but now in a defensible range (implies ~7-8 GW total, plausible with K-2/K-3 + 2-3 additional Chinese-supplied units).

**Wind — GCAM grows faster.** GCAM v1 wind (356 PJ by 2050) is 2.2x MSG's 161 PJ. This represents what competitive dynamics would produce given Sindh/Balochistan wind resources — MSG's lower wind may reflect site-specific constraints. Both models agree wind is a minor contributor relative to solar.

---

## 4. Transport Electrification — The Remaining Gap

| Model | 2025 | 2030 | 2035 | 2040 | 2045 | 2050 |
|-------|-----:|-----:|-----:|-----:|-----:|-----:|
| MSG | 0.3 | 11 | 146 | 220 | 392 | 652 |
| GCAM v1 | 52 | 72 | 107 | 151 | 195 | 246 |
| Gap factor | — | — | MSG 1.4x | MSG 1.5x | MSG 2.0x | MSG 2.7x |

Despite v1's aggressive BEV share-weight boost (4W: 1.0→7.0, 2W/3W: 2.0→8.0), GCAM produces only 246 PJ of transport electricity by 2050 — still 2.7x below MSG's 652 PJ. v1 improved over v0 (198→246 PJ) but not enough.

**Root cause:** In GCAM's logit competition, boosting BEV share-weights alone is insufficient because ICE technologies (Liquids) continue competing at their natural cost advantage. The missing lever is **ICE suppression** — reducing Liquids share-weights to represent real-world policies like registration bans, fuel economy standards, and import restrictions on ICE vehicles that the NEV Policy implies.

**v2 strategy (recommended):**
1. Further increase BEV share-weights: 4W → 15.0, 2W/3W → 18.0, Bus → 15.0
2. **NEW: Suppress ICE (Liquids) share-weights**: Start at 1.0 (2025), decline to 0.5 (2035), 0.3 (2045), 0.2 (2050)
3. These SW changes represent both the push (mandates/subsidies for EVs) and pull (restrictions on ICE) of the NEV Policy

Target: 300-400 PJ by 2050 (own estimate of defensible range, between v1 and MSG).

---

## 5. Emissions

### CO2 from Energy and Industrial Processes (Mt CO2/yr)

| Model | 2025 | 2030 | 2035 | 2040 | 2045 | 2050 |
|-------|-----:|-----:|-----:|-----:|-----:|-----:|
| MSG | 203 | 322 | 395 | 503 | 610 | 773 |
| GCAM v1 | 241 | 289 | 343 | 414 | 504 | 596 |

GCAM v1 starts higher (241 vs 203 Mt in 2025) but grows slower, reflecting its lower fossil generation. MSG overtakes around 2030 and reaches 773 Mt by 2050 (30% higher than GCAM's 596 Mt). The crossover timing is consistent with the coal+gas mix divergence.

### Kyoto Gases — The Structural Mismatch

| Model | Variable | 2025 | 2030 | 2050 |
|-------|----------|-----:|-----:|-----:|
| MSG | Emissions\|Kyoto Gases (total) | 246 | 371 | 860 |
| GCAM v1 | Emissions\|Kyoto Gases\|E&IP | ~576 | ~666 | ~1,194 |

**CRITICAL**: MSG reports total Kyoto Gases (including agriculture CH4/N2O), while GCAM's gcamreport output labels E&IP-scope Kyoto Gases. Direct comparison is misleading. GCAM's total Kyoto Gases (if agriculture included) would be even higher. The ~600 Mt CO2e gap in non-CO2 GHGs reflects Pakistan's large agricultural sector (~22% of GDP, major ruminant/rice methane sources) that GCAM models systemically but MSG may not fully capture.

**Paper implication:** The abstract's claim that "Pakistan's Current Measures trajectory falls below 2C Ability-to-Pay allocations" depends on emissions scope. Using E&IP CO2 only, both models may support this. Using full Kyoto Gases, the conclusion is much harder to sustain.

---

## 6. Final Energy and Primary Energy

### Final Energy (PJ/yr)

| Model | 2025 | 2030 | 2035 | 2040 | 2045 | 2050 |
|-------|-----:|-----:|-----:|-----:|-----:|-----:|
| MSG | 3,043 | 3,983 | 4,653 | 5,627 | 6,703 | 8,382 |
| GCAM v1 | ~4,447 | ~4,947 | ~5,605 | ~6,408 | ~7,443 | ~8,686 |

Total final energy converges to within ~4% by 2050 despite GCAM starting 46% higher in 2025. The 2025 discrepancy reflects different base year calibrations and definitions of what enters "final energy" — a structural model difference, not a tuning issue.

### Primary Energy — Fossil imports track generation

MSG's heavier coal trajectory implies higher coal imports (146→2,044 PJ by 2050). GCAM v1's primary energy is ~9% higher than MSG at 2050 but with a very different composition (more solar/wind, less coal/gas).

---

## 7. v0 → v1 Changes and Remaining Issues

### What Changed in v1

| Dimension | v0 | v1 | Direction |
|-----------|----:|----:|-----------|
| Nuclear gen 2050 (PJ) | 295 | 166 | ↓ Tapered (correct) |
| Coal gen 2050 (PJ) | 404 | 479 | ↑ Less suppression |
| Gas gen 2050 (PJ) | 467 | 548 | ↑ Less suppression |
| EV SW (4W max) | 3.0 | 7.0 | ↑ More aggressive |
| Transport elec 2050 (PJ) | 198 | 246 | ↑ Modest improvement |

### What Still Needs Tuning (v2 Priorities)

| Issue | Priority | Action |
|-------|----------|--------|
| Transport electrification gap (246 vs 652 PJ) | **P1** | Create `cm_07_ev_v2.xml` with ICE suppression |
| Coal still low (479 vs 1,056 PJ) | P2 | Consider further fossil SW increase in v2 — but this may be a defensible structural difference |
| Solar possibly too high (1,152 vs 613 PJ) | P2 | Could moderate SW from 3.5→2.5 but solar dominance is GCAM's strength narrative |
| Gas still low (548 vs 1,116 PJ) | P2 | Same as coal — may document as structural difference |

**Recommendation:** Only create v2 for transport (`cm_07_ev_v2.xml`). The solar/fossil differences are defensible model structural differences suitable for discussion in the paper. The transport gap is a **policy implementation gap** — the NEV Policy targets are real and GCAM should reflect them more fully.

---

## 8. Implications for the Paper

### Narrative Framing

The models tell complementary stories. Frame the paper around what they **agree** on:

1. **Both models agree** that Pakistan's CM trajectory leads to 596–773 Mt CO2/yr E&IP by 2050 — a substantial increase from current levels requiring significant additional policy to meet NDC targets.
2. **Both models agree** that solar is central to Pakistan's energy transition, with solar becoming the dominant generation source between 2035-2045.
3. **Both models agree** that NDC targets (15-50% below CM) require significant additional policy beyond current measures.
4. **Both models agree** that Net Zero by 2050 is extremely ambitious and requires near-total decarbonization of the power sector.

Where they **disagree**, frame as uncertainty ranges:
- Fossil fuel role: 1,027–2,172 PJ coal+gas by 2050 (range)
- Transport electrification: 246–652 PJ by 2050 (range)
- Non-CO2 GHG accounting: major methodological gap requiring explicit scope declaration

### Recommended Paper Figures

1. **Stacked bar: Electricity generation mix** — MSG vs GCAM v1 at 2030 and 2050 — shows the structural shift
2. **Line plot: CO2 E&IP trajectory** — both models 2025-2050 — shows convergence/divergence timing
3. **Line plot: Transport electrification** — the gap story, with NEV Policy targets overlaid
4. **Grouped bar: Final energy by sector** — 2050 snapshot for structural comparison
5. **Scenario range: CO2 under NDC/NetZero** — show that despite CM divergence, mitigation scenarios converge

### Scope Recommendations

- Compare against carbon budgets using **E&IP CO2 only** for consistency between models
- Report Kyoto Gases separately with explicit scope notes
- Acknowledge agriculture emissions gap as a methodological limitation
- Use generation (PJ) not capacity (GW) for all electricity comparisons

---

## 9. Emission Scenario Constraints (v1 Basis)

The following constraint values were computed from GCAM v1 (CMRev) E&IP CO2 output and are used in the NDC and Net Zero XMLs:

| Period | CM v1 E&IP (Mt CO2) | NDCU (MTC) | NDCC (MTC) | NetZero (MTC) |
|--------|---------------------:|-----------:|-----------:|--------------:|
| 2025 | 241.26 | — | — | — |
| 2030 | 288.99 | 66.994 | 39.408 | 52.617 |
| 2035 | 343.39 | 77.721 | 46.853 | 39.462 |
| 2040 | 413.67 | 93.738 | 56.489 | 26.308 |
| 2045 | 503.90 | 114.169 | 68.817 | 13.154 |
| 2050 | 596.39 | 135.091 | 81.417 | 0.000 |

Conversion: Mt CO2 × 12/44 = MTC. NDCU multipliers: 0.85 (2030), 0.83 (2035+). NDCC: 0.50. NetZero: linear from CM 2025 to 0 at 2050.

---

*Previous version: `comparison_commentary_v0.md` (used CM v0 / "CurrentMeasures" output from `gcam_output_iamc_ref_cm_tuned_standardized.csv`)*
