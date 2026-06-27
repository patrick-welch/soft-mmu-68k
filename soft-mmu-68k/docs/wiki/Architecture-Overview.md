# Architecture Overview

This page explains the current implemented architecture of the **Soft Memory Management Unit (Soft MMU)** in this repository.

It is not a description of an ideal future design. It is a description of the **implemented repo state**.

## Purpose

The project implements a modular, synthesizable **Memory Management Unit (MMU)** for 68k-family systems, with a current first-pass architecture that supports:

- software-visible register configuration
- Motorola-style **Function Code (FC)** decode
- transparent-translation qualification
- translation-cache lookup
- minimal page-table walking
- permission enforcement
- first-pass flush, probe, and preload control operations
- Basys 3 smoke-demo bring-up

The repository describes this as implemented through packet `P11`, with several behaviors still explicitly marked first-pass only. These include **Transparent Translation (TT0 / TT1)**, **MMU Status Register (MMUSR)** behavior, **Page Test (PTEST)** semantics, **Page Load (PLOAD)** semantics, **Page Flush (PFLUSH)** semantics, and the difference between Motorola-aligned descriptor packing and the still-compact live translation datapath. [[Glossary]] should be read alongside this page.

## High-level structure

The current architecture can be understood as seven cooperating layers:

1. **Software-visible control state**
2. **Access classification**
3. **Transparent-translation qualification**
4. **Translation-cache lookup**
5. **Page-table walking and refill**
6. **Permission enforcement**
7. **Control operations and status reporting**

Those layers are brought together in the top-level integration wrapper `rtl/core/mmu_top.v`.

## 1. Software-visible control state

The register block provides the control-and-status state used by the rest of the Memory Management Unit. The currently implemented register set is:

- **Current Root Pointer (CRP)**
- **Supervisor Root Pointer (SRP)**
- **Translation Control (TC)**
- **Transparent Translation 0 (TT0)**
- **Transparent Translation 1 (TT1)**
- **MMU Status Register (MMUSR)**

The register block is intentionally simple and deterministic. It provides synchronous storage, a simple read/write interface, and reset defaults that leave translation disabled immediately after reset. The repo also states clearly that the current **MMU Status Register (MMUSR)** image is a first-pass software-visible model rather than a fully synthesized Motorola-compatible result generator. For details, see [[MMU-Registers]].

## 2. Access classification

All translation and permission decisions depend on the current **Function Code (FC)**.

The project currently uses these first-pass **Function Code (FC)** semantics:

- `3'b001` = user data
- `3'b010` = user program
- `3'b101` = supervisor data
- `3'b110` = supervisor program
- `3'b111` = Central Processing Unit (CPU) / special space
- `3'b000` and `3'b100` are treated as reserved encodings

This decode is implemented by `rtl/core/mmu_decode.v`, which produces simplified semantic outputs such as user versus supervisor, program versus data, and Central Processing Unit (CPU) / special-space classification. The decode intentionally avoids adding a separate validity pin for reserved encodings; instead, reserved encodings simply do not assert normal memory-space outputs. See [[Function-Codes-and-Access-Classification]].

## 3. Transparent-translation qualification

Before the current implementation performs normal translation-cache lookup or page-table walking, it checks whether the access matches the implemented first-pass **Transparent Translation (TT0 / TT1)** subset.

The current transparent-translation subset uses the existing 32-bit register images with the following meaning:

- base byte
- mask byte
- enable bit
- user/supervisor matching bits
- program/data matching bits

If a transparent-translation match occurs, the current design bypasses page-table translation and returns an identity-style physical address by resizing the logical address onto the physical-address bus. In the current subset, transparent translation is also allowed to suppress page-derived permission denial for a valid access request. However, transparent translation does **not** legalize malformed requests, and it does **not** apply to Central Processing Unit (CPU) / special-space accesses. The repo explicitly calls this a narrow first-pass subset and warns against describing it as full Motorola transparent-translation support.

## 4. Translation-cache lookup

If the access does not qualify for transparent translation, the next stage is the direct-mapped translation cache.

The repo uses both **Address Translation Cache (ATC)** language and **Translation Lookaside Buffer (TLB)** language. In practical implementation terms, the current fast path is a direct-mapped **Translation Lookaside Buffer (TLB)** consisting of:

- `rtl/core/tlb_dm.v` for storage, refill, and invalidation
- `rtl/core/tlb_compare.v` for tag and **Function Code (FC)** comparison plus physical-address reconstruction

This path performs indexed lookup, compares the stored tag and stored **Function Code (FC)**, and on a hit reconstructs the physical address from the stored physical-frame number and the page offset. If a hit occurs on a processor request, the integration wrapper proceeds to permission checking. If the lookup misses, the request enters the page-table-walk path. See [[Translation-Cache-(TLB-and-ATC)]].

## 5. Page-table walking and refill

On a translation-cache miss, the current architecture starts a page-table walk.

The page-table walker is intentionally minimal in the current repo:

- it is single-level only
- it uses an abstract memory request/response interface
- it reads one descriptor per miss
- it does not decide permissions itself
- it forwards attribute information to later logic

