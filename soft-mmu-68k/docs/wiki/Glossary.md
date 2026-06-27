# Glossary

This page is the authoritative vocabulary reference for the **Soft MMU for 68K Systems** project.

Its purpose is not just to decode acronyms. Its purpose is to define the system’s concepts precisely enough that a reader can move from terminology to architecture, from architecture to implementation, and from implementation to verification.

## How to use this page

This glossary is designed for three kinds of readers:

- a new reader trying to learn the project from first principles
- a contributor trying to understand how a term is used in this repo
- a reviewer trying to verify whether a term is being used precisely and honestly

If a term is implemented in the repo, the entry should identify where it is currently realized.

## Editorial rules for glossary entries

Each entry should try to include the following when applicable.

### 1. Full term first

Acronyms should be expanded on first use.

For example:

- **MMU (Memory Management Unit)**
- **FC (Function Code)**
- **TLB (Translation Lookaside Buffer)**
- **ATC (Address Translation Cache)**

Definitions should avoid using unexplained acronyms inside the definition itself.

### 2. Definition before shorthand

Each entry should begin with a true definition, not just a synonym or a code reference.

A good entry explains:

- what the term means in computer architecture
- what it means in this project
- what it does **not** mean when the implementation is only partial

### 3. Repo-aware meaning

Many terms in this project have both:

- a historical or Motorola-manual meaning
- a current repo-specific meaning

When those differ, the entry should say so explicitly.

### 4. Implementation pointer

If the term maps to code, include a short **Where implemented in repo** section.

Examples:

- `rtl/core/mmu_regs.v`
- `rtl/core/mmu_decode.v`
- `rtl/core/perm_check.v`
- `rtl/core/tlb_dm.v`
- `rtl/core/pt_walker.v`
- `rtl/core/flush_ctrl.v`
- `rtl/core/mmu_top.v`

### 5. First-pass honesty

This glossary should be careful not to overstate the current implementation.

Some parts of the repo are intentionally first-pass only, including:

- **Transparent Translation (TT0 / TT1)**
- **MMU Status Register (MMUSR)** result semantics
- **Page Test (PTEST)** behavior
- **Page Load (PLOAD)** behavior
- **Page Flush (PFLUSH)** behavior
- full end-to-end Motorola long-format descriptor use

Where relevant, entries should distinguish between:

- **implemented now**
- **implemented as a first-pass subset**
- **deferred or incomplete**

## Reading recommendation

If you are new to the project, start with these entries first:

- **Soft MMU**
- **MMU (Memory Management Unit)**
- **PMMU (Paged Memory Management Unit)**
- **CRP (Current Root Pointer)**
- **TC (Translation Control)**
- **FC (Function Code)**
- **Transparent Translation**
- **TLB (Translation Lookaside Buffer)**
- **ATC (Address Translation Cache)**
- **Page-table walker**
- **Descriptor**
- **MMUSR (MMU Status Register)**

Then continue to:

- [[Architecture-Overview]]
- [[Function-Codes-and-Access-Classification]]
- [[Descriptor-Formats]]
- [[Translation-Flow]]

## Scope note

This glossary describes the **implemented repo state**.

It is not a glossary of the entire Motorola memory-management architecture in the abstract. It is a glossary for this project’s current implementation and documentation. When a Motorola concept is only partially implemented here, the glossary should say so directly.

## Entry format template

Use this structure when adding or revising entries.

### Term name

**Full Name (if acronym).**  
Definition paragraph.

**Project meaning.**  
How the term is used in this repo today.

**Current status.**  
Implemented, first-pass, deferred, or mixed.

**Where implemented in repo.**  
List code and/or design-doc locations if applicable.

---

## Glossary entries

> The entries below should be maintained as part of the project’s technical reference material.  
> When changing terminology in code or docs, update this page as part of the same work.  
> This glossary describes the **implemented repo state** of the project. It should not claim full Motorola architectural completeness where the repo itself does not support that claim.

### Soft MMU

