# Translation Flow

This page explains how a request moves through the current implemented Soft Memory Management Unit datapath.

It describes the **implemented repo state** and should be read as an explanation of the current first-pass design, not as a claim of complete Motorola architectural behavior.

## Purpose

The goal of the current translation flow is to turn a logical access request into one of four broad outcomes:

- a transparent-translation-qualified result
- a translation-cache hit result
- a page-walk-derived result
- a fault

The current integrated path is implemented in `rtl/core/mmu_top.v`, with support from:

- `rtl/core/mmu_regs.v`
- `rtl/core/mmu_decode.v`
- `rtl/core/perm_check.v`
- `rtl/core/tlb_dm.v`
- `rtl/core/tlb_compare.v`
- `rtl/core/pt_walker.v`
- `rtl/core/flush_ctrl.v`

The repo explicitly describes this as a first-pass integration wrapper for register/control, translation-cache lookup, page walk, refill, permission checks, and transparent-translation qualification.

## Where implemented in repo

Primary implementation sources for the current translation flow:

- integrated datapath: `rtl/core/mmu_top.v`
- register block: `rtl/core/mmu_regs.v`
- Function Code decode: `rtl/core/mmu_decode.v`
- permission checking: `rtl/core/perm_check.v`
- translation cache: `rtl/core/tlb_dm.v`, `rtl/core/tlb_compare.v`
- page-table walker: `rtl/core/pt_walker.v`
- control shim: `rtl/core/flush_ctrl.v`
- smoke-demo harness: `fpga/basys3/tops/top_mmu_demo.v`

## The request interface

A normal processor-style request enters the current integration wrapper with these key inputs:

- request valid
- logical address
- **Function Code (FC)**
- read/write intent
- fetch intent

The output side can then return:

- response valid
- physical address
- translated-hit indication
- fault indication
- fault code
- permission-fault detail bits

This interface reflects the first-pass goal of modeling address translation and protection behavior without yet claiming full external bus timing or full Motorola completion semantics.

## High-level translation-flow summary

The current request flow can be summarized as:

1. read current control state from the register block
2. decode the Function Code
3. check transparent-translation qualification
4. if not transparent, perform translation-cache lookup
5. if miss, start the page-table walker
6. if a translation is obtained, refill the translation cache
7. apply permission checking
8. return response or fault

This page expands those steps in detail.

## Step 1: register-state availability

The translation flow depends on the current register block.

At integration time, `mmu_top.v` instantiates the Memory Management Unit register block and receives:

- **Current Root Pointer (CRP)**
- **Supervisor Root Pointer (SRP)**
- **Translation Control (TC)**
- **Transparent Translation 0 (TT0)**
- **Transparent Translation 1 (TT1)**
- **MMU Status Register (MMUSR)**

Not every one of those values is used equally in the current first-pass datapath, but the register block is the configuration spine of the system. In particular:

- **Current Root Pointer (CRP)** feeds the current walker table base
- **Translation Control (TC)** contributes table-entry configuration
- **Transparent Translation 0 (TT0)** and **Transparent Translation 1 (TT1)** feed the transparent-translation qualifier



## Step 2: Function Code decode

The request’s **Function Code (FC)** is decoded by `mmu_decode`.

This produces a compact set of semantic outputs:

- user versus supervisor
- program versus data
- Central Processing Unit (CPU) / special-space flag

These decoded meanings are then used in both the transparent-translation path and the permission path. The current design relies on this simplified semantic interface rather than passing raw classification complexity into every downstream block.

## Step 3: transparent-translation qualification

Before the current design checks the normal translation cache, it checks whether the access qualifies for the current first-pass transparent-translation subset.

This qualification depends on:

- the current **Transparent Translation 0 (TT0)** and **Transparent Translation 1 (TT1)** values
- whether the access is a normal memory-space access
- whether privilege matches
- whether program/data space matches
- whether the masked logical-address high-byte comparison matches

If a transparent-translation match occurs:

- the request bypasses page-table translation
- the physical address becomes an identity-style resize of the logical address
- the translated-hit output is **not** asserted, because the repo reserves that signal for translated translation-cache-backed hits
- the request can still be denied if malformed, because transparent translation does not legalize a bad request encoding

The design docs explicitly state that Central Processing Unit (CPU) / special-space accesses do not transparently match in the current subset.

## Step 4: translation-cache lookup

If the request does not qualify for transparent translation, the integration wrapper performs a lookup in the direct-mapped translation cache.

This path uses:

- `tlb_dm.v` for indexed storage
- `tlb_compare.v` for tag and Function Code comparison

The lookup compares:

- the relevant virtual tag
- the stored Function Code

If the entry hits:

- the physical address is reconstructed from the physical-frame number plus page offset
- the entry’s attributes are returned
- the permission stage decides whether the request is allowed

This is the fast translated path in the current design.

## Step 5: translation-cache hit permission check

A translation-cache hit is not the end of the flow.

Once a hit occurs, the integration wrapper derives user and supervisor permission banks from the entry’s attribute bits and passes the request through the hit-path permission checker.

That checker decides whether the translated hit is:

- allowed
- denied as a permission fault
- malformed as a bad request

If permission succeeds:

- the response is valid
- the physical address is the translation-cache output
- the translated-hit output is asserted

