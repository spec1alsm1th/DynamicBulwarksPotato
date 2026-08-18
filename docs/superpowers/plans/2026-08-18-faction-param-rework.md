# Faction Parameter Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the overloaded `LOOT_FACTION` lobby parameter into an independent world-loot pool and a new `ENEMY_GEAR_FACTION` pool, stop re-arming enemies so they keep native role loadouts, apply nine new parameter defaults, and ship it as release `v1.1.0`.

**Architecture:** This is an Arma 3 multiplayer mission, not an application. Lobby parameters are static classes in `description.ext`, read at runtime with `BIS_fnc_getParamValue`. `hostiles/lists.sqf` and `loot/lists.sqf` run once on the server at mission start and populate global arrays (`List_OPFOR`, `List_Armour`, `List_Primaries`, ...) that every spawner reads. All changes land in those two list builders, four spawner scripts, and `description.ext`.

**Tech Stack:** SQF (Arma 3 scripting), `description.ext` config syntax, git, `gh` CLI for the release.

**Spec:** `docs/superpowers/specs/2026-08-18-faction-param-rework-design.md`

## Global Constraints

- **No test framework exists.** Arma 3 missions cannot be unit-tested outside the game. Every task below is verified by (a) exact `grep` assertions on the working tree and (b) `diag_log` lines that must appear in the server RPT during the integration run in Task 6. Do not claim a task passes on the basis of reading the code.
- **Every `diag_log` message must be prefixed `DynBulwarks: `** — that is the existing convention and the integration run greps for it.
- **Never let a filter produce an empty list.** Every new filter or override must check its result count and fall back to the previous value with a `diag_log` line explaining the fallback. An empty `List_OPFOR` or `List_Primaries` breaks the mission.
- **`vehicles` is nular in SQF** — never write `forEach vehicles _g`. Use parentheses around unary command arguments: `forEach (units _g)`.
- **Do not touch `FRIENDLY_FACTION`**, `List_NATO`, `List_Defectors`, or `SUPPORT_AIRCRAFT`. They carry the FDF paratroop and C-160 behaviour and are explicitly out of scope.
- **Do not change `BULWARK_SUPPORTITEMS` prices** in `editMe.sqf`. The economy shift is documented in the release notes instead.
- Files in this repo use **CRLF** line endings; `.sqf` files use tabs in older code and four spaces in newer blocks. Match the surrounding file.
- Commit after every task with the message given in that task's final step.

---

### Task 1: Remove enemy re-arming

Enemies currently have their primary weapon stripped and replaced with a random weapon from the loot pool whenever loot filtering is on, and independently whenever `RANDOM_WEAPONS` is Yes. Both destroy the vanilla role loadouts the spec requires. This task removes the loot-driven re-arm entirely and flips `RANDOM_WEAPONS` to default No.

**Files:**
- Modify: `loot/lists.sqf:52-58`
- Modify: `hostiles/spawnInfantry.sqf:40-59`
- Modify: `hostiles/spawnSquad.sqf:9-11`
- Modify: `hostiles/airborneWave.sqf:12-14`
- Modify: `hostiles/specSwticharooWave.sqf:37-50`
- Modify: `description.ext` (`RANDOM_WEAPONS` default)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: the global `LOOT_REARM_ENEMIES` no longer exists. No later task may reference it.

- [ ] **Step 1: Delete `LOOT_REARM_ENEMIES` from the loot list builder**

In `loot/lists.sqf`, delete this entire block (the comment and the assignment):

```sqf
// Whether enemies get re-armed from the loot pool (spawnInfantry, spawnSquad,
// airborneWave, specSwticharooWave). Normally on whenever loot is filtered, so
// enemy weapons match the loot theme. Disabled for case 8: world loot is Finnish,
// but the Russians keep their own RHS weapons rather than spawning with RK-62s.
LOOT_REARM_ENEMIES = (_lootFactionParam != 0 && {_lootFactionParam != 8});
```

Leave the `diag_log` line that follows it untouched.

- [ ] **Step 2: Remove the re-arm block from `spawnInfantry.sqf`**

Delete these lines in full (comment, parameter read, and the whole `if` block):

```sqf
// Replace weapon with faction-appropriate one if loot faction filtering is active
private _lootFaction = "LOOT_FACTION" call BIS_fnc_getParamValue;
if (_lootFaction != 0 && {isNil "LOOT_REARM_ENEMIES" || {LOOT_REARM_ENEMIES}}) then {
	_unitPrimaryWeap = primaryWeapon _unit;
	_primaryAmmoTpyes = getArray (configFile >> "CfgWeapons" >> _unitPrimaryWeap >> "magazines");
	{
		if (_x in _primaryAmmoTpyes) then {
			_unit removeMagazineGlobal _x;
		};
	} forEach magazines _unit;
	_unitPrimaryToAdd = selectRandom List_Primaries;
	_unitMagToAdd = selectRandom getArray (configFile >> "CfgWeapons" >> _unitPrimaryToAdd >> "magazines");
	_unit addWeaponGlobal _unitPrimaryToAdd;
	_unit addPrimaryWeaponItem _unitMagToAdd;
	_unit addMagazine _unitMagToAdd;
	_unit addMagazine _unitMagToAdd;
	_unit addMagazine _unitMagToAdd;
	_unit selectWeapon _unitPrimaryToAdd;
};
```

The `removeAllAssignedItems _unit;` line that follows stays.

- [ ] **Step 3: Narrow `_replaceWeapons` in `spawnSquad.sqf`**

Replace lines 9-11:

```sqf
_randWeapons = "RANDOM_WEAPONS" call BIS_fnc_getParamValue;
_lootFaction = "LOOT_FACTION" call BIS_fnc_getParamValue;
_replaceWeapons = (_randWeapons == 1 || {_lootFaction != 0 && {isNil "LOOT_REARM_ENEMIES" || {LOOT_REARM_ENEMIES}}});
```

with:

```sqf
// RANDOM_WEAPONS is the only thing that re-arms enemies now. Loot faction
// filtering no longer touches enemy loadouts, so units keep their config
// weapons and role kit (AT soldiers keep launchers, etc).
_replaceWeapons = (("RANDOM_WEAPONS" call BIS_fnc_getParamValue) == 1);
```

Leave the `if (_replaceWeapons) then { ... }` block at line 78 untouched.

- [ ] **Step 4: Narrow `_replaceWeapons` in `airborneWave.sqf`**

Replace lines 12-14:

```sqf
private _randWeapons = "RANDOM_WEAPONS" call BIS_fnc_getParamValue;
private _lootFaction = "LOOT_FACTION" call BIS_fnc_getParamValue;
private _replaceWeapons = (_randWeapons == 1 || {_lootFaction != 0 && {isNil "LOOT_REARM_ENEMIES" || {LOOT_REARM_ENEMIES}}});
```

with:

```sqf
// RANDOM_WEAPONS is the only thing that re-arms enemies now — see spawnSquad.sqf.
private _replaceWeapons = (("RANDOM_WEAPONS" call BIS_fnc_getParamValue) == 1);
```

Leave the `if (_replaceWeapons) then { ... }` block at line 114 untouched.

- [ ] **Step 5: Remove the re-arm block from `specSwticharooWave.sqf`**

Delete these lines in full:

```sqf
	// Replace weapon with faction-appropriate one if loot faction filtering is active
	if (("LOOT_FACTION" call BIS_fnc_getParamValue) != 0 && {isNil "LOOT_REARM_ENEMIES" || {LOOT_REARM_ENEMIES}}) then {
		private _unitPrimaryWeap = primaryWeapon _unit;
		private _primaryAmmoTpyes = getArray (configFile >> "CfgWeapons" >> _unitPrimaryWeap >> "magazines");
		{ if (_x in _primaryAmmoTpyes) then { _unit removeMagazineGlobal _x; }; } forEach magazines _unit;
		private _unitPrimaryToAdd = selectRandom List_Primaries;
		private _unitMagToAdd = selectRandom getArray (configFile >> "CfgWeapons" >> _unitPrimaryToAdd >> "magazines");
		_unit addWeaponGlobal _unitPrimaryToAdd;
		_unit addPrimaryWeaponItem _unitMagToAdd;
		_unit addMagazine _unitMagToAdd;
		_unit addMagazine _unitMagToAdd;
		_unit addMagazine _unitMagToAdd;
		_unit selectWeapon _unitPrimaryToAdd;
	};
```

The `removeAllAssignedItems _unit;` line that follows stays.

- [ ] **Step 6: Flip the `RANDOM_WEAPONS` default**

In `description.ext`, change the `RANDOM_WEAPONS` class so it reads:

```cpp
	class RANDOM_WEAPONS
	{
		title = "Randomize Hostile Weapons (overrides default role loadouts)";
		values[] = {1, 0};
		texts[] = {"Yes", "No"};
		default = 0;
	};
```

- [ ] **Step 7: Verify no references survive**

Run:

```bash
grep -rn "LOOT_REARM_ENEMIES" --include=*.sqf --include=*.ext .
```

Expected: **no output at all.** Then run:

```bash
grep -rn "LOOT_FACTION" --include=*.sqf . | grep -v "loot/lists.sqf"
```

Expected: only `hostiles/lists.sqf` matches remain (they are replaced in Task 3). No matches in `spawnInfantry.sqf`, `spawnSquad.sqf`, `airborneWave.sqf`, or `specSwticharooWave.sqf`.

- [ ] **Step 8: Verify brace balance in every edited SQF file**

Deleting blocks by hand is the likeliest way to break this mission, and Arma will only tell you at mission start. Run:

```bash
for f in loot/lists.sqf hostiles/spawnInfantry.sqf hostiles/spawnSquad.sqf hostiles/airborneWave.sqf hostiles/specSwticharooWave.sqf; do
  echo "$f: open=$(grep -o '{' "$f" | wc -l) close=$(grep -o '}' "$f" | wc -l)"
done
```

Expected: `open` equals `close` for every file. If any file is unbalanced, you deleted a brace that belonged to surrounding code — re-check that edit before continuing.

- [ ] **Step 9: Commit**

```bash
git add loot/lists.sqf hostiles/spawnInfantry.sqf hostiles/spawnSquad.sqf hostiles/airborneWave.sqf hostiles/specSwticharooWave.sqf description.ext
git commit -m "Stop re-arming enemies from the loot pool"
```

---

### Task 2: Add the `ENEMY_GEAR_FACTION` parameter

Adds the new lobby parameter and retitles `LOOT_FACTION`. This task is config only — nothing reads the new parameter until Task 3.

**Files:**
- Modify: `description.ext:204-219` (the `FRIENDLY_FACTION` / `LOOT_FACTION` region)

**Interfaces:**
- Consumes: nothing.
- Produces: parameter `ENEMY_GEAR_FACTION`, integer values `0`–`14`, default `0`. Tasks 3 and 4 read it with `["ENEMY_GEAR_FACTION", 0] call BIS_fnc_getParamValue`. The value meanings are fixed here and must not be renumbered later:
  `0` Match enemy faction, `1` All loaded content, `2` Vanilla + official DLC only, `3` CUP (all), `4` CUP Takistani, `5` CUP Russian, `6` CUP ChDKZ, `7` RHS (all), `8` RHS AFRF, `9` RHS USAF, `10` RHS GREF, `11` Global Mobilization, `12` S.O.G. Prairie Fire, `13` CSLA Iron Curtain, `14` Northern Fronts CW, `15` RHS SAF.

- [ ] **Step 1: Retitle `LOOT_FACTION` and add the new parameter**

In `description.ext`, replace the whole `LOOT_FACTION` class:

```cpp
	class LOOT_FACTION
	{
		title = "Weapon, Gear & Vehicle Faction (requires DLC/mod)";
		values[] = {0, 1, 2, 3, 4, 5, 6, 7, 8};
		texts[] = {"All loaded content", "Vanilla + official DLC only", "CUP", "RHS", "Global Mobilization", "S.O.G. Prairie Fire", "CSLA Iron Curtain", "Match enemy faction", "Northern Fronts CW (enemies keep own weapons)"};
		default = 7;
	};
```

with these two classes:

```cpp
	class LOOT_FACTION
	{
		title = "Lootable Weapons & Gear - what players can find (requires DLC/mod)";
		values[] = {0, 1, 2, 3, 4, 5, 6, 7, 8};
		texts[] = {"All loaded content", "Vanilla + official DLC only", "CUP", "RHS", "Global Mobilization", "S.O.G. Prairie Fire", "CSLA Iron Curtain", "Match enemy faction", "Northern Fronts CW"};
		default = 7;
	};

	class ENEMY_GEAR_FACTION
	{
		title = "Enemy Weapons, Gear & Vehicles (requires DLC/mod)";
		values[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
		texts[] = {"Match enemy faction (default)", "All loaded content", "Vanilla + official DLC only", "CUP (all)", "CUP - Takistani", "CUP - Russian", "CUP - ChDKZ", "RHS (all)", "RHS - AFRF", "RHS - USAF", "RHS - GREF", "Global Mobilization", "S.O.G. Prairie Fire", "CSLA Iron Curtain", "Northern Fronts CW", "RHS - SAF"};
		default = 0;
	};
```

Note the `LOOT_FACTION` option 8 text loses its "(enemies keep own weapons)" suffix — after Task 1 that is true of every option.

- [ ] **Step 2: Verify the parameter parses as a balanced config class**

Run:

```bash
grep -n "class ENEMY_GEAR_FACTION" -A 7 description.ext
```

