# GCAM Emissions Policy Mechanisms

> Comprehensive reference for GCAM's emissions constraint framework: instruments, coverage modes, multi-gas accounting, solver mechanics, and interpretation pitfalls.
> Based on C++ source (`cvs/objects/policy/`), existing XML files (`input/policy/`), and GCAM documentation.
>
> **Last updated:** 2026-04-22

---

## Table of Contents

1. [Foundations: GHGs and CO2-Equivalence](#1-foundations-ghgs-and-co2-equivalence)
2. [GCAM Emissions Architecture](#2-gcam-emissions-architecture)
3. [The Three Policy Instruments](#3-the-three-policy-instruments)
4. [Coverage Configurations: FFICT, UCT, All-GHG](#4-coverage-configurations)
5. [Multi-Gas GHG Policy Mechanics](#5-multi-gas-ghg-policy-mechanics)
6. [Carbon Accounting Deep Dive](#6-carbon-accounting-deep-dive)
7. [Why Model Output ≠ Multiplier × Baseline](#7-why-model-output--multiplier--baseline)
8. [Solver Behavior and Convergence](#8-solver-behavior-and-convergence)
9. [Pakistan-Specific Context](#9-pakistan-specific-context)
10. [Worked Examples](#10-worked-examples)
11. [Units Reference](#11-units-reference)
12. [C++ Implementation Reference](#12-c-implementation-reference)
13. [Common Pitfalls and Interpretation](#13-common-pitfalls-and-interpretation)
14. [Loading Order Rules](#14-loading-order-rules)
15. [Files in This Repository](#15-files-in-this-repository)

---

## 1. Foundations: GHGs and CO2-Equivalence

### The Kyoto Basket

The UNFCCC Kyoto Protocol defines six greenhouse gas groups, each with a different atmospheric warming potential:

| Gas | Formula | GWP100 (AR2) | Main Sources |
|-----|---------|-------------|--------------|
| Carbon dioxide | CO2 | 1 | Fossil fuel combustion, cement, deforestation |
| Methane | CH4 | 21 | Rice paddies, livestock, landfills, natural gas |
| Nitrous oxide | N2O | 310 | Fertilizer, industrial processes, combustion |
| Perfluoroethane | C2F6 | 9,200 | Aluminum smelting |
| Tetrafluoromethane | CF4 | 6,500 | Aluminum smelting |
| Sulfur hexafluoride | SF6 | 23,900 | Electrical switchgear |
| HFCs (125, 134a, 245fa) | Various | 1,030–2,800 | Refrigeration, air conditioning |

### CO2-Equivalence (CO2e)

To compare and aggregate different gases, each is converted to CO2-equivalent using the Global Warming Potential over 100 years (GWP100):

```
Emissions_CO2e = Emissions_gas × GWP100_gas
```

Example: 1 Tg CH4 = 21 Mt CO2e (using AR2 GWPs, which GCAM uses by default).

### Why GWP Choice Matters

GCAM uses **IPCC AR2 GWPs** (the Kyoto Protocol standard). AR5/AR6 use updated values (CH4 = 28, N2O = 265). This matters for comparison with inventories using newer GWPs. Pakistan's NDC doesn't specify which GWP set — assume AR2 for consistency with GCAM.

---

## 2. GCAM Emissions Architecture

### How Technologies Report Emissions

Every GCAM technology that burns fuel or uses industrial processes reports CO2 emissions proportional to the carbon content of its input fuel. These emissions enter a **market** named `"CO2"`. The market is regional (e.g., `Pakistan`).

Non-CO2 gases are handled similarly:
- **CH4**: reported by energy technologies (fugitive emissions, incomplete combustion) and agriculture (rice, livestock)
- **N2O**: reported by agriculture (fertilizer application), some industrial processes
- **F-gases**: reported by specific industrial sectors (aluminum, refrigeration)

Each gas variant has its own market:
- `CO2` — fossil/industrial CO2
- `CO2_LUC` — land-use change CO2 (deforestation, afforestation)
- `CO2_FUG` — fugitive CO2
- `CH4`, `CH4_AWB` (ag waste burning), `CH4_AGR` (agriculture)
- `N2O`, `N2O_AWB`, `N2O_AGR`
- `C2F6`, `CF4`, `HFC125`, `HFC134a`, `HFC245fa`, `SF6`

### Marginal Abatement Cost (MAC) Curves

For non-CO2 gases, GCAM uses **MAC curves** that define how much abatement is available at each carbon price level. When a gas faces a carbon price:

```
Abatement_fraction = f(effective_price)    (from MAC curve lookup)
Actual_emissions = Uncontrolled_emissions × (1 - Abatement_fraction)
```

MAC curves are loaded from `all_energy_emissions_MAC.xml`, `all_aglu_emissions_IRR_MGMT_MAC.xml`, etc. They encode technology-specific abatement options (e.g., capturing CH4 from rice paddies, reducing N2O from fertilizer).

---

## 3. The Three Policy Instruments

GCAM has three policy instruments, all implemented via the `<ghgpolicy>` and `<linked-ghg-policy>` XML elements.

### 3a. Emissions Constraint (`<constraint>`)

The model **endogenously finds the carbon price** that achieves a given emissions level.

```xml
<ghgpolicy name="CO2">
    <market>Pakistan</market>
    <constraint year="2030">68.224</constraint>
    <constraint year="2035">79.666</constraint>
</ghgpolicy>
```

**Mechanism**: The solver creates a "market" where supply = constraint value. It iterates carbon prices until total emissions (demand) equals the constraint (supply). The endogenous carbon price is the key output — it tells you the marginal cost of meeting the target.

**Units**: MTC (million tonnes carbon) for CO2 markets. Mt CO2e for GHG markets.

**Use when**: You have a hard emissions target (e.g., NDC pledge: "reduce emissions to X Mt by 2030").

**Interpolation**: GCAM linearly interpolates between defined years. If you set 2030 and 2050, GCAM computes 2035, 2040, 2045. For clarity, define every model year explicitly.

### 3b. Fixed Carbon Tax (`<fixedTax>`)

The model takes the price as given and **reports the resulting emissions**.

```xml
<ghgpolicy name="CO2">
    <market>Pakistan</market>
    <fixedTax year="2025">25</fixedTax>
    <fixedTax year="2030">31.9</fixedTax>
</ghgpolicy>
```

**Units**: 1990$/tC (1990 US dollars per tonne carbon).

**Mechanism**: Price is fixed; the CO2 market is NOT solved. Technologies see this price signal and adjust their fuel/technology choices accordingly. The model reports how much emissions result.

**Use when**: You want to test "what happens at carbon price X?" or model an actual carbon tax policy.

### 3c. Linked GHG Policy (`<linked-ghg-policy>`)

Links one gas's market to another policy's market, with adjustable price and demand multipliers.

```xml
<linked-ghg-policy name="CH4">
    <market>Pakistan</market>
    <linked-policy>GHG</linked-policy>
    <price-adjust year="1975" fillout="1">5.727</price-adjust>
    <demand-adjust year="1975" fillout="1">21</demand-adjust>
</linked-ghg-policy>
```

**Two knobs**:

| Knob | Effect | Math |
|------|--------|------|
| `price-adjust` | Multiplier from parent policy price to this gas's effective price | `effective_gas_price = parent_price × price-adjust` |
| `demand-adjust` | Multiplier from this gas's emissions to contribution in parent market | `CO2e_contribution = gas_emissions × demand-adjust` |

**Use when**: Linking CO2_LUC to CO2 (FFICT vs UCT), or linking all gases to a GHG umbrella market.

### If Both Constraint and FixedTax Are Set

Constraint takes precedence. The fixedTax value serves as the solver's initial price guess, which can help convergence (the solver starts closer to the answer).

---

## 4. Coverage Configurations

The "coverage" of an emissions policy determines which sectors and gases are constrained. For CO2, the critical split is between fossil/industrial CO2 and land-use CO2 (AFOLU). For multi-gas policies, coverage extends to all Kyoto gases.

### 4a. FFICT — Fossil Fuel and Industrial Carbon Trading

**What it covers**: Energy sector CO2 only (power generation, industry, transport, buildings). AFOLU is invisible to the policy.

**Implementation**: Create a `<ghgpolicy name="CO2">` with constraints, then link CO2_LUC with `price-adjust=0, demand-adjust=0`:

```xml
<linked-ghg-policy name="CO2_LUC">
    <market>Pakistan</market>
    <linked-policy>CO2</linked-policy>
    <price-adjust year="1975" fillout="1">0.0</price-adjust>   <!-- AFOLU doesn't see price -->
    <demand-adjust year="1975" fillout="1">0.0</demand-adjust> <!-- AFOLU doesn't count -->
</linked-ghg-policy>
```

**Effect**: The constraint binds E&IP CO2 exactly to the target value. Land-use emissions/sinks are ignored. This is the cleanest way to model "energy sector emissions reduction" policies.

**File**: `input/extra/policy/pak_co2luc_ffict.xml`

### 4b. UCT — Universal Carbon Tax/Trading

**What it covers**: All CO2 — energy + industrial + AFOLU (deforestation, afforestation).

**Implementation**: Set `price-adjust=1, demand-adjust=1` for CO2_LUC:

```xml
<linked-ghg-policy name="CO2_LUC">
    <price-adjust year="1975" fillout="1">1.0</price-adjust>   <!-- AFOLU sees full price -->
    <demand-adjust year="1975" fillout="1">1.0</demand-adjust> <!-- AFOLU counts toward constraint -->
</linked-ghg-policy>
```

**Effect**: AFOLU faces the carbon price AND counts toward the constraint. If AFOLU is a net **sink** (as in Pakistan), it provides a buffer — E&IP emissions can slightly exceed the raw target because the sink offsets them.

**Pakistan AFOLU**: Pakistan's land sector is a net CO2 sink of approximately -5 to -18 Mt CO2/yr (growing over time due to afforestation programs). Under UCT, this means E&IP can be ~2-6% above the nominal target.

**File**: `input/extra/policy/pak_co2luc_uct.xml`

### 4c. All-GHG — Multi-Gas Economy-Wide

**What it covers**: All Kyoto gases (CO2, CH4, N2O, F-gases) across all sectors.

**Implementation** (two-step):

1. **GHG market with constraints** (Mt CO2e):
```xml
<ghgpolicy name="GHG">
    <market>Pakistan</market>
    <constraint year="2030">564.5</constraint>
</ghgpolicy>
```

2. **Link each gas** to the GHG market via `<linked-ghg-policy>`:
```xml
<linked-ghg-policy name="CO2">
    <market>Pakistan</market>
    <linked-policy>GHG</linked-policy>
    <price-adjust year="1975" fillout="1">1</price-adjust>
    <demand-adjust year="1975" fillout="1">3.667</demand-adjust>
</linked-ghg-policy>
<linked-ghg-policy name="CH4">
    <market>Pakistan</market>
    <linked-policy>GHG</linked-policy>
    <price-adjust year="1975" fillout="1">5.727</price-adjust>
    <demand-adjust year="1975" fillout="1">21</demand-adjust>
</linked-ghg-policy>
<!-- ... similar for N2O, F-gases ... -->
```

**Effect**: The solver finds one GHG price. Each gas sees an effective price proportional to its GWP. Gases with MAC curves (CH4, N2O) can be abated independently of CO2 — e.g., reducing rice paddy CH4 is "counted" toward the total constraint via its GWP contribution.

**Key difference from CO2-only**: The model has more flexibility. It can meet the constraint by abating CO2 (switching fuels in power, improving efficiency) OR by abating CH4/N2O (agricultural practices, waste management) — whichever is cheaper on the MAC curve. This typically produces a **lower carbon price** than a CO2-only constraint with the same stringency, because cheap non-CO2 abatement is available.

**Files**: `input/extra/policy/pak_ghg_constraint_*_v1_ts_const.xml` + `input/extra/policy/pak_linked_ghg_policy.xml`

### 4d. GHG-Energy — Multi-Gas with Energy-Only Pricing

A hybrid approach: **all Kyoto gases count toward the constraint** (economy-wide target), but **only energy-sector gases face the carbon price** (energy-sector instruments). Agricultural CH4 and N2O variants (`CH4_AWB`, `CH4_AGR`, `N2O_AWB`, `N2O_AGR`) have `price-adjust=0`, so they contribute to the constraint via `demand-adjust` but don't respond to the price signal.

This models the policy stance: "We commit to an economy-wide NDC target, but our policy instruments only apply to the energy and industrial sector." This is realistic for many developing countries where agricultural emissions policy is politically infeasible.

**Implications**:
- Agricultural CH4/N2O grow unchecked at baseline rates
- Their growing emissions "eat into" the CO2e budget, forcing deeper cuts from the energy sector
- Carbon prices will be **higher than All-GHG** (no cheap ag abatement) but **lower than CO2-only FFICT** (energy CH4/N2O can still abate)
- More realistic policy representation for Pakistan where agriculture is ~60% of non-CO2

**Implementation**: Uses the same `<ghgpolicy name="GHG">` constraint XMLs as All-GHG, but with `pak_linked_ghg_policy_energy.xml` instead of `pak_linked_ghg_policy.xml`.

**Files**: Same GHG constraint XMLs + `input/extra/policy/pak_linked_ghg_policy_energy.xml`

### 4e. Summary Matrix

| Mode | Policy name | What's constrained | AFOLU CO2 | Non-CO2 GHGs | AG CH4/N2O priced? | Config suffix |
|------|------------|-------------------|-----------|--------------|--------------------|----|
| FFICT | `CO2` | E&IP CO2 only | Excluded | Excluded | N/A | `_ffict_` |
| UCT | `CO2` | All CO2 (E&IP + AFOLU) | Included | Excluded | N/A | `_uct_` |
| All-GHG | `GHG` | All Kyoto gases, all sectors | Included via CO2 link | Included via GWP links | Yes | `_ghg_` |
| GHG-Energy | `GHG` | All Kyoto gases, all sectors | Included via CO2 link | Count but not priced (AG) | No | `_ghg_energy_` |

---

## 5. Multi-Gas GHG Policy Mechanics

### The GWP Weighting Math

When the solver sets the GHG market price to `P_GHG` (in some base unit), each gas sees:

```
Effective_price_gas = P_GHG × price_adjust_gas
```

And each gas contributes to the GHG market demand as:

```
Demand_contribution_gas = Emissions_gas × demand_adjust_gas
```

The solver iterates until:

```
Σ (Emissions_gas × demand_adjust_gas)  =  Constraint_GHG
  over all linked gases
```

### Price-Adjust vs Demand-Adjust: Why They're Different

For CO2: `demand-adjust = 3.667` converts MTC (GCAM's internal CO2 unit) to Mt CO2e. `price-adjust = 1.0` means CO2 sees the full GHG price.

For CH4: `demand-adjust = 21` is the GWP100 (1 Tg CH4 = 21 Mt CO2e). `price-adjust = 5.727 = 21 / 3.667` converts the GHG price (which is per Mt CO2e) to an effective price per unit of CH4 in GCAM's internal units.

The relationship: `price-adjust = demand-adjust / CO2_demand-adjust`. This ensures that the marginal cost of abating 1 Mt CO2e is the same regardless of which gas you're abating — i.e., the model optimizes cost-effectively across gases.

### F-Gases: Price-Adjust = 0

F-gases (C2F6, CF4, HFCs, SF6) have `price-adjust=0`: they don't respond to the carbon price (no MAC curves, or negligible abatement potential at model resolution), but their emissions still count toward the aggregate constraint via `demand-adjust > 0`. This means:
- F-gas emissions are taken as given (exogenous trend)
- They "use up" a portion of the CO2e budget
- The remaining budget must be met by CO2, CH4, and N2O abatement

### What Happens When You Constrain All GHGs

1. **The solver finds a single GHG price** that equates total CO2e demand to the constraint.
2. **CO2 abatement**: energy system switches fuels, deploys renewables/nuclear, improves efficiency. This is the largest lever.
3. **CH4 abatement**: MAC curves kick in for rice paddies (water management), livestock (feed additives, manure management), waste (landfill gas capture), fugitive energy (leak repair). These are often cheap — $5-50/tCO2e.
4. **N2O abatement**: MAC curves for fertilizer (nitrification inhibitors, precision application), industrial processes. Moderate cost.
5. **F-gases**: Not abated (price-adjust=0), but their emissions count.

The result: **more flexible abatement**, **lower carbon price**, and potentially **different energy system outcomes** compared to CO2-only constraints.

---

## 6. Carbon Accounting Deep Dive

### Economy-Wide Accounting Under Constraint

When you constrain `GHG` at X Mt CO2e, the model ensures:

```
CO2_fossil × 3.667 + CO2_LUC × 3.667 + CO2_FUG × 3.667
  + CH4 × 21 + CH4_AWB × 21 + CH4_AGR × 21
  + N2O × 310 + N2O_AWB × 310 + N2O_AGR × 310
  + Σ(F-gas × GWP)
  ≤ X
```

This is the equilibrium condition the solver enforces in each model period.

### The AFOLU Carbon Sink

Pakistan's land-use sector is a net **carbon sink**: deforestation is low, and afforestation programs contribute negative CO2_LUC. Under economy-wide accounting:

- If AFOLU = -15 Mt CO2/yr, that's -15 × 3.667 = -55 Mt CO2e "free credit"
- The energy system can emit more before hitting the cap
- This is a real physical offset — trees are absorbing CO2

### Non-CO2 Dominance in Pakistan

Pakistan's Kyoto Gases (~575 Mt CO2e in 2025) break down roughly as:
- CO2 (energy + industrial): ~250 Mt CO2/yr = ~916 Mt CO2e (via 3.667 conversion from MTC)
- Actually, the IAMC variable "Emissions|Kyoto Gases" reports in CO2e directly
- CH4 + N2O (mostly agriculture: rice, livestock, fertilizer): a very large share
- In the CM baseline, Kyoto Gases are ~574 Mt CO2e vs CO2 E&IP ~250 Mt CO2

This means **agriculture is the dominant source of non-CO2 GHGs in Pakistan**. An all-GHG constraint will therefore exert significant pressure on the agricultural sector through CH4 and N2O pricing.

---

## 7. Why Model Output ≠ Multiplier × Baseline

A common expectation: "If I constrain to 85% of CM, the model should report exactly 85% of CM emissions." This is rarely true. Here's why:

### 7a. General Equilibrium Effects

GCAM is a partial-equilibrium model with inter-sector feedbacks:
- Constraining emissions raises the carbon price
- Higher carbon price changes relative fuel costs → different technology mix
- Different technology mix changes electricity price → different demand → different GDP growth (if macro module is active)
- Different GDP growth → different energy demand → different emissions

The final emissions are the outcome of all these simultaneous adjustments, not a simple percentage cut.

### 7b. MAC Curve Non-Linearity

Marginal abatement costs rise non-linearly. The first 10% reduction might cost $5/tCO2; the next 10% might cost $50/tCO2. The carbon price must rise to the marginal cost of the last tonne abated. This means:
- The relationship between constraint stringency and resulting emissions is non-linear
- Small changes in the constraint can cause large price jumps if the economy hits a "kink" in the aggregate MAC curve

### 7c. Inter-Sector Leakage

If you constrain CO2 (FFICT), uncovered sectors (agriculture, land-use) are unaffected. But:
- Higher electricity prices might reduce irrigation pumping → less agricultural output → less fertilizer → less N2O
- Or: higher energy costs might shift bioenergy demand → land-use change → CO2_LUC feedback

These indirect effects mean covered-sector emissions might be exactly at the constraint, but total economy emissions shift unpredictably.

### 7d. Technology Switching Thresholds

GCAM uses logit share equations. As carbon prices cross certain thresholds, technologies can "flip" — e.g., coal-to-gas switching happens at $20-40/tCO2, gas-to-renewables at $50-100/tCO2. Near these thresholds, small constraint changes cause disproportionate technology shifts.

### 7e. AFOLU Offset (UCT/All-GHG Only)

Under economy-wide accounting, the AFOLU sink "absorbs" some emissions. If the sink is -15 Mt CO2/yr, then a 250 Mt target effectively allows E&IP to emit 265 Mt. The sink magnitude itself changes with land-use decisions (which respond to carbon prices).

### 7f. Intertemporal Smoothing

GCAM runs 5-year periods independently (no perfect foresight). Capital stock from previous periods constrains current-period choices. A tight constraint in 2030 might be "partially met" by capital turnover that started in 2025 without any carbon price.

### Practical Implication

For NDC scenarios: set the constraint, run the model, check the output. The constraint is binding — total covered emissions will equal the constraint value (within solver tolerance). But **other** emission variables (CO2-only, sectoral breakdowns) will differ from naive multiplier calculations.

---

## 8. Solver Behavior and Convergence

### How the Solver Works

GCAM uses a Broyden-method solver (configured in `input/solution/cal_broyden_config.xml`). For each model period:

1. The solver sets an initial guess for the carbon price
2. Runs the economy with that price → calculates total emissions
3. Compares emissions to constraint → adjusts price
4. Repeats until |emissions - constraint| < tolerance

### Convergence Issues

| Problem | Symptom | Fix |
|---------|---------|-----|
| Constraint = 0 | Solver tries infinite price, doesn't converge | Use near-zero (e.g., 1 MTC = 3.67 Mt CO2) |
| Very tight constraint (>50% cut) | Solver oscillates, very high prices | Provide `fixedTax` as initial guess; enable CCS |
| Multiple equilibria | Different runs give different solutions | Set solver parameters in `cal_broyden_config.xml` |
| NaN in carbon price | Division by zero in MAC curves | Check that MAC curves are defined for the region |

### Using FixedTax as Initial Guess

If you set both `<constraint>` and `<fixedTax>` for the same gas/year, the constraint is binding and the fixedTax serves as the solver's starting price. This can dramatically improve convergence:

```xml
<ghgpolicy name="CO2">
    <market>Pakistan</market>
    <constraint year="2030">68.224</constraint>
    <fixedTax year="2030">50</fixedTax>  <!-- starting guess: $50/tC -->
</ghgpolicy>
```

### Solution Tolerance

The solver considers the market "solved" when:
```
|demand - supply| / max(|demand|, |supply|) < tolerance
```
Default tolerance is ~0.001 (0.1%). This means constraint values might be met within ±0.1%.

---

## 9. Pakistan-Specific Context

### Emission Profile

Pakistan's emissions are dominated by:
1. **Energy**: ~250 Mt CO2/yr (2025), growing fast due to coal (CPEC) and gas expansion
2. **Agriculture**: Large CH4 (rice paddies, livestock) and N2O (fertilizer) — these make up the bulk of the gap between CO2 and Kyoto Gases
3. **AFOLU CO2**: Net sink of -5 to -18 Mt CO2/yr
4. **Industry**: Cement, fertilizer, steel — included in E&IP CO2

### NDC Framing

Pakistan's NDC states targets as **percentage reductions from business-as-usual for all GHGs**, not CO2-only. This means:
- The correct modeling approach is the **All-GHG** constraint (`<ghgpolicy name="GHG">`)
- Using CO2-only FFICT is a complementary analysis showing "what if we only constrain the energy sector?"

### Practical Differences: FFICT vs All-GHG for Pakistan

| Aspect | FFICT (CO2 E&IP) | All-GHG |
|--------|-----------------|---------|
| What's constrained | Fossil+industrial CO2 only | CO2 + CH4 + N2O + F-gases |
| Agricultural impact | None (no price signal) | CH4/N2O from rice, livestock, fertilizer face price |
| AFOLU sink credit | None | Yes (-5 to -18 Mt CO2/yr offset) |
| Expected carbon price | Higher (less flexibility) | Lower (cheap CH4/N2O abatement available) |
| Energy system impact | Full burden on energy sector | Shared burden with agriculture |
| Pakistan relevance | "Energy transition only" story | "Economy-wide NDC" story |

### CM Baseline Numbers (CurrentMeasuresRev)

| Variable | 2025 | 2030 | 2035 | 2050 |
|----------|------|------|------|------|
| CO2 E&IP (Mt CO2/yr) | ~250 | ~289 | ~342 | ~595 |
| Kyoto Gases (Mt CO2e/yr) | ~574 | ~663 | ~765 | ~1199 |

The Kyoto Gases are roughly 2.3× the CO2 E&IP, reflecting Pakistan's large agricultural non-CO2.

---

## 10. Worked Examples

### Example A: FFICT CO2-Only (NDC Unconditional)

**Given**: CM E&IP at 2030 = 289.11 Mt CO2. NDC Unconditional = 85% of CM.

1. Target = 0.85 × 289.11 = 245.74 Mt CO2
2. Convert: 245.74 × 12/44 = 67.02 MTC
3. XML: `<ghgpolicy name="CO2"><market>Pakistan</market><constraint year="2030">67.02</constraint>`
4. Add FFICT link: `pak_co2luc_ffict.xml` (AFOLU excluded)
5. Result: model finds carbon price such that E&IP CO2 = 245.74 Mt. Land-use unaffected.

### Example B: All-GHG (NDC Unconditional)

**Given**: CM Kyoto Gases at 2030 = 663.38 Mt CO2e. NDC Unconditional = 85% of CM.

1. Target = 0.85 × 663.38 = 563.87 Mt CO2e
2. XML: `<ghgpolicy name="GHG"><market>Pakistan</market><constraint year="2030">563.87</constraint>`
3. Add linked policy: `pak_linked_ghg_policy.xml` (all gases linked)
4. Result: model finds GHG price; CO2 abates via fuel switching, CH4 abates via agricultural MAC curves. Total CO2e = 563.87 Mt. But CO2-only might be 260 Mt (not 245.74) because some abatement comes from CH4/N2O instead.

### Example C: Why CO2 Output Differs Between Modes

Under FFICT at 85% NDC: CO2 E&IP is exactly the constraint (245.74 Mt, within tolerance).

Under All-GHG at 85% NDC: Total CO2e = 563.87 Mt. But CO2 E&IP might be 260 Mt because:
- CH4 abatement contributes ~30 Mt CO2e (cheap: rice paddy management)
- N2O abatement contributes ~20 Mt CO2e (moderate: fertilizer optimization)
- CO2 only needs to abate ~44 Mt CO2e less than under FFICT
- So CO2 is higher, but total GHGs are at target

---

## 11. Units Reference

| Quantity | GCAM Internal Unit | Common Unit | Conversion |
|----------|-------------------|-------------|------------|
| CO2 constraint | MTC | Mt CO2/yr | Mt CO2 × 12/44 = MTC |
| GHG constraint | Mt CO2e | Mt CO2e/yr | Direct (demand-adjust handles per-gas conversion) |
| Carbon price | 1990$/tC | $/tCO2 | $/tCO2 × 44/12 = $/tC |
| GHG price | 1990$/tCO2e | $/tCO2e | (solver output) |
| Energy | EJ | GWa | EJ × 31.71 = GWa |
| CH4 emissions | TgCH4 | Mt CH4 | 1 Tg = 1 Mt |
| N2O emissions | TgN2O | Mt N2O | 1 Tg = 1 Mt |

---

## 12. C++ Implementation Reference

| File | Class | Purpose |
|------|-------|---------|
| `cvs/objects/policy/source/policy_ghg.cpp` | `GHGPolicy` | Creates CO2/GHG market, applies constraint/fixedTax |
| `cvs/objects/policy/source/linked_ghg_policy.cpp` | `LinkedGHGPolicy` | Links one gas to another's market with price/demand adjust |
| `cvs/objects/policy/source/policy_portfolio_standard.cpp` | `PolicyPortfolioStandard` | RPS, CES, portfolio standards |

Key behaviors in `policy_ghg.cpp`:
- **Line 208-210**: If `fixedTax` set → `unsetMarketToSolve()`, fix price.
- **Line 214-219**: If `constraint` set → `setMarketToSolve()`, add constraint as supply.
- **Line 177-198**: Linear interpolation between defined years for both tax and constraint.
- **Line 173**: Output unit = "MTC" for CO2 markets.

Key behaviors in `linked_ghg_policy.cpp`:
- Price propagation: `effective_price = parent_price × price_adjust`
- Demand contribution: `demand += emissions × demand_adjust` (added to parent market)
- The linked policy does NOT create its own market — it modifies the linked (parent) market.

---

## 13. Common Pitfalls and Interpretation

### Pitfall 1: "My CO2 isn't exactly 85% of baseline"

Under All-GHG, the constraint is on **total CO2e**, not CO2 alone. CO2 will be higher than 85% if cheap non-CO2 abatement is available (which it is in Pakistan).

### Pitfall 2: "The carbon price seems too high/low"

FFICT produces higher prices than All-GHG at the same percentage constraint because:
- FFICT: only energy CO2 can abate → steeper MAC curve
- All-GHG: CH4/N2O can also abate → flatter aggregate MAC curve

### Pitfall 3: "Constraint = 0 crashes the model"

GCAM cannot achieve zero emissions without negative-emission technologies (BECCS, DAC). If they're unavailable for the region, set near-zero (1 MTC ≈ 3.67 Mt CO2) instead.

### Pitfall 4: "FFICT and UCT give similar results"

If Pakistan's AFOLU is a small net sink (-5 to -18 Mt CO2/yr) relative to E&IP (~250-600 Mt), the UCT buffer is only 2-6%. The energy system response is nearly identical.

### Pitfall 5: Leakage and Rebound

When Pakistan faces a carbon price but other regions don't:
- Pakistan's energy-intensive production might shift to unconstrained regions (leakage)
- This is modeled via trade in GCAM (if trade is enabled for the sector)
- Result: Pakistan's emissions hit target, but global emissions might not decrease proportionally

### Pitfall 6: Loading Order

Linked policies MUST be loaded AFTER the policy they link to. If `pak_linked_ghg_policy.xml` is loaded before `pak_ghg_constraint_*.xml`, the GHG market doesn't exist yet and the links fail silently.

---

## 14. Loading Order Rules

**Critical**: In the configuration XML, policy files must appear in this order:

```xml
<!-- CORRECT: constraint creates market, then link attaches to it -->
<Value name="ghg_constraint">../input/extra/policy/pak_ghg_constraint_ndc_uncond_v1_ts_const.xml</Value>
<Value name="ghg_link">../input/extra/policy/pak_linked_ghg_policy.xml</Value>

<!-- WRONG: link before market exists -->
<Value name="ghg_link">../input/extra/policy/pak_linked_ghg_policy.xml</Value>
<Value name="ghg_constraint">../input/extra/policy/pak_ghg_constraint_ndc_uncond_v1_ts_const.xml</Value>
```

Same rule applies to CO2-only: constraint XML before CO2_LUC link XML.

---

## 15. Files in This Repository

### CO2-Only Constraints (FFICT)

| File | Description |
|------|-------------|
| `input/extra/policy/pak_co2_constraint_ndc_uncond_v1_ts_const.xml` | NDC Uncond: 0.85×CM@2030, 0.83×CM@2035+ (MTC) |
| `input/extra/policy/pak_co2_constraint_ndc_cond_v1_ts_const.xml` | NDC Cond: 0.50×CM@2030, 0.50×CM@2035+ (MTC) |
| `input/extra/policy/pak_co2_constraint_netzero_v1_ts_const.xml` | Net Zero: linear to 0 at 2050 (MTC) |
| `input/extra/policy/pak_co2luc_ffict.xml` | FFICT link: AFOLU excluded |
| `input/extra/policy/pak_co2luc_uct.xml` | UCT link: AFOLU included |

### All-GHG Constraints

| File | Description |
|------|-------------|
| `input/extra/policy/pak_ghg_constraint_ndc_uncond_v1_ts_const.xml` | NDC Uncond all-GHG: 0.85×CM@2030, 0.83×CM@2035+ (Mt CO2e) |
| `input/extra/policy/pak_ghg_constraint_ndc_cond_v1_ts_const.xml` | NDC Cond all-GHG: 0.50×CM (Mt CO2e) |
| `input/extra/policy/pak_ghg_constraint_netzero_v1_ts_const.xml` | Net Zero all-GHG: linear to 0 (Mt CO2e) |
| `input/extra/policy/pak_linked_ghg_policy.xml` | Links all gases to GHG market (all gases priced) |
| `input/extra/policy/pak_linked_ghg_policy_energy.xml` | Links all gases to GHG market (AG CH4/N2O NOT priced) |

### Config Files

| File | Coverage |
|------|----------|
| `exe/configuration_*_ffict_v1_ts_const.xml` | CO2 energy-only |
| `exe/configuration_*_uct_v1_ts_const.xml` | CO2 economy-wide |
| `exe/configuration_*_ghg_v1_ts_const.xml` | All-GHG economy-wide |
| `exe/configuration_*_ghg_energy_v1_ts_const.xml` | GHG-Energy: economy-wide target, energy-sector pricing |

### Generator Script

| File | Description |
|------|-------------|
| `analysis/3_generate_emission_constraints_v1.R` | Reads CM baseline, computes all constraints, writes XMLs + configs + trace CSVs |
