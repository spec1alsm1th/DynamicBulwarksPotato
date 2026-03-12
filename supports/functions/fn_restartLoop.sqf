/**
*  fn_restartLoop
*
*  Restarts the mission loop without resetting the wave counter.
*  Kills all remaining EAST units first, then relaunches missionLoop.sqf.
*  Free support — no cost — available to all players.
*
*  Domain: Server
**/

params ["_player"];

private _playerName = name _player;
diag_log format ["DynBulwarks: restartLoop triggered by %1", _playerName];

["SpecialWarning", [format ["%1 restarted the mission loop!", _playerName]]] remoteExec ["BIS_fnc_showNotification", 0];

// Kill any remaining EAST infantry
{ if (side _x == east && alive _x) then { _x setDamage 1; }; } forEach allUnits;

// Kill any remaining EAST vehicles
{
    if (alive _x && side _x == east) then {
        { if (alive _x) then { _x setDamage 1; }; } forEach crew _x;
        _x setDamage 1;
    };
} forEach (allMissionObjects "LandVehicle" + allMissionObjects "Air" + allMissionObjects "Ship");

// Decrement attkWave so fn_startWave's increment brings us back to the same wave
attkWave = (attkWave - 1) max 0;
publicVariable "attkWave";

// Stop the current loop and relaunch — attkWave is preserved (see missionLoop.sqf)
runMissionLoop = false;
sleep 2;
[bulwarkRoomPos] execVM "missionLoop.sqf";
