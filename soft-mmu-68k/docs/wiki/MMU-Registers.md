# MMU Registers

## Purpose

The register block provides the software-visible configuration and status state needed by the current first-pass Memory Management Unit (MMU) implementation.

At present, the implemented register set includes:

- **Current Root Pointer (CRP)**
- **Supervisor Root Pointer (SRP)**
- **Translation Control (TC)**
- **Transparent Translation 0 (TT0)**
- **Transparent Translation 1 (TT1)**
- **MMU Status Register (MMUSR)**

The register block should be read as a first-pass implementation packet. It exposes the register image needed by the current RTL and Basys 3 smoke demo. It is not yet a complete architectural model of every Motorola PMMU register behavior.

## Where implemented in repo

The register block is implemented in:

- `rtl/core/mmu_regs.v`

It is instantiated and consumed by:

- `rtl/core/mmu_top.v`

It is configured by the current Basys 3 smoke-demo harness in:

- `fpga/basys3/tops/top_mmu_demo.v`

It is unit-tested in:

- `tb/unit/mmu_regs_tb.sv`

## Register address map

The current RTL uses a simple 4-bit register-select interface.

| Address | Register | Meaning |
|---:|---|---|
| `4'h0` | `CRP` | Current Root Pointer |
| `4'h1` | `SRP` | Supervisor Root Pointer |
| `4'h2` | `TC` | Translation Control |
| `4'h3` | `TT0` | Transparent Translation Register 0 image |
| `4'h4` | `TT1` | Transparent Translation Register 1 image |
| `4'h5` | `MMUSR` | MMU Status Register image |

The RTL exposes `wr_en`, `rd_en`, `addr`, `wr_data`, and `rd_data` for register access. Register outputs are also exported to the rest of the MMU as `crp`, `srp`, `tc`, `tt0`, `tt1`, and `mmusr`.

## Reset behavior

The current block uses a synchronous active-low reset.

On reset, all implemented register images are cleared to zero:

- `CRP = 0`
- `SRP = 0`
- `TC = 0`
- `TT0 = 0`
- `TT1 = 0`
- `MMUSR = 0`

The project treats `TC = 0` as translation disabled immediately after reset for the current first-pass design.

## CRP and SRP

`CRP` and `SRP` are parameterized to `PA_WIDTH` and are exposed as physical-address-width register images.

Current behavior:

- writes load `wr_data[PA_WIDTH-1:0]`
- reads zero-extend the register image into `rd_data[31:0]`
- `CRP` is currently used by `mmu_top` as the page-table base presented to the first-pass page walker
- `SRP` is stored and exposed, but not yet fully consumed as a complete supervisor-root selection model

## TC

`TC` is a 32-bit register image.

Current behavior:

- writes store the full 32-bit value
- reads return the full 32-bit value
- the current integration derives first-pass table configuration from this image

This page does not claim complete Motorola `TC` field compatibility. Exact field semantics remain part of the deferred compatibility work.

## TT0 and TT1

`TT0` and `TT1` are 32-bit register images used by the current first-pass transparent-translation subset.

The current `mmu_top` implementation interprets the following subset:

| Bits | Current first-pass meaning |
|---:|---|
| `[31:24]` | logical-address high-byte base |
| `[23:16]` | logical-address high-byte mask, where `1` means don't care |
| `[15]` | entry enable |
| `[14]` | match supervisor normal-memory accesses |
| `[13]` | match user normal-memory accesses |
| `[12]` | match program space |
| `[11]` | match data space |

CPU/special space is explicitly excluded from transparent-translation matches in the current first-pass implementation.

On a transparent match, the current design returns an identity-style physical address by resizing the logical address onto the physical-address bus. This bypasses descriptor translation and page-derived permission checking for an otherwise valid CPU request.

This is a narrow project subset, not a complete Motorola TT/TTR implementation.

## MMUSR

`MMUSR` is a 16-bit status image returned in the low half of `rd_data`.

The current first-pass layout follows the visible status-class categories used by the project RTL:

| Bit(s) | Name | Current meaning |
|---:|---|---|
| `[15]` | `B` | bus error |
| `[14]` | `L` | limit violation |
| `[13]` | `S` | supervisor violation |
| `[12]` | `A` | access-level violation |
| `[11]` | `W` | write-protect violation |
| `[10]` | `I` | invalid descriptor/page |
| `[9]` | `M` | modified |
| `[8]` | reserved | forced low by this block |
| `[7]` | `G` | globally shared |
| `[6:4]` | reserved | forced low by this block |
| `[3:0]` | level | level number field |

Current first-pass write policy:

- status-class bits are software-writable for unit testing and early bring-up
- level bits are directly writable
- reserved bits read back as zero

This is a practical early register image. It is not yet a complete hardware-produced Motorola `MMUSR` / `PTEST` result model.

## Basys 3 demo configuration

The Basys 3 smoke-demo top configures the MMU after reset using the register write interface.

Current demo constants include:

- `CRP` receives the demo table base address
- `TC` receives `TC_DEMO_VALUE`
- `TT0` receives `TT0_DEMO_VALUE`
- `TT1` receives `TT1_DEMO_VALUE`

The demo uses a tiny built-in descriptor responder and a small LED status view. It is a hardware smoke harness, not a complete 68k system.

## Verification status

The unit testbench `tb/unit/mmu_regs_tb.sv` checks:

- reset behavior
- readback behavior
- write/read behavior for the implemented registers
- `MMUSR` reserved-bit masking
- `MMUSR` writable status and level fields

The broader integration behavior is exercised through `mmu_top` and the Basys 3 smoke-demo path.

## Deferred compatibility work

The following are intentionally not claimed as complete by this page:

- full Motorola `TC` field decoding
- full `TT0` / `TT1` Motorola-compatible transparent-translation behavior
- full `MMUSR` synthesis from all translation and `PTEST` termination cases
- complete supervisor-root selection behavior using `SRP`
- full PMOVE/MOVEC instruction semantics around these registers

## Documentation hygiene note

This page is maintained from repo-controlled source under `soft-mmu-68k/docs/wiki/` and should not contain generated assistant-only citation artifacts.
