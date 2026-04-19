# MESSAGEix vs GCAM-Pakistan: Critical Comparison of Current Measures Results

> Generated: 2026-04-16
> Sources: `MESSAGEix-Pakistan_CM.xlsx` (MSG), `gcam_output_iamc_ref_cm_tuned_standardized.csv` (GCAM)
> All energy values normalized to PJ/yr for direct comparison (GCAM native: EJ/yr, MSG native: PJ/yr)

---

## 1. Executive Summary

The two models agree on the broad contours of Pakistan's energy trajectory — rising total electricity demand, growing renewables share, and emissions reaching 600–770 Mt CO2/yr from energy and industry by 2050 — but diverge sharply in the **composition** of the energy mix and the **magnitude** of non-CO2 greenhouse gases. The following table summarizes the most consequential divergences:

| Dimension | MESSAGE | GCAM-CM | Gap | Concern |
|-----------|---------|---------|-----|---------|
| Coal generation 2050 (PJ) | 1,056 | 404 | MSG 2.6x higher | **Critical** |
| Gas generation 2050 (PJ) | 1,116 | 467 | MSG 2.4x higher | **Critical** |
| Solar generation 2050 (PJ) | 613 | 1,149 | GCAM 1.9x higher | **High** |
| Nuclear generation 2050 (PJ) | 112 | 295 | GCAM 2.6x higher | **High** |
| Oil generation 2030 (PJ) | 179 | 69 | MSG 2.6x higher | Medium |
| Transport electrification 2050 (PJ) | 652 | 198 | MSG 3.3x higher | **High** |
| CO2 E&IP 2050 (Mt CO2) | 773 | 592 | MSG 31% higher | **Critical** |
| Kyoto Gases 2050 (Mt CO2e) | 860 | 1,194 | GCAM 39% higher | **Critical** |
| Hydro generation 2050 (PJ) | 194 | 175 | ~10% gap | Low |
| Total Final Energy 2050 (PJ) | 8,382 | 8,686 | ~4% gap | Low |

---

## 2. Detailed Comparison by Sector

### 2.1 Electricity Generation Mix

This is where the models diverge most. Both produce a similar **total** electricity output (within 10–15%), but the fuel mix tells very different stories about Pakistan's power sector.

#### Generation (PJ/yr)

| Technology | Model | 2025 | 2030 | 2035 | 2040 | 2045 | 2050 | 2060 |
|-----------|-------|-----:|-----:|-----:|-----:|-----:|-----:|-----:|
| **Coal** | MSG | 74 | 224 | 383 | 566 | 775 | 1,056 | 1,114 |
| | GCAM-CM | 116 | 145 | 180 | 245 | 327 | 404 | 573 |
| **Gas** | MSG | 151 | 217 | 406 | 588 | 820 | 1,116 | 1,976 |
| | GCAM-CM | 199 | 234 | 267 | 326 | 402 | 467 | 615 |
| **Oil** | MSG | 10 | 179 | 204 | 231 | 238 | 193 | 191 |
| | GCAM-CM | 55 | 69 | 87 | 123 | 165 | 195 | 232 |
| **Nuclear** | MSG | 84 | 86 | 112 | 112 | 112 | 112 | 112 |
| | GCAM-CM | 65 | 89 | 118 | 169 | 234 | 295 | 425 |
| **Hydro** | MSG | 137 | 190 | 192 | 194 | 194 | 194 | 194 |
| | GCAM-CM | 144 | 150 | 156 | 163 | 169 | 175 | 188 |
| **Solar** | MSG | 147 | 164 | 222 | 307 | 410 | 613 | 1,123 |
| | GCAM-CM | 56 | 218 | 384 | 622 | 899 | 1,149 | 1,527 |
| **Wind** | MSG | 15 | 14 | 34 | 38 | 121 | 161 | 354 |
| | GCAM-CM | 16 | 41 | 83 | 170 | 273 | 356 | 512 |
| **Total** | MSG | 622 | 1,076 | 1,556 | 2,040 | 2,670 | 3,450 | 5,064 |
| | GCAM-CM | 652 | 954 | 1,293 | 1,850 | 2,522 | 3,113 | 4,179 |

#### Key Observations

