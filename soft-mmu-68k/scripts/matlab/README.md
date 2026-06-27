# MATLAB Verification Tooling

This directory contains MATLAB support code for project verification collateral.

The files here are not synthesizable RTL. They are used to model expected behavior, generate golden vectors, and inspect verification coverage for selected RTL blocks.

## Directory layout

- `models/` — MATLAB reference models for RTL behavior.
- `generators/` — scripts/functions that generate golden-vector files.
- `examples/` — runnable demos that exercise the models and generators.

## Current model: `perm_check`

The current MATLAB collateral models `rtl/core/perm_check.v`.

Files:

- `models/mmu_perm_check_reference.m`
- `generators/generate_perm_check_vectors.m`
- `examples/run_perm_check_demo.m`

The reference model uses the same project permission-bit convention as the RTL:

- bit 0: read permission
- bit 1: write permission
- bit 2: execute permission

The generated fault field uses the current project bit assignments:

| Bit | Name |
|---:|---|
| 0 | `no_read` |
| 1 | `write_protect` |
| 2 | `no_execute` |
| 3 | `privilege_related` |
| 4 | `bad_req` |

The current project policy is that `tt_bypass` wins for this checker: the reference model returns `allow = true` and `fault = 0` when transparent-translation bypass is asserted.

## Generated vectors

The generator exhaustively covers:

- user/supervisor mode
- all 3-bit request encodings
- all 3-bit user permission values
- all 3-bit supervisor permission values
- transparent-translation bypass off/on

That produces:

```text
2 * 8 * 8 * 8 * 2 = 2048 rows
```

The demo writes the generated CSV to:

```text
tb/common/golden_vectors/perm_check_golden_vectors.csv
```

## Running the demo

From MATLAB, run:

```matlab
run('soft-mmu-68k/scripts/matlab/examples/run_perm_check_demo.m')
```

The example is location-aware and adds the required `models/` and `generators/` paths before generating the CSV.

## Documentation policy

When MATLAB-generated golden vectors are used by a testbench, the relevant design or verification document should identify:

- the MATLAB reference model used
- the generator used
- the output golden-vector path
- the behavioral scope being modeled
- any first-pass project policy that differs from complete Motorola PMMU behavior
