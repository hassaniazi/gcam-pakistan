# python3 -c "
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

# " 2>/dev/null