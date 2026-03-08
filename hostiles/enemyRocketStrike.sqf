/**
*  enemyRocketStrike
*
*  Spawns an off-map EAST mortar that fires at the bulwark.
*  Triggered by fn_startWave for wave 10+ at ~30% chance.
*
*  Domain: Server
**/

private _factionParam = "HOSTILE_FACTION" call BIS_fnc_getParamValue;

// Faction-appropriate EAST mortar classnames
private _preferredMortars = switch (_factionParam) do {
	case 7: { ["vn_o_vc_static_mortar_type53"] };   // SOG PF VC mortar
	case 1: { ["CUP_O_2b14_82mm_RU"] };              // CUP Russian 2B14
	case 2: { ["rhs_2b14_82mm_msv"] };               // RHS AFRF 2B14
	case 4: { ["I_F_Mortar_01_F"] };                 // Contact LDF (INDEP)
	default { ["O_Mortar_01_F"] };                   // Vanilla CSAT
};

private _validMortars = [];
{
	if (isClass (configFile >> "CfgVehicles" >> _x)) then {
		_validMortars pushBack _x;
	};
} forEach _preferredMortars;

if (count _validMortars == 0) then {
	_validMortars = ["O_Mortar_01_F"];
};

// Spawn mortar off-map
private _spawnPos = [bulwarkCity, BULWARK_RADIUS + 600, BULWARK_RADIUS + 900, 3, 0, 10, 0] call BIS_fnc_findSafePos;
if (count _spawnPos < 2) then { _spawnPos = bulwarkCity; };

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

// Aim at the bulwark with a random ±35 m offset so rounds scatter
private _cx = position bulwarkBox select 0;
private _cy = position bulwarkBox select 1;
private _targetPos = [
	_cx + (random 70) - 35,
	_cy + (random 70) - 35,
	0
];
_gunner doArtilleryFire [_targetPos, _ammoType, 3];

diag_log format ["DynBulwarks: enemyRocketStrike — mortar: %1, ammo: %2", _mortarClass, _ammoType];

["SpecialWarning", ["INCOMING MORTAR FIRE! Take cover!"]] remoteExec ["BIS_fnc_showNotification", 0];

// Clean up after barrage
[_mortar, _mortarGroup] spawn {
	params ["_m", "_g"];
	sleep 90;
	if (alive _m) then { deleteVehicle _m; };
	{ deleteVehicle _x } forEach (units _g);
};
