# Changelog

## v1.1.1 — 2026-08-18

Bug fixes found by auditing the server RPT logs. No behaviour changes to
anything that was already working.

### Loot pools could end up empty

`loot/lists.sqf` fell back to an unfiltered scan when a loot faction produced
no backpacks or no explosives, but not when it produced no **weapons** or
**apparel**. Selecting a loot faction whose mod is not installed left those
pools empty, and `selectRandom` on an empty array returns nil — so every loot
spawn in every building threw. The 2026-08-14 log carried 444
`Undefined variable: _weapon` and 217 `_clothes` errors from
`loot/spawnLoot.sqf` for exactly this reason. Both pools now fall back the
same way backpacks and explosives already did.

### Faction lookups used classnames that do not exist

Verified against the installed mod configs by extracting them from the PBOs:

- **CUP Takistani army has no `CfgGroups` entry at all**, so the old
  `CUP_O_TK` test failed and every CUP game silently dropped to the
  CfgVehicles prefix scan. Now tries `CUP_O_TK`, then `CUP_O_TK_MILITIA`,
  then `CUP_O_TK_INS`.
- **CUP US faction is `CUP_B_US_Army`**, not `CUP_B_US`.
- **RHS SAF east faction is `rhssaf_faction_army_opfor`**;
  `rhssaf_faction_army` is Independent and `rhssaf_faction_airforce` does not
  exist at all.
- `ENEMY_GEAR_FACTION` now falls back to the same CfgVehicles prefix scan
  `HOSTILE_FACTION` uses, so a wrong or changed faction name degrades to a
  working unit list instead of the parameter silently doing nothing. This
  matters most for S.O.G., whose `CfgGroups` names still cannot be verified —
  the mod ships encrypted `.ebo` files that no tool can read.

### Not changed

The `"SOG Prairie Fire CfgGroups not found"` line will still appear in the
RPT on every start. It is harmless: the prefix scan behind it has been
producing correct PAVN/VC units all along.

## v1.1.0 — 2026-08-18

### Lobby parameters

- **"Weapon, Gear & Vehicle Faction" is now "Lootable Weapons & Gear."** It
  controls only what players can find in the world.
- **New: "Enemy Weapons, Gear & Vehicles."** Sets which faction the enemy
  infantry and vehicles come from, independently of the loot pool. Includes
  per-faction options for CUP (Takistani, Russian, ChDKZ) and RHS (AFRF, USAF,
  GREF, SAF). Defaults to "Match enemy faction", which behaves exactly as
  before.
- "Friendly Faction" is unchanged — it still controls the FDF paratroops and
  the C-160 supply aircraft.

### Enemy loadouts

- **Enemies now keep their default loadouts.** They are no longer re-armed from
  the loot pool, so an AT soldier keeps his launcher and a machinegunner keeps
  his MG. "Randomize Hostile Weapons" now defaults to No for the same reason;
  set it to Yes to get the old mixed-weapons behaviour back. Note that random
  weapons are drawn from the *loot* pool, not the enemy gear pool.

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

### Server

- Livonia (Enoch) copy added alongside Cam Lao Nam, Altis, Stratis, Tanoa and
  Malden. Livonia is Contact DLC terrain — players without Contact cannot join
  that copy.
- Mission folders on the server are now named after the release
  (`DynamicBulwarksFDFK_v1_1_0_20260818.<terrain>`), and the version shows in
  the lobby as `dynamicBulwarks v1.1.0`.
- CUP (Terrains Core, Weapons, Units, Vehicles) added to the server mod set so
  the CUP faction options work. **Clients need these mods to connect.**

### Known limits

- The lootable-gear pool stays at mod granularity (CUP, RHS, ...) rather than
  per-faction. Loose weapons carry no faction tag in their config, so there is
  nothing to filter them by.
- With a specific enemy gear faction selected, "Enemy Faction" no longer decides
  which infantry spawn; it continues to control enemy air and artillery assets.