**Coal and Gas — the largest divergence.** By 2050, MSG projects Pakistan generating 2,172 PJ from coal+gas combined, versus GCAM's 871 PJ — a factor of 2.5x. This is the single most important structural difference between the models. MSG sees Pakistan as a far more fossil-intensive economy under current measures. By 2060, MSG's gas alone (1,976 PJ) exceeds GCAM's entire fossil generation. This divergence drives the CO2 emissions gap.

*Possible explanations:*
- GCAM's CM scenario has aggressively reduced share-weights for coal (0.35), gas (0.55), and oil (0.04), which may be overcorrecting relative to what "current measures" actually implies
- MSG may be reflecting committed pipeline projects (CPEC coal plants, LNG terminals) more literally
- GCAM's competitive dynamics mean that boosting solar/nuclear automatically crowds out fossil more than in MSG's technology-explicit framework

**Solar — opposite timing, eventually converging.** MSG starts with 147 PJ of solar in 2025 (reflecting the "consumer-led solar boom" narrative in the abstract), while GCAM-CM has only 56 PJ. But GCAM's solar grows explosively and overtakes MSG by 2030 (218 vs 164 PJ), reaching 1,149 PJ by 2050 versus MSG's 613 PJ. By 2060, the gap narrows (1,527 vs 1,123 PJ) as MSG's solar accelerates.

*Why this matters:* The abstract argues that "consumer-led solar adoption" drives Pakistan below 2C allocations. But the two models disagree on whether solar scales fast enough to displace fossil — GCAM says yes (solar dominates by 2040), MSG says it takes until 2060.

**Nuclear — fundamentally different trajectories.** GCAM-CM projects continuous nuclear expansion to 295 PJ by 2050 (driven by share-weight = 2.5), while MSG caps nuclear at ~112 PJ (4.46 GW) from 2035 onward. This reflects different assumptions about Pakistan's nuclear program: GCAM allows endogenous growth, MSG treats it as constrained by current plans (likely reflecting political/financing constraints and IAEA safeguards that GCAM doesn't model).

**Oil — MSG's 2030 spike.** MSG shows oil generation jumping from 10 PJ (2025) to 179 PJ (2030) — an 18x increase. GCAM shows a gentle rise from 55 to 69 PJ. This is likely the RFO mapping issue flagged in the team chat: some gas/oil dual-fuel plants may be assigned differently between models.

**Wind — opposite directions.** GCAM-CM *reduced* wind generation from baseline (share-weight lowered to 0.45) to match the CM target of 0.45 GWa, while MSG keeps wind also modest but with a late surge. Both models agree wind is small now, but GCAM sees wind growing more steadily.

### 2.2 Installed Capacity

Capacity comparisons are treacherous due to GCAM's use of gcamreport's blended capacity factors, which inflate GW figures. However, the **direction** and **relative magnitudes** remain informative.

| Technology | 2025 MSG | 2025 GCAM-CM | 2050 MSG | 2050 GCAM-CM | Note |
|------------|------:|------:|------:|------:|------|
| Solar (GW) | 28.3 | 25.1 | 84.4 | 482.8 | GCAM inflated by CF mismatch |
| Wind (GW) | 2.5 | 4.6 | 17.0 | 85.1 | Same issue |
| Nuclear (GW) | 3.3 | 16.1 | 4.5 | 41.2 | GCAM clearly inflated |
| Hydro (GW) | 10.9 | 40.6 | 13.1 | 49.4 | GCAM inflated |
| Coal (GW) | 5.0 | 12.5 | 39.4 | 44.6 | Closer |
| Gas (GW) | 15.1 | 272.2 | 107.9 | 151.2 | GCAM wildly inflated |
| Oil (GW) | 5.9 | — | 7.2 | — | Not reported separately in GCAM |

GCAM's gas capacity of 272 GW in 2025 is obviously an artifact — Pakistan's actual installed gas capacity is ~15 GW. This confirms the known issue with gcamreport capacity figures and reinforces that **generation (PJ/GWa) is the only reliable basis for inter-model comparison**, not capacity.

### 2.3 Emissions

#### CO2 from Energy and Industrial Processes (Mt CO2/yr)

| Model | 2025 | 2030 | 2035 | 2040 | 2045 | 2050 | 2060 |
|-------|-----:|-----:|-----:|-----:|-----:|-----:|-----:|
| MSG | 203 | 322 | 395 | 503 | 610 | 773 | 1,068 |
| GCAM-CM | 243 | 291 | 347 | 417 | 503 | 592 | 792 |
| GCAM-Ref | 250 | 306 | 372 | 456 | 558 | 660 | 888 |

