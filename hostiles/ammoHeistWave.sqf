/**
*  ammoHeistWave
*
*  An enemy supply truck is parked 200–400m from the Bulwark with a guard detail.
*  Players must neutralise the guards, steal the truck, and drive it back within
*  BULWARK_RADIUS. On success an ammo cache is spawned and all players earn 100 pts.
*  Guards are added to waveUnits — the wave does not end until they are dead.
*
*  Domain: Server
**/

private _guardClass = if (count List_OPFOR > 0) then { selectRandom List_OPFOR } else { "O_Soldier_F" };
private _factionParam = "HOSTILE_FACTION" call BIS_fnc_getParamValue;

// Faction-appropriate truck
private _truckClass = switch (_factionParam) do {
	case 1: { "CUP_O_Ural_Open_RU" };
	case 2: { "rhs_ural_open_msv" };
	case 6: { "gm_gc_army_truck_transport" };
	case 7: { "vn_o_truck_zil_01" };
	case 8: { "CSLA_Ural" };
	default { "O_Truck_02_transport_F" };
};
if !(isClass (configFile >> "CfgVehicles" >> _truckClass)) then { _truckClass = "O_Truck_02_transport_F"; };

// Spawn position 200–400m from bulwark (flat ground for driving)
private _truckPos = [bulwarkCity, 200, 400, 5, 0, 60, 0] call BIS_fnc_findSafePos;
if (count _truckPos < 2) then { _truckPos = bulwarkCity vectorAdd [250, 0, 0]; };
private _truckX = _truckPos select 0;
private _truckY = _truckPos select 1;

// Spawn truck with no crew
private _truck = createVehicle [_truckClass, _truckPos, [], 0, "NONE"];
mainZeus addCuratorEditableObjects [[_truck], true];

// Spawn 5–7 guards in ring around truck, added to waveUnits
private _guardCount = 5 + floor (random 3);
for "_i" from 0 to (_guardCount - 1) do {
	private _angle = (_i / _guardCount) * 360;
	private _guardPos = [_truckX + 12 * sin _angle, _truckY + 12 * cos _angle, 0];
	private _gGrp = createGroup [EAST, true];
	private _guard = _gGrp createUnit [_guardClass, _guardPos, [], 0, "FORM"];
	_guard setBehaviour "COMBAT";
	_guard setCombatMode "RED";
	mainZeus addCuratorEditableObjects [[_guard], true];
	(waveUnits select 0) pushBack _guard;
};

// Map marker
createMarker ["ammoHeistMarker", _truckPos];
"ammoHeistMarker" setMarkerType "mil_flag";
"ammoHeistMarker" setMarkerColor "ColorOrange";
"ammoHeistMarker" setMarkerText "SUPPLY TRUCK";

// Monitoring
[_truck] spawn {
	params ["_t"];

	while { true } do {
		sleep 3;

		// Truck destroyed — failure
		if !(alive _t) exitWith {
			deleteMarker "ammoHeistMarker";
			["SpecialWarning", ["Supply truck destroyed — no ammo cache this wave!"]] remoteExec ["BIS_fnc_showNotification", 0];
			ammoHeistWave = false;
			publicVariable "ammoHeistWave";
		};

		// Wave ended before retrieval — silent cleanup
		if (bulwarkBox getVariable ["buildPhase", false]) exitWith {
			deleteMarker "ammoHeistMarker";
			if (alive _t) then { deleteVehicle _t; };
			ammoHeistWave = false;
			publicVariable "ammoHeistWave";
		};

		// Truck driven back to bulwark — success
		if (_t distance bulwarkCity < BULWARK_RADIUS) exitWith {
			private _cachePos = getPos _t;
			deleteVehicle _t;
			deleteMarker "ammoHeistMarker";

			// Spawn ammo cache
			private _cache = createVehicle ["Box_NATO_AmmoVeh_F", _cachePos, [], 0, "NONE"];
			mainZeus addCuratorEditableObjects [[_cache], true];

			// Fill with a broad selection of ammo
			_cache addMagazineCargoGlobal ["30Rnd_65x39_caseless_mag", 20];
			_cache addMagazineCargoGlobal ["30Rnd_556x45_Stanag", 20];
			_cache addMagazineCargoGlobal ["20Rnd_762x51_Mag", 15];
			_cache addMagazineCargoGlobal ["200Rnd_65x39_cased_Box", 5];
			_cache addMagazineCargoGlobal ["HandGrenade", 20];
			_cache addMagazineCargoGlobal ["SmokeShell", 10];
			_cache addItemCargoGlobal ["FirstAidKit", 5];
			_cache addItemCargoGlobal ["Medikit", 1];

			{
				if (alive _x && side _x == west) then { [_x, 100] call killPoints_fnc_add; };
			} forEach allPlayers;

			["SpecialWarning", ["AMMO SECURED! Supply cache at the Bulwark — +100 pts each!"]] remoteExec ["BIS_fnc_showNotification", 0];
			ammoHeistWave = false;
			publicVariable "ammoHeistWave";
		};
	};
};
