/**
*  enemyAirstrike
*
*  Spawns a faction-appropriate Mi-2 helicopter to attack the bulwark.
*  Triggered by fn_startWave for wave 10+ at ~30% chance.
*
*  Domain: Server
**/

private _factionParam = "HOSTILE_FACTION" call BIS_fnc_getParamValue;

// Preferred EAST Mi-2 classnames per faction
private _preferredHelis = switch (_factionParam) do {
	case 7: { ["vn_o_air_mi2_04_01", "vn_o_air_mi2_04_02", "vn_o_air_mi2_04_04"] }; // SOG PF: PAVN armed Mi-2
	case 1: { ["CUP_O_Mi2_RU", "CUP_O_Mi24_RU"] };            // CUP Russian
	case 2: { ["RHS_Mi2_vvs", "RHS_Mi24V_vvs"] };              // RHS AFRF
	case 8: { ["CSLA_Mi2", "CSLA_Mi24D"] };                    // CSLA
	default { ["O_Heli_Attack_02_F", "O_Heli_Attack_01_F"] };  // Vanilla CSAT
};

// Validate classnames
private _validHelis = [];
{
	if (isClass (configFile >> "CfgVehicles" >> _x)) then {
		_validHelis pushBack _x;
	};
} forEach _preferredHelis;

// Fallback to vanilla
if (count _validHelis == 0) then {
	{
		if (isClass (configFile >> "CfgVehicles" >> _x)) exitWith { _validHelis = [_x]; };
	} forEach ["O_Heli_Attack_02_F", "O_Heli_Attack_01_F"];
};
if (count _validHelis == 0) then { _validHelis = ["O_Heli_Attack_02_F"]; };

diag_log format ["DynBulwarks: enemyAirstrike — helis: %1", _validHelis];

private _heliClass = selectRandom _validHelis;
private _spawnPos = [bulwarkCity, BULWARK_RADIUS + 1000, BULWARK_RADIUS + 2000, 0, 1] call BIS_fnc_findSafePos;
private _spawnPosAir = [_spawnPos select 0, _spawnPos select 1, 150];

private _heliGroup = createGroup [EAST, true];
private _result = [_spawnPosAir, 0, _heliClass, _heliGroup] call BIS_fnc_spawnVehicle;
private _heli = _result select 0;

_heli setPos _spawnPosAir;
_heli setDir ([_spawnPos, getPos bulwarkBox] call BIS_fnc_dirTo);
_heli flyInHeight 80;
_heliGroup setCombatMode "RED";
_heliGroup setBehaviour "COMBAT";

private _wp = _heliGroup addWaypoint [position bulwarkBox, 0];
_wp setWaypointType "SAD";
_wp setWaypointFlyInHeight 80;

mainZeus addCuratorEditableObjects [[_heli], true];

["SpecialWarning", ["ENEMY HELICOPTER! Incoming Mi-2 attack on the bulwark!"]] remoteExec ["BIS_fnc_showNotification", 0];

// Auto-despawn after 120 seconds
[_heli, _heliGroup] spawn {
	params ["_h", "_g"];
	sleep 120;
	// Kill crew first so deleteVehicle doesn't eject them alive as orphaned EAST units
	{ if (alive _x) then { _x setDamage 1; }; } forEach (units _g);
	if (alive _h) then { deleteVehicle _h; };
};