**At 2025**, GCAM actually exceeds MSG on CO2 E&IP (243 vs 203 Mt). But MSG's emissions grow much faster, crossing over GCAM by 2035 and reaching 773 Mt by 2050 vs GCAM's 592 Mt (31% higher). This is entirely consistent with MSG's much heavier coal+gas trajectory.

#### Kyoto GHGs — The Structural Mismatch

| Model | 2025 | 2030 | 2035 | 2040 | 2045 | 2050 |
|-------|-----:|-----:|-----:|-----:|-----:|-----:|
| MSG | 246 | 371 | 450 | 567 | 684 | 860 |
| GCAM-CM | 576 | 666 | 768 | 892 | 1,037 | 1,194 |

This is the most striking divergence: **GCAM's Kyoto gases are 2.3x MSG's in 2025 and 1.4x by 2050.** But GCAM's CO2 is *lower* than MSG's. The arithmetic is revealing:

| Model | 2050 CO2 E&IP | 2050 Kyoto | Non-CO2 Kyoto (implied) |
|-------|-----:|-----:|-----:|
| MSG | 773 | 860 | ~87 |
| GCAM | 592 | 1,194 | ~602 |

GCAM attributes ~602 Mt CO2e/yr to non-CO2 GHGs (CH4, N2O from agriculture, waste, fugitive emissions, AFOLU), while MSG implies only ~87 Mt. This is an **order-of-magnitude structural difference** that likely reflects:

1. **Scope difference**: MSG may not fully model agriculture/AFOLU/waste emissions, while GCAM includes them systemically
2. **GCAM reports `Kyoto Gases` inclusively** — it includes agriculture CH4 (rice, livestock), waste CH4, N2O from fertilizers, and land-use CO2
3. **Pakistan's agriculture sector** is enormous (~22% of GDP) with large ruminant populations and rice paddies — GCAM's higher non-CO2 is likely more realistic

**This matters for the paper's argument.** The abstract claims Pakistan's CM trajectory "falls below 2C Ability-to-Pay allocations." If MSG's lower Kyoto figure is used, this is more easily true. If GCAM's much higher total is used (which includes agriculture), the conclusion may not hold. The paper needs to explicitly state which emissions scope is being compared against the carbon budgets — energy-only, E&IP, or full Kyoto including AFOLU.

### 2.4 Final Energy and Transport Electrification

#### Final Energy (PJ/yr)

| Model | 2025 | 2030 | 2035 | 2040 | 2045 | 2050 |
|-------|-----:|-----:|-----:|-----:|-----:|-----:|
| MSG | 3,043 | 3,983 | 4,653 | 5,627 | 6,703 | 8,382 |
| GCAM-CM | 4,447 | 4,947 | 5,605 | 6,408 | 7,443 | 8,686 |

Total final energy is quite close by 2050 (~4% gap) but GCAM starts much higher in 2025 (4,447 vs 3,043 PJ — 46% higher). This narrows over time as MSG's demand grows faster. The 2025 discrepancy likely reflects different base year calibrations and definitions of what enters "final energy."

#### Transport Electrification (PJ/yr)

| Model | 2025 | 2030 | 2035 | 2040 | 2045 | 2050 |
|-------|-----:|-----:|-----:|-----:|-----:|-----:|
| MSG | 0.3 | 10.5 | 146 | 220 | 392 | 652 |
| GCAM-CM | 38.5 | 54.5 | 79 | 114 | 152 | 198 |

MSG envisions **radically more transport electrification** — 652 vs 198 PJ by 2050 (3.3x). MSG's trajectory implies massive EV penetration consistent with the Pakistan New Energy Vehicle Policy targets noted in the team chat (Arfa's notes). However, MSG shows almost zero transport electricity in 2025 (0.3 PJ) jumping to 146 PJ by 2035, which is an implausibly steep ramp.

GCAM's transport electrification is much flatter. The 2025 value of 38.5 PJ is actually very high (GCAM includes 2W/3W e-vehicles), and growth is modest. This suggests GCAM isn't aggressively implementing the EV policy targets — a gap that needs closing.

### 2.5 Primary Energy and Trade

| | MSG (PJ) | GCAM-CM (PJ) |
|--|-----:|-----:|
| Primary Energy 2025 | 3,526 | 5,071 |
| Primary Energy 2050 | 9,478 | 10,292 |

