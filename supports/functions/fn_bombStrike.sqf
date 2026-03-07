/**
*  fn_bombStrike
*
*  Calls a faction-appropriate bomber to drop cluster bombs on the target position.
*  Distinct from airStrike (Missile CAS).
*
*  Domain: Server
**/
params ["_player", "_targetPos"];

if (count _targetPos == 0) then {
	[_player, "bombStrike"] remoteExec ["BIS_fnc_addCommMenuItem", _player]; // refund if aimed at sky
} else {
	private _smoker = "SmokeShellRed" createVehicle [_targetPos select 0, _targetPos select 1, 10];
	_smoker setVelocity [0, 0, -100];
	_smoker setVectorDirandUp [[0, 0, -1], [0.1, 0.1, 1]];

	// Select faction-appropriate bomber
	private _factionParam = "HOSTILE_FACTION" call BIS_fnc_getParamValue;
	private _preferredBombers = switch (_factionParam) do {
		case 7: { ["vn_b_air_f4c_bmb", "vn_b_air_f100d_bmb"] }; // SOG PF: F-4 Phantom / F-100 Super Sabre (verified from OSAT)
		default { ["B_Plane_CAS_01_DynamicLoadout_F"] };
	};

	private _bomberClass = "B_Plane_CAS_01_DynamicLoadout_F";
	{
		if (isClass (configFile >> "CfgVehicles" >> _x)) exitWith { _bomberClass = _x; };
	} forEach _preferredBombers;

	private _angle = round random 360;
	private _casGroup = createGroup WEST;
	private _cas = _casGroup createUnit ["ModuleCAS_F", _targetPos, [], 0, ""];
	_cas setDir _angle;
	_cas setVariable ["vehicle", _bomberClass, true];
	_cas setVariable ["type", 2, true]; // type 2 = cluster bombs
};