Expected: the class prints with `values[]` containing 16 entries, `texts[]` containing 16 entries, and `default = 0;`. Count them — a `values[]`/`texts[]` length mismatch makes Arma silently drop the parameter from the lobby.

- [ ] **Step 3: Commit**

```bash
git add description.ext
git commit -m "Add ENEMY_GEAR_FACTION parameter, retitle LOOT_FACTION"
```

---

### Task 3: Drive the enemy vehicle filter from `ENEMY_GEAR_FACTION`

The armoured/armed-car vehicle filter currently reads `LOOT_FACTION`. Repoint it at the new parameter and add per-faction matching. Per-faction options match the config `faction` property rather than the classname, because CUP puts the faction at the *end* of vehicle classnames (`CUP_O_T55_TKA`) where a prefix test would fail.

**Files:**
- Modify: `hostiles/lists.sqf:417-451` (the `_vehFactionParam` / `_passesVehFilter` block)

**Interfaces:**
- Consumes: `ENEMY_GEAR_FACTION` values `0`–`14` from Task 2.
- Produces: private `_gearParam` (the raw parameter value, `0` when "match enemy faction") and `_gearResolved` (the mod-level value that "match" resolved to) in the scope of `hostiles/lists.sqf`. Task 4 reads `_gearParam`, so it must remain in scope and must not be overwritten.

- [ ] **Step 1: Replace the vehicle filter block**

In `hostiles/lists.sqf`, replace everything from the line `// Vehicle faction filter - uses LOOT_FACTION parameter` down to and including the line `diag_log format ["DynBulwarks: Vehicle faction filter = %1 (filterActive = %2)", _vehFactionParam, _filterVehicles];`, with:

```sqf
// Vehicle faction filter - uses the ENEMY_GEAR_FACTION parameter.
// _gearParam is the raw lobby value and stays in scope for the unit override
// further down; _gearResolved is what "match enemy faction" resolved to.
private _gearParam = ["ENEMY_GEAR_FACTION", 0] call BIS_fnc_getParamValue;
diag_log format ["DynBulwarks: ENEMY_GEAR_FACTION parameter = %1", _gearParam];

private _gearResolved = _gearParam;
if (_gearParam == 0) then {
    // "Match enemy faction" resolves to the mod-level option for whatever
    // HOSTILE_FACTION picked. This reproduces the old LOOT_FACTION default.
    _gearResolved = switch (_factionParam) do {
        case 1: { 3 };    // CUP enemies   -> CUP (all)
        case 2: { 7 };    // RHS enemies   -> RHS (all)
        case 6: { 11 };   // GM enemies    -> Global Mobilization
        case 7: { 12 };   // SOG enemies   -> S.O.G. Prairie Fire
        case 8: { 13 };   // CSLA enemies  -> CSLA Iron Curtain
        default { 2 };    // Vanilla/Apex/Contact/Western Sahara -> vanilla + DLC
    };
    diag_log format ["DynBulwarks: ENEMY_GEAR_FACTION 'match enemy faction' resolved to %1", _gearResolved];
};

// Option 1 "All loaded content" is the only value that disables filtering.
private _filterVehicles = _gearResolved != 1;

// Mod-level classname prefix test. Used directly by the mod-level options and
// as the fallback when a per-faction config-faction match finds nothing.
private _vehPrefixFilter = switch (_gearResolved) do {
    case 2: {
        // Vanilla + official DLC: exclude known mod/CDLC prefixes
        {
            private _n = toLower _this;
            !((_n select [0,4]) == "cup_") &&
            {!((_n select [0,3]) == "rhs")} &&
            {!((_n select [0,3]) == "gm_")} &&
            {!((_n select [0,3]) == "vn_")} &&
            {!((_n select [0,5]) == "csla_")}
        }
    };
    case 3: { { (toLower _this select [0,4]) == "cup_" } };
    case 4: { { (toLower _this select [0,4]) == "cup_" } };
    case 5: { { (toLower _this select [0,4]) == "cup_" } };
    case 6: { { (toLower _this select [0,4]) == "cup_" } };
    case 7: { { (toLower _this select [0,3]) == "rhs" } };
    case 8: { { (toLower _this select [0,4]) == "rhs_" } };
    case 9: { { (toLower _this select [0,7]) == "rhsusf_" } };
    case 10: { { (toLower _this select [0,8]) == "rhsgref_" } };
    case 11: { { (toLower _this select [0,3]) == "gm_" } };
    case 12: { { (toLower _this select [0,3]) == "vn_" } };
    case 13: { { (toLower _this select [0,5]) == "csla_" } };
    // NFCW ships no armour of its own, so armour comes from RHS.
    case 14: { { (toLower _this select [0,3]) == "rhs" } };
    case 15: { { (toLower _this select [0,7]) == "rhssaf_" } };
    default { { true } };
};

// Per-faction options additionally require the vehicle's config "faction" to be
// one of these. Empty means "no faction restriction, prefix test only".
private _vehFactionNames = switch (_gearResolved) do {
    case 4: { ["cup_o_tk", "cup_o_tk_ins", "cup_o_tk_mil"] };
    case 5: { ["cup_o_ru", "cup_o_ru_air", "cup_o_rus"] };
    case 6: { ["cup_o_chdkz", "cup_o_chdkz_ins"] };
    case 8: { ["rhs_faction_msv", "rhs_faction_vdv", "rhs_faction_vmf", "rhs_faction_vv", "rhs_faction_vpvo", "rhs_faction_rva"] };
    case 9: { ["rhs_faction_usarmy_d", "rhs_faction_usarmy_wd", "rhs_faction_usmc_d", "rhs_faction_usmc_wd", "rhs_faction_socom"] };
    case 10: { ["rhsgref_faction_cdf_ground", "rhsgref_faction_chdkz", "rhsgref_faction_nationalist", "rhsgref_faction_un"] };
    case 15: { ["rhssaf_faction_army", "rhssaf_faction_airforce", "rhssaf_faction_un"] };
    default { [] };
};

// Combined test. _this is the classname string; the config lookup is done here
// so callers keep passing a classname exactly as before.
private _passesVehFilter = {
    private _cn = _this;
    private _ok = _cn call _vehPrefixFilter;
    if (_ok && {count _vehFactionNames > 0}) then {
        private _f = toLower getText (configFile >> "CfgVehicles" >> _cn >> "faction");
        _ok = _f in _vehFactionNames;
    };
    _ok
};

diag_log format ["DynBulwarks: Vehicle faction filter = %1 (filterActive = %2, factionNames = %3)", _gearResolved, _filterVehicles, _vehFactionNames];
```

- [ ] **Step 2: Add the empty-result fallback for `List_Armour`**

A per-faction filter that names a faction the loaded mod does not use would leave `List_Armour` empty and no armour would ever spawn. Immediately after the existing line:

```sqf
List_Armour = _armouredVehicles;
```