GCAM starts 44% higher in 2025 but converges to only 9% higher by 2050. MSG's coal imports grow from 146 PJ (2025) to 2,044 PJ (2050), consistent with its coal-heavy generation path. GCAM should show less coal import growth given its lower coal generation.

---

## 3. What This Means for the Study

### 3.1 The Two-Model Narrative

The inter-model comparison reveals two fundamentally different visions of Pakistan's energy transition under "current measures":

- **MSG story**: Pakistan remains fossil-dependent through 2050, with coal and gas providing 63% of electricity. Solar grows modestly but transport electrification is the major decarbonization lever. Current measures lead to ~773 Mt CO2/yr from E&IP by 2050.

- **GCAM story**: Pakistan transitions faster — solar and nuclear dominate growth, fossil fuel role shrinks proportionally (though still grows in absolute terms). Current measures lead to ~592 Mt CO2/yr from E&IP by 2050 (24% lower than MSG).

Neither story is necessarily wrong — they reflect different structural assumptions. But the delta is large enough that the paper's conclusions depend on which model drives the narrative.

### 3.2 Implications for the Abstract's Claims

> "Pakistan's Current Measures trajectory, driven largely by consumer-led solar adoption, already falls below 2C Ability-to-Pay allocations through 2050."

- **Under MSG**, this may hold if the comparison uses E&IP CO2 only, since MSG solar adoption is modest but total Kyoto gases are low (860 Mt CO2e)
- **Under GCAM**, this is harder to support — GCAM's Kyoto total is 1,194 Mt CO2e, 39% higher, largely because GCAM accounts for agriculture/AFOLU emissions that MSG doesn't
- The paper needs to either: (a) harmonize scope by comparing E&IP CO2 only against carbon budgets, or (b) acknowledge that agriculture emissions create a wedge that complicates the "below 2C" claim

> "NDC Conditional scenario approaches 1.5C-consistent fair-share requirements."

- Since NDC Conditional = 0.5x CM, the GCAM NDC-C target would be ~296 Mt CO2 E&IP by 2050 — much lower than MSG's ~387 Mt. The two models would agree directionally but disagree on the scale of reduction needed.

### 3.3 Real-World Implications

1. **Coal lock-in risk**: MSG's coal trajectory implies massive new coal infrastructure (39 GW by 2050). If this is credible, it means Pakistan faces significant stranded asset risk under stronger climate policy. GCAM's lower coal trajectory suggests current measures may already be sufficient to limit coal — but this depends on whether the CM share-weight tuning is too aggressive.

2. **Nuclear feasibility**: GCAM projects Pakistan growing to 41+ GW of nuclear by 2050 — this implies ~30 reactors beyond current plans, which is geopolitically and financially implausible. MSG's cap at 4.5 GW is more realistic given Pakistan's position in the global nuclear order.

3. **Solar ceiling**: Both models agree solar is central, but disagree on the pace. Pakistan's grid infrastructure, intermittency challenges, and storage requirements create a practical ceiling that neither model may be capturing. GCAM's 483 GW installed solar by 2050 (even if inflated by CF issues) assumes grid-scale absorption that is extremely ambitious.

4. **Transport electrification**: MSG's vision of 652 PJ of transport electricity requires massive charging infrastructure and ignores Pakistan's constrained grid. GCAM's more modest 198 PJ may be more realistic for the near term, though the EV policy targets suggest aspirations closer to MSG.

5. **Agriculture as the emissions wildcard**: GCAM's inclusion of ~600 Mt CO2e/yr from non-CO2 sources (mostly agriculture) means that even if Pakistan decarbonizes electricity perfectly, it still faces a massive agriculture emissions challenge that MSG doesn't surface. The paper should discuss this methodological gap explicitly.

---

## 4. Data Quality and Harmonization Issues

### 4.1 Known Issues

| Issue | Impact | Resolution |
|-------|--------|------------|
| **GCAM capacity GW inflate** | Gas shows 272 GW vs real 15 GW | Use generation (PJ/GWa) for comparison, not capacity |
| **RFO/oil mapping** | Oil gen differs wildly (MSG 179 vs GCAM 69 PJ in 2030) | Need gas+oil combined comparison; may resolve per Arfa's chat comment |
| **2025 calibration** | GCAM final energy 46% higher at baseline | Check base year data sources; may need discussion in methods |
| **Non-CO2 GHG scope** | GCAM 602 Mt vs MSG 87 Mt implied non-CO2 | State scope explicitly in paper; consider energy-only comparison |
| **EV scope** | GCAM includes 2W/3W; MSG may be 4W-only | Harmonize variable definition |
| **Kyoto Gases** | GCAM plots E&IP only in notebook, MSG plots total | Ensure apples-to-apples in paper figures |

