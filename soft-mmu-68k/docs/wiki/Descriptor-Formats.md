# Descriptor Formats

This page documents the descriptor formats used by the current **Soft Memory Management Unit (Soft MMU)** project.

It is critical to read this page carefully, because the current repo has **two different descriptor realities**:

1. a **Motorola-aligned long-format descriptor subset** implemented by `descriptor_pack`
2. a **compact first-pass live translation datapath descriptor format** still used by the current page-table walker and Basys 3 smoke harness

This distinction is intentional in the current repo and should not be blurred.

## Purpose

A **descriptor** is a translation-structure record that contains address and policy information used by the memory-management system.

In Motorola-style memory-management terminology, descriptors can describe:

- root translation structures
- pointer or table structures
- page mappings

In this repo, descriptor handling is split between:

- a combinational reference-style packing and unpacking module
- the currently live translation datapath

The purpose of this page is to explain both, and to explain where they are aligned and where they are not yet aligned.

## Where implemented in repo

Primary sources for current descriptor behavior:

- design description: `docs/design/descriptor_formats.md`
- descriptor pack/unpack implementation: `rtl/core/descriptor_pack.v`
- current live walker descriptor consumption: `rtl/core/pt_walker.v`
- current integration context: `rtl/core/mmu_top.v`
- current repo-status statement: `README.md`
- Basys 3 smoke-demo descriptor responder: `fpga/basys3/tops/top_mmu_demo.v`

## The most important current repo caveat

The current repo explicitly states that `descriptor_pack` is Motorola-aligned for a long-format subset, **but the live translation datapath has not yet migrated end-to-end to Motorola long-format descriptors**.

That means:

- the descriptor-format work is real
- the bit placements in `descriptor_pack` are meaningful
- but the current walker and smoke-demo path still operate on their own compact page-descriptor image

This is not an error in the docs. It is the current design state. The wiki should preserve that fact carefully. [[Glossary]] should also reflect it. 

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
- avoid pretending that the entire datapath has already migrated to this format

This is one of the most mature documentation choices in the repo because it separates:
- **format alignment**
from
- **end-to-end datapath migration**

## Descriptor widths

The current descriptor-packing module defaults to:

- `DESCR_WIDTH = 64`
- `PA_WIDTH = 32`
- `LIMIT_WIDTH = 15`

and describes itself as a **64-bit long-format-oriented subset**.

The code explicitly checks that descriptor width is at least 64 for the current long-format defaults.

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
The root descriptor in this repo is currently most important as a format-modeling concept inside `descriptor_pack`. The live integrated datapath still uses the register-level **Current Root Pointer (CRP)** as the walker root rather than consuming a full long-format root descriptor end to end.

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

This is the descriptor kind that most directly overlaps conceptually with the live translation datapath, because the current page-table walker and permission path also operate on page-level policy bits.

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

These attributes appear in the long-format subset in `descriptor_pack`, and closely related page-attribute concepts also appear in the live walker’s compact attribute output.

## What `descriptor_pack` does

`descriptor_pack` is a combinational pack/unpack module.

Its responsibilities are:

- pack root, pointer, or page descriptor information into the chosen descriptor representation
- unpack descriptor fields back into output signals
- preserve compatibility behavior for older valid-style interfaces
- enforce the current long-format-oriented default layout

It does **not** by itself make the integrated datapath long-format end to end.

That distinction is fundamental.

## The live datapath descriptor format

The current live page-table walker does **not** consume the 64-bit long-format subset from `descriptor_pack`.

Instead, `pt_walker.v` documents its own **compact default page-descriptor layout**. In that layout, the walker expects fields such as:

- descriptor type
- valid bit
- supervisor bit
- write-protect bit
- cache-inhibit bit
- modified bit
- used bit
- page-frame information

This means the live datapath is still using a compact first-pass page-descriptor image rather than the long-format descriptor subset.

## Why the current split exists

The current split between `descriptor_pack` and the live datapath is understandable and actually healthy documentation-wise.

It allows the project to:

- bring descriptor bit-format alignment closer to Motorola conventions
- document that work honestly
- keep the current walker and integration path simple and reviewable
- avoid claiming more datapath migration than has actually been completed

This is exactly the kind of design discipline the wiki should preserve.

## Descriptor formats in the Basys 3 smoke demo

The Basys 3 smoke-demo harness uses a tiny built-in descriptor responder rather than a full memory system.

That responder builds a small set of canned page-descriptor cases for the live walker path, including:

- a valid user-accessible translated page
- a valid supervisor-only translated page
- an invalid descriptor
- an abstract bus-error case

Those demo descriptors are part of the compact live datapath model, not proof that the hardware demo is already using end-to-end long-format Motorola descriptors.

## What this page should not claim

This page should **not** claim that the current repo has already implemented:

- full Motorola long-format descriptor use throughout the translation datapath
- full multi-level descriptor-tree walking
- every Motorola descriptor field
- full long-format legality or behavior propagation through the current board demo

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
- if you are asking **“What descriptor image does the current integrated translation datapath actually consume?”**, look at `pt_walker.v` and the Basys 3 smoke-demo responder

That rule will prevent most confusion.

## Current status summary

The current descriptor story in this repo is:

- **implemented:** Motorola-aligned long-format subset in `descriptor_pack`
- **implemented:** compact first-pass page-descriptor image in the live walker/datapath
- **not yet complete:** end-to-end migration of the live datapath to long-format Motorola descriptors
- **not yet complete:** full multi-level descriptor tree support
- **not yet complete:** full field coverage for Motorola descriptor variants

## Related pages

- [[Glossary]]
- [[Architecture-Overview]]
- [[Translation-Flow]]
- [[Page-Table-Walker]]
- [[MMU-Registers]]