If permission fails:

- the response is still valid in the sense that a conclusion was reached
- the fault output is asserted
- the fault code identifies a permission fault
- the permission-fault detail bits are returned

This separation between “translation hit” and “permission success” is important. A request can hit in the translation cache and still fault at the protection stage.

## Step 6: translation-cache miss and walker start

If the translation cache misses, the integration wrapper captures the request state and starts the page-table walker.

The pending state includes:

- whether the original request was a processor request
- logical address
- Function Code
- read/write intent
- fetch intent

The integration wrapper then moves from its idle state into a walker-start state and then into a wait-for-walker-completion state. This makes the current design explicitly single-outstanding-request oriented.

## Step 7: page-table walk

The current page-table walker is minimal and single-level.

It receives:

- the pending logical address
- the pending Function Code
- the table base from **Current Root Pointer (CRP)**
- the table-entry span derived from **Translation Control (TC)**

It then performs one abstract descriptor fetch.

The walker can complete in one of four broad ways:

- valid page translation
- invalid descriptor
- unmapped result
- bus error

The walker does not decide access permission. Instead, it returns page attributes for later interpretation. That is a deliberate division of labor in the current architecture.

## Step 8: refill

If the walker returns a valid translation, it also emits refill information for the translation cache.

That refill information includes:

- the virtual address that was walked
- the physical-page base
- the Function Code carried by the pending request
- the attribute bits associated with the walked page

The direct-mapped translation cache then stores that new translation into the indexed entry.

This means the miss path is not only a one-time resolution path. It is also how the fast path is taught future translations.

## Step 9: post-walk permission check

When the walker completes without a walker fault, the integration wrapper derives permission banks from the walker-returned attributes and runs the walk-path permission checker.

That means a walked translation can still fail due to protection even though the descriptor was valid and the walk completed normally.

If permission succeeds:

- the response is valid
- the physical address is formed from the walked page base plus original page offset

If permission fails:

- the response is valid as a completed decision
- a permission-fault code is returned
- the permission-fault detail bits are provided

This mirrors the separation used in the translation-cache hit path. Translation success and permission success are not the same concept.

## Step 10: walker-fault handling

If the walker reports a fault, the integration wrapper translates that walker-level fault into the outward response fault codes.

Current walker fault mapping includes:

- invalid descriptor → invalid fault
- unmapped result → unmapped fault
- bus error → bus-error fault

This is one of the places where the current first-pass design is very readable: walker fault classes stay distinct instead of being prematurely collapsed into one generic translation failure.

## Control-path interaction with translation flow

The translation flow is not only for ordinary processor requests. It also interacts with the current control shim.

The control path supports first-pass:

- flush all
- targeted flush
- probe
- preload

### Flush
A whole-translation-cache flush clears all entries. A targeted flush matches by address plus Function Code and invalidates the matching entry if present.

### Probe
A probe uses the current lookup path to determine whether the system currently has a usable first-pass result for the probed address and Function Code.

The returned status distinguishes:

- translated result
- transparent-translation-qualified result
- miss

This is a crucial part of the current repo because it makes the translated-versus-transparent distinction visible without requiring a complete architectural **Page Test (PTEST)** and **MMU Status Register (MMUSR)** model.

### Preload
Preload currently drives a request/ready style flow and can trigger a walk on a miss, but it remains part of a first-pass control model rather than a full completed architectural operation.

## What counts as a “hit” in the current design

The current repo is careful about the word “hit.”

### Translated hit
A **translated hit** is a translation-cache-backed translated result. In the current integration wrapper, this is what `resp_hit_o` is reserved for.

### Transparent-translation-qualified success
A transparent-translation-qualified success is **not** reported as a translated hit. It is a valid result, but it is not a translation-cache hit. This distinction is one of the most important conceptual points in the current repo and should be preserved in the wiki.

## Translation flow in the Basys 3 demo

The Basys 3 smoke-demo harness is a valuable teaching view of the current translation flow.

It does not instantiate a full bus-accurate system. Instead, it:

- programs the register block after reset
- builds a demo request from switches
- drives access, probe, preload, or targeted flush modes
- uses a tiny built-in descriptor responder for walk responses
- displays compact result and status information on light-emitting diodes

The repo documentation says this proves that the current subset can:

- configure the register block
- perform translated access and probe behavior
- show transparent-translation-qualified identity-style behavior
- show a user permission fault
- rerun canned cases from switches

It also explicitly says this does **not** prove full Motorola architectural behavior, full legality handling, multi-level walking, or real processor execution.

## Current limitations

This page should be read with the repo’s current boundaries in mind:

- the transparent-translation subset is narrow
- the control-path semantics are first-pass only
- the walker is single-level only
- the integration wrapper handles one outstanding translation request at a time
- the current repo does not yet provide a complete Motorola architectural model
- the long-format descriptor model is not yet propagated end-to-end through the live datapath

Those limitations are part of the current translation flow and should remain visible in the documentation.

## Related pages

- [[Glossary]]
- [[Architecture-Overview]]
- [[Function-Codes-and-Access-Classification]]
- [[Translation-Cache-(TLB-and-ATC)]]
- [[Page-Table-Walker]]
- [[Control-Operations-(PTEST-PLOAD-PFLUSH)]]