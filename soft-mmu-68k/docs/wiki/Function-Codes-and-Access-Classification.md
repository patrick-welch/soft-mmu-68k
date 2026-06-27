# Function Codes and Access Classification

This page documents how the current repo classifies accesses using **Function Code (FC)** values.

It describes the **implemented repo state**, not a hypothetical complete future decode model.

## Purpose

The **Function Code (FC)** is one of the most important inputs to the current Soft Memory Management Unit design.

In this repo, the **Function Code (FC)** influences:

- user versus supervisor classification
- program versus data classification
- whether an access counts as normal memory space
- whether transparent translation is allowed to match
- which permission rules apply
- whether a targeted translation-cache invalidation matches an entry

This means that access classification is not just a front-end decode convenience. It is part of the architectural meaning of a request.

## Where implemented in repo

Primary sources for the current classification model:

- design description: `docs/design/address_map.md`
- Function Code decode logic: `rtl/core/mmu_decode.v`
- permission checking: `rtl/core/perm_check.v`
- top-level use of classification: `rtl/core/mmu_top.v`
- smoke-demo access generation: `fpga/basys3/tops/top_mmu_demo.v`

## Current Function Code meanings

The current repo explicitly defines the following first-pass **Function Code (FC)** meanings:

- `3'b001` = user data
- `3'b010` = user program
- `3'b101` = supervisor data
- `3'b110` = supervisor program
- `3'b111` = Central Processing Unit (CPU) / special space
- `3'b000` and `3'b100` are treated as reserved encodings

This is not left implicit. The design doc states these meanings directly, and the decode module implements the same mapping directly rather than deriving it indirectly from bit slicing alone.

## Why Function Code matters in this repo

In a memory-management design, not all accesses are equivalent.

A user data load, a supervisor instruction fetch, and a Central Processing Unit (CPU) / special-space access may all need different treatment. The current repo uses the **Function Code (FC)** to determine:

- privilege class
- access-space class
- transparent-translation eligibility
- permission-bank selection
- translation-cache match identity

This makes the **Function Code (FC)** part of the system’s semantic contract, not just a convenience signal.

## `mmu_decode` behavior

The decode module produces five outputs from the 3-bit **Function Code (FC)** input:

- `is_user`
- `is_super`
- `is_program`
- `is_data`
- `cpu_space`

These outputs are intentionally simple.

The module comments explain the design intent:

- `is_user` and `is_super` reflect the privilege half selected by the Function Code
- `is_program` and `is_data` assert only for valid normal memory-space encodings
- `cpu_space` asserts only for the explicit `3'b111` Central Processing Unit (CPU) / special-space code
- reserved encodings do not assert normal program/data or Central Processing Unit (CPU) / special-space meaning

This keeps the downstream interface small and makes it possible for later logic to treat reserved encodings as “not a normal memory access” without needing a separate validity output.

## User versus supervisor classification

The current repo distinguishes user and supervisor access classes explicitly.

### User access
A **user access** is an access classified as user-mode by the current Function Code decode. In the current encoding model, user accesses are:

- user data (`3'b001`)
- user program (`3'b010`)

These accesses are subject to the user permission bank in the permission checker unless a valid transparent-translation bypass applies.

### Supervisor access
A **supervisor access** is an access classified as supervisor-mode by the current Function Code decode. In the current encoding model, supervisor accesses are:

- supervisor data (`3'b101`)
- supervisor program (`3'b110`)

These accesses are subject to the supervisor permission bank in the permission checker.

## Program versus data classification

The current repo also distinguishes between program-space and data-space access classes.

### Program access
A **program access** is an access classified as instruction or fetch space by the current Function Code decode. In the current mapping, that means:

- user program (`3'b010`)
- supervisor program (`3'b110`)

Program-space meaning matters for transparent-translation matching because the current **Transparent Translation (TT0 / TT1)** subset includes separate program/data match controls. It also matters in the Basys 3 demo, which allows the user to select program/fetch versus data behavior from switches.

