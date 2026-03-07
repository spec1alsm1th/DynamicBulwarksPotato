/**
*  spawnHelicopterWave
*
*  Spawns 4 faction-appropriate attack helicopters for the helicopter wave.
*  Replaces the old drone (demineWave) attack.
*
*  Domain: Server
**/

private _factionParam = ["HOSTILE_FACTION", 0] call BIS_fnc_getParamValue;

// Preferred attack helicopter classnames per faction (OPFOR/EAST side)
private _preferredHelis = switch (_factionParam) do {
    case 0: { ["O_Heli_Attack_02_F", "O_Heli_Attack_01_F"] };                                         // Vanilla CSAT
    case 1: { ["CUP_O_Mi24_V_Dynamic_RU", "CUP_O_Mi24_P_Dynamic_RU", "CUP_O_Ka50_RU"] };             // CUP Russian
    case 2: { ["RHS_Mi24P_vvs", "RHS_Mi35M_vvs", "RHS_Ka52_vvs"] };                                   // RHS AFRF
    case 3: { ["O_T_Heli_Attack_02_F", "O_T_Heli_Light_02_F"] };                                       // Apex CSAT Pacific
    case 4: { ["O_Heli_Attack_02_F", "O_Heli_Attack_01_F"] };                                          // Contact - fall back to vanilla CSAT
    case 5: { ["O_W_Heli_Attack_01_F", "O_Heli_Attack_02_F"] };                                        // Western Sahara
    case 6: { ["gm_gc_airforce_mi2urn", "gm_gc_airforce_mi2us"] };                                     // Global Mobilization (East German Mi-2)
    case 7: { ["vn_o_air_mi2_04_01", "vn_o_air_mi2_04_02", "vn_o_air_mi2_04_04"] };                   // S.O.G. Prairie Fire (PAVN Mi-2 armed, verified from OSAT)
    case 8: { ["CSLA_Mi24V"] };                                                                         // CSLA Iron Curtain
    default { ["O_Heli_Attack_02_F"] };
};

// Verify classnames actually exist in loaded config, keep valid ones only
private _validHelis = [];
{
    if (isClass (configFile >> "CfgVehicles" >> _x)) then {
        _validHelis pushBack _x;
    };
} forEach _preferredHelis;

// Fallback scan: find any armed EAST helicopter matching the faction prefix
if (count _validHelis == 0) then {
    private _prefix = toLower (switch (_factionParam) do {
        case 1: { "cup_o_" };
        case 2: { "rhs_" };
        case 3: { "o_t_heli" };
        case 5: { "o_w_heli" };
        case 6: { "gm_gc_" };
        case 7: { "vn_o_air" };
        case 8: { "csla_" };
        default { "o_heli" };
    });
    private _prefLen = count _prefix;
    private _cfgVeh = configFile >> "CfgVehicles";
    for "_vi" from 0 to (count _cfgVeh - 1) do {
        private _item = _cfgVeh select _vi;
        if (isClass _item) then {
            private _cn = configName _item;
            if (getNumber (_item >> "scope") == 2 && {getNumber (_item >> "side") == 0}) then {
                private _sim = getText (_item >> "simulation");
                if (_sim in ["helicopterX", "helicopterRTD"]) then {
                    if ((toLower _cn) select [0, _prefLen] == _prefix) then {
                        private _hasWeapon = false;
                        private _turrets = _item >> "Turrets";
                        if (isClass _turrets) then {
                            for "_ti" from 0 to (count _turrets - 1) do {
                                private _t = _turrets select _ti;
                                if (isClass _t && {!(getArray (_t >> "weapons") isEqualTo [])}) then {
                                    _hasWeapon = true;
                                };
                            };
                        };
                        if (_hasWeapon) then { _validHelis pushBackUnique _cn; };
                    };
                };
            };
        };
    };
};

// Last resort: vanilla CSAT attack helicopter
if (count _validHelis == 0) then {
    _validHelis = ["O_Heli_Attack_02_F"];
};

diag_log format ["DynBulwarks: helicopterWave using classes: %1", _validHelis];

// Spawn 4 attack helicopters
for "_i" from 1 to 4 do {
    private _spawnPos = [bulwarkCity, BULWARK_RADIUS + 200, BULWARK_RADIUS + 500, 0, 1] call BIS_fnc_findSafePos;
    private _spawnPosAir = [_spawnPos select 0, _spawnPos select 1, 120];
    private _heliClass = selectRandom _validHelis;
    private _heliGroup = createGroup [EAST, true];

    private _heliResult = [_spawnPosAir, 0, _heliClass, _heliGroup] call BIS_fnc_spawnVehicle;
    private _heli = _heliResult select 0;
    private _heliCrew = fullCrew _heli;

    // Fly to bulwark and attack
    private _wp = _heliGroup addWaypoint [position bulwarkBox, 0];
    _wp setWaypointType "SAD";
    (leader _heliGroup) flyInHeight 80;
    _heliGroup setCombatMode "RED";
    _heliGroup setBehaviour "COMBAT";

    mainZeus addCuratorEditableObjects [[_heli], true];

    // Kill point handlers on crew (pilots/gunners are the "units" that count for wave end)
    {
        private _crewUnit = _x select 0;
        _crewUnit addEventHandler ["Hit", killPoints_fnc_hit];
        _crewUnit addEventHandler ["Killed", killPoints_fnc_killed];
        _crewUnit setVariable ["killPointMulti", HOSTILE_ARMOUR_POINT_SCORE];
        unitArray = waveUnits select 0;
        unitArray append [_crewUnit];
    } forEach _heliCrew;

    sleep 1;
};