A **Soft Memory Management Unit (Soft MMU)** is a memory-management design implemented as synthesizable hardware description language rather than as fixed silicon. In general computer-architecture terms, a Soft Memory Management Unit performs the same conceptual role as a conventional Memory Management Unit: it interprets logical addresses, applies translation rules, enforces permissions, and reports faults. In this project, the term refers specifically to a modular, synthesizable 68k-family memory-management design that is intended to be readable, reviewable, FPGA-buildable, and educational.

**Project meaning.** In this repo, the Soft Memory Management Unit includes a software-visible register block, Function Code decode, permission checking, a direct-mapped translation-cache path, a minimal page-table walker, a first-pass control shim, a top-level integration wrapper, and a Basys 3 smoke-demo harness. The term therefore refers to a real implemented subsystem, not merely to a plan or aspiration.

**Current status.** Implemented as a meaningful first-pass 68k-family subset. Not yet a fully complete Motorola architectural reproduction.

**Where implemented in repo.** Most directly represented by `rtl/core/mmu_top.v` and the `rtl/core/` module family as a whole.

---

### MMU (Memory Management Unit)

A **Memory Management Unit (MMU)** is the hardware subsystem that interprets logical addresses, applies translation policy, enforces access permissions, and reports translation or protection faults. In general architectural use, the term can describe many different designs. In this project, the term refers to the current 68k-family memory-management subsystem implemented in the repo.

**Project meaning.** The Memory Management Unit in this project is the integrated behavior produced by the register block, Function Code decode, transparent-translation qualification, translation-cache lookup, page-table walking, refill, permission checking, and control-operation handling.

**Current status.** Implemented through a substantial first-pass subset with clearly documented boundaries.

**Where implemented in repo.** `rtl/core/mmu_top.v` plus supporting modules in `rtl/core/`.

---

### PMMU (Paged Memory Management Unit)

A **Paged Memory Management Unit (PMMU)** is Motorola’s paged memory-management model, especially associated with the Motorola MC68851 and closely related Motorola MC68030 behavior. The term is historically useful because it identifies the family of semantics this project is trying to approximate. At the same time, the repo documentation repeatedly warns that the current implementation should not yet be described as a fully complete Motorola architectural model.

**Project meaning.** In this project, “PMMU-like” means “aligned with Motorola 68851 / 68030 style semantics where implemented,” while still distinguishing first-pass subsets and deferred work.

**Current status.** Conceptually central, but only partially implemented as a full historical architecture.

**Where implemented in repo.** Reflected across `README.md`, `docs/design/address_map.md`, `docs/design/descriptor_formats.md`, and `rtl/core/mmu_top.v`.

---

### CRP (Current Root Pointer)

The **Current Root Pointer (CRP)** is the register that holds the base address of the root translation structure used by the current translation path. In architecture terms, a root pointer is the starting address from which the memory-management system begins walking translation tables. In this project, the Current Root Pointer is one of the most important control registers because the current page-table walker uses it directly as its table base.

**Project meaning.** The Current Root Pointer is part of the live translated datapath, not just a decorative register. It is also programmed explicitly by the Basys 3 smoke-demo harness during startup.

**Current status.** Implemented.

**Where implemented in repo.** `rtl/core/mmu_regs.v`, `rtl/core/mmu_top.v`, `fpga/basys3/tops/top_mmu_demo.v`.

---

### SRP (Supervisor Root Pointer)

The **Supervisor Root Pointer (SRP)** is the supervisor-context root-pointer register in the current register block. In a fuller Motorola-oriented implementation, it would be used to represent a supervisor-context translation root distinct from the current root pointer. In the present repo, it is a real implemented register and part of the software-visible programming model, even though the most visible first-pass walker hookup is centered on the Current Root Pointer.

**Project meaning.** The Supervisor Root Pointer is part of the current Memory Management Unit vocabulary and compatibility story, even where the current datapath emphasis is elsewhere.

**Current status.** Implemented as part of the register block.

**Where implemented in repo.** `rtl/core/mmu_regs.v`, `rtl/core/mmu_top.v`.

---

### TC (Translation Control)

