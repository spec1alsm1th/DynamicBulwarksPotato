/**
*  vipWave
*
*  A stranded friendly officer must be located, revived (stand within 5m for 5s),
*  then escorted back alive to the Bulwark.
*
*  Phase 1 — proximity rescue: player holds near VIP for 5 continuous seconds
*  Phase 2 — escort: VIP moves toward bulwark; players keep them alive
*  150 pts per player on successful extraction.
*
*  Domain: Server
**/

private _factionParam = "HOSTILE_FACTION" call BIS_fnc_getParamValue;
private _guardClass = switch (_factionParam) do {
	case 7: { selectRandom ["vn_o_nva_inf_rifleman_01", "vn_o_vc_inf_guerrilla_01"] };
	case 1: { "CUP_O_RU_Soldier" };
	case 2: { "rhs_msv_rifleman" };
	case 6: { "gm_gc_army_rifleman" };
	case 8: { "CSLA_Soldier_base" };
	default { "O_Soldier_F" };
};
if !(isClass (configFile >> "CfgVehicles" >> _guardClass)) then { _guardClass = "O_Soldier_F"; };

// VIP class — WEST officer
private _vipClass = "B_officer_F";
if !(isClass (configFile >> "CfgVehicles" >> _vipClass)) then { _vipClass = "B_Soldier_F"; };

// Spawn position 150–350m from bulwark
private _vipPos = [bulwarkCity, 150, 350, 5, 0, 10, 0] call BIS_fnc_findSafePos;
private _vipX = _vipPos select 0;
private _vipY = _vipPos select 1;

// Spawn VIP (WEST group, captive, immobile)
private _vipGroup = createGroup [WEST, true];
private _vip = _vipGroup createUnit [_vipClass, _vipPos, [], 0, "NONE"];
_vip disableAI "MOVE";
_vip setCaptive true;
_vip removeAllWeapons;
_vip removeAllItems;
_vip removeAllAssignedItems;
_vip setUnitPos "DOWN";
mainZeus addCuratorEditableObjects [[_vip], true];

// Spawn 5–7 EAST guards approaching the VIP
private _guardCount = 5 + floor (random 3);
for "_i" from 0 to (_guardCount - 1) do {
	private _angle = (_i / _guardCount) * 360;
	private _dist = 30 + floor (random 30);
	private _guardPos = [_vipX + _dist * sin _angle, _vipY + _dist * cos _angle, 0];
	private _gGrp = createGroup [EAST, true];
	private _guard = _gGrp createUnit [_guardClass, _guardPos, [], 0, "FORM"];
	_guard setBehaviour "COMBAT";
	_guard setCombatMode "RED";
	_guard doMove _vipPos;
	mainZeus addCuratorEditableObjects [[_guard], true];
	(waveUnits select 0) pushBack _guard;
};

// Map marker
createMarker ["vipMarker", _vipPos];
"vipMarker" setMarkerType "mil_medic";
"vipMarker" setMarkerColor "ColorGreen";
"vipMarker" setMarkerText "VIP";

// Monitoring script
[_vip, _vipGroup] spawn {
	params ["_v", "_vg"];

	// --- Phase 1: rescue ---
	private _rescued = false;
	private _rescueProgress = 0;
	private _activeRescuer = objNull;

	while { !_rescued } do {
		sleep 1;

		if (bulwarkBox getVariable ["buildPhase", false]) exitWith {
			deleteMarker "vipMarker";
			if (alive _v) then { deleteVehicle _v; };
			deleteGroup _vg;
			vipWave = false;
			publicVariable "vipWave";
		};

		if !(alive _v) exitWith {
			deleteMarker "vipMarker";
			["SpecialWarning", ["VIP KIA — the officer didn't make it."]] remoteExec ["BIS_fnc_showNotification", 0];
			vipWave = false;
			publicVariable "vipWave";
		};

		private _candidates = allPlayers select { alive _x && side _x == west && _x distance _v < 5 };
		private _near = if (count _candidates > 0) then { _candidates select 0 } else { objNull };

		if !(isNull _near) then {
			if (_near != _activeRescuer) then {
				_activeRescuer = _near;
				_rescueProgress = 0;
			};
			_rescueProgress = _rescueProgress + 1;
			[format ["Reviving officer... %1/5s — stay close!", _rescueProgress]] remoteExec ["hint", _activeRescuer];
			if (_rescueProgress >= 5) then {
				_rescued = true;
				_v enableAI "MOVE";
				_v setCaptive false;
				_v setUnitPos "UP";
				_v doMove bulwarkCity;
				deleteMarker "vipMarker";
				["SpecialWarning", ["OFFICER REVIVED! Escort them back to the Bulwark!"]] remoteExec ["BIS_fnc_showNotification", 0];
			};
		} else {
			if (_rescueProgress > 0 && !(isNull _activeRescuer)) then {
				["Revive interrupted — stay within 5m!"] remoteExec ["hint", _activeRescuer];
			};
			_rescueProgress = 0;
			_activeRescuer = objNull;
		};
	};

	// Bail if Phase 1 exited via buildPhase or VIP death
	if !(alive _v) exitWith {};
	if (bulwarkBox getVariable ["buildPhase", false]) exitWith {};

	// --- Phase 2: escort to bulwark ---
	while { true } do {
		sleep 3;

		// Keep VIP moving in case they stop
		if (alive _v) then { _v doMove bulwarkCity; };

		if !(alive _v) exitWith {
			["SpecialWarning", ["VIP KIA — the officer didn't make it."]] remoteExec ["BIS_fnc_showNotification", 0];
		};

		if (bulwarkBox getVariable ["buildPhase", false]) exitWith {
			if (alive _v) then { deleteVehicle _v; };
		};

		if (alive _v && _v distance bulwarkCity < BULWARK_RADIUS) exitWith {
			deleteVehicle _v;
			{
				if (alive _x && side _x == west) then { [_x, 150] call killPoints_fnc_add; };
			} forEach allPlayers;
			["SpecialWarning", ["VIP EXTRACTED! Officer secured — +150 pts each!"]] remoteExec ["BIS_fnc_showNotification", 0];
		};
	};

	vipWave = false;
	publicVariable "vipWave";
};
