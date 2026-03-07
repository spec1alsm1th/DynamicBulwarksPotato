/**
*  fn_artilleryBarrage
*
*  Calls an off-map mortar barrage on the target position.
*
*  Domain: Server
**/
params ["_player", "_targetPos"];

if (count _targetPos == 0) then {
	[_player, "artilleryBarrage"] remoteExec ["BIS_fnc_addCommMenuItem", _player]; // refund if aimed at sky
} else {
	private _smoker = "SmokeShellRed" createVehicle [_targetPos select 0, _targetPos select 1, 0];

	// Spawn an off-map WEST mortar
	private _spawnPos = [bulwarkCity, BULWARK_RADIUS + 400, BULWARK_RADIUS + 700, 3, 0, 10, 0] call BIS_fnc_findSafePos;
	if (count _spawnPos < 2) then { _spawnPos = bulwarkCity; };

	private _mortarGroup = createGroup [WEST, true];
	private _result = [_spawnPos, 0, "B_Mortar_01_F", _mortarGroup] call BIS_fnc_spawnVehicle;
	private _mortar = _result select 0;
	private _gunner = gunner _mortar;

	// Use whatever ammo the mortar spawns with; add vanilla rounds as fallback
	private _ammoType = "";
	{ if (_x != "") exitWith { _ammoType = _x; }; } forEach magazines _mortar;
	if (_ammoType == "") then {
		_mortar addMagazineAmmoCargo ["3Rnd_82mm_Mo_shells", 8];
		_ammoType = "3Rnd_82mm_Mo_shells";
	};

	_gunner doArtilleryFire [_targetPos, _ammoType, 8];

	["TaskAssigned", ["FIRE FOR EFFECT!", "Artillery barrage inbound on target."]] remoteExec ["BIS_fnc_showNotification", 0];

	// Clean up after barrage
	[_mortar, _mortarGroup] spawn {
		params ["_m", "_g"];
		sleep 90;
		{ deleteVehicle _x } forEach vehicles _g;
		{ deleteVehicle _x } forEach units _g;
	};
};