The **Translation Control (TC)** register is the current translation-control image in the software-visible register block. In general architectural terms, a translation-control register determines important aspects of how translation structures are interpreted. In this repo, the Translation Control register is both programmer-visible and live in the datapath: the integration wrapper derives table-entry configuration from it and passes that configuration into the current page-table walker.

**Project meaning.** Translation Control is the bridge between software-visible setup and live walker behavior in the current implementation. It is also programmed explicitly by the Basys 3 smoke-demo harness.

**Current status.** Implemented and actively used.

**Where implemented in repo.** `rtl/core/mmu_regs.v`, `rtl/core/mmu_top.v`, `fpga/basys3/tops/top_mmu_demo.v`.

---

### TT0 / TT1 (Transparent Translation 0 / Transparent Translation 1)

**Transparent Translation 0 (TT0)** and **Transparent Translation 1 (TT1)** are the two transparent-translation register images in the current programming model. The repo defines a narrow first-pass subset for them: logical-address high-byte base, logical-address high-byte mask, enable bit, privilege-match bits, and program/data match bits. These registers are therefore meaningful and active, but they are not yet a full implementation of Motorola transparent-translation register semantics or legality rules.

**Project meaning.** Transparent Translation 0 and Transparent Translation 1 are the control points for the current transparent-translation subset and materially affect the top-level Memory Management Unit behavior. They are programmed by the Basys 3 smoke-demo harness and consumed by the transparent-translation qualifier in the integration wrapper.

**Current status.** Implemented as a narrow first-pass subset. Full legality handling and full field decoding are deferred.

**Where implemented in repo.** `rtl/core/mmu_regs.v`, `rtl/core/mmu_top.v`, `docs/design/address_map.md`, `fpga/basys3/tops/top_mmu_demo.v`.

---

### Transparent Translation

**Transparent Translation** is the mechanism by which selected accesses bypass normal page-table translation and instead produce an identity-style physical result. In general terms, this means certain address classes are treated specially and do not consume the ordinary translation-table path. In this repo, Transparent Translation is one of the most important and most carefully caveated concepts. The design documentation makes clear that the current implementation is a **first-pass transparent-translation subset**, not full Motorola transparent-translation support.

**Project meaning.** Transparent Translation in this project uses the current Transparent Translation 0 / Transparent Translation 1 register images plus Function Code classification to determine whether a request should bypass the normal translated datapath. If a transparent-translation match occurs, the project returns an identity-style physical address by resizing the logical address onto the physical-address bus. Central Processing Unit / special-space accesses are explicitly excluded from transparent matching in the current subset.

**Current status.** Implemented in a narrow first-pass subset only.

**Where implemented in repo.** `docs/design/address_map.md`, `rtl/core/mmu_top.v`.

---

### `tt_bypass`

`tt_bypass` is the internal signal that tells the permission-check path that a valid transparent-translation-qualified access should bypass page-derived permission denial. This is a subtle but important implementation term. The project documentation is explicit that Transparent Translation does **not** legalize malformed access requests. Therefore, `tt_bypass` is not a universal escape hatch. It only suppresses page-derived denial for an otherwise valid access request.

**Project meaning.** `tt_bypass` is the mechanism that connects the transparent-translation qualifier in `mmu_top` to the permission checker in `perm_check`.

**Current status.** Implemented in the current first-pass transparent-translation path.

**Where implemented in repo.** `rtl/core/perm_check.v`, `rtl/core/mmu_top.v`, `docs/design/address_map.md`.

---

### FC (Function Code)

A **Function Code (FC)** is the 68k-family access-classification signal that identifies the privilege and address-space class of an access. In the current repo, the Function Code is central to access classification. It determines user versus supervisor meaning, program versus data meaning, Central Processing Unit / special-space status, transparent-translation eligibility, permission-bank selection, translation-cache entry identity, and targeted invalidation identity.

**Project meaning.** The current repo explicitly defines first-pass Function Code meanings instead of leaving them implicit. This is important because it turns access classification into an explicit, documented contract rather than an assumption buried inside code.

**Current status.** Implemented and deeply integrated into the translated and transparent paths.

