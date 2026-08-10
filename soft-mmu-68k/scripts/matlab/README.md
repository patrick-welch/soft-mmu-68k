# MATLAB Verification Tooling

This directory contains MATLAB support code for project verification collateral.

The files here are not synthesizable RTL. They are used to model expected behavior, generate directed-case tables and golden vectors, and inspect verification coverage for selected RTL blocks.

## Directory layout

- `models/` - MATLAB reference models for RTL behavior.
- `generators/` - scripts/functions that generate directed-case tables and/or golden-vector files.
- `examples/` - runnable demos that exercise the models and generators.

## Current proven flow: `perm_check`

MGV0 established `perm_check` as the first proven MATLAB-backed vector flow in
this repo:

```text
MATLAB reference model -> generated CSV -> SystemVerilog testbench -> HDL Regression Action
```

The MATLAB source generates the committed CSV vectors, and
`tb/unit/perm_check_tb.sv` consumes that committed CSV as an additional
verification layer. This does not replace RTL verification; it adds a
cross-check against an independently written reference model for this one
checker.

Files:

- `models/mmu_perm_check_reference.m`
- `generators/generate_perm_check_vectors.m`
- `examples/run_perm_check_demo.m`
- `tb/common/golden_vectors/perm_check_golden_vectors.csv`
- `tb/unit/perm_check_tb.sv`

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

The committed generated CSV lives at:

```text
tb/common/golden_vectors/perm_check_golden_vectors.csv
```

## Running the demo

From MATLAB, run:

```matlab
run('soft-mmu-68k/scripts/matlab/examples/run_perm_check_demo.m')
```

The example is location-aware and adds the required `models/` and `generators/` paths before generating the CSV.

## Current in-memory reference flow: `MTC1` TC/CRP span model

MTC1 adds a deterministic MATLAB reference model for the current
TC1B-tested single-level TC/CRP span boundary:

```text
MATLAB scalar reference model -> in-memory directed-case table -> demo assertions
```

This is intentionally different from the `perm_check` golden-vector flow.
MTC1 writes no CSV, creates no output directory, and has no SystemVerilog
consumer in this packet.

Files:

- `models/mmu_tc_crp_span_reference.m`
- `generators/generate_tc_crp_span_vectors.m`
- `examples/run_tc_crp_span_demo.m`

The current MTC1 behavioral boundary is:

```text
VPN             = VA >> PAGE_SHIFT
PAGE_OFFSET     = low PAGE_SHIFT bits of VA
VPN_WIDTH       = VA_WIDTH - PAGE_SHIFT
TABLE_ENTRIES   = low VPN_WIDTH bits of TC
IN_RANGE        = VPN < TABLE_ENTRIES
ROOT_SOURCE     = CRP
SRP_USED        = false
DESCRIPTOR_REQ  = IN_RANGE
DESCRIPTOR_ADDR = CRP + VPN * DESCR_BYTES, when IN_RANGE
PREWALK_FAULT   = none when IN_RANGE
                  unmapped_span when not IN_RANGE
```

An in-range result only permits the current descriptor request. It does not
mean that final translation succeeded. Descriptor validity/type, bus errors,
permissions, TLB behavior, and final physical-address generation remain
outside MTC1.

The generator returns one in-memory MATLAB table with 13 deterministic rows
covering nine conceptual cases:

1. first in-range VPN;
2. last in-range VPN;
3. first out-of-range VPN;
4. alternate CRP;
5. TC span change;
6. SRP inert / supervisor-class access;
7. same VPN with different page offset;
8. zero table span;
9. TC upper bits inert.

Paired comparison cases account for the 13 table rows. The generator-only
metadata columns are `case_name` and `variant`; the remaining columns are the
20 canonical MTC1 scalar-model result fields.

The scalar implementation uses MATLAB `uint64` values for integer-safe scalar
representation. Accordingly:

```text
VA_WIDTH <= 64
FC_WIDTH <= 64
```

are MATLAB scalar representation limits only. They are **not** MC68851
architectural limits and are **not** SM68861 architectural limits.

MTC1 does not implement full Motorola TC address geometry. The following remain
explicitly deferred:

- TIA/TIB/TIC/TID decoding;
- PS-driven page-size selection;
- Initial Shift semantics;
- multi-level address partitioning;
- architectural CRP/SRP root-selection rules;
- root- and pointer-descriptor traversal.

Run the MTC1 demo from the Git working-tree root with:

```matlab
run('soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m')
```

If MATLAB is already in the `soft-mmu-68k/` project-content directory, the
equivalent invocation is:

```matlab
run('scripts/matlab/examples/run_tc_crp_span_demo.m')
```

The demo adds the required model/generator paths, displays the in-memory
directed-case table, prints a concise summary, and asserts the packet invariants
without creating a committed artifact.

## Documentation policy

When MATLAB-generated golden vectors are used by a testbench, the relevant design or verification document should identify:

- the MATLAB reference model used
- the generator used
- the output golden-vector path
- the consuming SystemVerilog testbench
- the behavioral scope being modeled
- any first-pass project policy that differs from complete Motorola PMMU behavior

Do not imply that MATLAB replaces RTL verification, directed HDL tests, integration benches, or HDL regression. Treat MATLAB-backed vectors as packet-specific reference collateral.