insert:

```sqf
// A per-faction filter that matches nothing must not silently remove all armour.
// Re-scan with the mod-level prefix test only.
if (count List_Armour == 0 && {count _vehFactionNames > 0}) then {
    diag_log format ["DynBulwarks: no armour matched faction names %1, falling back to the mod-level prefix filter", _vehFactionNames];
    _vehFactionNames = [];
    private _retry = [];
    for "_x" from 0 to (count _cfgVehicles - 1) do {
        private _cv = _cfgVehicles select _x;
        if (isClass _cv) then {
            private _cn = configName _cv;
            if (getText (_cv >> "vehicleClass") == "Armored" && {getNumber (_cv >> "scope") != 0} && {getText (_cv >> "simulation") != "parachute"} && {count getArray (_cv >> "artilleryAmmo") == 0} && {!_filterVehicles || {_cn call _passesVehFilter}}) then {
                _retry pushBack _cn;
            };
        };
    };
    List_Armour = _retry;
    diag_log format ["DynBulwarks: armour fallback scan found %1 classes", count List_Armour];
};
```

- [ ] **Step 3: Verify the old parameter is gone from this file**

Run:

```bash
grep -n "LOOT_FACTION\|_vehFactionParam" hostiles/lists.sqf
```

Expected: **no output.** `LOOT_FACTION` must now appear only in `loot/lists.sqf` and `description.ext`.

- [ ] **Step 4: Verify brace balance**

```bash
echo "open=$(grep -o '{' hostiles/lists.sqf | wc -l) close=$(grep -o '}' hostiles/lists.sqf | wc -l)"
```

Expected: `open` equals `close`.

- [ ] **Step 5: Commit**

```bash
git add hostiles/lists.sqf
git commit -m "Filter enemy vehicles by ENEMY_GEAR_FACTION"
```

---

### Task 4: Source enemy infantry from `ENEMY_GEAR_FACTION`

When the player picks a specific gear faction, the enemy infantry classes come from that faction's `CfgGroups` entry — which is what makes the enemies "spawn with gear from that pool" while keeping every unit's own config loadout. Left at "Match enemy faction", nothing changes and `HOSTILE_FACTION` decides as it always has.

**Files:**
- Modify: `hostiles/lists.sqf` — insert a block after the "Last resort" vanilla fallback lines (currently around line 362) and before `List_Defectors = List_NATO;`

**Interfaces:**
- Consumes: `_gearParam` and the helpers `_isFactionLoaded`, `_unitsFromFaction`, `_tryFindFaction` — all already defined earlier in the same file. `_gearParam` is defined in Task 3; because Task 3's block sits *below* this insertion point, Step 1 moves the read upward.
- Produces: possibly-overwritten `List_OPFOR`, `List_Viper`, `List_INDEP`. Does **not** touch `List_NATO` or `List_Defectors`.

- [ ] **Step 1: Move the `_gearParam` read above the unit block**

Cut these two lines from the Task 3 block:

```sqf
private _gearParam = ["ENEMY_GEAR_FACTION", 0] call BIS_fnc_getParamValue;
diag_log format ["DynBulwarks: ENEMY_GEAR_FACTION parameter = %1", _gearParam];
```

and paste them immediately after the existing line:

```sqf
diag_log format ["DynBulwarks: HOSTILE_FACTION parameter = %1", _factionParam];
```

The Task 3 block needs no other edit — `private _gearResolved = _gearParam;` reads the outer variable correctly once the declaration has moved above it.

- [ ] **Step 2: Insert the unit override block**

Immediately after this existing line in `hostiles/lists.sqf`:

```sqf
if (count List_NATO == 0)  then { diag_log "DynBulwarks: NATO list empty, using vanilla fallback";  List_NATO  = call _vanillaNATO; };
```

insert:

```sqf
// --- Enemy gear faction: unit source override ---
// When ENEMY_GEAR_FACTION names a specific faction, enemy infantry comes from
// that faction's CfgGroups entry instead of the HOSTILE_FACTION selection.
// Units keep their own config loadouts, which is what preserves role kit.
// List_NATO and List_Defectors are deliberately untouched: friendly paratroops
// stay under FRIENDLY_FACTION's control.
if (_gearParam > 2) then {
    private _gearOPFOR = [];
    private _gearViper = [];
    switch (_gearParam) do {
        case 3: {   // CUP (all)
            _gearOPFOR = ["East", "CUP_O_TK", "Infantry", ""] call _unitsFromFaction;
            _gearViper = ["East", "CUP_O_RU", "Infantry", ""] call _unitsFromFaction;
        };
        case 4: {   // CUP - Takistani
            _gearOPFOR = ["East", "CUP_O_TK", "Infantry", ""] call _unitsFromFaction;
            _gearViper = _gearOPFOR;
        };
        case 5: {   // CUP - Russian
            _gearOPFOR = ["East", "CUP_O_RU", "Infantry", ""] call _unitsFromFaction;
            _gearViper = _gearOPFOR;
        };
        case 6: {   // CUP - ChDKZ
            _gearOPFOR = ["East", "CUP_O_ChDKZ", "Infantry", ""] call _unitsFromFaction;
            _gearViper = _gearOPFOR;
        };
        case 7: {   // RHS (all)
            _gearOPFOR = ["East", "rhs_faction_msv", "rhs_group_rus_msv_infantry", ""] call _unitsFromFaction;
            _gearViper = ["East", "rhs_faction_vdv", "rhs_group_rus_vdv_infantry", ""] call _unitsFromFaction;
        };
        case 8: {   // RHS - AFRF
            _gearOPFOR = ["East", "rhs_faction_msv", "rhs_group_rus_msv_infantry", ""] call _unitsFromFaction;
            _gearViper = ["East", "rhs_faction_vdv", "rhs_group_rus_vdv_infantry", ""] call _unitsFromFaction;
        };
        case 9: {   // RHS - USAF
            _gearOPFOR = ["West", "rhs_faction_usarmy_d", "rhs_group_nato_usarmy_d_infantry", ""] call _unitsFromFaction;
            _gearViper = _gearOPFOR;
        };
        case 10: {  // RHS - GREF
            private _gref = [["East","rhsgref_faction_chdkz"],["Indep","rhsgref_faction_nationalist"],["West","rhsgref_faction_cdf_ground"]] call _tryFindFaction;
            if ((_gref select 1) != "") then {
                _gearOPFOR = [_gref select 0, _gref select 1, "Infantry", ""] call _unitsFromFaction;
                _gearViper = _gearOPFOR;
            };
        };
        case 11: {  // Global Mobilization
            private _gm = [["East","gm_gc"],["East","gm_gc_army"],["East","gm_gc_mil"]] call _tryFindFaction;
            if ((_gm select 1) != "") then {
                _gearOPFOR = [_gm select 0, _gm select 1, "Infantry", ""] call _unitsFromFaction;
                _gearViper = _gearOPFOR;
            };
        };
        case 12: {  // S.O.G. Prairie Fire
            private _pavn = [["East","vn_o_pavn"],["East","O_PAVN"],["East","vn_o_army_pavn"]] call _tryFindFaction;
            if ((_pavn select 1) != "") then {
                _gearOPFOR = [_pavn select 0, _pavn select 1, "Infantry", ""] call _unitsFromFaction;
                private _vc = [["East","vn_o_vc"],["Indep","vn_i_vc"],["East","O_VC"]] call _tryFindFaction;
                if ((_vc select 1) != "") then {
                    _gearViper = [_vc select 0, _vc select 1, "Infantry", ""] call _unitsFromFaction;
                } else {
                    _gearViper = _gearOPFOR;
                };
            };
        };
        case 13: {  // CSLA Iron Curtain
            private _csla = [["East","CSLA"],["East","csla_faction"],["East","csla"]] call _tryFindFaction;
            if ((_csla select 1) != "") then {
                _gearOPFOR = [_csla select 0, _csla select 1, "Infantry", ""] call _unitsFromFaction;
                _gearViper = _gearOPFOR;
            };
        };
        case 15: {  // RHS - SAF (Serbian Armed Forces; RHS ships them on more
                    // than one side, so try each rather than assuming East)
            private _saf = [["East","rhssaf_faction_army"],["Indep","rhssaf_faction_army"],["West","rhssaf_faction_army"],["Indep","rhssaf_faction_un"]] call _tryFindFaction;
            if ((_saf select 1) != "") then {
                _gearOPFOR = [_saf select 0, _saf select 1, "Infantry", ""] call _unitsFromFaction;
                _gearViper = _gearOPFOR;
            };
        };
        case 14: {  // Northern Fronts CW
            {
                private _pick = if (["Indep", _x] call _isFactionLoaded) then { _x } else { _x + "_W" };
                if (["Indep", _pick] call _isFactionLoaded) then {
                    private _catUnits = ["Indep", _pick, "Infantry", ""] call _unitsFromFaction;
                    { _gearOPFOR pushBackUnique _x } forEach _catUnits;
                };
            } forEach ["NFCW_80", "NFCW_88"];
            _gearViper = _gearOPFOR;
        };
    };

    if (count _gearOPFOR > 0) then {
        List_OPFOR = _gearOPFOR;
        List_Viper = if (count _gearViper > 0) then { _gearViper } else { _gearOPFOR };
        List_INDEP = List_OPFOR + List_Viper;
        diag_log format ["DynBulwarks: ENEMY_GEAR_FACTION %1 -> %2 OPFOR / %3 Viper units", _gearParam, count List_OPFOR, count List_Viper];
    } else {
        diag_log format ["DynBulwarks: ENEMY_GEAR_FACTION %1 produced no units, keeping HOSTILE_FACTION lists (OPFOR=%2)", _gearParam, count List_OPFOR];
    };
};
```