**Where implemented in repo.** `docs/design/address_map.md`, `rtl/core/mmu_decode.v`, `rtl/core/perm_check.v`, `rtl/core/tlb_dm.v`, `rtl/core/tlb_compare.v`, `rtl/core/mmu_top.v`.

---

### User data Function Code

The **user data Function Code** is the current first-pass encoding `3'b001`. It represents a user-mode data access.

**Project meaning.** This classification affects privilege interpretation, permission-bank selection, transparent-translation matching, and demo behavior.

**Current status.** Implemented.

**Where implemented in repo.** `docs/design/address_map.md`, `rtl/core/mmu_decode.v`.

---

### User program Function Code

The **user program Function Code** is the current first-pass encoding `3'b010`. It represents a user-mode program or fetch access.

**Project meaning.** This classification matters for program-space matching in Transparent Translation and for fetch-path semantics in the integrated request interface.

**Current status.** Implemented.

**Where implemented in repo.** `docs/design/address_map.md`, `rtl/core/mmu_decode.v`.

---

### Supervisor data Function Code

The **supervisor data Function Code** is the current first-pass encoding `3'b101`. It represents a supervisor-mode data access.

**Project meaning.** This classification selects supervisor privilege semantics and participates in targeted invalidation identity and translation-cache identity.

**Current status.** Implemented.

**Where implemented in repo.** `docs/design/address_map.md`, `rtl/core/mmu_decode.v`.

---

### Supervisor program Function Code

The **supervisor program Function Code** is the current first-pass encoding `3'b110`. It represents a supervisor-mode program or fetch access.

**Project meaning.** This classification combines supervisor privilege with program-space meaning and is part of the current access-classification model.

**Current status.** Implemented.

**Where implemented in repo.** `docs/design/address_map.md`, `rtl/core/mmu_decode.v`.

---

### CPU/special space Function Code

The **Central Processing Unit / special-space Function Code** is the explicit current encoding `3'b111`. It represents the current repo’s Central Processing Unit / special-space class rather than a normal program-space or data-space access. This distinction matters because the current transparent-translation subset explicitly excludes Central Processing Unit / special-space accesses.

**Project meaning.** A request with the Central Processing Unit / special-space Function Code continues down the ordinary translated or probe path in the current subset rather than taking transparent-translation bypass.

**Current status.** Implemented as a distinct classification.

**Where implemented in repo.** `docs/design/address_map.md`, `rtl/core/mmu_decode.v`, `rtl/core/mmu_top.v`.

---

### Reserved Function Code encodings

The **reserved Function Code encodings** in the current first-pass model are `3'b000` and `3'b100`. The repo does not interpret them as ordinary program space, ordinary data space, or Central Processing Unit / special space. Instead, the decoder simply deasserts the normal semantic outputs for those encodings.

**Project meaning.** Reserved encodings are treated as “not a normal memory access” in the current subset, without introducing a separate Function Code validity output.

**Current status.** Implemented with a deliberately small interface.

**Where implemented in repo.** `docs/design/address_map.md`, `rtl/core/mmu_decode.v`.

---

### MMUSR (MMU Status Register)

The **MMU Status Register (MMUSR)** is the current software-visible status image in the register block. This is one of the most important entries to describe honestly. The repo clearly states that the current MMU Status Register behavior is a first-pass software-visible model and should **not** be described as a fully complete Motorola architectural result synthesis. It is therefore useful, real, and part of the current programming model, but still partly a control-layer and bring-up-oriented status image.

**Project meaning.** The current MMU Status Register gives software a visible status image that tests and early software can reason about. It is part of the software-visible interface of the current subset, but it remains explicitly first-pass.

**Current status.** Implemented and software-visible, but first-pass only.

**Where implemented in repo.** `rtl/core/mmu_regs.v`, with related caveats in `README.md` and `docs/design/address_map.md`.

---

### ATC (Address Translation Cache)

An **Address Translation Cache (ATC)** is a small cache of recently used address translations. In Motorola terminology, this is the fast structure that avoids repeating page-table walks for every translated access. In general computer-architecture language, the same role is often called a **Translation Lookaside Buffer (TLB)**. In this project, both terms appear, but the practical first implementation is a direct-mapped translation-cache path.

