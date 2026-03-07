/**
*  fn_startWave
*
*  starts a new Wave
*
*  Domain: Server
**/


["Terminate"] remoteExec ["BIS_fnc_EGSpectator", 0];
[] remoteExec ["killPoints_fnc_updateHud", 0];

for ("_i") from 0 to 14 do {
	if(_i > 10) then {"beep_target" remoteExec ["playsound", 0];} else {"readoutClick" remoteExec ["playsound", 0];};
	[format ["<t>%1</t>", 15-_i], 0, 0, 1, 0] remoteExec ["BIS_fnc_dynamicText", 0];
	sleep 1;
};

// Delete
_final = waveUnits select ("BODY_CLEANUP" call BIS_fnc_getParamValue);
{deleteVehicle _x} foreach _final;
// Shuffle
waveUnits set [2, waveUnits select 1];
waveUnits set [1, waveUnits select 0];
waveUnits set [0, []];

playersInWave = [];
_allHCs = entities "HeadlessClient_F";
_allHPs = allPlayers - _allHCs;
{ playersInWave pushBack getPlayerUID _x; } foreach _allHPs;
publicVariable "playersInWave";

attkWave = (attkWave + 1);
publicVariable "attkWave";

waveSpawned = false;

//If last wave was a night time wave then skip back to the time it was previously
if(!isNil "nightWave") then {
	if (nightWave) then {
		skipTime currentTime;
	};
};

// Restore fog to mission weather level (fogWave will override this below if active)
private _missionFog = switch (if (!isNil "MISSION_WEATHER") then { MISSION_WEATHER } else { 0 }) do {
	case 3: { 0.65 }; // Foggy
	case 4: { 0.15 }; // Storm
	default { 0 };
};
15 setFog _missionFog;

[] remoteExec ["killPoints_fnc_updateHud", 0];

_respawnTickets = [west] call BIS_fnc_respawnTickets;
if (_respawnTickets <= 0) then {
	RESPAWN_TIME = 99999;
	publicVariable "RESPAWN_TIME";
};
[RESPAWN_TIME] remoteExec ["setPlayerRespawnTime", 0];

bulwarkBox setVariable ["buildPhase", false, true];

//determine if Special wave

if (attkWave < 10) then {
	randSpecChance = 4;
	maxSinceSpecial = 4;
	maxSpecialLimit = 1;
};

if (attkWave >= 10 && attkWave < 15) then {
	randSpecChance = 3;
	maxSinceSpecial = 3;
	maxSpecialLimit = 1;
};

if (attkWave >= 15) then {
	randSpecChance = 2;
	maxSinceSpecial = 2;
	maxSpecialLimit = 0;
};

if ((floor random randSpecChance == 1 || wavesSinceSpecial >= maxSinceSpecial) && attkWave >= 5 && wavesSinceSpecial >= maxSpecialLimit) then {
	specialWave = true;
}else{
	wavesSinceSpecial = wavesSinceSpecial + 1;
	specialWave = false;
};

SpecialWaveType = "";
droneCount = 0;

if (specialWave && attkWave >= 5 and attkWave < 10) then {
	SpecialWaveType = selectRandom ["specCivs", "fogWave", "swticharooWave"];
	wavesSinceSpecial = 0;
};

if (specialWave && attkWave >= 10) then {
	private _wavePool = [
		"specCivs", "fogWave", "swticharooWave", "suicideWave",
		"specMortarWave", "nightWave", "demineWave", "defectorWave"
	];
	if ("HOSTAGE_WAVE" call BIS_fnc_getParamValue == 1) then {
		_wavePool pushBack "hostageWave";
	};
	if ("AIRBORNE_WAVE" call BIS_fnc_getParamValue == 1) then {
		_wavePool pushBack "airborneWave";
	};
	if ("BOMB_WAVE" call BIS_fnc_getParamValue == 1) then {
		_wavePool pushBack "bombWave";
	};
	SpecialWaveType = selectRandom _wavePool;
	wavesSinceSpecial = 0;
//}else{
	//SpecialWaveType = "airborneWave"; //else for testing new special waves: do not remove
};

if (SpecialWaveType == "suicideWave") then {
	suicideWave = true;
	execVM "hostiles\suicideWave.sqf";
	execVM "hostiles\suicideAudio.sqf";
} else {
	suicideWave = false;
};

if (SpecialWaveType == "specMortarWave") then {
	specMortarWave = true;
	[] execVM "hostiles\specMortar.sqf";
}else{
	specMortarWave = false;
};

if (SpecialWaveType == "specCivs") then {
	specCivs = true;
	[] execVM "hostiles\civWave.sqf";
}else{
	specCivs = false;
};

if (SpecialWaveType == "nightWave") then {
	nightWave = true;
	currentTime = daytime;
	skipTime (24 - currentTime);
}else{
	nightWave = false;
};

if (SpecialWaveType == "fogWave") then {
	fogWave = true;
	15 setFog 1;
}else{
	fogWave = false;
};

if (SpecialWaveType == "swticharooWave") then {
	swticharooWave = true;
	execVM "hostiles\specSwticharooWave.sqf";
}else{
	swticharooWave = false;
};

