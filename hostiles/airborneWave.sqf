/**
*  airborneWave
*
*  All enemy infantry arrives via transport helicopter. Helicopters fly to a
*  landing zone near the bulwark, land, disembark troops, then fly away.
*  Vehicles and armour still spawn normally via createWave.sqf.
*
*  Domain: Server
**/

private _factionParam = "HOSTILE_FACTION" call BIS_fnc_getParamValue;
private _randWeapons = "RANDOM_WEAPONS" call BIS_fnc_getParamValue;
private _lootFaction = "LOOT_FACTION" call BIS_fnc_getParamValue;
private _replaceWeapons = (_randWeapons == 1 || _lootFaction != 0);

private _noOfPlayers = 1 max floor ((playersNumber west) * HOSTILE_TEAM_MULTIPLIER);

// Determine unit class and point score by wave tier (mirrors createWave.sqf tiers)
private _unitClasses = HOSTILE_LEVEL_1;
private _killScore = HOSTILE_LEVEL_1_POINT_SCORE;
if (attkWave > 6) then {
	_unitClasses = HOSTILE_LEVEL_2;
	_killScore = HOSTILE_LEVEL_2_POINT_SCORE;
};
if (attkWave > 12) then {
	_unitClasses = HOSTILE_LEVEL_3;
	_killScore = HOSTILE_LEVEL_3_POINT_SCORE;
};

// AI skill scaled to wave
private _skill = ((attkWave / 40) min 1) max 0.05;

// Number of helicopter passes scaled to wave; each drops _unitsPerPass troops
private _heliPasses = (2 + floor (attkWave / 3)) min 8;
private _unitsPerPass = _noOfPlayers max 4;

// Preferred faction-appropriate transport helicopter classnames
private _preferredTransports = switch (_factionParam) do {
	case 0: { ["O_Heli_Light_02_F", "O_Heli_Transport_04_F"] };          // Vanilla CSAT
	case 1: { ["CUP_O_Mi8_RU", "CUP_O_Mi17_RU"] };                       // CUP Russian
	case 2: { ["RHS_Mi8mt_vvs", "RHS_Mi8AMTSh_vvs"] };                   // RHS AFRF
	case 3: { ["O_T_Heli_Light_02_F", "O_T_Heli_Transport_04_F"] };      // Apex CSAT Pacific
	case 4: { ["O_Heli_Light_02_F", "O_Heli_Transport_04_F"] };          // Contact (fallback)
	case 5: { ["O_W_Heli_Light_01_F", "O_Heli_Light_02_F"] };            // Western Sahara
	case 6: { ["gm_gc_airforce_mi2t"] };                                   // Global Mobilization
	case 7: { ["vn_o_air_mi2_01_01", "vn_o_air_mi2_01_02", "vn_o_air_mi2_01_03"] };  // S.O.G. Prairie Fire (PAVN transport Mi-2)
	case 8: { ["CSLA_Mi8T", "CSLA_Mi8"] };                                // CSLA Iron Curtain
	default { ["O_Heli_Light_02_F"] };
};

// Validate classnames; keep only what is loaded
private _validTransports = [];
{
	if (isClass (configFile >> "CfgVehicles" >> _x)) then {
		_validTransports pushBack _x;
	};
} forEach _preferredTransports;

// Fallback scan: any EAST helicopter with "transport" or "light" in its type
if (count _validTransports == 0) then {
	{
		if (isClass (configFile >> "CfgVehicles" >> _x)) exitWith {
			_validTransports = [_x];
		};
	} forEach ["O_Heli_Light_02_F", "O_Heli_Transport_04_F", "O_Heli_Light_01_F"];
};

// Absolute fallback
if (count _validTransports == 0) then {
	_validTransports = ["O_Heli_Light_02_F"];
};

diag_log format ["DynBulwarks: airborneWave — transports: %1, passes: %2, units/pass: %3", _validTransports, _heliPasses, _unitsPerPass];

// Approach and landing altitude
private _approachAlt = 80;

