# Address Map & Function Codes (FC)

**What this defines**
- VA spaces & FC[2:0] → User/Supervisor × Program/Data
- Transparent translation regions (TTR) vs translated regions
- Device vs cacheable attributes (if modeled)

**To specify with cites**
- FC decode and privilege rules  [^PRM], [^68030-UM]
- TTR matching algorithm (040/060)  [^68040-UM], [^68060-UM]

**Open items**
- Final attribute set (W/R/X/U/S + cache modes) and default TTR masks.

*References:* [^PRM] [^68030-UM] [^68040-UM] [^68060-UM]
