# fia — Fiscal Incidence Analysis package for Stata

> Standardized analytics for CEQ-based fiscal equity indicators.  


## Overview

`fia` is a modular Stata package that computes a comprehensive set of fiscal incidence indicators from harmonized FIA microdata. It follows the CEQ (Commitment to Equity) methodology (Lustig, 2018) and outputs results in a standardized format compatible with the Fiscal Equity Hub indicator database.

## Installation

```stata
* Local development: add the package folder to your ado path
adopath ++ "path/to/_fia_package"

* Future: net install
net install fia, from("https://raw.githubusercontent.com/daniel-valdgon/Fiscal_Equity-Hub/main/_fia_package")
```

## Quick Start

```stata
use "microdata_GMB.dta", clear

fia core [aw=pondih], ///
    country(GMB) ///
    output("GMB_indicators.xlsx") ///
    taxonomy("correlative.xlsx") ///
    tax(PIT CIT) ///
    transfer(CCT UCT pensions) ///
    indtax(VAT excise) ///
    inkind(education health) ///
    subsidy(energy_sub food_sub) ///
    pline(zref line_1)
```

## Subcommands

| Command | Indicator IDs | Description |
|---------|--------------|-------------|
| `fia core` | All | Run full pipeline and export to Excel |
| `fia setup` | — | Validate data, set policy globals |
| `fia inequality` | 3, 4 | Gini coefficient, Theil index |
| `fia poverty` | 10–26 | FGT0 (headcount), FGT1 (gap) |
| `fia incidence` | 37, 38 | Netcash and conditional incidence by decile |
| `fia marginal` | 44, 45 | Marginal contribution to poverty and inequality |
| `fia concentration` | 39, 40, 42, 43 | Concentration shares, coefficients, Kakwani |
| `fia coverage` | 52–59 | Coverage by decile, targeting errors |
| `fia effectiveness` | 48, 49 | CEQ impact and spending effectiveness |
| `fia redistribution` | 46, 47, 67–69 | Redistributive impact, 90-10 ratio, absolute Gini, RS decomposition |
| `fia shares` | 60 | Share of consumption/income by decile |
| `fia export` | — | Merge taxonomy IDs and export to Excel |

## Required Variables

The input dataset must contain:

| Variable | Description |
|----------|-------------|
| `hhid` | Household identifier |
| `pondih` | Household sampling weight |
| `ymp_pc` | Pre-fiscal (market) income per capita |
| `yn_pc`, `yd_pc`, `yc_pc`, `yf_pc` | Post-fiscal income concepts (optional) |
| Instrument variables | As specified in `tax()`, `transfer()`, etc. (both levels and `_pc` suffixes) |
| `zref` | Primary poverty line (or as specified in `pline()`) |

## Dependencies

- **sp_groupfunction**: Gini, Theil, coverage, poverty estimation via Mata
- **groupfunction**: Collapse-like weighted means
- **quantiles**: Weighted quantile/decile generation
- **covconc** (optional): Concentration coefficients

These ados should be installed or available in your ado path (e.g., in `_ado/`).

## Architecture

```
fia.ado                 ← Main dispatcher (gettoken → fia_<subcmd>)
fia.sthlp               ← Help file
fia_core.ado            ← Orchestrator: setup → deciles → all subcommands → export
fia_setup.ado           ← Data validation, policy macro definitions
fia_inequality.ado      ← Gini + Theil (sp_groupfunction)
fia_poverty.ado         ← FGT0 + FGT1 (sp_groupfunction)
fia_incidence.ado       ← Netcash + conditional incidence
fia_marginal.ado        ← Marginal contributions (counterfactual income)
fia_concentration.ado   ← Concentration shares, CC, Kakwani
fia_coverage.ado        ← Coverage by decile + targeting errors
fia_effectiveness.ado   ← CEQ impact & spending effectiveness
fia_redistribution.ado  ← RI, 90-10 ratio, abs Gini, poverty impact, RS
fia_shares.ado          ← Income/consumption shares by decile
fia_export.ado          ← Taxonomy merge + Excel export
example_fia.do          ← Usage example
```

Each subcommand saves its results to a global tempfile (`$fia_result_<name>`) so they can be accessed individually or appended by `fia_export`.

## Comparison with Do-File Pipeline

| Feature | Do-files (3-00 to 3-16) | fia package |
|---------|------------------------|-------------|
| Entry point | `3-00-Run_All_Indicators.do` | `fia core` |
| Configuration | Global macros in 3-00 | `syntax` options + `fia_setup` |
| Modularity | Separate do-files, `include` | Separate ado programs, auto-loaded |
| Reproducibility | Must set paths manually | Self-contained with `adopath` |
| Help | Header comments | `help fia` (SMCL) |
| Error handling | `cap noisily` in runner | Built into each subcommand |

## Authors

- Daniel Valderrama (dvalderrama1@worldbank.org)
- JM Monroy (jmonroypaez@worldbank.org)

## License

GNU General Public License v3.0 — see [LICENSE](../LICENSE)