// Spawn helicopter passes staggered in time
for "_h" from 1 to _heliPasses do {

	// Find a clear landing zone near the bulwark
	private _lzPos = [bulwarkCity, 20, 100, 5, 0, 0.3, 10] call BIS_fnc_findSafePos;
	if (count _lzPos < 2) then { _lzPos = bulwarkCity; };

	// Each heli approaches from a different random direction
	private _entryPos = [bulwarkCity, BULWARK_RADIUS + 700, BULWARK_RADIUS + 1400, 0, 1] call BIS_fnc_findSafePos;
	private _entryPosAir = [_entryPos select 0, _entryPos select 1, _approachAlt];

	// Exit on the far side
	private _exitDir = ([_lzPos, _entryPos] call BIS_fnc_dirTo) + 180;
	private _exitX = (_lzPos select 0) + sin(_exitDir) * (BULWARK_RADIUS + 800);
	private _exitY = (_lzPos select 1) + cos(_exitDir) * (BULWARK_RADIUS + 800);
	private _exitPosAir = [_exitX, _exitY, _approachAlt];

	// Spawn troops at LZ (they will be loaded into cargo immediately)
	private _troopGroup = createGroup [EAST, true];
	for "_p" from 1 to _unitsPerPass do {
		private _unitClass = selectRandom _unitClasses;
		private _spawnOffset = [(random 10) - 5, (random 10) - 5, 0];
		private _unit = _troopGroup createUnit [_unitClass, _lzPos vectorAdd _spawnOffset, [], 2, "CAN_COLLIDE"];

		private _skillAim = _skill * 0.75;
		_unit setUnitAbility _skill;
		_unit setSkill ["aimingAccuracy", _skillAim];
		_unit setSkill ["aimingSpeed", _skillAim];
		_unit setSkill ["aimingShake", _skill];
		_unit setSkill ["spotTime", 0.05];

		_unit addEventHandler ["Hit", killPoints_fnc_hit];
		_unit addEventHandler ["Killed", killPoints_fnc_killed];
		_unit setVariable ["killPointMulti", _killScore];

		// Apply random weapon replacement if loot faction filtering is active
		if (_replaceWeapons) then {
			private _unitPrimary = primaryWeapon _unit;
			private _primaryAmmoTypes = getArray (configFile >> "CfgWeapons" >> _unitPrimary >> "magazines");
			{
				if (_x in _primaryAmmoTypes) then { _unit removeMagazineGlobal _x; };
			} forEach magazines _unit;
			private _newWeapon = selectRandom List_Primaries;
			private _newMag = selectRandom getArray (configFile >> "CfgWeapons" >> _newWeapon >> "magazines");
			_unit addWeaponGlobal _newWeapon;
			_unit addPrimaryWeaponItem _newMag;
			_unit addMagazine _newMag;
			_unit addMagazine _newMag;
			_unit addMagazine _newMag;
			_unit selectWeapon _newWeapon;
		};

		// PISTOL_HOSTILES early-wave restriction
		if (attkWave <= PISTOL_HOSTILES) then {
			removeAllWeapons _unit;
			private _pistolMag = if (!isNil "HOSTILE_PISTOL_MAG") then { HOSTILE_PISTOL_MAG } else { "16Rnd_9x21_Mag" };
			private _pistol = if (!isNil "HOSTILE_PISTOL") then { HOSTILE_PISTOL } else { "hgun_P07_F" };
			_unit addMagazine _pistolMag;
			_unit addMagazine _pistolMag;
			_unit addWeapon _pistol;
		};

		// Random optic — same probability curve as ground infantry
		if (attkWave > PISTOL_HOSTILES && primaryWeapon _unit != "") then {
			private _opticChance = (attkWave / 40) min 0.75;
			if (random 1 < _opticChance) then {
				_unit addPrimaryWeaponItem selectRandom [
					"optic_MRCO", "optic_LRPS", "optic_SOS", "optic_KHS_blk", "optic_Hamr", "optic_Arco"
				];
			};
		};

		mainZeus addCuratorEditableObjects [[_unit], true];
		unitArray = waveUnits select 0;
		unitArray append [_unit];
	};

	// Spawn heli
	private _heliClass = selectRandom _validTransports;
	private _heliGroup = createGroup [EAST, true];
	private _heliResult = [_entryPosAir, 0, _heliClass, _heliGroup] call BIS_fnc_spawnVehicle;
	private _heli = _heliResult select 0;

	_heli setPos _entryPosAir;
	_heli setDir ([_entryPos, _lzPos] call BIS_fnc_dirTo);
	(leader _heliGroup) flyInHeight _approachAlt;
	_heliGroup setCombatMode "GREEN";
	_heliGroup setBehaviour "CARELESS";

	// Load troops into cargo
	{ _x moveInCargo _heli; } forEach (units _troopGroup);

	// Waypoints: fly to LZ and unload, then exit
	private _wp1 = _heliGroup addWaypoint [_lzPos, 0];
	_wp1 setWaypointType "TR UNLOAD";
	_wp1 setWaypointCompletionRadius 20;

	private _wp2 = _heliGroup addWaypoint [_exitPosAir, 0];
	_wp2 setWaypointType "Move";

	mainZeus addCuratorEditableObjects [[_heli], true];

	// Wait for unload to complete, then send troops into combat
	[_troopGroup, _heli, _heliGroup] spawn {
		params ["_tg", "_helicopter", "_hg"];

		waitUntil {
			sleep 3;
			(currentWaypoint _hg >= 2) || !alive _helicopter
		};

		_tg setCombatMode "RED";
		_tg setBehaviour "COMBAT";
		{
			if (alive _x) then { _x doMove (getPos (selectRandom playableUnits)); };
		} forEach (units _tg);

		// Clean up heli after it flies away
		sleep 60;
		if (alive _helicopter) then { deleteVehicle _helicopter; };
	};

	sleep 10; // Stagger helicopter passes
};