### Data access
A **data access** is an access classified as ordinary data space by the current Function Code decode. In the current mapping, that means:

- user data (`3'b001`)
- supervisor data (`3'b101`)

Data-space meaning likewise matters for transparent-translation matching and demo behavior.

## Central Processing Unit (CPU) / special space

The current repo explicitly treats `3'b111` as **Central Processing Unit (CPU) / special space**.

This is a distinct classification from normal program space and normal data space. The design documentation and the integration logic both say that Central Processing Unit (CPU) / special-space accesses are **excluded** from the first-pass transparent-translation subset. That means that even if the address byte pattern might otherwise look like a transparent-translation match, Central Processing Unit (CPU) / special-space accesses do not take that bypass in the current implementation.

This is one of the most important caveats in the current design.

## Reserved encodings

The current repo treats `3'b000` and `3'b100` as **reserved encodings**.

This means:

- they are not ordinary program accesses
- they are not ordinary data accesses
- they are not Central Processing Unit (CPU) / special-space accesses
- they should not transparently match
- they are not automatically given a normal memory-space interpretation

The current decoder implements this by simply not asserting the normal semantic outputs for them. That is an intentional simplification. The project notes that if a later interface needs an explicit Function Code validity output, that should be added explicitly rather than being inferred from the existing small output set.

## Function Code and permission checking

The **Function Code (FC)** matters to permission checking in two ways.

### 1. It determines privilege class
The decode result chooses whether the permission checker should interpret the request as user or supervisor.

The permission checker itself accepts:

- `is_user`
- user permission bank
- supervisor permission bank
- Read / Write / Execute request class
- transparent-translation bypass status

This means the Function Code indirectly determines which permission bank is active.

### 2. It helps determine privilege-related denial
The permission checker can also identify a **privilege-related** denial, meaning a user-mode access is denied even though the supervisor permission bank would allow the same access class.

That concept only makes sense if the current access privilege was classified correctly, so the Function Code decode is upstream of that decision.

## Function Code and transparent translation

The current transparent-translation subset requires a normal memory-space Function Code.

The design documentation defines the match requirements as:

- entry enabled
- normal user/supervisor program/data Function Code
- privilege match
- space-class match
- masked high-byte compare match

This means the Function Code is not incidental to transparent translation. It is one of the required match dimensions. A region match on the logical address alone is not enough.

## Function Code and translation-cache identity

In the current repo, the translation-cache path stores and compares the **Function Code (FC)** as part of the entry identity.

That matters because the translation cache is not keyed only by virtual tag. It also incorporates access classification. The comparison helper `tlb_compare.v` compares both:

- tag
- stored Function Code

Likewise, targeted invalidation in the direct-mapped translation-cache path uses address plus Function Code rather than address alone. This is a very important implementation fact because it means access class is part of what makes a cached translation entry distinct.

## Function Code in the Basys 3 demo

The Basys 3 smoke-demo harness exposes current Function Code selection in a friendly way.

The demo switch logic builds a demo Function Code from:

- supervisor versus user selection
- program versus data selection

That makes the board harness a direct teaching tool for Function Code classification. It allows the current repo to demonstrate:

- user translated access
- supervisor translated access
- program-space versus data-space selection
- supervisor-only page behavior
- transparent-translation-qualified access behavior

without requiring a full 68k processor core in hardware.

## Current limitations

This page should be read with the current repo boundaries in mind:

- the Function Code classification is implemented and real
- the transparent-translation subset is still first-pass only
- reserved encodings are handled by deassertion of normal semantic outputs rather than a separate validity signal
- Central Processing Unit (CPU) / special-space handling is explicitly conservative in the current subset
- this page describes the implemented classification model, not every possible Motorola nuance

Those caveats are part of the project’s current honesty and should remain attached to this page.

## Related pages

- [[Glossary]]
- [[Architecture-Overview]]
- [[MMU-Registers]]
- [[Translation-Flow]]
- [[Control-Operations-(PTEST-PLOAD-PFLUSH)]]