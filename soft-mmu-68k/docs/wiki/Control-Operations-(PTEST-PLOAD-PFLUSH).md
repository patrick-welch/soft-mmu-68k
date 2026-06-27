# Control Operations (PTEST PLOAD PFLUSH)

This page documents the current first-pass control-operation behavior implemented in the Soft Memory Management Unit project.

It describes the **implemented repo state**, and it is especially important to read this page with caution: the current repo explicitly says these behaviors are **first-pass control-layer shims**, not full Motorola architectural instruction models.

## Purpose

The current control path exists to provide practical, reviewable, and testable handling for:

- **Page Flush All (PFLUSHA)**
- targeted **Page Flush (PFLUSH)**
- **Page Test (PTEST)**
- **Page Load (PLOAD)**

These operations are implemented through the `flush_ctrl` control shim and integrated into `mmu_top`.

The current goal is not full instruction-level emulation. The current goal is to provide a usable control surface for:

- translation-cache maintenance
- probe/status behavior
- preload triggering
- hardware smoke-demo use
- integration-bench validation

## Where implemented in repo

Primary implementation sources for the current control model:

- control shim: `rtl/core/flush_ctrl.v`
- current probe and status behavior description: `docs/design/address_map.md`
- integrated use in top-level MMU: `rtl/core/mmu_top.v`
- repo status and first-pass caveats: `README.md`
- hardware-facing use in smoke demo: `fpga/basys3/tops/top_mmu_demo.v`

## First and most important caveat

The repo repeatedly says the following in substance:

- **Page Test (PTEST)** is not yet fully architecturally complete
- **Page Load (PLOAD)** is not yet fully architecturally complete
- **Page Flush (PFLUSH)** behavior is represented as a first-pass control shim
- **MMU Status Register (MMUSR)** result behavior is not yet a full Motorola architectural model

That means this page should be read as documentation of **current implemented control behavior**, not as a claim of complete historical compatibility.

## The `flush_ctrl` module

`flush_ctrl` is the current control-operation shim.

It is explicitly documented in code as:

- minimal
- first-pass
- not a full instruction model

Its main responsibilities are:

- accept control commands
- generate one-cycle flush pulses
- manage one in-flight probe or preload at a time
- return a compact latched status/result record
- distinguish translated results from transparent-translation-qualified results

That makes it one of the key “bridge” modules in the current repo: it connects architectural vocabulary to the current simple implementation.

## Command model

The current control shim uses a command interface with operation values representing:

- no operation
- flush all
- flush match
- probe
- preload

These commands are carried into the integration wrapper and then translated into behavior against the translation-cache and lookup path.

## Busy and ready behavior

The current control shim exposes:

- command valid
- command ready
- busy

This makes the control path behave like a small command engine.

In the current implementation:

- only one in-flight probe or preload request is supported at a time
- flush operations generate one-cycle completion-style pulses
- probe and preload can occupy the control path until their response condition is satisfied

This is a good example of the project choosing clarity and reviewability over premature complexity.

## Page Flush All (PFLUSHA)

**Page Flush All (PFLUSHA)** is the current whole-translation-cache invalidation operation.

In the current repo, this operation causes the control shim to emit a one-cycle whole-cache flush pulse. The direct-mapped translation-cache implementation then clears all valid entries.

The control shim also returns a status completion record, but this record is intentionally minimal and zero-status in the current implementation.

### Practical meaning
This is the simplest control operation in the current design. It is the maintenance operation that forces all cached translations to be forgotten.

### Current implementation scope
The project treats this as a current maintenance primitive, not as proof of complete Motorola architectural flush semantics.

## Targeted Page Flush (PFLUSH match)

Targeted **Page Flush (PFLUSH)** in the current repo means invalidating a translation-cache entry using:

- address
- Function Code

This is important because the current translation-cache identity includes both tag and Function Code. A targeted flush therefore needs both pieces of information to identify the matching entry correctly.

The control shim emits:

- a one-cycle targeted flush pulse
- the explicit address operand
- the explicit Function Code operand

The direct-mapped translation-cache then invalidates the matching entry if present.

### Practical meaning
This is the current repo’s first-pass “flush one matching translation” behavior.

### Important conceptual point
Because translation-cache identity includes Function Code, targeted flush is not simply “flush by address.”

## Page Test (PTEST)

**Page Test (PTEST)** is the current probe-style control operation.

In the current repo, probe behavior is one of the most important control features because it makes the current system’s translation result visible without needing a complete architectural processor interface.

The control shim currently defines probe behavior in terms of a small latched status/result record.

### What probe does in the current repo
A probe asks whether the current first-pass system has a usable result for a given:

- logical address
- Function Code

That result can be:

- a translated result
- a transparent-translation-qualified result
- a miss

### Probe result meaning
The current docs define the current probe result meaning very carefully.

For `CMD_PROBE`, the current repo says `status_hit_o` means:

> a usable first-pass result exists

That is broader than “translation-cache hit.”

A probe can count as successful if it found:

- a normal translated result
- or a transparent-translation-qualified result

This is a very important distinction.

## Probe result classes

The current repo defines three broad probe result classes.

### 1. Translated result
A **translated result** means the probe found a normal translated answer.

In the current control path, this means:

- status hit is asserted
- the translated-status class bit is set
- the transparent-translation match class bit is clear
- the status physical address is the translated physical address

