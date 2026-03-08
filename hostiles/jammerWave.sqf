/**
*  jammerWave
*
*  Enemy SIGINT jammer disables the support menu until it is destroyed.
*  Players must fight through the guard detail and destroy the jammer prop.
*  If all guards are wiped before the jammer falls, reinforcements are called every 120s.
*
*  Domain: Server
**/

private _guardClass = if (count List_OPFOR > 0) then { selectRandom List_OPFOR } else { "O_Soldier_F" };

// Find spawn position 100–250m from bulwark
private _jammerPos = [bulwarkCity, 100, 250, 5, 0, 60, 0] call BIS_fnc_findSafePos;
if (count _jammerPos < 2) then { _jammerPos = bulwarkCity vectorAdd [150, 0, 0]; };

// Jammer prop — use an ammo box (has a real damage model, satisfying to destroy)
private _jammerObj = createVehicle ["Box_East_Ordnance_F", _jammerPos, [], 0, "NONE"];
_jammerObj allowDamage true;
mainZeus addCuratorEditableObjects [[_jammerObj], true];

// Guard ring — 6–8 guards
private _guardCount = 6 + floor (random 3);
private _initialGuards = [];
private _jammerX = _jammerPos select 0;
private _jammerY = _jammerPos select 1;

for "_i" from 0 to (_guardCount - 1) do {
	private _angle = (_i / _guardCount) * 360;
	private _guardPos = [_jammerX + 8 * sin _angle, _jammerY + 8 * cos _angle, 0];
	private _gGrp = createGroup [EAST, true];
	private _guard = _gGrp createUnit [_guardClass, _guardPos, [], 0, "FORM"];
	_guard setBehaviour "COMBAT";
	_guard setCombatMode "RED";
	mainZeus addCuratorEditableObjects [[_guard], true];
	(waveUnits select 0) pushBack _guard;
	_initialGuards pushBack _guard;
};

// Activate jammer — support menu locked in fn_support.sqf
jammerActive = true;
publicVariable "jammerActive";

// Map marker
createMarker ["jammerMarker", _jammerPos];
"jammerMarker" setMarkerType "mil_triangle";
"jammerMarker" setMarkerColor "ColorRed";
"jammerMarker" setMarkerText "JAMMER";

// Monitoring
[_jammerObj, _initialGuards, _guardClass] spawn {
	params ["_jammer", "_initGuards", "_gClass"];

	private _lastReinforceTime = time;

	while { true } do {
		sleep 5;

		// Wave ended before jammer destroyed — silent cleanup
		if (bulwarkBox getVariable ["buildPhase", false]) exitWith {
			deleteMarker "jammerMarker";
			if (alive _jammer) then { deleteVehicle _jammer; };
			jammerActive = false;
			publicVariable "jammerActive";
			jammerWave = false;
			publicVariable "jammerWave";
		};

		// Jammer destroyed — success
		if !(alive _jammer) exitWith {
			deleteMarker "jammerMarker";
			jammerActive = false;
			publicVariable "jammerActive";

			{
				if (alive _x && side _x == west && _x distance _jammer < 150) then {
					[_x, 75] call killPoints_fnc_add;
				};
			} forEach allPlayers;

			["SpecialWarning", ["JAMMER DESTROYED! Support menu restored! +75 pts nearby."]] remoteExec ["BIS_fnc_showNotification", 0];
			jammerWave = false;
			publicVariable "jammerWave";
		};

		// Reinforcements every 120s once original guards are all dead
		if ((time - _lastReinforceTime) >= 120) then {
			if ({ alive _x } count _initGuards == 0) then {
				_lastReinforceTime = time;
				for "_j" from 1 to 3 do {
					private _rPos = [getPos _jammer, 50, 150, 3, 0, 10, 0] call BIS_fnc_findSafePos;
					private _rGrp = createGroup [EAST, true];
					private _r = _rGrp createUnit [_gClass, _rPos, [], 0, "FORM"];
					_r setBehaviour "COMBAT";
					_r setCombatMode "RED";
					_r doMove (getPos _jammer);
					mainZeus addCuratorEditableObjects [[_r], true];
					(waveUnits select 0) pushBack _r;
				};
				["SpecialWarning", ["Jammer — enemy reinforcements inbound!"]] remoteExec ["BIS_fnc_showNotification", 0];
			};
		};
	};
};