### 4.2 Recommended Harmonization for Paper Figures

1. **Emissions**: Plot both `Emissions|CO2|Energy and Industrial Processes` for direct comparison. Reserve Kyoto Gases for a separate exhibit, noting GCAM's agriculture inclusion.
2. **Capacity**: Do NOT use GW for GCAM. Use generation (PJ or TWh) for all electricity comparisons.
3. **Transport**: Harmonize EV definitions. Compare `Final Energy|Transportation|Electricity` but note scope differences.
4. **Base year**: Both models should match Pakistan's known 2020/2021 energy balance. Check GCAM's higher 2025 baseline against IEA/HDIP data.

---

## 5. Tuning Plan — What Needs to Change in GCAM Input XMLs

Based on this comparison, the following adjustments would bring GCAM-CM closer to MSG while maintaining internal consistency. **Priority**: items tagged P1 should be done before the next team meeting; P2 before paper submission.

### P1 — Critical (do before next run)

#### 5.1 Reduce Nuclear Growth (P1)

**Problem**: GCAM-CM nuclear grows to 295 PJ by 2050 and 425 PJ by 2060 (from share-weight 2.5). MSG caps at 112 PJ (4.46 GW). Real-world Pakistan has ~3.3 GW nuclear, with Chashma and Karachi units. Plans for 2-3 more Chinese-supplied units are uncertain.

**Action**: In `cm_04_nuclear.xml`:
- Reduce share-weight from 2.5 → 1.2 for 2025–2035
- Cap at current levels after 2035 by setting share-weight to 0.5 for 2035–2050
- Or: use `fixedOutput` for nuclear if specific plant pipeline (C-5, K-2, K-3) is known
- Target: ~112–150 PJ by 2050 to bracket MSG's 112 PJ

#### 5.2 Increase Coal Generation (P1)

**Problem**: GCAM-CM coal is 404 PJ by 2050 vs MSG's 1,056 PJ. The CM share-weight (0.35) over-suppresses coal relative to committed CPEC projects and Pakistan's actual coal expansion plans (Thar mines, Hub, Port Qasim).

**Action**: In `cm_05_fossil_reduce.xml`:
- Increase coal share-weight from 0.35 → 0.55 (or higher)
- Check: does this bring coal gen to ~500–700 PJ by 2050? (Doesn't need to match MSG's 1,056 fully — that seems very high)
- Consider: what committed coal capacity exists? NEPRA data shows ~5 GW installed, ~2 GW under construction
- Reasonable target: 500–800 PJ by 2050 (midpoint between models)

#### 5.3 Increase Gas Generation (P1)

**Problem**: GCAM-CM gas is 467 PJ by 2050 vs MSG's 1,116 PJ. Pakistan has ~15 GW of gas capacity and active LNG import infrastructure.

**Action**: In `cm_05_fossil_reduce.xml`:
- Increase gas share-weight from 0.55 → 0.70
- Target: ~600–800 PJ by 2050

#### 5.4 Moderate Solar Growth Rate (P1)

**Problem**: GCAM-CM solar reaches 1,149 PJ by 2050 vs MSG's 613 PJ. The share-weight of 3.5 causes GCAM solar to dominate too early (exceeding MSG by 2030).

**Action**: In `cm_02_solar.xml`:
- Reduce share-weight from 3.5 → 2.0–2.5
- This moderates growth while keeping solar as the dominant renewable
- Target: ~700–900 PJ by 2050 (between the two models)
- Keep 2025 level reasonable: GCAM has 56 PJ vs MSG's 147 PJ. The 2025 gap is partly base-year calibration and may not be fixable via share-weights alone.

#### 5.5 Update Emission Constraint Values (P1)

**Problem**: NDC/NetZero constraint XMLs use placeholder MTC values from CM iteration 1. Now that tuned CM is available, update with real values.

**Action**: Read CM E&IP emissions from the tuned output:
- 2025: 243 Mt CO2 → 66.4 MTC
- 2030: 291 Mt CO2 → 79.5 MTC  
- 2035: 347 Mt CO2 → 94.6 MTC

