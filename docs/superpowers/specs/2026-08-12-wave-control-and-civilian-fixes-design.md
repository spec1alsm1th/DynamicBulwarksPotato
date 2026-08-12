# Wave Control and Civilian Fixes — Design

Date: 2026-08-12
Mission: `DynamicBulwarksFDFK.Cam_Lao_Nam`

Four independent changes requested after play testing. Each can be applied
and reverted on its own.

## 1. New wave types default to disabled

**Problem.** The six wave types added most recently ship enabled, so a fresh
server picks them up without anyone opting in.

**Change.** In `description.ext`, set `default = 0` on `HOSTAGE_WAVE`,
`AIRBORNE_WAVE`, `BOMB_WAVE`, `JAMMER_WAVE`, `VIP_WAVE`, and
`AMMO_HEIST_WAVE`.

No script change is needed. `bulwark/functions/fn_startWave.sqf` already
gates each type on its parameter when building `_wavePool`; a disabled type
simply never enters the pool.

`SPECIAL_WAVES` stays at `default = 1`. The older types (specCivs, fogWave,
swticharooWave, suicideWave, specMortarWave, demineWave, defectorWave) are
not affected.

## 2. Remove the wave-cutoff staleness failsafes

**Problem.** Commit `4025f83` added two timers that force-kill every
remaining EAST unit when the EAST count has not dropped for a while. They
were meant to unstick enemies clipped underground, but in practice they end
waves early.

**Change.** Remove both.

- `missionLoop.sqf` — drop the `_lastEastCount` / `_staleTimer` declarations
  and the tracking block inside the wave loop.
- `bulwark/functions/fn_startWave.sqf` — drop the equivalent block inside
  the switcheroo-wave loop.

Everything else in those loops is untouched: the `sleep 1` pacing, the
all-hostiles-dead exit, the all-players-down failure check, and the Zeus
curator registration all remain.

**Accepted consequence.** An enemy that becomes unreachable now stalls the
wave indefinitely. Change 3 is the manual remedy.

## 3. "Force Next Wave" in the bulwark menu

The free `skipWave` support already exists and already ends an active wave.
It is renamed and extended to also cut the build phase short, so one menu
entry covers both "this wave is stuck" and "we are done building".

- `editMe.sqf` — rename the `BULWARK_SUPPORTITEMS` entry to
  `"Force Next Wave"`. The dispatch key stays `skipWave`, so
  `score/functions/fn_support.sqf`, `supports/functions.hpp`, and
  `supports/CommunicationMenu.h` need no edits.
- `supports/functions/fn_skipWave.sqf` — replace the build-phase early exit
  with a branch:
  - Active wave: current behaviour (kill remaining EAST infantry, destroy
    remaining EAST vehicles and their crews).
  - Build phase: set `BULWARK_FORCE_NEXT_WAVE = true` and notify players.
- `bulwark/functions/fn_endWave.sqf` — replace `sleep _downTime` with a
  one-second-tick loop that also exits on `BULWARK_FORCE_NEXT_WAVE`. The
  flag is cleared immediately before the loop so a force from a previous
  round cannot leak into this one.

`fn_skipWave` and `fn_endWave` both run on the server
(`killPoints_fnc_support` dispatches with `remoteExec` target 2), so a plain
global variable is sufficient — no `publicVariable`.

## 4. Vietnam-era unarmed civilians only

**Problem.** `hostiles/CivWave.sqf` builds its spawn pool by scanning all of
`CfgVehicles` for `isMan != 0 && side == 3`. On Cam Lao Nam that admits every
modern Arma 3 civilian, every mod-added civilian, armed civilians, and
non-public base classes.

**Change.** Tighten the accept condition inside the existing scan loop:

1. `getNumber (_config >> "scope") == 2` — public classes only.
2. `getArray (_config >> "weapons") - ["Throw", "Put"]` must be empty —
   drops armed civilians from any source.
3. When `HOSTILE_FACTION == 7` (SOG PF), require the classname to begin with
   `vn_c_`. Other faction settings keep the unrestricted pool.

The faction check follows the switch pattern already used in `editMe.sqf`,
`hostiles/lists.sqf`, and the support functions.

**Fallback.** If the filtered pool comes out empty, log a warning and fall
back to the unfiltered civilian list rather than to `["C_man_1"]`. A SOG
naming change then degrades to wrong-era civilians instead of twenty
identical modern men.

## Out of scope

Removing ACRE is a server mod-load change on the host at 192.168.68.50. It
is not part of this mission folder and is not covered here.
