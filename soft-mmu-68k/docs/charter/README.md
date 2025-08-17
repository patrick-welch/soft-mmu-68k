# Charter & Workflow

**Goal:** A synthesizable soft MMU compatible with 68851/68030-style semantics.

**Outcomes:** Correct programming model (CRP/SRP/TC/TTx/MMUSR), faithful ATC/TTR behavior, and instruction-visible effects (PLOAD, PFLUSH, PTEST, MOVEC).

**Ground truth:** Vendor-primary manuals listed in `../refs/README.md`.

**Change control:** Every RTL change that affects architected behavior must include:
- A reference to the exact manual section(s)
- A short rationale (design note)
- Test evidence (link to TB and vectors)

**Done means:** Spec-aligned ✅ + tests passing ✅ + cited ✅.
