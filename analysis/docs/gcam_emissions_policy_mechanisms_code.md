# GCAM Emissions Policy Mechanisms

> Reference for how GCAM implements emissions constraints, carbon taxes, and sector coverage.
> Based on C++ source (`cvs/objects/policy/`) and existing XML files (`input/policy/`).

---

## 1. The Two Core Instruments

GCAM has two ways to impose an emissions policy, both via the `<ghgpolicy>` XML element:

### 1a. Emissions Constraint (`<constraint>`)

The model **finds the carbon price** that achieves a given emissions level.

```xml
<ghgpolicy name="CO2">
    <market>Pakistan</market>
    <constraint year="2030">68.224</constraint>
    <constraint year="2035">79.666</constraint>
</ghgpolicy>
```

- **Units**: MTC (million tonnes carbon). Convert from Mt CO2: `Mt CO2 × 12/44 = MTC`.
- **Mechanism**: The solver sets the CO2 market to "solve" and adds the constraint as supply. It iterates until demand (emissions) equals supply (constraint).
- **Use when**: You have a hard emissions target (e.g., NDC pledges).
- **Output**: The endogenous carbon price tells you the cost of meeting the target.

### 1b. Fixed Carbon Tax (`<fixedTax>`)

The model takes the price as given and **reports the resulting emissions**.

```xml
<ghgpolicy name="CO2">
    <market>Pakistan</market>
    <fixedTax year="2025">25</fixedTax>
    <fixedTax year="2030">31.9</fixedTax>
</ghgpolicy>
```

- **Units**: 1990$/tC (1990 US dollars per tonne carbon). Convert from $/tCO2: `$/tCO2 × 44/12 = $/tC`.
- **Mechanism**: Price is fixed; the market is NOT solved. The model reports how much emissions result.
- **Use when**: You want to test "what happens at carbon price X?"
- **Example**: `input/policy/carbon_tax_25_5.xml` ($25/tC growing at 5%/yr).

### If both are set

Constraint takes precedence. The fixedTax value serves as the solver's initial price guess, which can help convergence.

### Interpolation

GCAM linearly interpolates between defined years. If you set 2030 and 2050, GCAM computes 2035, 2040, 2045 automatically. However, for clarity and to avoid surprises, it's best to define every model year explicitly (every 5 years: 2025, 2030, ..., 2100).

---

## 2. Sector Coverage: FFICT vs UCT

The policy `name` determines which gases participate. But for CO2, there's a critical split between **fossil/industrial CO2** and **land-use CO2 (AFOLU)**. This is controlled by a `<linked-ghg-policy>` for `CO2_LUC`.

### What is `CO2_LUC`?

In GCAM, technologies report their CO2 emissions to a market named `CO2`. Land-use-change emissions report to a separate market named `CO2_LUC`. A linked policy connects `CO2_LUC` back to `CO2` with two knobs:

```xml
<linked-ghg-policy name="CO2_LUC">
    <market>Pakistan</market>
    <linked-policy>CO2</linked-policy>
    <price-adjust year="1975" fillout="1">X</price-adjust>
    <demand-adjust year="1975" fillout="1">Y</demand-adjust>
</linked-ghg-policy>
```

| Knob | What it controls |
|------|------------------|
| `price-adjust` | Does AFOLU see the carbon price? 0.0 = no, 1.0 = yes. |
| `demand-adjust` | Does AFOLU CO2 count toward the constraint? 0.0 = no, 1.0 = yes. |

### The Three Configurations

| Name | price-adjust | demand-adjust | Result |
|------|-------------|---------------|--------|
| **FFICT** (Fossil Fuel Industrial Carbon Trading) | 0.0 | 0.0 | Energy-only: AFOLU is invisible to the policy. Only fossil/industrial CO2 is constrained. |
| **UCT** (Universal Carbon Tax/Trading) | 1.0 | 1.0 | Economy-wide: AFOLU faces the price AND counts in the constraint. If AFOLU is a net sink (as in Pakistan: -11 to -18 Mt CO2/yr), it offsets E&IP emissions. |
| **UCT price-only** | 1.0 | 0.0 | AFOLU faces the price signal but doesn't count toward the constraint. Used in fixedTax scenarios. |

### Example files in this repo

| File | Type | Pattern |
|------|------|---------|
| `input/policy/global_ffict.xml` | FFICT | `price=0.0, demand=0.0` for all regions |
| `input/policy/global_uct.xml` | UCT price-only | `price=1.0, demand=0.0` (for tax scenarios) |
| `input/policy/global_uct_in_constraint.xml` | Full UCT | `price=1.0, demand=1.0` (for constraint scenarios) |
| `input/extra/policy/pak_co2luc_ffict.xml` | FFICT | Pakistan-only, energy-only |
| `input/extra/policy/pak_co2luc_uct.xml` | Full UCT | Pakistan-only, energy+agriculture |

### Pakistan AFOLU context

Pakistan's land-use sector is a **net CO2 sink** (approx -5 to -18 Mt CO2/yr, growing over time). This means:

- Under **FFICT**: The constraint binds E&IP CO2 exactly to the target.
- Under **UCT**: The AFOLU sink provides a buffer — E&IP can be slightly above target (by ~2-6%) because the sink offsets it.

---

## 3. Market Scope: Regional vs. Global

The `<market>` element determines whether the policy is regional or global:

```xml
<market>Pakistan</market>   <!-- Pakistan-only: carbon price/constraint applies to Pakistan only -->
<market>global</market>     <!-- All regions share one carbon market -->
```

- For Pakistan scenarios: always use `<market>Pakistan</market>`.
- Global carbon trading uses `<market>global</market>` — one region sets the constraint/tax, others get `<ghgpolicy name="CO2"><market>global</market></ghgpolicy>` with no values (they participate in the shared market).

---

## 4. Multi-Gas Economy-Wide Policy (GHG)

For economy-wide multi-gas policies (not currently used in this project, but available):

1. Create a `<ghgpolicy name="GHG">` with constraints.
2. Link individual gases via `<linked-ghg-policy>` with GWP multipliers:

```xml
<linked-ghg-policy name="CO2">
    <linked-policy>GHG</linked-policy>
    <demand-adjust year="1975" fillout="1">3.667</demand-adjust>  <!-- tC → tCO2e -->
</linked-ghg-policy>
<linked-ghg-policy name="CH4">
    <linked-policy>GHG</linked-policy>
    <price-adjust year="1975" fillout="1">5.727</price-adjust>
    <demand-adjust year="1975" fillout="1">21</demand-adjust>     <!-- GWP100 -->
</linked-ghg-policy>
```

Example: `input/policy/ghg_net0_constraint_global.xml` + `input/policy/linked_ghg_policy.xml`.

---

## 5. Loading Order

**Critical rule**: Linked policies must be loaded AFTER the policy they link to.

In configuration XML:
```xml
<!-- CORRECT ORDER -->
<Value name="co2_constraint">../input/extra/policy/pak_co2_constraint_ndc_uncond.xml</Value>
<Value name="co2luc_link">../input/extra/policy/pak_co2luc_ffict.xml</Value>

<!-- WRONG ORDER — will produce errors -->
<Value name="co2luc_link">../input/extra/policy/pak_co2luc_ffict.xml</Value>
<Value name="co2_constraint">../input/extra/policy/pak_co2_constraint_ndc_uncond.xml</Value>
```

This is noted in `global_uct.xml`: *"WARNING: Linked policies must be read in after the policy to which it links."*

---

## 6. Units Reference

| Quantity | GCAM Internal Unit | Common Unit | Conversion |
|----------|-------------------|-------------|------------|
| Emissions constraint | MTC | Mt CO2/yr | Mt CO2 × 12/44 = MTC |
| Carbon price | 1990$/tC | $/tCO2 | $/tCO2 × 44/12 = $/tC |
| Energy | EJ | GWa | EJ × 31.71 = GWa |

---

## 7. Worked Example: Pakistan NDC Unconditional

**Given**: CM E&IP at 2030 = 294.30 Mt CO2. NDC Unconditional = 85% of CM.

**Step 1**: Target = 0.85 × 294.30 = 250.155 Mt CO2

**Step 2**: Convert to MTC = 250.155 × 12/44 = 68.224 MTC

**Step 3**: Create `<ghgpolicy name="CO2"><market>Pakistan</market><constraint year="2030">68.224</constraint></ghgpolicy>`

**Step 4**: Choose coverage:
- Energy-only → add `pak_co2luc_ffict.xml`
- Energy+Ag → add `pak_co2luc_uct.xml`

**Step 5**: Add both files to configuration XML (constraint FIRST, link SECOND).

---

## 8. C++ Implementation Reference

| File | Class | Purpose |
|------|-------|---------|
| `cvs/objects/policy/source/policy_ghg.cpp` | `GHGPolicy` | Creates CO2 market, applies constraint/fixedTax |
| `cvs/objects/policy/source/linked_ghg_policy.cpp` | `LinkedGHGPolicy` | Links one gas to another's market with adjustable price/demand |
| `cvs/objects/policy/source/policy_portfolio_standard.cpp` | `PolicyPortfolioStandard` | Share-based or quantity-based portfolio standards (RPS, CES) |

Key behaviors in `policy_ghg.cpp`:
- Line 208-210: If `fixedTax` set → `unsetMarketToSolve()`, fix price.
- Line 214-219: If `constraint` set → `setMarketToSolve()`, add constraint as supply.
- Line 177-198: Linear interpolation between defined years for both tax and constraint.
- Line 173: Output unit = "MTC".

---

## 9. Solver Notes

- **Constraint = 0**: GCAM may fail to solve if no negative-emission technologies (BECCS, DAC) are available. First try 1.0 MTC (= 3.67 Mt CO2) as near-zero instead of absolute zero.
- **Very tight constraints** (>50% reduction from baseline): High carbon prices may cause nonlinear solver behavior. Check `exe/logs/main_log.txt` for convergence issues.
- **Order of solver relaxation**: If a scenario fails, first try relaxing the constraint (e.g., NDC Cond 50% → 55%), then check if CCS technologies are enabled for Pakistan.