Note the guard is `_gearParam > 2`: values `0` (match), `1` (all loaded content) and `2` (vanilla + DLC) do not name a single faction, so unit selection stays with `HOSTILE_FACTION` for those and only the vehicle filter changes.

- [ ] **Step 3: Verify ordering and balance**

```bash
grep -n "_gearParam" hostiles/lists.sqf | head -3
```

Expected: the first line printed is the `private _gearParam = [...]` assignment, and it has a lower line number than the `if (_gearParam > 2) then {` line. If the assignment comes second, Step 1 was not applied and `_gearParam` will be `nil` at use.

```bash
echo "open=$(grep -o '{' hostiles/lists.sqf | wc -l) close=$(grep -o '}' hostiles/lists.sqf | wc -l)"
```

Expected: `open` equals `close`.

- [ ] **Step 4: Verify friendly-side globals are untouched**

```bash
git diff hostiles/lists.sqf | grep -E "^[-+].*(List_NATO|List_Defectors|SUPPORT_AIRCRAFT|FRIENDLY_FACTION)"
```

Expected: **no output.** If any line prints, this task has touched the FDF paratroop path, which is out of scope — revert that hunk.

- [ ] **Step 5: Commit**

```bash
git add hostiles/lists.sqf
git commit -m "Source enemy infantry from ENEMY_GEAR_FACTION when set"
```

---

### Task 5: Apply the new parameter defaults

Eight default changes in `description.ext`. `RANDOM_WEAPONS` was already flipped in Task 1.

**Files:**
- Modify: `description.ext` (eight `default =` lines)

**Interfaces:**
- Consumes: nothing.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Change the eight defaults**

Change only the `default =` line inside each named class. Do not touch `values[]` or `texts[]` — every new value already exists in its array.

| Class | Old `default` | New `default` |
|---|---|---|
| `HUD_POINT_HITMARKERS` | `1` | `0` |
| `LOOT_HOUSE_DISTRIBUTION` | `2` | `3` |
| `LOOT_ROOM_DISTRIBUTION` | `2` | `3` |
| `SAT_UNLOCK_POINTS` | `1000` | `0` |
| `MONEY_PICKUP_POINTS` | `2000` | `500` |
| `SCORE_KILL` | `100` | `50` |
| `SCORE_HIT` | `20` | `0` |
| `SCORE_DAMAGE_BASE` | `20` | `0` |

- [ ] **Step 2: Verify each new default is a legal value for its parameter**

Run:

```bash
for c in HUD_POINT_HITMARKERS LOOT_HOUSE_DISTRIBUTION LOOT_ROOM_DISTRIBUTION SAT_UNLOCK_POINTS MONEY_PICKUP_POINTS SCORE_KILL SCORE_HIT SCORE_DAMAGE_BASE RANDOM_WEAPONS; do
  echo "--- $c"; grep -A 5 "class $c$" description.ext | grep -E "values|default"
done
```

Expected, checked by eye for each block: the number on the `default =` line appears inside that block's `values[] = {...}` list. A default that is not in `values[]` makes Arma fall back to the first value silently.

- [ ] **Step 3: Confirm the diff is exactly eight lines**

```bash
git diff description.ext | grep -c "^+.*default"
```

Expected: `8`. If it is higher, something other than a default changed.

- [ ] **Step 4: Commit**

```bash
git add description.ext
git commit -m "Apply new lobby defaults for scoring and loot density"
```

---

### Task 6: Integration run on the server

Nothing above has been executed by the game. This task is the only real verification the plan has, and it must pass before Task 7.

**Files:**
- None modified. This task deploys and reads logs.

**Interfaces:**
- Consumes: the working tree from Tasks 1-5, committed.
- Produces: a pass/fail judgement gating the release.

- [ ] **Step 1: Push and deploy**

```bash
git push origin master
```

Then deploy to the server: `ssh Administrator@192.168.68.50` and run the `Arma3MissionsPull` scheduled task, which bounces the server and hard-resets all five mission clones. RPT logs live on that machine, not locally.

