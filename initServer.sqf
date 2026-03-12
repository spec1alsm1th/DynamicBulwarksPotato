// variable to prevent players rejoining during a wave
playersInWave = [];
publicVariable "playersInWave";

// Bulwark position chosen by host/admin (published from pickBulwarkPos.sqf)
DB_specBulwarkPos = [];
publicVariable "DB_specBulwarkPos";

["<t size = '.5'>Loading lists.<br/>Please wait...</t>", 0, 0, 10, 0] remoteExec ["BIS_fnc_dynamicText", 0];
_hLocation = [] execVM "locationLists.sqf";
_hLoot     = [] execVM "loot\lists.sqf";
_hHostiles = [] execVM "hostiles\lists.sqf";
waitUntil {
    scriptDone _hLocation &&
    scriptDone _hLoot &&
    scriptDone _hHostiles
};
_hConfig   = [] execVM "editMe.sqf";
waitUntil { scriptDone _hConfig };

// Wait for host/admin to pick bulwark position (only needed when using List_SpecificPoint)
private _t0 = time;
waitUntil {
    ((DB_specBulwarkPos isEqualType [] && {count DB_specBulwarkPos == 3}) ) || ((time - _t0) > 300)
};

if (DB_specBulwarkPos isEqualType [] && {count DB_specBulwarkPos == 3}) then {
    private _pos = DB_specBulwarkPos;

    if (getMarkerColor "specBulwarkLoc" == "") then {
        createMarker ["specBulwarkLoc", _pos];
        "specBulwarkLoc" setMarkerType "mil_dot";
        "specBulwarkLoc" setMarkerText "Bulwark Location";
    };
    "specBulwarkLoc" setMarkerPos _pos;
};

["<t size = '.5'>Creating Base...</t>", 0, 0, 30, 0] remoteExec ["BIS_fnc_dynamicText", 0];
_basepoint = [] execVM "bulwark\createBase.sqf";
waitUntil { scriptDone _basepoint };

["<t size = '.5'>Ready</t>", 0, 0, 0.5, 0] remoteExec ["BIS_fnc_dynamicText", 0];

publicVariable "bulwarkBox";
publicVariable "PARATROOP_CLASS";
publicVariable "BULWARK_SUPPORTITEMS";
publicVariable "BULWARK_BUILDITEMS";
publicVariable "PLAYER_STARTWEAPON";
publicVariable "PLAYER_STARTMAP";
publicVariable "PLAYER_STARTNVG";
publicVariable "ENGINEER_TOOLKIT";
publicVariable "BULWARK_RADIUS";
publicVariable "PISTOL_HOSTILES";
publicVariable "DOWN_TIME";
publicVariable "RESPAWN_TICKETS";
publicVariable "RESPAWN_TIME";
publicVariable "PLAYER_OBJECT_LIST";
publicVariable "MIND_CONTROLLED_AI";
publicVariable "SCORE_RANDOMBOX";

//determine if Support Menu is available
_supportParam = ("SUPPORT_MENU" call BIS_fnc_getParamValue);
if (_supportParam == 1) then {
  SUPPORTMENU = false;
}else{
  SUPPORTMENU = true;
};
publicVariable 'SUPPORTMENU';

//Determine team damage Settings
_teamDamageParam = ("TEAM_DAMAGE" call BIS_fnc_getParamValue);
if (_teamDamageParam == 0) then {
  TEAM_DAMAGE = false;
}else{
  TEAM_DAMAGE = true;
};
publicVariable 'TEAM_DAMAGE';

//determine if hitmarkers appear on HUD
HITMARKERPARAM = ("HUD_POINT_HITMARKERS" call BIS_fnc_getParamValue);
publicVariable 'HITMARKERPARAM';

// Time of day (TIME_OF_DAY param: 7=Morning, 12=Day, 15=Afternoon, 19=Evening, 2=Night, -1=Random)
private _todParam = "TIME_OF_DAY" call BIS_fnc_getParamValue;
private _timeToSet = if (_todParam == -1) then { 6 + floor random 16 } else { _todParam };
setDate [2018, 7, 1, _timeToSet, 0];

// Weather (WEATHER param: 0=Clear, 1=Overcast, 2=Rainy, 3=Foggy, 4=Storm, -1=Random)
private _weatherParam = "WEATHER" call BIS_fnc_getParamValue;
if (_weatherParam == -1) then { _weatherParam = floor random 5; };
MISSION_WEATHER = _weatherParam;
publicVariable "MISSION_WEATHER";

switch (_weatherParam) do {
	case 0: { // Clear
		0 setOvercast 0;
		0 setRain 0;
		0 setFog 0;
		setWind [0, 0];
	};
	case 1: { // Overcast
		0 setOvercast 0.65;
		0 setRain 0;
		0 setFog 0;
	};
	case 2: { // Rainy
		0 setOvercast 0.85;
		0 setRain 0.4;
		0 setFog 0.1;
		setWind [3, 3];
	};
	case 3: { // Foggy
		0 setOvercast 0.3;
		0 setRain 0;
		0 setFog 0.65;
	};
	case 4: { // Storm
		0 setOvercast 1;
		0 setRain 0.8;
		0 setFog 0.15;
		setWind [8, 8];
	};
};

[] execVM "revivePlayers.sqf";
[bulwarkRoomPos] execVM "missionLoop.sqf";

[] execVM "area\areaEnforcement.sqf";
[] execVM "hostiles\clearStuck.sqf";
//[] execVM "hostiles\solidObjects.sqf";
[] execVM "hostiles\moveHosToPlayer.sqf";