The walker can currently report three meaningful fault classes:

- invalid descriptor
- unmapped access
- bus error

If a valid page descriptor is returned, the walker emits refill information for the translation cache and forwards the page attributes for permission processing. The README states explicitly that multi-level page-table walking and broader descriptor coverage are still deferred. See [[Page-Table-Walker]].

## 6. Permission enforcement

Permission enforcement is handled by `rtl/core/perm_check.v`.

This stage evaluates the access as one of three classes:

- read
- write
- execute or fetch

It then checks the active privilege level against the user and supervisor permission banks. In the current design:

- malformed requests are reported as **bad requests**
- transparent-translation bypass applies only to otherwise valid requests
- user denials that would have been allowed in supervisor mode are marked as **privilege-related**

This stage exists twice in the integration wrapper:

- once for translation-cache hits
- once for walker-completed translations

That split keeps the architecture simple and makes the first-pass flow easier to review. See [[Glossary]] and [[Function-Codes-and-Access-Classification]].

## 7. Control operations and status reporting

The current control path is implemented by `rtl/core/flush_ctrl.v`.

This module is the first-pass shim for:

- **Page Flush All (PFLUSHA)**
- targeted **Page Flush (PFLUSH)**
- **Page Test (PTEST)**
- **Page Load (PLOAD)**

The repo is explicit that this is not yet a full Motorola instruction model. Its current responsibilities are:

- generate flush pulses
- manage a single in-flight probe or preload request
- latch a compact status/result record
- classify probe results as translated, transparent, or miss

This is especially important because the current repo uses the control/status path to make the translated-versus-transparent distinction visible without claiming full **MMU Status Register (MMUSR)** or full **Page Test (PTEST)** compatibility. See [[Control-Operations-(PTEST-PLOAD-PFLUSH)]].

## End-to-end request flow

The current processor request path can be summarized as follows:

1. A request enters `mmu_top` with:
   - logical address
   - **Function Code (FC)**
   - read/write intent
   - fetch intent

2. The access is classified using `mmu_decode`.

3. The current **Transparent Translation (TT0 / TT1)** subset is checked.

4. If transparent translation matches:
   - translation is bypassed
   - an identity-style physical address is produced
   - the access completes through the first-pass transparent path

5. If transparent translation does not match:
   - the direct-mapped **Translation Lookaside Buffer (TLB)** is checked

6. If the translation cache hits:
   - permission checking is applied
   - the request completes or faults

7. If the translation cache misses:
   - the page-table walker is started
   - the descriptor is fetched
   - refill data is produced if valid
   - permission checking is applied
   - the request completes or faults

That is the core current architecture.

## Descriptor-model boundary

One of the most important architectural boundaries in the repo is the difference between:

- the Motorola-aligned descriptor subset implemented by `descriptor_pack`
- and the compact page-descriptor format still used by the live walker and smoke-demo datapath

This distinction is not a bug in the documentation. It is intentional and explicitly documented. The wiki should preserve that distinction carefully so readers do not assume that the long-format descriptor model has already been propagated end to end through the implemented datapath. See [[Descriptor-Formats]].

## Hardware-facing architecture: Basys 3 smoke demo

The Basys 3 hardware flow is not a full system-on-chip integration. It is a self-configuring smoke harness.

The demo top:

- programs key Memory Management Unit registers after reset
- uses a tiny built-in descriptor responder instead of a complete system
- allows switch-selected access and probe scenarios
- exposes compact status and result information on light-emitting diodes

This makes it an excellent architectural teaching aid, but the repo docs are explicit that it should be treated as smoke-level proof, not as evidence of full Motorola architectural completeness. See [[FPGA-Demo-and-Basys-3-Bring-Up]].

## Current architectural boundaries

The current architecture should be understood with these limits in mind:

- **Transparent Translation (TT0 / TT1)** is a narrow first-pass subset.
- **MMU Status Register (MMUSR)** behavior is first-pass.
- **Page Test (PTEST)**, **Page Load (PLOAD)**, and **Page Flush (PFLUSH)** behavior is first-pass.
- multi-level page-table walking is deferred
- full Motorola legality handling is deferred
- full end-to-end long-format descriptor datapath migration is deferred
- the Basys 3 hardware path is a smoke harness, not a full processor system

Those limits are not weaknesses in the documentation. They are part of the architecture as currently implemented and should be preserved explicitly in the wiki.

## Where implemented in repo

- register block: `rtl/core/mmu_regs.v`
- access classification: `rtl/core/mmu_decode.v`
- permission checking: `rtl/core/perm_check.v`
- translation cache: `rtl/core/tlb_dm.v`, `rtl/core/tlb_compare.v`
- page-table walker: `rtl/core/pt_walker.v`
- control shim: `rtl/core/flush_ctrl.v`
- integration wrapper: `rtl/core/mmu_top.v`
- Basys 3 demo top: `fpga/basys3/tops/top_mmu_demo.v`

## Next pages

Recommended next reading:

- [[MMU-Registers]]
- [[Function-Codes-and-Access-Classification]]
- [[Descriptor-Formats]]
- [[Translation-Flow]]