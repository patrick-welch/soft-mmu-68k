# Descriptor Formats

This page documents the descriptor formats used by the current **Soft Memory Management Unit (Soft MMU)** project.

It is critical to read this page carefully, because the current repo has a
Motorola-aligned long-format descriptor subset, but still only a minimal
single-level live walker.

## Purpose

A **descriptor** is a translation-structure record that contains address and policy information used by the memory-management system.

In Motorola-style memory-management terminology, descriptors can describe:

- root translation structures
- pointer or table structures
- page mappings

In this repo, descriptor handling is split between:

- a combinational reference-style packing and unpacking module
- the currently live translation datapath

The purpose of this page is to explain both, and to explain where they are aligned and where they remain intentionally limited.

## Where implemented in repo

Primary sources for current descriptor behavior:

- design description: `docs/design/descriptor_formats.md`
- descriptor pack/unpack implementation: `rtl/core/descriptor_pack.v`
- current live walker descriptor consumption: `rtl/core/pt_walker.v`
- current integration context: `rtl/core/mmu_top.v`
- current repo-status statement: `README.md`
- Basys 3 smoke-demo descriptor responder: `fpga/basys3/tops/top_mmu_demo.v`

## The most important current repo caveat

D2 migrated the default live walker / `mmu_top` descriptor boundary to the
64-bit long-format page descriptor subset aligned with `descriptor_pack`.

That means compact 32-bit page descriptors are no longer the default live walker
boundary. Any source that still owns a compact image must convert it before
driving `pt_walker`.

This does **not** mean the repo now implements full Motorola PMMU descriptor-tree
behavior. The live walker is still single-level and still does not consume full
root or pointer descriptor trees end to end.

## Descriptor categories in the current repo

The descriptor-packing module currently models three categories:

- **root descriptor**
- **pointer descriptor**
- **page descriptor**

These are represented as a Motorola-aligned **long-format descriptor subset** in `descriptor_pack`.

## Descriptor packing philosophy

The current `descriptor_pack` module is deliberately conservative.

Its design goals are:

- preserve the existing external port list
- align the bit placements with Motorola long-format descriptor conventions where possible
- treat unsupported fields as zero
- provide combinational pack and unpack behavior
- avoid pretending that the entire Motorola PMMU descriptor model is implemented

This is one of the most mature documentation choices in the repo because it separates:
- **format alignment**
from
- **complete architectural descriptor-tree behavior**

## Descriptor widths

The current descriptor-packing module defaults to:

- `DESCR_WIDTH = 64`
- `PA_WIDTH = 32`
- `LIMIT_WIDTH = 15`

and describes itself as a **64-bit long-format-oriented subset**.

The default live walker / `mmu_top` page descriptor boundary now also uses the
64-bit page descriptor subset.

## Descriptor Type (DT)

The **Descriptor Type (DT)** field is one of the most important fields in the current descriptor model.

In the current compatibility scheme:

- the old standalone valid bit is **not** stored as a Motorola field
- instead, validity is represented by whether the **Descriptor Type (DT)** is nonzero
- when packing, a cleared compatibility valid input forces `DT = 00`
- when unpacking, validity is reported as true if `DT != 00`

This is important because it shows how the project is moving toward Motorola-compatible encoding while still preserving older interface structure.

## Limit/Upper (L/U)

The **Limit/Upper (L/U)** control is carried through legacy root and pointer control inputs in the current descriptor-packing interface.

The design documentation explains that these legacy inputs are now being interpreted as Motorola-style **Limit/Upper (L/U)** control because the older invalid-bit interpretation did not match Motorola long-format descriptor layouts.

That means the repo is not merely copying bit positions. It is also reinterpreting old interface meaning to better match the target architecture.

## LIMIT field

The **LIMIT** field is included in the current root and pointer long-format subsets.

It is stored in the upper control word for those descriptor kinds and is part of what makes the current subset recognizably Motorola-aligned.

## Root descriptor

A **root descriptor** is the descriptor form that represents a root translation structure.

In the current long-format subset, the root descriptor includes:

- **Limit/Upper (L/U)**
- **LIMIT**
- **Descriptor Type (DT)**
- root table address

The project documentation explicitly says that the other root-descriptor fields not currently exposed by the module interface are written as zero in this subset.

### Current project meaning
The root descriptor in this repo is currently most important as a format-modeling concept inside `descriptor_pack`. The live integrated datapath still uses the register-level **Current Root Pointer (CRP)** as the walker root rather than consuming a full long-format root descriptor tree end to end.

## Pointer descriptor

A **pointer descriptor** is the descriptor form that points to another translation-table structure.

In the current long-format subset, the pointer descriptor includes:

- **Limit/Upper (L/U)**
- **LIMIT**
- **Descriptor Type (DT)**
- next-table address

Like the root descriptor, unsupported fields are currently written as zero.

### Current project meaning
The pointer descriptor is correctly modeled as part of the long-format subset, but the live datapath has not yet been extended into a full multi-level walker that consumes these descriptors end to end.

That is why the repo simultaneously says:
- descriptor format work is real
- multi-level walking remains deferred

## Page descriptor

A **page descriptor** is the descriptor form that carries page-level translation and protection state.

In the current long-format subset, the page descriptor includes:

- **Supervisor-only (S)**
- **Cache Inhibit (CI)**
- **Modified (M)**
- **Used (U)**
- **Write Protect (WP)**
- **Descriptor Type (DT)**
- page base physical address

This is the descriptor kind now consumed by the default live walker boundary.

## Page attribute meanings

The current repo models several page-level attributes that are important both conceptually and practically.

### Supervisor-only (S)
**Supervisor-only (S)** indicates that the page is restricted to supervisor-mode access.

In the current project, this attribute is especially visible because the Basys 3 smoke demo includes a supervisor-only translated page as one of its canned cases.

### Cache Inhibit (CI)
**Cache Inhibit (CI)** indicates that the page should be treated as non-cacheable.

### Modified (M)
**Modified (M)** indicates modification state for the page.

### Used (U)
**Used (U)** indicates usage or reference state for the page.

### Write Protect (WP)
**Write Protect (WP)** indicates that writes are disallowed for the page.

These attributes appear in the long-format subset in `descriptor_pack`, and the live walker consumes the corresponding long-format page-descriptor fields at its default boundary.

## What `descriptor_pack` does

`descriptor_pack` is a combinational pack/unpack module.

Its responsibilities are:

- pack root, pointer, or page descriptor information into the chosen descriptor representation
- unpack descriptor fields back into output signals
- preserve compatibility behavior for older valid-style interfaces
- enforce the current long-format-oriented default layout

It does **not** by itself make the integrated datapath a full Motorola descriptor-tree implementation.

That distinction is fundamental.

## The live datapath descriptor format

After D2, the current live page-table walker consumes the 64-bit long-format page descriptor subset at the default boundary.

The walker consumes page-level fields such as:

- descriptor type
- supervisor bit
- write-protect bit
- cache-inhibit bit
- modified bit
- used bit
- page-frame information

The walker still remains intentionally minimal:

- single-level only
- one descriptor read per miss
- no full root/pointer traversal
- no complete TC/CRP/SRP-driven Motorola table-walk semantics

## Descriptor formats in the Basys 3 smoke demo

The Basys 3 smoke-demo harness uses a tiny built-in descriptor responder rather than a full memory system.

That responder builds a small set of canned page-descriptor cases for the live walker path, including:

- a valid user-accessible translated page
- a valid supervisor-only translated page
- an invalid descriptor
- an abstract bus-error case

Those demo descriptors are smoke-level evidence for the current subset. They are not proof that the hardware demo implements full Motorola descriptor-tree behavior.

## What this page should not claim

This page should **not** claim that the current repo has already implemented:

- full Motorola descriptor-tree walking
- full multi-level descriptor-tree walking
- every Motorola descriptor field
- full long-format legality or behavior propagation through the current board demo
- full Motorola PMMU compatibility

The current repo docs explicitly warn against that reading.

## Known unsupported or deferred descriptor areas

The current repo documentation identifies several descriptor-related areas that remain incomplete or unsupported in the subset, including fields such as:

- **Shared Global (SG)**
- access-level controls
- gate or lock controls
- various reserved or software-defined fields

These are currently packed as zero because they are not exposed on the module interface.

## Practical reading rule

When reading the repo, apply this rule:

- if you are asking **“What descriptor format is the project trying to model?”**, look at `descriptor_pack`
- if you are asking **“What descriptor image does the current integrated translation datapath actually consume?”**, look at `pt_walker.v`, `mmu_top.v`, and the Basys 3 smoke-demo responder

That rule will prevent most confusion.

## Current status summary

The current descriptor story in this repo is:

- **implemented:** Motorola-aligned long-format subset in `descriptor_pack`
- **implemented:** 64-bit long-format page descriptor subset at the default live walker / `mmu_top` boundary
- **not yet complete:** full multi-level descriptor tree support
- **not yet complete:** full root/pointer traversal through the live datapath
- **not yet complete:** full field coverage for Motorola descriptor variants

## Related pages

- [[Glossary]]
- [[Architecture-Overview]]
- [[Translation-Flow]]
- [[Page-Table-Walker]]
- [[MMU-Registers]]
