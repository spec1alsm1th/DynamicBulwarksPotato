{
	[_x, false] remoteExec ["setUnconscious", 0];
	_x action ["CancelAction", _x];
	_x switchMove "PlayerStand";
	[ "#rev", 1, _x ] remoteExecCall ["BIS_fnc_reviveOnState", _x];
	_x setDamage 0;
}forEach allPlayers;

_downTime = ("DOWN_TIME" call BIS_fnc_getParamValue);
_specialWaves = ("SPECIAL_WAVES" call BIS_fnc_getParamValue);
_maxWaves = ("MAX_WAVES" call BIS_fnc_getParamValue);

_CenterPos = _this;
// Preserve attkWave on manual restart from Zeus console — only reset on a fresh mission start
if (isNil "attkWave" || { attkWave < 0 }) then { attkWave = 0; publicVariable "attkWave"; };
suicideWave = false;

waveUnits = [[],[],[]];
revivedPlayers = [];
MIND_CONTROLLED_AI = [];
wavesSinceArmour = 0;
wavesSinceCar = 0;
wavesSinceSpecial = 0;
SatUnlocks = [];
publicVariable 'SatUnlocks';

//spawn start loot
if (isServer) then {
	execVM "loot\spawnLoot.sqf";
};

diag_log format ["DynBulwarks: missionLoop — starting (attkWave=%1, maxWaves=%2, specialWaves=%3)", attkWave, _maxWaves, _specialWaves];
sleep 15;
runMissionLoop = true;
missionFailure = false;

// start in build phase
bulwarkBox setVariable ["buildPhase", true, true];

[west, RESPAWN_TICKETS] call BIS_fnc_respawnTickets;

while {runMissionLoop} do {

	//Reset the AI position checks
	AIstuckcheck = 0;
	AIStuckCheckArray = [];

	diag_log format ["DynBulwarks: missionLoop — entering wave loop (attkWave=%1, players=%2)", attkWave, count (allPlayers - entities "HeadlessClient_F")];
	[] call bulwark_fnc_startWave;

	// Staleness failsafe: track last EAST count and time to detect units stuck underground
	private _lastEastCount = EAST countSide allUnits;
	private _staleTimer = 0;

	while {runMissionLoop} do {

		sleep 1;

		// Get all human players in this wave cycle // moved to contain players that respawned in this wave
		_allHCs = entities "HeadlessClient_F";
		_allHPs = allPlayers - _allHCs;

		//Check if all hostiles dead
		if (EAST countSide allUnits == 0) exitWith {};

		// Staleness failsafe: if EAST count hasn't changed for 10 minutes, kill remaining units
		// (handles units clipped underground or otherwise inaccessible to Zeus/players)
		private _currentEastCount = EAST countSide allUnits;
		if (_currentEastCount < _lastEastCount) then {
			_lastEastCount = _currentEastCount;
			_staleTimer = 0;
		} else {
			_staleTimer = _staleTimer + 1;
			if (_staleTimer >= 600) then {
				diag_log format ["DynBulwarks: Staleness failsafe triggered — %1 EAST unit(s) stuck for 10 minutes, force-removing", _currentEastCount];
				{ if (side _x == east && alive _x) then { _x setDamage 1; }; } forEach allUnits;
				_staleTimer = 0;
			};
		};

		//check if all players dead or unconscious
		_deadUnconscious = [];
		{
			if ((!alive _x) || ((lifeState _x) == "INCAPACITATED")) then {
				_deadUnconscious pushBack _x;
			};
		} foreach _allHPs;
		_respawnTickets = [west] call BIS_fnc_respawnTickets;
		if (count (_allHPs - _deadUnconscious) <= 0 && _respawnTickets <= 0) then {
			diag_log format ["DynBulwarks: missionLoop — all players down (alive=%1, tickets=%2), checking for revival", count (_allHPs - _deadUnconscious), _respawnTickets];
			sleep 1;

			//Check that Players have not been revived
			_deadUnconscious = [];
			{
				if ((!alive _x) || ((lifeState _x) == "INCAPACITATED")) then {
					_deadUnconscious pushBack _x;
				};
			} foreach _allHPs;
			if (count (_allHPs - _deadUnconscious) <= 0 && _respawnTickets <= 0) then {
				sleep 1;
				if (count (_allHPs - _deadUnconscious) <= 0 && _respawnTickets <= 0) then {
					diag_log "DynBulwarks: missionLoop — mission failure triggered (End1)";
					runMissionLoop = false;
					missionFailure = true;
					"End1" call BIS_fnc_endMissionServer;
				};
			};
		};

		//Add objects to zeus
		{
			mainZeus addCuratorEditableObjects [[_x], true];
		} foreach _allHPs;
	};

	if(missionFailure) exitWith {};

	if (_maxWaves > 0 && {attkWave >= _maxWaves}) exitWith {
		diag_log format ["DynBulwarks: missionLoop — max waves reached (%1), ending mission (End2)", attkWave];
		"End2" call BIS_fnc_endMissionServer;
	};

	diag_log format ["DynBulwarks: missionLoop — wave %1 cleared, calling endWave", attkWave];
	[] call bulwark_fnc_endWave;

};
