/**
*  hostageWave
*
*  Selects one random player, teleports them to a remote location
*  without weapons, surrounded by EAST guards.
*  Other players must rescue them.
*
*  Domain: Server
**/

private _allHCs = entities "HeadlessClient_F";
private _allHPs = allPlayers - _allHCs;

// Only run if more than 2 players
if (count _allHPs <= 2) exitWith {
	hostageWave = false;
	["TaskAssigned",["Hostage Wave","Not enough players — skipped."]] remoteExec ["BIS_fnc_showNotification", 0];
};

// Pick random player
private _hostage = selectRandom _allHPs;
hostageUnit = _hostage;
publicVariable "hostageUnit";

// Save loadout to restore on rescue
private _savedLoadout = getUnitLoadout _hostage;
hostageLoadout = _savedLoadout;

// Find a safe position away from bulwark (200–600m away)
private _rescuePos = [bulwarkCity, 200, 600, 5, 0, 10, 0] call BIS_fnc_findSafePos;

// Teleport hostage (run on hostage's machine)
[_rescuePos] remoteExec ["setPos", _hostage];
sleep 0.5;

// Strip weapons (run on server)
removeAllWeapons _hostage;
removeAllItems _hostage;
removeAllAssignedItems _hostage;

// Notify hostage
private _timerSeconds = "HOSTAGE_TIMER" call BIS_fnc_getParamValue;
private _timerHint = if (_timerSeconds > 0) then {
	format ["You have been taken HOSTAGE!\nStay still — move and the guards will shoot!\nYou have %1 minutes before execution!", floor (_timerSeconds / 60)]
} else {
	"You have been taken HOSTAGE! Stay still — move and the guards will shoot!"
};
[_timerHint] remoteExec ["hint", _hostage];

// Spawn guard ring (6–8 guards)
private _guardCount = 6 + floor random 3;
private _guardGroup = createGroup [EAST, true];
private _guards = [];

for "_i" from 0 to (_guardCount - 1) do {
	private _angle = (_i / _guardCount) * 360;
	private _offsetX = 10 * sin _angle;
	private _offsetY = 10 * cos _angle;
	private _guardPos = [(_rescuePos select 0) + _offsetX, (_rescuePos select 1) + _offsetY, 0];

	// Use faction-appropriate infantry class
	private _factionParam = "HOSTILE_FACTION" call BIS_fnc_getParamValue;
	private _guardClass = switch (_factionParam) do {
		case 7: { selectRandom ["vn_o_nva_inf_rifleman_01", "vn_o_vc_inf_guerrilla_01"] };
		case 1: { "CUP_O_RU_Soldier" };
		case 2: { "rhs_msv_rifleman" };
		case 6: { "gm_gc_army_rifleman" };
		case 8: { "CSLA_Soldier_base" };
		default { "O_Soldier_F" };
	};

	// Validate classname; fall back to vanilla
	if !(isClass (configFile >> "CfgVehicles" >> _guardClass)) then {
		_guardClass = "O_Soldier_F";
	};

	private _guard = _guardGroup createUnit [_guardClass, _guardPos, [], 0, "FORM"];
	_guard setBehaviour "CARELESS";
	_guard setCombatMode "YELLOW";
	_guard doWatch _hostage;
	_hostage reveal [_guard, 4];
	mainZeus addCuratorEditableObjects [[_guard], true];
	_guards pushBack _guard;
};

// Map marker visible to all
private _markerName = "hostageMarker";
createMarker [_markerName, _rescuePos];
_markerName setMarkerType "mil_objective";
_markerName setMarkerColor "ColorRed";
_markerName setMarkerText "HOSTAGE";

// Notify all players
["SpecialWarning", [format ["%1 HAS BEEN TAKEN HOSTAGE! Find and rescue them!", name _hostage]]] remoteExec ["BIS_fnc_showNotification", 0];

// Monitor rescue condition — includes execution timer
[_guards, _hostage, _markerName, hostageLoadout, _timerSeconds] spawn {
	params ["_guards", "_hostage", "_markerName", "_savedLoadout", "_timeLimit"];

	private _elapsed = 0;
	private _executed = false;

	waitUntil {
		sleep 3;
		_elapsed = _elapsed + 3;

		// Timer active: warn at 60s, execute at limit
		if (_timeLimit > 0) then {
			if (_elapsed == _timeLimit - 60) then {
				["SpecialWarning", ["60 SECONDS — the hostage will be EXECUTED!"]] remoteExec ["BIS_fnc_showNotification", 0];
			};
			if (_elapsed >= _timeLimit) then {
				_executed = true;
			};
		};

		({alive _x} count _guards == 0) || {!alive _hostage} || _executed
	};

	deleteMarker _markerName;

	if (_executed) then {
		if (alive _hostage) then { _hostage setDamage 1; };
		["SpecialWarning", [format ["%1 was EXECUTED — time ran out!", name _hostage]]] remoteExec ["BIS_fnc_showNotification", 0];
	} else if (alive _hostage) then {
		// Rescued!
		_hostage setUnitLoadout _savedLoadout;
		["TaskSucceeded", ["RESCUED!", format ["%1 has been rescued!", name _hostage]]] remoteExec ["BIS_fnc_showNotification", 0];
		// Award points to nearby rescuers (within 50m)
		{
			if (side _x == west && _x != _hostage && (_x distance _hostage < 50)) then {
				[_x, 50] call killPoints_fnc_add;
			};
		} forEach allPlayers;
	} else {
		["SpecialWarning", [format ["%1 was killed — the hostage is lost.", name _hostage]]] remoteExec ["BIS_fnc_showNotification", 0];
	};

	hostageWave = false;
	publicVariable "hostageWave";
};
