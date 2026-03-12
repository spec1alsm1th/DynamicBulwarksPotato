/**
*  fn_skipWave
*
*  Kills all remaining EAST units and vehicles, ending the current wave
*  immediately. Free support — no cost — available to all players.
*
*  Domain: Server
**/

params ["_player"];

// Only valid during an active wave
if (bulwarkBox getVariable ["buildPhase", false]) exitWith {
    ["Wave is not active — nothing to skip."] remoteExec ["hint", _player];
};

private _playerName = name _player;
diag_log format ["DynBulwarks: skipWave triggered by %1", _playerName];

["SpecialWarning", [format ["%1 called in a wave skip!", _playerName]]] remoteExec ["BIS_fnc_showNotification", 0];

// Kill all remaining EAST infantry (allUnits = alive soldiers only)
{ if (side _x == east && alive _x) then { _x setDamage 1; }; } forEach allUnits;

// Destroy any remaining EAST vehicles (tanks, cars, helis spawned with EAST crew)
{
    if (alive _x && side _x == east) then {
        { if (alive _x) then { _x setDamage 1; }; } forEach crew _x;
        _x setDamage 1;
    };
} forEach (allMissionObjects "LandVehicle" + allMissionObjects "Air" + allMissionObjects "Ship");