### 2. Transparent-translation-qualified result
A **transparent-translation-qualified result** means the probe did not consume a normal translated page-table result but instead matched the first-pass transparent-translation subset.

In the current control path, this means:

- status hit is asserted
- the transparent-translation match class bit is set
- the translated-status class bit is clear
- the status physical address mirrors the probed logical address resized to physical-address width

This is one of the most important parts of the current repo because it keeps transparent-translation behavior visible and separate from translated-hit behavior.

### 3. Miss
A **miss** means no usable first-pass result was found.

In the current control model:

- status hit is deasserted
- class bits are not forced into a translated or transparent interpretation by the control shim

## Why probe semantics matter so much here

Probe is where several current project ideas meet:

- translation-cache semantics
- transparent-translation semantics
- status reporting semantics
- first-pass **MMU Status Register (MMUSR)** caveats

Because the current repo is not yet claiming full historical **Page Test (PTEST)** behavior, the probe/status model is the practical way the project communicates what the system currently knows about an address.

That is why the wiki should describe probe with more care than flush.

## Page Load (PLOAD)

**Page Load (PLOAD)** is the current preload-style control operation.

In the current repo, preload is explicitly limited. The code comments say:

- preload drives a request/ready handshake
- there is not yet a full walk-completion model for preload

This means the current implementation is useful as a control concept and as a structure for future development, but it should not be documented as a fully mature architectural behavior.

### Practical meaning
In the current first-pass model, preload is a way to ask the system to set up translation state through the current lookup or walk path.

### Documentation rule
The wiki should describe preload as **implemented in first-pass form**, not as architecturally complete.

## Status outputs

The current control shim produces a compact status record including:

- status valid
- status command
- status hit
- status physical address
- status bits

These fields are intentionally small and practical.

They are not the same thing as a complete historical **MMU Status Register (MMUSR)** model.

## Status class bits

The current repo uses status bits to distinguish result classes.

### Transparent-translation match status bit
The top status-class bit is used to indicate a transparent-translation-qualified result.

### Translated-status bit
The next-highest status-class bit is used to indicate a translated result.

These bits matter because the control shim is responsible for classifying results in a way that is visible to both tests and the Basys 3 smoke demo.

## `status_hit_o` meaning

One of the most subtle and important points in the current control design is the meaning of `status_hit_o`.

It does **not** simply mean “translation-cache hit.”

In the current repo, it means:

- a usable first-pass result exists

That can include:
- translated result
- transparent-translation-qualified result

This is a better semantic choice for the current subset than overloading the term “hit” to mean only one of those cases.

## Relationship to `resp_hit_o`

The repo also makes an important distinction between:

- `status_hit_o`
- `resp_hit_o`

In the current design:

- `resp_hit_o` is reserved for translated translation-cache-backed hits
- transparent-translation-qualified success does **not** claim a translated hit
- but transparent-translation-qualified success **can** still produce `status_hit_o = 1`

This distinction is one of the most important pieces of current repo vocabulary and should be preserved throughout the wiki.

## Integration with `mmu_top`

`mmu_top.v` instantiates `flush_ctrl` and wires it into:

- translation-cache invalidation
- probe requests
- preload requests
- top-level status reporting

This means the control shim is not an isolated helper. It is part of the integrated behavior of the current Memory Management Unit.

## Control operations in the Basys 3 smoke demo

The Basys 3 smoke-demo harness uses these control behaviors directly.

The front-panel mode selection includes cases for:

- access
- probe
- preload then access plus probe
- targeted flush-match then access plus probe

That makes the board demo a practical teaching aid for the current control model.

It also means that these control operations are not just theoretical support features. They are part of the current hardware-visible user experience.

## What the current control model proves

The current control model proves that the repo can:

- issue whole-cache flushes
- issue targeted flushes
- perform first-pass probes
- distinguish translated results from transparent-translation-qualified results
- drive preload-style control flow
- expose compact status for tests and board smoke cases

## What the current control model does not prove

The current control model does **not** prove:

- complete Motorola instruction semantics
- full architecturally correct **MMU Status Register (MMUSR)** synthesis
- full **Page Test (PTEST)** termination semantics
- complete **Page Load (PLOAD)** behavior
- every legality rule associated with transparent translation and historical PMMU behavior

The current repo is very explicit about those limits, and the wiki should remain equally explicit.

## Practical editorial guidance

When writing about these control operations elsewhere in the wiki:

- say **first-pass control shim** unless you are discussing future work
- distinguish **translated result** from **transparent-translation-qualified result**
- do not use “hit” carelessly
- do not imply full Motorola instruction compatibility unless that is actually implemented later

## Current status summary

The current repo’s control-operation story is:

- **implemented:** flush all
- **implemented:** targeted flush by address plus Function Code
- **implemented:** first-pass probe/status behavior
- **implemented:** first-pass preload handshake behavior
- **not yet complete:** full Motorola **Page Test (PTEST)** semantics
- **not yet complete:** full Motorola **Page Load (PLOAD)** semantics
- **not yet complete:** full Motorola **MMU Status Register (MMUSR)** result model

## Related pages

- [[Glossary]]
- [[Architecture-Overview]]
- [[Translation-Flow]]
- [[Translation-Cache-(TLB-and-ATC)]]
- [[Function-Codes-and-Access-Classification]]
- [[FPGA-Demo-and-Basys-3-Bring-Up]]