/**
*  fn_skipWave
*
*  "Force Next Wave" — free support, no cost, available to all players.
*
*  During an active wave: kills all remaining EAST units and vehicles so the
*  wave ends immediately.
*  During the build phase: cuts the DOWN_TIME countdown short so the next
*  wave starts immediately (see fn_endWave).
*
*  Domain: Server
**/

params ["_player"];

private _playerName = name _player;

// Build phase — cut the remaining build time short instead of killing units
if (bulwarkBox getVariable ["buildPhase", false]) exitWith {
    diag_log format ["DynBulwarks: forceNextWave (build phase) triggered by %1", _playerName];
    BULWARK_FORCE_NEXT_WAVE = true;
    ["SpecialWarning", [format ["%1 called in the next wave early!", _playerName]]] remoteExec ["BIS_fnc_showNotification", 0];
};

diag_log format ["DynBulwarks: forceNextWave (active wave) triggered by %1", _playerName];

["SpecialWarning", [format ["%1 called in a wave skip!", _playerName]]] remoteExec ["BIS_fnc_showNotification", 0];

// Signal fn_startWave to skip the rest of the wave (createWave spawn, loot, etc.)
BULWARK_WAVE_SKIPPED = true;

// Kill all remaining EAST infantry (allUnits = alive soldiers only)
{ if (side _x == east && alive _x) then { _x setDamage 1; }; } forEach allUnits;

// Destroy any remaining EAST vehicles (tanks, cars, helis spawned with EAST crew)
{
    if (alive _x && side _x == east) then {
        { if (alive _x) then { _x setDamage 1; }; } forEach crew _x;
        _x setDamage 1;
    };
} forEach (allMissionObjects "LandVehicle" + allMissionObjects "Air" + allMissionObjects "Ship");
