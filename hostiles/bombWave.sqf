/**
*  bombWave
*
*  A bomb is planted inside the bulwark perimeter. Players must fight through
*  guards and defuse it (stand within 5m with a ToolKit for 10 seconds).
*  If the timer expires the bomb detonates, heavily damaging the bulwark.
*
*  Domain: Server
**/

private _timerSeconds = "BOMB_TIMER" call BIS_fnc_getParamValue;

// Bomb spawns inside the bulwark, away from the box itself so players can reach it
private _bombPos = [bulwarkBox, 8, BULWARK_RADIUS * 0.5, 0, 0, 60, 0] call BIS_fnc_findSafePos;
if (count _bombPos < 2) then { _bombPos = getPos bulwarkBox; };
_bombPos = _bombPos vectorAdd [0, 0, 0.05];

// Visual prop — indestructible until we trigger it
private _bombObj = createVehicle ["Box_East_Ordnance_F", _bombPos, [], 0, "NONE"];
_bombObj allowDamage false;

// Spawn guards around the bomb (6–8)
private _guardCount = 6 + floor random 3;
private _guardGroup = createGroup [EAST, true];
private _guards = [];
private _guardClass = if (count List_OPFOR > 0) then { selectRandom List_OPFOR } else { "O_Soldier_F" };

for "_i" from 0 to (_guardCount - 1) do {
	private _angle = (_i / _guardCount) * 360;
	private _guardPos = [(_bombPos select 0) + 8 * sin _angle, (_bombPos select 1) + 8 * cos _angle, 0];

	private _guard = _guardGroup createUnit [_guardClass, _guardPos, [], 0, "FORM"];
	_guard setBehaviour "COMBAT";
	_guard setCombatMode "RED";
	mainZeus addCuratorEditableObjects [[_guard], true];
	_guards pushBack _guard;
};

// Map marker
private _markerName = "bombMarker";
createMarker [_markerName, _bombPos];
_markerName setMarkerType "mil_destroy";
_markerName setMarkerColor "ColorRed";
_markerName setMarkerText "BOMB";

// Announce with timer
private _timerMins = floor (_timerSeconds / 60);
["SpecialWarning", [format ["BOMB PLANTED in the Bulwark! Defuse within %1 minutes — use ToolKit!", _timerMins]]] remoteExec ["BIS_fnc_showNotification", 0];

// Monitor: timer countdown + defuse detection (server-side polling)
[_bombObj, _markerName, _timerSeconds, _bombPos] spawn {
	params ["_bomb", "_marker", "_timeLimit", "_bPos"];

	private _elapsed = 0;
	private _defused = false;
	private _timedOut = false;
	private _defuseProgress = 0;
	private _activeDefuser = objNull;

	while { !_defused && !_timedOut } do {
		sleep 1;
		_elapsed = _elapsed + 1;
		private _remaining = _timeLimit - _elapsed;

		// Countdown notifications at 30-second marks
		if (_remaining > 0 && { _remaining % 30 == 0 }) then {
			private _mins = floor (_remaining / 60);
			private _secs = _remaining % 60;
			private _timeStr = if (_mins > 0) then {
				format ["%1m %2s", _mins, _secs]
			} else {
				format ["%1s", _secs]
			};
			["SpecialWarning", [format ["BOMB: %1 remaining — DEFUSE IT!", _timeStr]]] remoteExec ["BIS_fnc_showNotification", 0];
		};

		// Final 20-second warning
		if (_remaining == 20) then {
			["SpecialWarning", ["20 SECONDS — BOMB DETONATION IMMINENT!"]] remoteExec ["BIS_fnc_showNotification", 0];
		};

		// Check for a player with ToolKit within 5m of the bomb
		private _nearDefuser = objNull;
		{
			if (alive _x && _x distance _bomb < 5 && { "ToolKit" in items _x }) exitWith {
				_nearDefuser = _x;
			};
		} forEach allPlayers;

		if (!isNull _nearDefuser) then {
			// Same or new defuser?
			if (_nearDefuser != _activeDefuser) then {
				_activeDefuser = _nearDefuser;
				_defuseProgress = 0;
			};
			_defuseProgress = _defuseProgress + 1;
			[format ["Defusing... %1/10s — stay still!", _defuseProgress]] remoteExec ["hint", _activeDefuser];
		} else {
			// Defuser moved away
			if (_defuseProgress > 0 && _defuseProgress < 10) then {
				["Defusal interrupted! Stay within 5m of the bomb."] remoteExec ["hint", _activeDefuser];
			};
			_defuseProgress = 0;
			_activeDefuser = objNull;
		};

		if (_defuseProgress >= 10) then { _defused = true; };
		if (_remaining <= 0) then { _timedOut = true; };
	};

	deleteMarker _marker;
	deleteVehicle _bomb;

	if (_defused) then {
		["TaskSucceeded", ["BOMB DEFUSED!", "The threat has been neutralised!"]] remoteExec ["BIS_fnc_showNotification", 0];
		if (!isNull _activeDefuser && alive _activeDefuser) then {
			[_activeDefuser, 200] call killPoints_fnc_add;
			["Bomb defused. Outstanding work!"] remoteExec ["hint", _activeDefuser];
		};
	} else {
		["SpecialWarning", ["BOMB DETONATED — the Bulwark has taken heavy damage!"]] remoteExec ["BIS_fnc_showNotification", 0];
		["Alarm"] remoteExec ["playSound", 0];
		// Detonate: spawn an armed satchel charge at bomb position and trigger it
		private _expl = "SatchelCharge_Remote_Mag" createVehicle _bPos;
		_expl setDamage 1;
	};

	bombWave = false;
	publicVariable "bombWave";
};