- [ ] **Step 2: Run with the default parameters and read the RPT**

Start a mission with every parameter left at its default. In the newest RPT, confirm these lines appear and that no count is zero:

```
DynBulwarks: HOSTILE_FACTION parameter = 7
DynBulwarks: ENEMY_GEAR_FACTION parameter = 0
DynBulwarks: ENEMY_GEAR_FACTION 'match enemy faction' resolved to 12
DynBulwarks: Vehicle faction filter = 12 (filterActive = true, factionNames = [])
DynBulwarks: List_Armour=[...]
DynBulwarks: Loot faction filter = 5 (filterActive = true)
```

Expected: `List_Armour` is a non-empty array of `vn_*` classes, and no `ENEMY_GEAR_FACTION ... produced no units` line appears (with the parameter at 0, the unit override must not run at all).

- [ ] **Step 3: Check enemy loadouts in-game**

Spawn a wave and inspect two or three dead enemies. Expected: an AT soldier carries a launcher **and** a rifle, a machinegunner carries an MG, and no unit carries a weapon from a different mod than its uniform. This is the requirement the whole rework exists to satisfy — if it fails, stop and fix Task 1 before releasing.

- [ ] **Step 4: Sample the new gear-faction options**

Restart the mission three more times, setting `ENEMY_GEAR_FACTION` to **CUP - Takistani** (4), **RHS - AFRF** (8), and **Northern Fronts CW** (14). For each, confirm in the RPT:

```
DynBulwarks: ENEMY_GEAR_FACTION <n> -> <x> OPFOR / <y> Viper units
```

Expected: `<x>` and `<y>` are both greater than zero, and no `produced no units` line appears. A `falling back to the mod-level prefix filter` line is not fatal — it means one of the faction-name guesses in Task 3's `_vehFactionNames` is wrong for the installed mod version. If you see one, note the faction the RPT reports for a sample vehicle and correct that list before releasing.

- [ ] **Step 5: Confirm the loot pool is independent**

Set `LOOT_FACTION` to **Northern Fronts CW** (8) while leaving `ENEMY_GEAR_FACTION` at **RHS - AFRF** (8). Expected: loot found in buildings is NFCW gear, enemies are RHS AFRF units with RHS weapons. That combination was impossible before this rework and is the clearest proof the split works.

- [ ] **Step 6: Record the result**

If any step failed, stop and fix it under the task that owns it. Do not proceed to Task 7 on a partial pass.

---

### Task 7: Cut the v1.1.0 release

**Files:**
- Create: `docs/CHANGELOG.md`
- Modify: `description.ext` (version in `overviewText`)

**Interfaces:**
- Consumes: a passing Task 6.
- Produces: git tags `v1.1.0` and `bulwark-fdk-2026.08.18`, a GitHub release, and a player zip.

- [ ] **Step 1: Stamp the version in the mission overview**

In `description.ext`, change:

```cpp
overviewText = "Survive by scavenging equipment, in a randomly selected city, against ever increasing waves of hostiles.";
```

to:

```cpp
overviewText = "Survive by scavenging equipment, in a randomly selected city, against ever increasing waves of hostiles. [v1.1.0]";
```

- [ ] **Step 2: Write the changelog**

Create `docs/CHANGELOG.md`:

```markdown
# Changelog

## v1.1.0 — 2026-08-18

### Lobby parameters

- **"Weapon, Gear & Vehicle Faction" is now "Lootable Weapons & Gear."** It
  controls only what players can find in the world.
- **New: "Enemy Weapons, Gear & Vehicles."** Sets which faction the enemy
  infantry and vehicles come from, independently of the loot pool. Includes
  per-faction options for CUP (Takistani, Russian, ChDKZ) and RHS (AFRF, USAF,
  GREF). Defaults to "Match enemy faction", which behaves exactly as before.
- "Friendly Faction" is unchanged — it still controls the FDF paratroops and
  the C-160 supply aircraft.

### Enemy loadouts

- **Enemies now keep their default loadouts.** They are no longer re-armed from
  the loot pool, so an AT soldier keeps his launcher and a machinegunner keeps
  his MG. "Randomize Hostile Weapons" now defaults to No for the same reason;
  set it to Yes to get the old mixed-weapons behaviour back.

### New defaults

| Setting | Was | Now |
|---|---|---|
| Point hitmarkers on HUD | Yes | No |
| Loot distribution | Every second building | Every third building |
| Loot density | Every second location | Every third location |
| Points for finding satellite dish | 1000 | 0 |
| Points for the Collect Points pickup | 2000 | 500 |
| Points per kill | 100 | 50 |
| Points per hit | 20 | 0 |
| Damage bonus points | 20 | 0 |
| Randomize hostile weapons | Yes | No |

**Note on the economy:** these defaults cut point income to roughly a quarter of
what it was, while support prices are unchanged. Supports will take noticeably
longer to afford. If that proves too tight in play, either raise the scoring
parameters in the lobby or ask for a pass over the support prices.

### Known limits

- The lootable-gear pool stays at mod granularity (CUP, RHS, ...) rather than
  per-faction. Loose weapons carry no faction tag in their config, so there is
  nothing to filter them by.
- With a specific enemy gear faction selected, "Enemy Faction" no longer decides
  which infantry spawn; it continues to control enemy air and artillery assets.
```

- [ ] **Step 3: Fetch before pushing**

The remote `spec1alsm1th/DynamicBulwarksPotato` is shared with another contributor who also pushes to `master`. Run:

```bash
git fetch origin && git log origin/master --oneline -5
```

If anything arrived since Task 6, read the actual diffs rather than trusting the commit titles, and rebase onto them before tagging.

- [ ] **Step 4: Commit and tag**

```bash
git add description.ext docs/CHANGELOG.md
git commit -m "Release v1.1.0: split loot and enemy gear faction pools"
git tag -a v1.1.0 -m "v1.1.0 - loot/enemy gear pool split, native enemy loadouts, new defaults"
git tag -a bulwark-fdk-2026.08.18 -m "v1.1.0"
git push origin master --tags
```

- [ ] **Step 5: Build the player zip**

Build it from the tag rather than the working tree so no stray files ship:

```bash
git archive --format=zip --prefix=DynamicBulwarksFDFK.Cam_Lao_Nam/ -o /c/Users/samuli/AppData/Local/Temp/DynamicBulwarksFDFK-v1.1.0.zip v1.1.0
```

- [ ] **Step 6: Create the GitHub release**

```bash
gh release create v1.1.0 \
  --title "v1.1.0 - Loot and enemy gear pools split" \
  --notes-file docs/CHANGELOG.md \
  /c/Users/samuli/AppData/Local/Temp/DynamicBulwarksFDFK-v1.1.0.zip
```

