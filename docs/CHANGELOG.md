# Changelog

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