Update constraint XMLs:
- `pak_co2_constraint_ndc_uncond.xml`: 2030 = 0.85 × 79.5 = 67.5 MTC, 2035 = 0.83 × 94.6 = 78.5 MTC
- `pak_co2_constraint_ndc_cond.xml`: 2030 = 0.50 × 79.5 = 39.7 MTC, 2035 = 0.50 × 94.6 = 47.3 MTC
- `pak_co2_constraint_netzero.xml`: Linear from 2025 (66.4) to 0 at 2050

### P2 — Important (before paper submission)

#### 5.6 Implement EV Policy Targets (P2)

**Problem**: GCAM transport electrification (198 PJ by 2050) is far below MSG (652 PJ) and below Pakistan's New Energy Vehicle Policy targets (per Arfa's notes).

**Action**: In `cm_07_ev.xml`:
- Significantly increase BEV share-weights for 4W
- Consider separate 2W/3W vs 4W tuning if targets differ
- Target: 300–400 PJ by 2050 (between the two models)

#### 5.7 Oil/RFO Resolution (P2)

**Problem**: MSG shows 179 PJ oil gen in 2030; GCAM shows 69 PJ. Per chat, some dual-fuel plants are assigned to different categories. Need to check if gas+oil combined is closer.

**Action**:
- Compute GCAM gas+oil combined vs MSG gas+oil combined
  - 2030: GCAM gas+oil = 234+69 = 303 PJ; MSG gas+oil = 217+179 = 396 PJ
  - Still a gap, but smaller (24% vs 160% for oil alone)
- Discuss with Arfa: which specific plants are classified differently?
- May not need XML changes — just documenting the mapping difference may suffice

#### 5.8 Hydro Alignment Check (P2)

**Problem**: GCAM hydro = 175 PJ by 2050; MSG = 194 PJ. The 10% gap is small but systematic.

**Action**: In `cm_01_hydro.xml`:
- Check if fixedOutput can be increased slightly to match MSG's 194 PJ (~0.194 EJ)
- Currently set to 0.1437 EJ (144 PJ at 2025). The trajectory grows to 175 PJ by 2050.
- May need to add fixedOutput values for later years if planned hydro projects (e.g., Diamer-Basha, Dasu) are known

### P3 — Nice to have

#### 5.9 Wind Alignment (P3)

**Problem**: GCAM-CM wind (356 PJ by 2050) exceeds MSG (161 PJ) by 2.2x. The CM share-weight was already reduced.

**Action**: No further reduction recommended. GCAM's wind represents what competitive dynamics would produce — MSG's low wind may reflect specific site-level constraints that GCAM doesn't model. Document as structural difference.

#### 5.10 Base Year Calibration (P3)

**Problem**: GCAM final energy starts 46% higher than MSG in 2025. This is a fundamental calibration issue that affects all downstream comparisons.

**Action**: Investigate GCAM base year energy balance for Pakistan vs. MSG. This is an input data issue, not an XML tuning issue. Document in methods section as model difference.

---

## 6. Summary of XML Changes

| File | Current | Proposed | Target Outcome |
|------|---------|----------|----------------|
| `cm_04_nuclear.xml` | SW = 2.5 | SW = 1.2 (2025), 0.5 (2035+) | Nuclear ~150 PJ by 2050 |
| `cm_05_fossil_reduce.xml` (coal) | SW = 0.35 | SW = 0.55 | Coal ~500–700 PJ by 2050 |
| `cm_05_fossil_reduce.xml` (gas) | SW = 0.55 | SW = 0.70 | Gas ~600–800 PJ by 2050 |
| `cm_02_solar.xml` | SW = 3.5 | SW = 2.0–2.5 | Solar ~700–900 PJ by 2050 |
| `cm_07_ev.xml` | (current) | Increase BEV SW | Transport elec ~300–400 PJ by 2050 |
| `cm_01_hydro.xml` | fixedOutput = 0.1437 EJ | Add 2035+ values | Hydro ~194 PJ by 2050 |
| `pak_co2_constraint_*.xml` | Placeholder MTC | Updated from tuned CM | Fresh constraint values |

---

## 7. Recommended Discussion Points for Team Call

1. **Which emissions scope for the 2C/1.5C comparison?** GCAM's high non-CO2 GHGs (agriculture) versus MSG's energy-focused scope will lead to different conclusions about NDC adequacy.