- [ ] **Step 7: Verify the release exists**

```bash
gh release view v1.1.0
```

Expected: the release prints with the changelog body and one zip asset attached.

---

### Task 8: Add the Livonia (Enoch) mission copy

The mission is terrain-agnostic: `locationLists.sqf` derives cities from `nearestLocations` at runtime, and the bulwark position comes from the host clicking the map (`pickBulwarkPos.sqf`, via `BULWARK_LOCATIONS = List_SpecificPoint` in `editMe.sqf:28`). `mission.sqm` declares no terrain in `addons[]` — the map comes solely from the folder suffix. The stale `bulwark_zone_*` markers feed the unused `List_LocationMarkers` path and already ride along harmlessly on the Altis/Tanoa/Malden clones, so they need no cleanup.

**Files:**
- None in this repo. This task is server-side only.

**Interfaces:**
- Consumes: the repo at `origin/master`.
- Produces: a sixth clone, `S:\arma3server\mpmissions\DynamicBulwarksFDFK.Enoch`, kept in sync by Task 9's script.

- [ ] **Step 1: Clone the repo into the Enoch folder**

```bash
ssh Administrator@192.168.68.50 "git clone https://github.com/spec1alsm1th/DynamicBulwarksPotato.git S:\arma3server\mpmissions\DynamicBulwarksFDFK.Enoch"
```

- [ ] **Step 2: Verify the clone landed and matches the others**

```bash
ssh Administrator@192.168.68.50 "dir /b S:\arma3server\mpmissions | findstr DynamicBulwarksFDFK"
```

Expected: six entries, including `DynamicBulwarksFDFK.Enoch`. Then confirm it holds a real mission:

```bash
ssh Administrator@192.168.68.50 "dir /b S:\arma3server\mpmissions\DynamicBulwarksFDFK.Enoch\mission.sqm S:\arma3server\mpmissions\DynamicBulwarksFDFK.Enoch\description.ext"
```

Expected: both filenames print.

- [ ] **Step 3: Add Enoch to the nightly update loop**

This is done as part of Task 9's rewrite — the terrain list there must read `Cam_Lao_Nam, Altis, Stratis, Tanoa, Malden, Enoch`. If Task 9 is skipped, add `Enoch` to the existing `for %%m in (...)` list in `S:\arma3server\nightly_update.bat` instead.

- [ ] **Step 4: Confirm it appears in mission selection**

Restart the server and open the admin mission list. Expected: `DynamicBulwarksFDFK` appears under Livonia. Note that Livonia is Contact DLC terrain — players without Contact cannot join this copy. Tanoa already sets that precedent with Apex.

---

### Task 9: Versioned mission folder names

Goal: make the running version obvious both on disk and in the lobby. The current `nightly_update.bat` hardcodes `DynamicBulwarksFDFK.%%m`, so a versioned folder name requires discovering the folder rather than naming it. The batch `for` loop is replaced by a PowerShell script; the Steam update and restart logic in the `.bat` are left untouched.

`server.cfg` has no mission rotation entries, so renaming mission folders breaks nothing.

**Files:**
- Create: `VERSION` (in this repo)
- Modify: `description.ext` (`onLoadName`), `mission.sqm` (`briefingName`)
- Create on server: `S:\arma3server\update_missions.ps1`
- Modify on server: `S:\arma3server\nightly_update.bat`

**Interfaces:**
- Consumes: nothing from earlier tasks. Task 7 must set `VERSION` to the released version before the release is cut.
- Produces: mission folders named `DynamicBulwarksFDFK_<sanitised VERSION>.<terrain>`.

- [ ] **Step 1: Add the VERSION file to the repo**

Create `VERSION` containing exactly one line:

```
v1_1_0_20260818
```

Underscores only, no dots or hyphens: Arma splits a mission folder name on its **last** dot to find the terrain, and a name with stray punctuation is the kind of thing that fails quietly in the server browser. The PowerShell script sanitises anyway, but keeping the file clean means the folder name is predictable by eye.

- [ ] **Step 2: Stamp the version into the lobby display name**

In `description.ext`, change:

```cpp
onLoadName = "dynamicBulwarks";
```

to:

```cpp
onLoadName = "dynamicBulwarks v1.1.0";
```

and in `mission.sqm`, change:

```cpp
briefingName="Dynamic Bulwarks - FDFk Edition (Original by Omnios & Hilltop)";
```

to:

```cpp
briefingName="Dynamic Bulwarks - FDFk Edition v1.1.0 (Original by Omnios & Hilltop)";
```

This half is independent of the server script — even if the rename is reverted, the version stays visible once the mission loads.

- [ ] **Step 3: Write the PowerShell updater on the server**

Create `S:\arma3server\update_missions.ps1`:

```powershell
# Pulls each DynamicBulwarksFDFK mission clone and renames its folder to match
# the VERSION file in the repo. Called from nightly_update.bat.
$ErrorActionPreference = 'Continue'
$git      = 'C:\Program Files\Git\cmd\git.exe'
$missions = 'S:\arma3server\mpmissions'
$log      = 'S:\arma3server\logs\nightly_update.log'
$terrains = @('Cam_Lao_Nam','Altis','Stratis','Tanoa','Malden','Enoch')

function Write-Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    Add-Content -Path $log -Value $line -Encoding utf8
}

foreach ($t in $terrains) {
    # Match both the legacy name and any previously versioned name.
    $dir = Get-ChildItem -Path $missions -Directory -Filter "DynamicBulwarksFDFK*.$t" |
           Select-Object -First 1
    if ($null -eq $dir) { Write-Log "No mission folder found for terrain $t - skipping"; continue }

    Write-Log "Updating $($dir.Name)"
    & $git -C $dir.FullName fetch origin --prune | ForEach-Object { Write-Log $_ }
    & $git -C $dir.FullName reset --hard origin/master | ForEach-Object { Write-Log $_ }

    $versionFile = Join-Path $dir.FullName 'VERSION'
    if (-not (Test-Path $versionFile)) { Write-Log "No VERSION file in $($dir.Name) - leaving name unchanged"; continue }

    # Sanitise: Arma splits the folder name on its last dot to find the terrain,
    # so anything but letters, digits and underscores is replaced.
    $version = (Get-Content $versionFile -TotalCount 1).Trim() -replace '[^A-Za-z0-9_]', '_'
    if ([string]::IsNullOrWhiteSpace($version)) { Write-Log "VERSION in $($dir.Name) is empty - leaving name unchanged"; continue }

    $wanted = "DynamicBulwarksFDFK_$version.$t"
    if ($dir.Name -eq $wanted) { Write-Log "$($dir.Name) already correctly named"; continue }

    $target = Join-Path $missions $wanted
    if (Test-Path $target) { Write-Log "Cannot rename $($dir.Name): $wanted already exists"; continue }

    try {
        Rename-Item -Path $dir.FullName -NewName $wanted -ErrorAction Stop
        Write-Log "Renamed $($dir.Name) -> $wanted"
    } catch {
        Write-Log "Rename of $($dir.Name) failed: $_"
    }
}
```