**Project meaning.** The Address Translation Cache concept is realized in the repo as the direct-mapped fast translated path with explicit lookup, refill, and invalidate behavior.

**Current status.** Implemented in first-pass direct-mapped form.

**Where implemented in repo.** `rtl/core/tlb_dm.v`, `rtl/core/tlb_compare.v`, `rtl/core/mmu_top.v`.

---

### TLB (Translation Lookaside Buffer)

A **Translation Lookaside Buffer (TLB)** is the general computer-architecture term for a translation cache. In this repo, the Translation Lookaside Buffer is the practical first implementation of the fast translated path. It stores recently used translation state so that repeated accesses can complete without invoking the page-table walker.

**Project meaning.** The Translation Lookaside Buffer is direct-mapped in the current implementation. It is also keyed by both virtual translation identity and Function Code, which means translation-cache state depends on both address information and access classification.

**Current status.** Implemented in direct-mapped form. More complex associative forms remain future work.

**Where implemented in repo.** `rtl/core/tlb_dm.v`, `rtl/core/tlb_compare.v`, `rtl/core/mmu_top.v`.

---

### `tlb_compare`

`tlb_compare` is the direct-mapped entry-compare helper used by the Translation Lookaside Buffer path. It compares the stored tag and stored Function Code against the lookup request and, on a hit, reconstructs the physical address from the stored physical-frame number and the current page offset.

**Project meaning.** This module embodies the fact that a translation-cache hit in the current repo is not based on virtual tag alone. Function Code is also part of the entry identity.

**Current status.** Implemented.

**Where implemented in repo.** `rtl/core/tlb_compare.v`.

---

### Refill

A **refill** is the act of inserting a newly resolved translation into the Translation Lookaside Buffer after a miss. In a translated memory-management architecture, refill is what teaches the fast path a translation that was just learned through a slower page-table walk. In this repo, refill is part of the bridge between the walker and the direct-mapped Translation Lookaside Buffer.

**Project meaning.** The current page-table walker returns physical-page and attribute information that is fed back into the direct-mapped translation cache as refill state.

**Current status.** Implemented.

**Where implemented in repo.** `rtl/core/pt_walker.v`, `rtl/core/tlb_dm.v`, `rtl/core/mmu_top.v`.

---

### Page-table walker

A **page-table walker** is the logic that performs table-based translation after a translation-cache miss. It reads translation records and determines whether a usable page mapping exists. In this repo, the page-table walker is intentionally minimal and reviewable: it is single-level, uses an abstract memory interface, and forwards page attributes rather than deciding permissions itself.

**Project meaning.** The current walker performs one descriptor read per miss and can report invalid-descriptor, unmapped, and bus-error outcomes. Permission enforcement happens later in the integration wrapper.

**Current status.** Implemented in minimal single-level form. Multi-level walking is deferred.

**Where implemented in repo.** `rtl/core/pt_walker.v`, `rtl/core/mmu_top.v`.

---

### Descriptor

A **descriptor** is a structured record used by the memory-management system to represent translation information and related policy bits. In Motorola-style terminology, descriptors can represent root structures, table pointers, and page mappings. In this project, the term is especially important because the repo currently has **two descriptor worlds**: a Motorola-aligned long-format subset modeled in `descriptor_pack`, and a compact first-pass page-descriptor image used by the live page-table walker and smoke-demo datapath.

**Project meaning.** In this repo, “descriptor” can mean either the architectural Motorola-style format being modeled by `descriptor_pack` or the compact format actually consumed by the current live walker. Those are related, but they are not yet the same thing end to end.

**Current status.** Implemented in split form: long-format subset in `descriptor_pack`, compact page-descriptor image in the current live walker/datapath.

**Where implemented in repo.** `rtl/core/descriptor_pack.v`, `rtl/core/pt_walker.v`, `fpga/basys3/tops/top_mmu_demo.v`, `docs/design/descriptor_formats.md`.

---

### `descriptor_pack`