2. **Coal: is MSG's 1,056 PJ realistic?** This implies ~39 GW of coal operating at ~85% CF. Given Pakistan's recent coal struggles (cost overruns, circular debt, partial backtracking from CPEC coal) — is this the "current measures" or aspiration?

3. **Nuclear: constrained or unconstrained?** Need team consensus on whether nuclear should be modeled as constrained (MSG approach: cap at planned plants) or allowed to grow endogenously (current GCAM approach).

4. **Oil/RFO mapping**: Arfa flagged this — need resolution before finalizing figures.

5. **2025 base year calibration**: The 46% final energy gap at the starting point is significant. Both teams should verify against IEA/HDIP Pakistan energy balance data.

6. **Which figures to use?** The notebook's Kyoto Gases plot compares MSG total against GCAM E&IP — these aren't the same thing. Need to decide on harmonized variables for each figure.


<!-- 

python3 -c "
import pandas as pd

# Load GCAM CMRev
gcam = pd.read_excel('output/gcam_output_iamc_all_standardized.xlsx')
gcam.columns = gcam.columns.astype(str)
cmrev = gcam[(gcam['Scenario']=='CurrentMeasuresRev') & (gcam['Region']=='Pakistan')]

# Key vars for commentary
vars = [
    'Secondary Energy|Electricity|Coal',
    'Secondary Energy|Electricity|Gas',
    'Secondary Energy|Electricity|Oil',
    'Secondary Energy|Electricity|Nuclear',
    'Secondary Energy|Electricity|Hydro',
    'Secondary Energy|Electricity|Solar',
    'Secondary Energy|Electricity|Wind',
    'Secondary Energy|Electricity|Biomass',
    'Secondary Energy|Electricity',
    'Final Energy|Transportation|Electricity',
    'Final Energy|Transportation|Liquids',
    'Final Energy|Transportation',
    'Final Energy',
    'Emissions|CO2|Energy and Industrial Processes',
    'Emissions|CO2|Energy',
    'Emissions|Kyoto Gases|Energy and Industrial Processes',
    'Primary Energy|Coal',
    'Primary Energy|Gas',
    'Primary Energy|Oil',
    'Primary Energy|Nuclear',
    'Primary Energy|Biomass',
]
years = ['2025','2030','2035','2040','2045','2050']

for v in vars:
    row = cmrev[cmrev['Variable']==v]
    if len(row)==0:
        print(f'{v}: NOT FOUND')
        continue
    unit = row['Unit'].values[0]
    vals = [f'{float(row[y].values[0]):.4f}' if y in row.columns else 'NA' for y in years]
    # Convert to PJ if EJ
    if unit == 'EJ/yr':
        pj_vals = [f'{float(row[y].values[0])*1000:.1f}' for y in years]
        print(f'{v} ({unit}→PJ): {\" | \".join(pj_vals)}')
    else:
        print(f'{v} ({unit}): {\" | \".join(vals)}')

# Also get MSG
print()
print('=== MESSAGE ===')
msg = pd.read_excel('analysis/MESSAGEix-Pakistan_CM.xlsx')
msg.columns = msg.columns.astype(str)
msg_vars = [
    'Secondary Energy|Electricity|Coal',
    'Secondary Energy|Electricity|Gas',
    'Secondary Energy|Electricity|Oil',
    'Secondary Energy|Electricity|Nuclear',
    'Secondary Energy|Electricity|Hydro',
    'Secondary Energy|Electricity|Solar',
    'Secondary Energy|Electricity|Wind',
    'Secondary Energy|Electricity|Biomass',
    'Secondary Energy|Electricity',
    'Final Energy|Transportation|Electricity',
    'Final Energy|Transportation|Liquids',
    'Final Energy|Transportation',
    'Final Energy',
    'Emissions|CO2|Energy and Industrial Processes',
    'Emissions|CO2|Energy',
    'Emissions|Kyoto Gases',
    'Primary Energy|Coal',
    'Primary Energy|Gas',
    'Primary Energy|Oil',
    'Primary Energy|Nuclear',
    'Primary Energy|Biomass',
]
for v in msg_vars:
    row = msg[msg['Variable']==v]
    if len(row)==0: 
        print(f'{v}: NOT FOUND')
        continue
    unit = row['Unit'].values[0]
    vals = [f'{float(row[y].values[0]):.1f}' if y in row.columns else 'NA' for y in years]
    print(f'{v} ({unit}): {\" | \".join(vals)}')
" 2>/dev/null
 -->