# ATC/TLB Microarchitecture

**Minimum**: Direct-mapped ATC/TLB; refill from walker; invalidate hooks.
**Later**: Set-associative variant; replacement policy.

**Behavioral contract**
- Hit/miss, refill, attribute propagation  [^68030-UM]
- PFLUSH variants: what must be invalidated  [^68030-UM], [^68040-UM]
- PTEST semantics (reporting, MMUSR bits)  [^PRM], [^68030-UM]

*References:* [^68030-UM] [^68040-UM] [^PRM]