`descriptor_pack` is the project’s combinational descriptor pack/unpack module. It models a Motorola-aligned long-format subset for root descriptors, pointer descriptors, and page descriptors while preserving compatibility with the project’s existing module interface. It is important because it is the main place where the repo aligns its descriptor bit placements with Motorola long-format expectations.

**Project meaning.** `descriptor_pack` is the descriptor-format reference point for the project. It tells the reader how the repo intends to model root, pointer, and page-descriptor fields at the format level.

**Current status.** Implemented as a Motorola-aligned long-format subset. Not yet propagated end to end through the live translation datapath.

**Where implemented in repo.** `rtl/core/descriptor_pack.v`, with supporting explanation in `docs/design/descriptor_formats.md`.

---

### DT (Descriptor Type)

The **Descriptor Type (DT)** field is the field that encodes what kind of descriptor is being represented. In the current `descriptor_pack` compatibility scheme, it also acts as the basis for validity interpretation. A nonzero Descriptor Type is treated as meaning that a descriptor is valid.

**Project meaning.** In `descriptor_pack`, validity is interpreted through Descriptor Type rather than through a separate stored architecturally meaningful valid bit. In the current live walker, however, the compact descriptor image still includes an explicit valid bit. This difference is one of the current format-versus-live-datapath distinctions.

**Current status.** Implemented in the long-format subset and still distinct from the compact walker model.

**Where implemented in repo.** `rtl/core/descriptor_pack.v`, `rtl/core/pt_walker.v`.

---

### Root descriptor

A **root descriptor** is the descriptor form that represents a root translation structure. In the current long-format subset, the root descriptor includes Limit/Upper control, limit information, Descriptor Type, and root-table address.

**Project meaning.** The root descriptor is primarily a format-modeling concept in the current repo because the current live datapath still roots its walker directly from the Current Root Pointer register rather than consuming a fully propagated long-format root descriptor end to end.

**Current status.** Implemented as part of the long-format descriptor subset.

**Where implemented in repo.** `rtl/core/descriptor_pack.v`, `docs/design/descriptor_formats.md`.

---

### Pointer descriptor

A **pointer descriptor** is the descriptor form that points to another translation-table structure. In the current long-format subset, the pointer descriptor includes Limit/Upper control, limit information, Descriptor Type, and next-table address.

**Project meaning.** The pointer descriptor is correctly represented in the descriptor-format model even though the current live walker remains single-level and therefore does not yet consume multi-level pointer-descriptor trees end to end.

**Current status.** Implemented as part of the long-format descriptor subset. Full multi-level live consumption is deferred.

**Where implemented in repo.** `rtl/core/descriptor_pack.v`, `docs/design/descriptor_formats.md`.

---

### Page descriptor

A **page descriptor** is the descriptor form that represents a page mapping together with page-level policy bits. In the current long-format subset, the page descriptor includes supervisor-only, cache-inhibit, modified, used, write-protect, Descriptor Type, and page-base physical-address information.

**Project meaning.** The page descriptor is where the long-format descriptor model most directly overlaps conceptually with the live datapath, because the current walker and permission path also operate on page-level attributes. Even so, the live walker still uses a compact page-descriptor image rather than this long-format form end to end.

**Current status.** Implemented in the long-format subset; compact counterpart implemented in the live datapath.

**Where implemented in repo.** `rtl/core/descriptor_pack.v`, `rtl/core/pt_walker.v`, `docs/design/descriptor_formats.md`.

---

### Page attribute bits: S, WP, CI, M, U

The current repo uses a compact but important family of page-level attribute bits: **Supervisor-only (S)**, **Write Protect (WP)**, **Cache Inhibit (CI)**, **Modified (M)**, and **Used (U)**. In the long-format descriptor subset, these appear as page-descriptor fields. In the current live walker, closely corresponding bits appear in the compact page-descriptor image and are forwarded into the integration wrapper as page attributes.

**Project meaning.** These bits help determine page policy and later become the basis of user and supervisor permission-bank derivation in the top-level integration wrapper.

