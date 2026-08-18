# Faction Parameter Rework — Design

Date: 2026-08-18
Status: approved (pending spec review)

## Goal

Split the overloaded `LOOT_FACTION` parameter into two independent pools —
world loot and enemy equipment — give the enemy pool per-faction granularity
for CUP and RHS, guarantee enemies keep their native role loadouts, and apply
a set of new scoring/loot defaults. Ship as a versioned GitHub release.

## Current behaviour

- `HOSTILE_FACTION` — selects enemy unit classes (`List_OPFOR`, `List_Viper`,
  `List_INDEP`, `List_NATO`, `List_Bandits`) in `hostiles/lists.sqf`; also
  drives enemy airstrike / rocket strike / helicopter classes and the player
  support vehicle classes.
- `FRIENDLY_FACTION` — overrides `List_NATO` (friendly paratroops) and
  `SUPPORT_AIRCRAFT` (C-160 Transall). Sole non-default option: Northern
  Fronts Cold War (FDF).
- `LOOT_FACTION` — does three jobs: filters the world loot config scan
  (`loot/lists.sqf`), filters the enemy armoured vehicle pool
  (`hostiles/lists.sqf`), and enables `LOOT_REARM_ENEMIES`, which strips each
  spawned enemy's primary weapon and replaces it with a random weapon from the
  loot pool.

## Decisions

1. `FRIENDLY_FACTION` is **kept**. It is not a loot parameter; removing it
   would delete the FDF paratroops and the C-160 supply aircraft.
2. The enemy pool selects **unit classes and vehicles**, never re-arms.
   Native config loadouts are therefore preserved by construction.
3. Enemy re-arming from the loot pool is **removed entirely**, and
   `RANDOM_WEAPONS` defaults to No, since it randomises primaries independently.
4. Per-faction granularity is provided for enemy units/vehicles only. Loose
   weapons and gear carry no faction tag in config, so the loot pool stays at
   mod granularity.
5. Release tagged with semver (`v1.1.0`) in addition to the existing
   `bulwark-fdk-<date>` scheme.
6. Support prices are left unchanged; the income reduction is documented in
   the release notes for playtest judgement.

## Parameters

### `LOOT_FACTION` — retitled "Lootable Weapons & Gear (requires DLC/mod)"

Values unchanged (0–8: All loaded content, Vanilla + official DLC only, CUP,
RHS, Global Mobilization, S.O.G. Prairie Fire, CSLA Iron Curtain, Match enemy
faction, Northern Fronts CW). Scope narrows to the world-loot scan only. The
"(enemies keep own weapons)" suffix on option 8 is dropped — enemies keep their
own weapons under every option now.

### `ENEMY_GEAR_FACTION` — new, "Enemy Weapons, Gear & Vehicles (requires DLC/mod)"

| Value | Text |
|---|---|
| 0 | Match enemy faction (default) |
| 1 | All loaded content |
| 2 | Vanilla + official DLC only |
| 3 | CUP — Takistani |
| 4 | CUP — Russian |
| 5 | CUP — ChDKZ |
| 6 | RHS — AFRF |
| 7 | RHS — USAF |
| 8 | RHS — GREF |
| 9 | Global Mobilization |
| 10 | S.O.G. Prairie Fire |
| 11 | CSLA Iron Curtain |
| 12 | Northern Fronts CW |

Effects:

- **Vehicles** — replaces `LOOT_FACTION` as the source of the armoured vehicle
  classname filter in `hostiles/lists.sqf`. Per-faction options filter on the
  faction-encoded prefixes: `cup_o_tk_`, `cup_o_ru_`, `cup_o_chdkz_`, `rhs_`
  (AFRF), `rhsusf_`, `rhsgref_`.
- **Units** — when set to anything other than 0, rebuilds `List_OPFOR` /
  `List_Viper` / `List_INDEP` from that faction's `CfgGroups` entry using the
  existing `_unitsFromFaction` and `_isFactionLoaded` helpers, overriding what
  `HOSTILE_FACTION` selected. `List_NATO` and `List_Defectors` are untouched.
- Every override falls back to the `HOSTILE_FACTION` result with a `diag_log`
  line if the faction is not loaded or yields no units.

Known overlap, accepted deliberately: with a specific enemy gear faction set,
`HOSTILE_FACTION` no longer determines which infantry spawn — it continues to
drive enemy air/artillery assets. Left at the default the two do not interact.

## Code changes

- `loot/lists.sqf` — remove `LOOT_REARM_ENEMIES`; keep the loot filter.
- `hostiles/lists.sqf` — read `ENEMY_GEAR_FACTION` for the vehicle filter, add
  the per-faction prefix cases, add the unit-pool override block after the
  existing faction switch and before the bandit replacement.
- `hostiles/spawnInfantry.sqf`, `hostiles/spawnSquad.sqf`,
  `hostiles/airborneWave.sqf`, `hostiles/specSwticharooWave.sqf` — delete the
  `LOOT_REARM_ENEMIES` re-arm blocks and their `LOOT_FACTION` reads.
- `description.ext` — parameter titles, the new parameter, and the defaults
  below.

## Default changes

| Parameter | Old | New |
|---|---|---|
| `HUD_POINT_HITMARKERS` | 1 (Yes) | 0 (No) |
| `LOOT_HOUSE_DISTRIBUTION` | 2 | 3 (Every third building) |
| `LOOT_ROOM_DISTRIBUTION` | 2 | 3 (Every third location) |
| `SAT_UNLOCK_POINTS` | 1000 | 0 |
| `MONEY_PICKUP_POINTS` | 2000 | 500 |
| `SCORE_KILL` | 100 | 50 |
| `SCORE_HIT` | 20 | 0 |
| `SCORE_DAMAGE_BASE` | 20 | 0 |
| `RANDOM_WEAPONS` | 1 (Yes) | 0 (No) |

All new values already exist in their `values[]` arrays.

## Verification

No automated test harness exists for an Arma 3 mission. Verification is:

1. Config review of every touched file for SQF syntax and dangling references
   to `LOOT_REARM_ENEMIES` / `LOOT_FACTION`.
2. Deploy to the server at 192.168.68.50 and check the RPT for the pool-size
   `diag_log` lines under a representative sample of the new options
   (Match enemy faction, CUP Takistani, RHS AFRF, Northern Fronts CW).
3. Player-facing playtest before the release is announced.

## Out of scope

- Rebalancing `BULWARK_SUPPORTITEMS` prices against the reduced income.
- Per-faction granularity for the world loot pool.