if (SpecialWaveType == "demineWave") then {
	demineWave = true;
	execVM "hostiles\spawnHelicopterWave.sqf";
}else{
	demineWave = false;
};

if (SpecialWaveType == "defectorWave") then {
	defectorWave = true;
}else{
	defectorWave = false;
};

if (SpecialWaveType == "hostageWave") then {
	hostageWave = true;
	hostageUnit = objNull;
	[] execVM "hostiles\hostageWave.sqf";
} else {
	hostageWave = false;
};

if (SpecialWaveType == "airborneWave") then {
	airborneWave = true;
	[] execVM "hostiles\airborneWave.sqf";
} else {
	airborneWave = false;
};

if (SpecialWaveType == "bombWave") then {
	bombWave = true;
	[] execVM "hostiles\bombWave.sqf";
} else {
	bombWave = false;
};

//Notify start of wave and type of wave
if (suicideWave) then {
	["SpecialWarning",["SUICIDE BOMBERS! Don't Let Them Get Close!"]] remoteExec ["BIS_fnc_showNotification", 0];
	["Alarm"] remoteExec ["playSound", 0];
};

if (specMortarWave) then {
	["SpecialWarning",["MORTAR! FIND IT BEFORE IT DESTROYS THE BULWARK!"]] remoteExec ["BIS_fnc_showNotification", 0];
	["Alarm"] remoteExec ["playSound", 0];
};

if (specCivs) then {
	["SpecialWarning",["CIVILIANS Are Fleeing! Don't Shoot Them!"]] remoteExec ["BIS_fnc_showNotification", 0];
	["Alarm"] remoteExec ["playSound", 0];
};

if (nightWave) then {
	["SpecialWarning",["They mostly come at night. Mostly..."]] remoteExec ["BIS_fnc_showNotification", 0];
	["Alarm"] remoteExec ["playSound", 0];
};

if (fogWave) then {
	["SpecialWarning",["A dense fog is rolling in!"]] remoteExec ["BIS_fnc_showNotification", 0];
	["Alarm"] remoteExec ["playSound", 0];
};

if (swticharooWave) then {
	["SpecialWarning",["You were overrun! Take back the bulwark!! Quickly!"]] remoteExec ["BIS_fnc_showNotification", 0];
	["Alarm"] remoteExec ["playSound", 0];
	_secCount = 0;
	_deadUnconscious = [];
	sleep 1;
	while {EAST countSide allUnits > 0} do {
		_allHCs = entities "HeadlessClient_F";
		_allHPs = allPlayers - _allHCs;
		{
			if ((!alive _x) || ((lifeState _x) == "INCAPACITATED")) then {
				_deadUnconscious pushBack _x;
			};
		} foreach _allHPs;
		_respawnTickets = [west] call BIS_fnc_respawnTickets;
		if (count (_allHPs - _deadUnconscious) <= 0 && _respawnTickets <= 0) then {
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
					missionFailure = true;
				};
			};
		};
	};
};

if (demineWave) then {
	["SpecialWarning",["ATTACK HELICOPTERS! Incoming air attack!"]] remoteExec ["BIS_fnc_showNotification", 0];
	["Alarm"] remoteExec ["playSound", 0];
};

if (defectorWave) then {
	["SpecialWarning",["NATO Defectors Are Attacking Us!"]] remoteExec ["BIS_fnc_showNotification", 0];
	["Alarm"] remoteExec ["playSound", 0];
};

if (hostageWave) then {
	["Alarm"] remoteExec ["playSound", 0];
	// Notification with player name is sent inside hostageWave.sqf after the hostage is chosen
};

if (airborneWave) then {
	["SpecialWarning", ["AIRBORNE ASSAULT! Enemy forces inbound by air!"]] remoteExec ["BIS_fnc_showNotification", 0];
	["Alarm"] remoteExec ["playSound", 0];
};

if (bombWave) then {
	["Alarm"] remoteExec ["playSound", 0];
	// Full notification with timer is sent inside bombWave.sqf
};

if (!specialWave) then {
	["TaskAssigned",["In-coming","Wave " + str attkWave]] remoteExec ["BIS_fnc_showNotification", 0];
};

{
	if (!alive _x) then {
		deleteVehicle _x;
	};
} foreach allMissionObjects "LandVehicle";

{
	if (!alive _x) then {
		deleteVehicle _x;
	};
} foreach allMissionObjects "Air";

// Spawn
_createHostiles = execVM "hostiles\createWave.sqf";
waitUntil {scriptDone _createHostiles};

if (attkWave > 1) then { //if first wave give player extra time before spawning enemies
	{deleteMarker _x} foreach lootDebugMarkers;
	[] call loot_fnc_cleanup;
	_spawnLoot = execVM "loot\spawnLoot.sqf";
	waitUntil { scriptDone _spawnLoot};
};

// Enemy special abilities (wave 10+): ~30% chance of airstrike and/or rocket barrage
if (attkWave >= 10) then {
	if (random 1 < 0.30) then {
		[] spawn {
			sleep (30 + random 60);
			execVM "hostiles\enemyAirstrike.sqf";
		};
	};
	if (random 1 < 0.30) then {
		[] spawn {
			sleep (20 + random 40);
			execVM "hostiles\enemyRocketStrike.sqf";
		};
	};
};
