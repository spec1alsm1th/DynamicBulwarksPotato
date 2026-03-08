/**
*  fn_reconFlight
*
*  Calls a faction-appropriate observation aircraft to fly a single reconnaissance pass
*  over the clicked target area. All enemy contacts within 300m of the target are
*  marked on the map for 25 seconds then removed.
*
*  SOG Prairie Fire: O-1 Bird Dog (vn_b_air_o1_01)
*  Global Mobilization: DO-27
*  All others: Hummingbird light helicopter fallback
*
*  Domain: Server
**/
params ["_player", "_targetPos"];

if (count _targetPos == 0) then {
	[_player, "reconFlight"] remoteExec ["BIS_fnc_addCommMenuItem", _player]; // refund if aimed at sky
} else {
	private _factionParam = "HOSTILE_FACTION" call BIS_fnc_getParamValue;

	// Faction-appropriate light observation aircraft
	private _planeClass = switch (_factionParam) do {
		case 7: { "vn_b_air_o1_01" };         // SOG PF: O-1 Bird Dog
		case 6: { "gm_ge_airforce_do27_01" };  // Global Mobilization: DO-27
		default { "B_Heli_Light_01_F" };       // Fallback: Hummingbird
	};
	if !(isClass (configFile >> "CfgVehicles" >> _planeClass)) then {
		_planeClass = "B_Heli_Light_01_F";
	};

	// Fly-over path: entry from random direction → over target → exit opposite side
	private _flyAlt   = 120;
	private _entryDir = random 360;
	private _entryPos = [
		(_targetPos select 0) + 1200 * sin _entryDir,
		(_targetPos select 1) + 1200 * cos _entryDir,
		_flyAlt
	];
	private _overPos = [_targetPos select 0, _targetPos select 1, _flyAlt];
	private _exitPos = [
		(_targetPos select 0) - 1000 * sin _entryDir,
		(_targetPos select 1) - 1000 * cos _entryDir,
		_flyAlt
	];

	// Spawn aircraft
	private _reconGrp = createGroup [WEST, true];
	private _spawnResult = [_entryPos, 0, _planeClass, _reconGrp] call BIS_fnc_spawnVehicle;
	private _plane = _spawnResult select 0;
	_plane setPos _entryPos;
	_plane setDir ([_entryPos, _overPos] call BIS_fnc_dirTo);
	_reconGrp setBehaviour "CARELESS";
	_reconGrp setCombatMode "BLUE";

	// Waypoints: fly over target then exit
	private _wp1 = _reconGrp addWaypoint [_overPos, 0];
	_wp1 setWaypointType "Move";
	_wp1 setWaypointCompletionRadius 150;

	private _wp2 = _reconGrp addWaypoint [_exitPos, 0];
	_wp2 setWaypointType "Move";

	mainZeus addCuratorEditableObjects [[_plane], true];
	["TaskAssigned", ["RECON FLIGHT", "Observation aircraft inbound — stand by for contact report."]] remoteExec ["BIS_fnc_showNotification", 0];

	// Marking pass and cleanup
	[_plane, _targetPos, _reconGrp] spawn {
		params ["_p", "_tPos", "_g"];

		// Wait until aircraft is within range of target
		waitUntil {
			sleep 2;
			!alive _p || _p distance _tPos < 400
		};

		// Mark all EAST contacts within 300m of target position
		private _markers = [];
		if (alive _p) then {
			private _contacts = nearestObjects [_tPos, ["Man", "Car", "Tank", "Air"], 300];
			{
				if (side _x == east && alive _x) then {
					private _mkr = format ["reconFlight_%1_%2", floor time, _forEachIndex];
					createMarker [_mkr, getPos _x];
					_mkr setMarkerType "hd_dot";
					_mkr setMarkerColor "ColorRed";
					_markers pushBack _mkr;
				};
			} forEach _contacts;

			private _count = count _markers;
			if (_count > 0) then {
				["TaskSucceeded", ["RECON REPORT", format ["%1 enemy contact(s) spotted — marked for 25 seconds.", _count]]] remoteExec ["BIS_fnc_showNotification", 0];
			} else {
				["TaskSucceeded", ["RECON REPORT", "No contacts in the area."]] remoteExec ["BIS_fnc_showNotification", 0];
			};
		};

		// Hold markers for 25s then clear
		sleep 25;
		{ deleteMarker _x } forEach _markers;

		// Aircraft exits and despawns
		sleep 15;
		if (alive _p) then { deleteVehicle _p; };
		{ deleteVehicle _x } forEach (units _g);
	};
};
