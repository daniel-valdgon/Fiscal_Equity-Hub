# GSG3 Fiscal Equity Hub - Data Hub

This repository is the operational workspace for the GSG3 Fiscal Equity Hub pipeline. It combines source data, Stata scripts, intermediate artifacts, and final products used to build and maintain the Core Database.

The project is designed for reproducibility across countries and survey rounds, with a consistent directory structure and validation-first workflow.

## What This Repository Does

The Data Hub supports the full production cycle for fiscal incidence outputs:
- ingest country microdata and metadata,
- enforce structure and naming checks,
- generate harmonized indicators and simulation outputs,
- run cross-file validation diagnostics,
- export standardized tables for the Core Database and reporting products.

## Repository Layout

```text
00_Archive/
	Historical snapshots and prior repository states.

01-Data/
	Main input layer.
	- 00-Aux/                         Supporting reference files.
	- 01-01-FIA_Metadata/             Survey metadata by country and round.
	- 01-02-FIA_Microdata/            Core microdata inputs (.dta).
	- 01-03-FIA_Core Indicators/      Country-level core indicator packages.
	- 02-01-Fiscal-Aggregates/        Fiscal aggregates and related inputs.

02-Scripts/
	Stata code and custom ado utilities.
	- wb419055/00-Trunk.do            Main orchestration and checks.
	- wb419055/10. Outputs - Tool.do  Core database output generation.
	- wb419055/2. Validation.do       Validation metrics and exports.
	- wb419055/_ado/                  Project-specific ado programs.

03-Outputs/
	Intermediate and final run artifacts.

04-Products/
	Deliverables for database integration, metadata, CEQ Core, and QAG.
```

## Pipeline Architecture

### 1) Input Discovery and Structural Checks

The trunk script inspects microdata folders and validates expected structure.

Current checks include:
- each project folder should contain one `.dta` file,
- the data filename should match the folder naming convention,
- assertion diagnostics print explicit context to simplify debugging.

Primary script:
- `02-Scripts/wb419055/00-Trunk.do`

### 2) Policy Variable Framework

Policy groups are defined as local/global macro sets (direct taxes, social contributions, transfers, subsidies, indirect taxes, and in-kind transfers). These macro groups standardize downstream calculations and validation routines.

### 3) Output Generation for Core Database

The outputs script computes and exports long-format results to the Core Database workbook, including:
- scenario parameter snapshots,
- net cash positions by deciles,
- distributional indicators (gini, theil, poverty measures),
- social protection metrics (benefits, means, coverage, beneficiaries).

Primary script:
- `02-Scripts/wb419055/10. Outputs - Tool.do`

### 4) Validation Layer

The validation script compares scenario outputs to reference scenario datasets and writes diagnostics for QA.

Validation outputs include:
- wrong-observation rates,
- absolute relative-difference indicators,
- policy-level summary diagnostics.

Primary script:
- `02-Scripts/wb419055/2. Validation.do`

## Data and Naming Standards

To keep the pipeline stable across countries:
- use country/year/project folder nesting consistently,
- keep one primary simulation `.dta` file per project folder,
- align main `.dta` filename with project folder name where expected,
- preserve standardized variable names used by policy macro definitions,
- keep generated artifacts in `03-Outputs/` and final deliverables in `04-Products/`.

## Runtime Prerequisites

- Stata (recommended: Stata/SE or newer).
- Access permissions to the workspace path and shared folders.
- Project ado utilities available in `02-Scripts/wb419055/_ado/`.
- Expected global/local environment variables initialized by the main scripts.

## Typical Execution Flow

1. Open Stata in this repository workspace.
2. Set or verify user-specific root/global path configuration.
3. Confirm required inputs under `01-Data/`.
4. Run `02-Scripts/wb419055/00-Trunk.do` for structure checks and setup.
5. Run `02-Scripts/wb419055/10. Outputs - Tool.do` to produce database-ready outputs.
6. Run `02-Scripts/wb419055/2. Validation.do` to generate validation diagnostics.
7. Review resulting files in `03-Outputs/` and `04-Products/`.

## Output Targets

Main generated products are typically written to:
- Core database workbook sheets (scenario and long-format indicator tabs),
- validation sheets by scenario,
- output datasets used for downstream reporting and QA.

## Quality Assurance Approach

The workflow emphasizes traceable validation before publishing products:
- explicit assertions for folder/file expectations,
- fail-fast checks with contextual diagnostic messages,
- scenario-level comparison against reference outputs,
- standardized long-format exports for consistency across countries.

## Collaboration and Versioning Guidelines

- Do not edit archived material in `00_Archive/` unless explicitly required.
- Keep script headers current (author, date, intent, and change notes).
- Prefer additive changes and preserve backward compatibility of variable names.
- Document any new country-specific assumptions in script comments and PR notes.
- Verify naming and path assumptions before committing.

## Recommended GitHub Repository Sections

If this folder is published as a standalone GitHub repository, consider adding:
- `LICENSE` (institution-approved),
- `CONTRIBUTING.md` (review and coding conventions),
- `CODEOWNERS` (review routing),
- issue templates for data, code, and validation incidents.

## Project Context

This Data Hub is part of the broader Fiscal Equity Hub production environment and is intended for internal analytical operations, reproducible scenario processing, and curated Core Database generation.