**Current status.** Implemented in both the long-format subset and the compact live walker attribute path.

**Where implemented in repo.** `rtl/core/descriptor_pack.v`, `rtl/core/pt_walker.v`, `rtl/core/mmu_top.v`, `docs/design/descriptor_formats.md`.

---

### Permission check

The **permission check** stage is the logic that decides whether a given access is allowed once translation or translation qualification has produced an access context. In this project, permission checking is deliberately separated from translation-table walking. The current permission checker evaluates read, write, or execute intent together with privilege classification and transparent-translation bypass status.

**Project meaning.** The repo uses permission checking to distinguish normal translation success from protection success. A translated hit or a successful walk can still end in a permission fault.

**Current status.** Implemented.

**Where implemented in repo.** `rtl/core/perm_check.v`, `rtl/core/mmu_top.v`.

---

### `u_perm` and `s_perm`

The **user permission bank (`u_perm`)** and **supervisor permission bank (`s_perm`)** are the current permission vectors used by the permission checker. These vectors represent the effective read, write, and execute permissions available in user mode and supervisor mode.

**Project meaning.** In the current integration wrapper, these banks are derived from page attributes and then fed into the permission checker. This means page-level policy is translated into access-level allow or deny decisions through these vectors.

**Current status.** Implemented.

**Where implemented in repo.** `rtl/core/perm_check.v`, `rtl/core/mmu_top.v`.

---

### Privilege-related fault

A **privilege-related fault** is a permission-denial classification used when a user-mode access is denied even though the corresponding supervisor-mode permission would allow that same access class. This is a valuable diagnostic distinction because it identifies denials that arise specifically from privilege separation rather than from a total lack of permission in all contexts.

**Project meaning.** The current permission checker exposes this condition explicitly instead of collapsing it into a generic permission failure.

**Current status.** Implemented.

**Where implemented in repo.** `rtl/core/perm_check.v`.

---

### Bad request

A **bad request** is a malformed access request in which the Read / Write / Execute request-class encoding is illegal, meaning either none or more than one request class is asserted. In the current project, malformed requests are denied as malformed rather than being misinterpreted as a normal read, write, or execute request.

**Project meaning.** This keeps the permission model deterministic and avoids giving accidental meaning to malformed access encodings.

**Current status.** Implemented.

**Where implemented in repo.** `rtl/core/perm_check.v`.

---

### PFLUSH / PFLUSHA (Page Flush / Page Flush All)

**Page Flush (PFLUSH)** and **Page Flush All (PFLUSHA)** are maintenance operations that invalidate cached translation state. In the current project, these behaviors are represented through the first-pass control shim rather than through a fully complete instruction-accurate Motorola implementation. Whole-cache flush invalidates all cached translations, while targeted flush invalidates a matching translation-cache entry using address plus Function Code.

**Project meaning.** These are the current maintenance primitives for translation-cache state. They matter for software-visible control behavior, tests, and the Basys 3 smoke harness.

**Current status.** Implemented in first-pass control-shim form.

**Where implemented in repo.** `rtl/core/flush_ctrl.v`, `rtl/core/tlb_dm.v`, `rtl/core/mmu_top.v`, `tb/integ/instr_shim_tb.sv`.

---

### PLOAD (Page Load)

**Page Load (PLOAD)** is the preload-style control operation represented in the current repo. In general terms, a page-load operation asks the memory-management system to prepare or establish translation state. In the current project, Page Load exists in first-pass form: it participates in the control interface and lookup/walk flow, but the repo explicitly says it is not yet a fully complete Motorola architectural implementation.

**Project meaning.** Page Load is part of the current software-visible control vocabulary and future compatibility story, even though its semantics are still being tightened.

**Current status.** Implemented in first-pass form only.

**Where implemented in repo.** `rtl/core/flush_ctrl.v`, `rtl/core/mmu_top.v`, `tb/integ/instr_shim_tb.sv`.

---

### PTEST (Page Test)

