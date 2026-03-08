/**
*  enemyRocketStrike
*
*  SOG Prairie Fire: spawns an off-map H12 107mm Multiple Rocket Launcher
*  and fires 3 rockets at the bulwark area with ±35 m scatter.
*
*  All other factions: spawns a faction-appropriate off-map mortar
*  and fires 3 rounds with ±35 m scatter.
*
*  Triggered by fn_startWave for wave 10+ at ~30% chance.
*
*  Domain: Server
**/

private _factionParam = "HOSTILE_FACTION" call BIS_fnc_getParamValue;

// Shared: spawn position off-map, scatter target around bulwark
private _spawnPos = [bulwarkCity, BULWARK_RADIUS + 600, BULWARK_RADIUS + 900, 3, 0, 10, 0] call BIS_fnc_findSafePos;
if (count _spawnPos < 2) then { _spawnPos = bulwarkCity; };

private _cx = position bulwarkBox select 0;
private _cy = position bulwarkBox select 1;
private _targetPos = [
	_cx + (random 70) - 35,
	_cy + (random 70) - 35,
	0
];

if (_factionParam == 7) then {

	// --- SOG Prairie Fire: H12 107mm MRL ---
	private _h12Class = selectRandom [
		"vn_o_vc_static_h12",
		"vn_o_nva_static_h12",
		"vn_o_nva_65_static_h12"
	];
	private _h12Group = createGroup [EAST, true];
	private _result = [_spawnPos, 0, _h12Class, _h12Group] call BIS_fnc_spawnVehicle;
	private _h12 = _result select 0;
	private _gunner = gunner _h12;

	_gunner doArtilleryFire [_targetPos, "vn_h12_v_12_he_mag", 3];

	diag_log format ["DynBulwarks: enemyRocketStrike — H12: %1", _h12Class];
	["SpecialWarning", ["INCOMING ROCKETS! Take cover!"]] remoteExec ["BIS_fnc_showNotification", 0];

	[_h12, _h12Group] spawn {
		params ["_v", "_g"];
		sleep 90;
		if (alive _v) then { deleteVehicle _v; };
		{ deleteVehicle _x } forEach (units _g);
	};

} else {

	// --- All other factions: off-map mortar ---
	private _preferredMortars = switch (_factionParam) do {
		case 1: { ["CUP_O_2b14_82mm_RU"] };   // CUP Russian 2B14
		case 2: { ["rhs_2b14_82mm_msv"] };     // RHS AFRF 2B14
		case 4: { ["I_F_Mortar_01_F"] };       // Contact LDF
		default { ["O_Mortar_01_F"] };         // Vanilla CSAT
	};
	private _validMortars = _preferredMortars select { isClass (configFile >> "CfgVehicles" >> _x) };
	if (count _validMortars == 0) then { _validMortars = ["O_Mortar_01_F"]; };

	private _mortarClass = selectRandom _validMortars;
	private _mortarGroup = createGroup [EAST, true];
	private _result = [_spawnPos, 0, _mortarClass, _mortarGroup] call BIS_fnc_spawnVehicle;
	private _mortar = _result select 0;
	private _gunner = gunner _mortar;

	// Use whatever ammo the mortar spawns with; add vanilla rounds as fallback
	private _ammoType = "";
	{ if (_x != "") exitWith { _ammoType = _x; }; } forEach magazines _mortar;
	if (_ammoType == "") then {
		_mortar addMagazineAmmoCargo ["3Rnd_82mm_Mo_shells", 2];
		_ammoType = "3Rnd_82mm_Mo_shells";
	};

	_gunner doArtilleryFire [_targetPos, _ammoType, 3];

	diag_log format ["DynBulwarks: enemyRocketStrike — mortar: %1, ammo: %2", _mortarClass, _ammoType];
	["SpecialWarning", ["INCOMING MORTAR FIRE! Take cover!"]] remoteExec ["BIS_fnc_showNotification", 0];

	[_mortar, _mortarGroup] spawn {
		params ["_m", "_g"];
		sleep 90;
		if (alive _m) then { deleteVehicle _m; };
		{ deleteVehicle _x } forEach (units _g);
	};

};
