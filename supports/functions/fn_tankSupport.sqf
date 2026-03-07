/**
*  fn_tankSupport
*
*  Spawns a faction-appropriate friendly tank that advances to and defends the bulwark.
*
*  Domain: Server
**/
params ["_player"];

private _factionParam = "HOSTILE_FACTION" call BIS_fnc_getParamValue;

private _preferredTanks = switch (_factionParam) do {
	case 7: { ["vn_b_armor_m48_01_01", "vn_b_armor_m48_01_02", "vn_b_armor_m41_01_01", "vn_b_armor_m41_01_02"] }; // SOG PF: M48 Patton / M41 Walker Bulldog (verified from OSAT)
	case 1: { ["CUP_B_M60A3_US", "CUP_B_M1A1_US"] };         // CUP
	case 2: { ["RHS_M1A2SEPv2_USARMY", "RHS_M60A3_USMC"] };  // RHS
	case 6: { ["gm_ge_army_leopard1a1"] };                     // Global Mobilization
	default { ["B_MBT_01_cannon_F"] };
};

private _validTanks = [];
{
	if (isClass (configFile >> "CfgVehicles" >> _x)) then {
		_validTanks pushBack _x;
	};
} forEach _preferredTanks;

if (count _validTanks == 0) then {
	_validTanks = ["B_MBT_01_cannon_F"];
};

private _spawnPos = [bulwarkCity, BULWARK_RADIUS + 300, BULWARK_RADIUS + 600, 5, 0, 30, 0] call BIS_fnc_findSafePos;
if (count _spawnPos < 2) then { _spawnPos = bulwarkCity; };

private _tankClass = selectRandom _validTanks;
private _tankGroup = createGroup [WEST, true];
private _result = [_spawnPos, 0, _tankClass, _tankGroup] call BIS_fnc_spawnVehicle;
private _tank = _result select 0;

{ _x allowFleeing 0; } forEach units _tankGroup;

private _wp1 = _tankGroup addWaypoint [position bulwarkBox, 30];
_wp1 setWaypointType "MOVE";
_wp1 setWaypointCompletionRadius 30;

private _wp2 = _tankGroup addWaypoint [position bulwarkBox, 0];
_wp2 setWaypointType "SAD";

_tankGroup setCombatMode "RED";
_tankGroup setBehaviour "AWARE";

mainZeus addCuratorEditableObjects [[_tank], true];

["TaskAssigned", ["ARMOUR!", "Friendly tank is moving to your position."]] remoteExec ["BIS_fnc_showNotification", 0];