**Page Test (PTEST)** is the probe-style control operation represented in the current repo. Its purpose in the project is to ask whether the current system has a usable first-pass answer for a given logical address and Function Code. In the current repo, Page Test is especially important because a successful probe does not simply mean “translation-cache hit.” A usable translated result or a usable transparent-translation-qualified result can both count as successful probe outcomes.

**Project meaning.** Page Test is the vocabulary bridge between translated results, transparent-translation-qualified results, and status reporting in the current first-pass control model.

**Current status.** Implemented in first-pass control-shim form. Not architecturally complete.

**Where implemented in repo.** `rtl/core/flush_ctrl.v`, `rtl/core/mmu_top.v`, `docs/design/address_map.md`, `tb/integ/instr_shim_tb.sv`.

---

### Probe status

**Probe status** is the compact result record returned by the current Page Test control path. In the current project, probe status is important because it distinguishes between translated results, transparent-translation-qualified results, and misses without requiring a fully complete historical result model.

**Project meaning.** Probe status is how the current system exposes useful information about translation state to tests, software-visible control flow, and the Basys 3 smoke harness.

**Current status.** Implemented in first-pass status form.

**Where implemented in repo.** `rtl/core/flush_ctrl.v`, `rtl/core/mmu_top.v`, `docs/design/address_map.md`, `fpga/basys3/tops/top_mmu_demo.v`.

---

### `status_hit_o`

`status_hit_o` is the current probe-status signal that indicates that a usable first-pass result exists. This is a subtle and important term because, in the current repo, it does **not** mean only “translation-cache hit.” A translated result or a transparent-translation-qualified result can both count as probe success.

**Project meaning.** `status_hit_o` is broader than translated-hit status. It is part of the current first-pass status model that makes transparent-translation-qualified success visible rather than hiding it.

**Current status.** Implemented in the first-pass control/status path.

**Where implemented in repo.** `rtl/core/flush_ctrl.v`, `rtl/core/mmu_top.v`, `docs/design/address_map.md`.

---

### `resp_hit_o`

`resp_hit_o` is the current translated-hit signal in the normal response path. In the present implementation, it is reserved for translated, translation-cache-backed hits. This distinction matters because the current project explicitly does **not** let a transparent-translation-qualified success claim a translated hit.

**Project meaning.** `resp_hit_o` is intentionally narrower than `status_hit_o`. The distinction between the two is one of the most important pieces of current repo vocabulary.

**Current status.** Implemented.

**Where implemented in repo.** `rtl/core/mmu_top.v`, with supporting explanation in `README.md` and `docs/design/address_map.md`.

---

### `mmu_top`

`mmu_top` is the first-pass top-level integration wrapper for the current Memory Management Unit architecture. It is where the major implemented concepts meet: register block, Function Code decode, transparent-translation qualification, translation-cache lookup, page-table walking, refill, permission checking, and control operations.

**Project meaning.** If one file best represents the current implemented Memory Management Unit architecture, `mmu_top` is that file. It is the integrated execution narrative of the repo.

**Current status.** Implemented as a first-pass integration wrapper with explicit subset boundaries.

**Where implemented in repo.** `rtl/core/mmu_top.v`.

---

### Basys 3 smoke demo

The **Basys 3 smoke demo** is the hardware-facing demonstration harness for the project. It is not intended to be a full processor system, a bus-accurate integration, or proof of complete Motorola behavior. It is instead a deliberately small educational and verification harness that configures the current Memory Management Unit register block, drives canned access and control cases, and exposes compact results on switches and light-emitting diodes.

**Project meaning.** The smoke demo is the current hardware proof-of-life and teaching platform for the implemented subset.

**Current status.** Implemented and working as a smoke harness. Explicitly not a full system-on-chip integration.

**Where implemented in repo.** `fpga/basys3/tops/top_mmu_demo.v`, `README.md`.

---

## Maintenance rule

This glossary is part of the technical reference baseline for the project. When a term changes meaning in code, documentation, tests, or the wiki, update this page as part of the same change.

If a feature is still first-pass, say so plainly. If a term has both a Motorola-manual meaning and a current repo-specific meaning, explain both and distinguish them clearly.

This page should remain the authoritative vocabulary reference for the implemented repo state.