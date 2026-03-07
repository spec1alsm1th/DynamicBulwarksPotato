/**
*  enemyAirstrike
*
*  Spawns a faction-appropriate EAST jet to attack the bulwark.
*  Triggered by fn_startWave for wave 10+ at ~30% chance.
*
*  Domain: Server
**/

private _factionParam = "HOSTILE_FACTION" call BIS_fnc_getParamValue;

// Preferred EAST jet classnames per faction
private _preferredJets = switch (_factionParam) do {
	case 7: { ["vn_o_air_mig21_cas", "vn_o_air_mig19_cas"] }; // SOG PF: PAVN MiG-19/MiG-21 (verified from OSAT)
	case 1: { ["CUP_O_Su25_RU", "CUP_O_MIG29_RU"] };          // CUP Russian
	case 2: { ["RHS_Su25_vvs", "RHS_MiG29S_vvs"] };            // RHS AFRF
	case 8: { ["CSLA_Su22M4"] };                                // CSLA
	default { ["O_Plane_CAS_02_F", "O_Plane_CAS_01_F"] };      // Vanilla CSAT
};

// Validate classnames
private _validJets = [];
{
	if (isClass (configFile >> "CfgVehicles" >> _x)) then {
		_validJets pushBack _x;
	};
} forEach _preferredJets;

// Fallback to vanilla
if (count _validJets == 0) then {
	{
		if (isClass (configFile >> "CfgVehicles" >> _x)) exitWith { _validJets = [_x]; };
	} forEach ["O_Plane_CAS_02_F", "O_Plane_CAS_01_F", "O_Heli_Attack_02_F"];
};
if (count _validJets == 0) then { _validJets = ["O_Plane_CAS_02_F"]; };

diag_log format ["DynBulwarks: enemyAirstrike — jets: %1", _validJets];

private _jetClass = selectRandom _validJets;
private _spawnPos = [bulwarkCity, BULWARK_RADIUS + 1500, BULWARK_RADIUS + 2500, 0, 1] call BIS_fnc_findSafePos;
private _spawnPosAir = [_spawnPos select 0, _spawnPos select 1, 500];

private _jetGroup = createGroup [EAST, true];
private _result = [_spawnPosAir, 0, _jetClass, _jetGroup] call BIS_fnc_spawnVehicle;
private _jet = _result select 0;

_jet setPos _spawnPosAir;
_jet setDir ([_spawnPos, getPos bulwarkBox] call BIS_fnc_dirTo);
(leader _jetGroup) flyInHeight 300;
_jetGroup setCombatMode "RED";
_jetGroup setBehaviour "COMBAT";

private _wp = _jetGroup addWaypoint [position bulwarkBox, 0];
_wp setWaypointType "SAD";

mainZeus addCuratorEditableObjects [[_jet], true];

["SpecialWarning", ["ENEMY AIRSTRIKE! Incoming jet attack on the bulwark!"]] remoteExec ["BIS_fnc_showNotification", 0];

// Auto-despawn after 90 seconds
[_jet, _jetGroup] spawn {
	params ["_j", "_g"];
	sleep 90;
	if (alive _j) then { deleteVehicle _j; };
	{ if (alive _x) then { deleteVehicle _x; }; } forEach units _g;
};