Two notes for whoever edits this later. The `Get-ChildItem ... -Filter "DynamicBulwarksFDFK*.$t"` glob is what lets the script find a folder it renamed on a previous night — this is the whole reason the batch loop could not do the job. And native `git` stderr is deliberately **not** redirected with `2>&1`: in Windows PowerShell 5.1 that wraps each stderr line in an ErrorRecord and makes a successful `git` look like a failure.

- [ ] **Step 4: Back up and rewire `nightly_update.bat`**

```bash
ssh Administrator@192.168.68.50 "copy S:\arma3server\nightly_update.bat S:\arma3server\nightly_update.bat.bak-preversioning"
```

Then in `S:\arma3server\nightly_update.bat`, replace this block:

```bat
REM --- Reset and pull each mission to origin/master ---
for %%m in (Cam_Lao_Nam Altis Stratis Tanoa Malden) do (
    echo [%DATE% %TIME%] Updating mission %%m >> "%LOG%"
    %GIT% -C "%MISSIONS%\DynamicBulwarksFDFK.%%m" fetch origin --prune >> "%LOG%" 2>&1
    %GIT% -C "%MISSIONS%\DynamicBulwarksFDFK.%%m" reset --hard origin/master >> "%LOG%" 2>&1
)
```

with:

```bat
REM --- Reset, pull and version-rename each mission clone ---
echo [%DATE% %TIME%] Running update_missions.ps1 >> "%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -File S:\arma3server\update_missions.ps1 >> "%LOG%" 2>&1
```

Leave the `taskkill`, steamcmd, buildid and restart sections exactly as they are.

- [ ] **Step 5: Dry-run the script before trusting the nightly job**

Run it by hand while the server is stopped:

```bash
ssh Administrator@192.168.68.50 "powershell -NoProfile -ExecutionPolicy Bypass -File S:\arma3server\update_missions.ps1"
ssh Administrator@192.168.68.50 "dir /b S:\arma3server\mpmissions | findstr DynamicBulwarksFDFK"
```

Expected: six folders, each named `DynamicBulwarksFDFK_v1_1_0_20260818.<terrain>`. Then check the log:

```bash
ssh Administrator@192.168.68.50 "powershell -NoProfile -Command \"Get-Content S:\arma3server\logs\nightly_update.log -Tail 40\""
```

Expected: one `Renamed ... -> ...` line per terrain, and no `Cannot rename` or `failed` lines.

- [ ] **Step 6: Verify the renamed missions still load**

Restart the server and open the admin mission list. Expected: six `DynamicBulwarksFDFK_v1_1_0_20260818` entries, one per terrain, and the loaded mission shows `dynamicBulwarks v1.1.0`. A renamed folder that does not appear means the name still contains a character Arma rejects — check the sanitiser output in the log.

- [ ] **Step 7: Commit the repo-side half**

```bash
git add VERSION description.ext mission.sqm
git commit -m "Add VERSION file and stamp the version into the lobby name"
```

---

### Task 10: Install CUP on the server

Keimo's per-faction CUP options (values 4, 5, 6) do nothing until CUP is installed — the server's `-mod=` line currently carries `vn`, `cba_a3`, `rhsafrf`, `rhsusaf`, `rhsgref`, `rhssaf`, `northern_fronts_cw`, `military_aviation` and QoL mods, with no CUP at all. The mission handles this correctly (the faction is not found, it logs and falls back), so this is not a blocker for the release — but the options stay inert without it.

**Blocked on a manual step:** only CUP *Terrains* is downloaded on the local machine. CUP Weapons (`497660133`), Units (`497661914`) and Vehicles (`541888371`) must be subscribed to in the Steam Workshop and downloaded to `F:\SteamLibrary` before this task can run. `sync_mods_to_server.bat` already lists them and skips any that are missing.

**Files:**
- Already modified: `C:\Users\samuli\Documents\claudeadmin\sync_mods_to_server.bat` (backup at `.bak`)
- Modify on server: `S:\arma3server\start_arma3.bat`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: working CUP options for `ENEMY_GEAR_FACTION` values 3-6 and `LOOT_FACTION` value 2.

- [ ] **Step 1: Confirm the CUP mods are downloaded locally**

```bash
ls /f/SteamLibrary/steamapps/workshop/content/107410/ | grep -E "^(583496184|497660133|497661914|541888371)$"
```

Expected: all four IDs print. If any are missing, stop — subscribe in Steam and wait for the download. Running the sync early is harmless (it skips them) but pointless.

- [ ] **Step 2: Sync them to the server**

Run `C:\Users\samuli\Documents\claudeadmin\sync_mods_to_server.bat`. Expected: four `Syncing ...` lines for the CUP IDs and no `[SKIP]` lines for them.

- [ ] **Step 3: Create the junctions**

Every `@mod` folder on this server is a junction into the workshop content directory — match that pattern rather than copying:

```bash
ssh Administrator@192.168.68.50 "mklink /J S:\arma3server\@cup_terrains_core S:\steamcmd\steamapps\workshop\content\107410\583496184"
ssh Administrator@192.168.68.50 "mklink /J S:\arma3server\@cup_weapons S:\steamcmd\steamapps\workshop\content\107410\497660133"
ssh Administrator@192.168.68.50 "mklink /J S:\arma3server\@cup_units S:\steamcmd\steamapps\workshop\content\107410\497661914"
ssh Administrator@192.168.68.50 "mklink /J S:\arma3server\@cup_vehicles S:\steamcmd\steamapps\workshop\content\107410\541888371"
```

- [ ] **Step 4: Add them to the launch line**

Back up first:

```bash
ssh Administrator@192.168.68.50 "copy S:\arma3server\start_arma3.bat S:\arma3server\start_arma3.bat.bak-precup"
```

Then append to the `-mod=` list in `S:\arma3server\start_arma3.bat`:

```
;@cup_terrains_core;@cup_weapons;@cup_units;@cup_vehicles
```

Load order matters: `@cup_terrains_core` must come before the other three. Everything already on the line stays in its current order.

- [ ] **Step 5: Verify CUP loaded**

Restart the server and start a mission with `ENEMY_GEAR_FACTION` = **CUP - Takistani** (4). Expected in the RPT:

```
DynBulwarks: ENEMY_GEAR_FACTION 4 -> <x> OPFOR / <y> Viper units
```

with `<x>` greater than zero and no `produced no units` line. Also confirm `List_Armour` is a non-empty list of `CUP_*` classes.

- [ ] **Step 6: Tell players**

Clients need the same four CUP mods to join once they are on the server's `-mod=` line. Announce the mod list change before the next session, or players will be unable to connect.
