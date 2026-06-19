# Fiscal Equity Hub Revamping Plan

## Objective

Turn the current script collection into a single, executable, validation-first pipeline with one source of truth for setup, discovery, checks, staging, indicator computation, and exports.

## What Is Broken Today

1. The main orchestrator does not match the real project state.
2. Some include targets referenced by the trunk do not exist.
3. Path definitions are duplicated and inconsistent across scripts.
4. Policy macro definitions do not use one stable contract across modules.
5. Inventory, validation, setup, and indicator logic are mixed together.
6. Dataset discovery is repeated in multiple places.
7. There is no single manifest of detected projects and datasets.
8. Validation exists, but it is not organized as a formal gate before indicator production.

## Target Architecture

The pipeline should be reorganized into these sections, in this exact order:

1. Bootstrap
2. Registry and configuration
3. Inventory and manifest build
4. Structural validation
5. Schema validation
6. Harmonization validation
7. External reconciliation
8. Staging and derived variables
9. Indicator computation
10. Export and product assembly
11. Regression and release checks

## Proposed Folder Logic

Keep the current repository layout, but inside the scripts area organize the workflow conceptually as:

1. `00-setup/`
2. `01-registry/`
3. `02-inventory/`
4. `03-validation/`
5. `04-staging/`
6. `05-indicators/`
7. `06-exports/`
8. `07-tests/`
9. `revamping/`

This does not have to be implemented in one step, but all new work should move in this direction.

## Concrete To-Do List

### Phase 1. Make the pipeline truthful

1. Decide the single entry point that will remain authoritative.
2. Rewrite `00-Trunk.do` so it only calls scripts that actually exist.
3. Standardize the root path logic across all active scripts.
4. Remove or quarantine obsolete scripts that are no longer part of the active flow.
5. Define which scripts are production, experimental, and archived.

### Phase 2. Unify setup and configuration

1. Create one canonical setup file for user paths, globals, package checks, and output folders.
2. Move all duplicated path globals out of indicator scripts.
3. Create one canonical policy-definition file.
4. Replace inconsistent local/global macro contracts with one stable naming convention.
5. Add startup assertions that required globals and include files exist.

### Phase 3. Build a real inventory layer

1. Replace repeated folder scans with one inventory script.
2. Build a manifest dataset with one row per detected project.
3. Save in the manifest at least:
   - country
   - project folder
   - dataset path
   - folder depth
   - file count
   - naming status
   - validation status
4. Make all downstream scripts consume the manifest instead of rescanning folders.

### Phase 4. Formalize validation before indicators

1. Split validation into separate modules:
   - structure checks
   - schema checks
   - harmonization checks
   - metadata checks
   - benchmark checks
2. Require validation to pass before indicators can run.
3. Write all validation outputs to auditable logs and summary datasets.
4. Add explicit warning vs failure rules.

### Phase 5. Fill the missing checks

1. Check that every include target exists before execution.
2. Check uniqueness of household and individual keys.
3. Check required variables, forbidden variables, and variable types.
4. Check valid ranges for weights, years, poverty lines, PPPs, and CPI values.
5. Check sign conventions for taxes, transfers, subsidies, and in-kind components.
6. Check that totals equal the sum of components.
7. Check that income concepts can be reconstructed from fiscal instruments.
8. Check that per-capita and total variables are internally consistent.
9. Check that metadata workbook values match the microdata fields.
10. Check taxonomy coverage and orphan mappings.
11. Check merge success rates and unmatched observations.
12. Check that output datasets are reproducible after refactors.

### Phase 6. Cleanly separate staging from indicators

1. Move deciles, centiles, PPP conversions, and helper derivations into a staging layer.
2. Make indicator scripts assume validated staged inputs.
3. Ensure indicator scripts only compute indicators, not discover files or define project paths.
4. Reuse one shared setup include for all `3-xx` scripts.

### Phase 7. Stabilize outputs and testing

1. Define one output contract for cleaned indicators, logs, and final products.
2. Add a regression test harness that compares old and new outputs after structural refactors.
3. Keep one smoke test for the full pipeline and narrower tests for each module.
4. Prevent export steps from running if upstream validation failed.

## Immediate Priority Order

If we do this pragmatically, the next implementation order should be:

1. Fix `00-Trunk.do` so it reflects reality.
2. Create one canonical setup/config contract.
3. Build the manifest-based inventory script.
4. Rebuild validation as explicit pre-indicator gates.
5. Refactor indicator scripts to consume staged validated inputs.
6. Add regression tests for refactors.

## Working Rules During Revamp

1. No new active script should define its own root path logic.
2. No indicator script should scan folders directly.
3. No validation script should also compute production indicators.
4. Every structural refactor must be followed by a comparison test against the previous output.
5. The trunk script must remain executable at every milestone.

## First Concrete Milestone

Milestone 1 should deliver:

1. A cleaned `00-Trunk.do`.
2. A single setup/config file.
3. A single inventory/manifest file.
4. A minimal preflight validation module.
5. A short smoke test that proves the trunk runs end to end.

## Open Questions To Resolve While Polishing

1. What is the official source of truth when both microdata and core indicators exist?
2. Which scripts are active and which are legacy?
3. What is the mandatory naming convention for country/project folders?
4. Should validation stop on first failure or continue and summarize all failures?
5. Which outputs are mandatory before a run is considered publishable?

## Suggested Execution Style

Work incrementally in small refactors:

1. Change one contract.
2. Run a targeted validation test.
3. Compare outputs.
4. Only then move to the next layer.
