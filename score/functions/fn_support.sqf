/**
*  fn_support
*
*  Event handler for supports/communications menu
*
*  Domain: Client/Event
**/

_player   = _this select 0;
_target   = _this select 1;
_type     = _this select 2;
_aircraft = if (!isNil "SUPPORT_AIRCRAFT") then { SUPPORT_AIRCRAFT } else { _this select 3 };

// Jammer wave: block all support calls until the jammer is destroyed
if (!isNil "jammerActive" && { jammerActive }) exitWith {
    ["JAMMER ACTIVE — destroy the enemy SIGINT jammer to restore supports!"] remoteExec ["hint", _player];
};

switch (_type) do {
    case ("paraTroop"): {
        [_player, _target, PARATROOP_COUNT, _aircraft, PARATROOP_CLASS] call supports_fnc_paraTroop;
    };
    case ("reconFlight"): {
        [_player, _target] call supports_fnc_reconFlight;
    };
    case ("airStrike"): {
        [_player, _target, _aircraft] call supports_fnc_airStrike;
    };
    case ("ragePack"): {
        // Ragepack is a local effect so it needs to be executed locally
        [] remoteExec ["supports_fnc_ragePack", _player];
    };
    case ("mineField"): {
    [_player, _target] call supports_fnc_mineField;
    };
    case ("telePlode"): {
    [_player] call supports_fnc_telePlode;
    };
    case ("landForces"): {
        [_player] call supports_fnc_landForces;
    };
    case ("tankSupport"): {
        [_player] call supports_fnc_tankSupport;
    };
    case ("artilleryBarrage"): {
        [_player, _target] call supports_fnc_artilleryBarrage;
    };
    case ("bombStrike"): {
        [_player, _target] call supports_fnc_bombStrike;
    };
    case ("skipWave"): {
        [_player] call supports_fnc_skipWave;
    };
    case ("restartLoop"): {
        [_player] call supports_fnc_restartLoop;
    };
};
