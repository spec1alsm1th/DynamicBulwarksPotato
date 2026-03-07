/**
*  hostiles/lists
*
*  Populates global arrays with various unit types
*
*  Domain: Server
**/

_zombieSpider = [];
_zombiePlayer = [];
_zombieCrawler = [];
_zombieFast = [];
_zombieMedium = [];
_zombieSlow = [];
_zombieBoss = [];
_zombieWalker = [];

_count =  count (configFile >> "CfgVehicles");
for "_x" from 0 to (_count-1) do {
    _item=((configFile >> "CfgVehicles") select _x);
    if (isClass _item) then {
        if (getnumber (_item >> "scope") == 2) then {
            if (gettext (_item >> "vehicleClass") == "Ryanzombiesspider") then {
                _zombieSpider = _zombieSpider + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "Ryanzombiesplayer") then {
                _zombiePlayer = _zombiePlayer + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "RyanzombiesCrawler") then {
                _zombieCrawler = _zombieCrawler + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "Ryanzombiesfast") then {
                _zombieFast = _zombieFast + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "Ryanzombiesslow") then {
                _zombieSlow = _zombieSlow + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "Ryanzombiesmedium") then {
                _zombieMedium = _zombieMedium + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "Ryanzombiesboss") then {
                _zombieBoss = _zombieBoss + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "Ryanzombieswalker") then {
                _zombieWalker = _zombieWalker + [configname _item]
            };
        };
    };
};

List_ZombieSpider = _zombieSpider;
List_ZombiePlayer = _zombiePlayer;
List_ZombieCrawler = _zombieCrawler;
List_ZombieFast = _zombieFast;
List_ZombieMedium = _zombieMedium;
List_ZombieSlow = _zombieSlow;
List_ZombieBoss = _zombieBoss;
List_ZombieWalker = _zombieWalker;

_bandits = [];
_groupConfig = configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "BanditCombatGroup";
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=((_groupConfig) select _x);
    if (isClass _item) then {
		_bandits pushback getText (_item >> "vehicle");
    };
};
List_Bandits = _bandits;

_paraBandits = [];
_groupConfig = configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "ParaCombatGroup";
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=((_groupConfig) select _x);
    if (isClass _item) then {
		_paraBandits pushback getText (_item >> "vehicle");
    };
};
List_ParaBandits = _paraBandits;

// Helper: extract unit classnames from a CfgGroups group config
_unitsFromGroup = {
    params ["_groupCfg"];
    private _units = [];
    private _cnt = count _groupCfg;
    for "_ui" from 0 to (_cnt - 1) do {
        private _item = _groupCfg select _ui;
        if (isClass _item) then {
            _units pushBack getText (_item >> "vehicle");
        };
    };
    _units
};

// Helper: extract units from a faction's category (collects ALL unique units from ALL groups)
// If the specified category doesn't exist or is empty, scans all categories in the faction
_unitsFromFaction = {
    params ["_side", "_faction", "_category", ["_preferredGroup", ""]];
    private _factionCfg = configfile >> "CfgGroups" >> _side >> _faction;
    private _units = [];

    if (!isClass _factionCfg) exitWith {
        diag_log format ["DynBulwarks: Faction %1 >> %2 not found in CfgGroups", _side, _faction];
        []
    };

    private _catCfg = _factionCfg >> _category;

    if (isClass _catCfg) then {
        // Category found - extract units from ALL groups in the category
        for "_g" from 0 to (count _catCfg - 1) do {
            private _groupCfg = _catCfg select _g;
            if (isClass _groupCfg) then {
                private _groupUnits = [_groupCfg] call _unitsFromGroup;
                { _units pushBackUnique _x } forEach _groupUnits;
            };
        };
    };

    // If category not found or empty, scan ALL categories in the faction
    if (count _units == 0) then {
        diag_log format ["DynBulwarks: Category '%1' not found or empty in %2 >> %3, scanning all categories", _category, _side, _faction];
        for "_ci" from 0 to (count _factionCfg - 1) do {
            private _cat = _factionCfg select _ci;
            if (isClass _cat) then {
                for "_gi" from 0 to (count _cat - 1) do {
                    private _groupCfg = _cat select _gi;
                    if (isClass _groupCfg) then {
                        private _groupUnits = [_groupCfg] call _unitsFromGroup;
                        { _units pushBackUnique _x } forEach _groupUnits;
                    };
                };
            };
        };
    };

    diag_log format ["DynBulwarks: _unitsFromFaction [%1,%2,%3] found %4 units", _side, _faction, _category, count _units];
    _units
};

// Helper: check if a faction exists in CfgGroups
_isFactionLoaded = {
    params ["_side", "_faction"];
    isClass (configfile >> "CfgGroups" >> _side >> _faction)
};

// Helper: try multiple possible faction classnames, return first match as [side, faction]
// Returns ["",""] if none found
// NOTE: pass array directly, e.g. [[side,faction],[side,faction]] call _tryFindFaction
_tryFindFaction = {
    private _candidates = _this;
    private _result = ["", ""];
    {
        if ([_x select 0, _x select 1] call _isFactionLoaded) exitWith {
            _result = _x;
        };
    } forEach _candidates;
    _result
};

// Read faction parameter (0 = Vanilla, 1 = CUP, 2 = RHS, 3 = Apex, etc.)
private _factionParam = ["HOSTILE_FACTION", 0] call BIS_fnc_getParamValue;
diag_log format ["DynBulwarks: HOSTILE_FACTION parameter = %1", _factionParam];

// --- Vanilla defaults ---
private _vanillaOPFOR = { [configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSquad"] call _unitsFromGroup };
private _vanillaINDEP = { [configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad"] call _unitsFromGroup };
private _vanillaNATO  = { [configfile >> "CfgGroups" >> "West" >> "BLU_F" >> "Infantry" >> "BUS_InfSquad"] call _unitsFromGroup };
private _vanillaViper = { [configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "SpecOps" >> "OI_ViperTeam"] call _unitsFromGroup };

// Initialize lists as empty - will be populated by CfgGroups or CfgVehicles fallback
List_OPFOR = [];
List_Viper = [];
List_INDEP = [];
List_NATO  = [];

switch (_factionParam) do {
    case 1: {
        // CUP factions
        if (["East", "CUP_O_TK"] call _isFactionLoaded) then {
            diag_log "DynBulwarks: Using CUP factions (CfgGroups)";
            List_OPFOR = ["East", "CUP_O_TK", "Infantry", ""] call _unitsFromFaction;
            List_Viper = ["East", "CUP_O_RU", "Infantry", ""] call _unitsFromFaction;
            List_INDEP = ["East", "CUP_O_ChDKZ", "Infantry", ""] call _unitsFromFaction;
            List_NATO = ["West", "CUP_B_US", "Infantry", ""] call _unitsFromFaction;
        } else {
            diag_log "DynBulwarks: CUP CfgGroups not found, will try CfgVehicles scan";
        };
    };
    case 2: {
        // RHS factions
        if (["East", "rhs_faction_msv"] call _isFactionLoaded) then {
            diag_log "DynBulwarks: Using RHS factions (CfgGroups)";
            List_OPFOR = ["East", "rhs_faction_msv", "rhs_group_rus_msv_infantry", ""] call _unitsFromFaction;
            List_Viper = ["East", "rhs_faction_vdv", "rhs_group_rus_vdv_infantry", ""] call _unitsFromFaction;
            List_INDEP = List_OPFOR + List_Viper;
            List_NATO = ["West", "rhs_faction_usarmy_d", "rhs_group_nato_usarmy_d_infantry", ""] call _unitsFromFaction;
        } else {
            diag_log "DynBulwarks: RHS CfgGroups not found, will try CfgVehicles scan";
        };
    };
    case 3: {
        // Apex DLC - CSAT Pacific / Viper
        if (["East", "OPF_T_F"] call _isFactionLoaded) then {
            diag_log "DynBulwarks: Using Apex factions (CfgGroups)";
            List_OPFOR = ["East", "OPF_T_F", "Infantry", ""] call _unitsFromFaction;
            List_Viper = ["East", "OPF_T_F", "SpecOps", ""] call _unitsFromFaction;
            List_INDEP = List_OPFOR + List_Viper;
            List_NATO = ["West", "BLU_T_F", "Infantry", ""] call _unitsFromFaction;
        } else {
            diag_log "DynBulwarks: Apex CfgGroups not found, will try CfgVehicles scan";
        };
    };
    case 4: {
        // Contact DLC - Livonian Defense Force
        if (["Indep", "IND_E_F"] call _isFactionLoaded) then {
            diag_log "DynBulwarks: Using Contact factions (CfgGroups)";
            List_OPFOR = ["Indep", "IND_E_F", "Infantry", ""] call _unitsFromFaction;
            List_Viper = ["Indep", "IND_E_F", "SpecOps", ""] call _unitsFromFaction;
            List_INDEP = List_OPFOR;
            List_NATO = call _vanillaNATO;
        } else {
            diag_log "DynBulwarks: Contact CfgGroups not found, will try CfgVehicles scan";
        };
    };
    case 5: {
        // Western Sahara CDLC - Tura / Sefrawi / ION PMC
        if (["East", "OPF_W_F"] call _isFactionLoaded) then {
            diag_log "DynBulwarks: Using Western Sahara factions (CfgGroups)";
            List_OPFOR = ["East", "OPF_W_F", "Infantry", ""] call _unitsFromFaction;
            List_Viper = ["Indep", "IND_W_F", "Infantry", ""] call _unitsFromFaction;
            List_INDEP = List_OPFOR + List_Viper;
            List_NATO = ["West", "BLU_W_F", "Infantry", ""] call _unitsFromFaction;
        } else {
            diag_log "DynBulwarks: Western Sahara CfgGroups not found, will try CfgVehicles scan";
        };
    };
    case 6: {
        // Global Mobilization CDLC - East German Army
        private _gmEast = [["East","gm_gc"],["East","gm_gc_army"],["East","gm_gc_mil"]] call _tryFindFaction;
        if ((_gmEast select 1) != "") then {
            diag_log format ["DynBulwarks: Using Global Mobilization factions (CfgGroups, East=%1)", _gmEast select 1];
            List_OPFOR = [_gmEast select 0, _gmEast select 1, "Infantry", ""] call _unitsFromFaction;
            List_Viper = List_OPFOR;
            List_INDEP = List_OPFOR;
            private _gmWest = [["West","gm_ge"],["West","gm_ge_army"],["West","gm_ge_mil"]] call _tryFindFaction;
            if ((_gmWest select 1) != "") then {
                List_NATO = [_gmWest select 0, _gmWest select 1, "Infantry", ""] call _unitsFromFaction;
            };
        } else {
            diag_log "DynBulwarks: GM CfgGroups not found, will try CfgVehicles scan";
        };
    };
    case 7: {
        // S.O.G. Prairie Fire CDLC - PAVN / Viet Cong
        private _pavn = [["East","vn_o_pavn"],["East","O_PAVN"],["East","vn_o_army_pavn"]] call _tryFindFaction;
        if ((_pavn select 1) != "") then {
            diag_log format ["DynBulwarks: Using S.O.G. Prairie Fire factions (CfgGroups, PAVN=%1)", _pavn select 1];
            List_OPFOR = [_pavn select 0, _pavn select 1, "Infantry", ""] call _unitsFromFaction;
            private _vc = [["East","vn_o_vc"],["Indep","vn_i_vc"],["East","O_VC"]] call _tryFindFaction;
            if ((_vc select 1) != "") then {
                List_Viper = [_vc select 0, _vc select 1, "Infantry", ""] call _unitsFromFaction;
            } else {
                List_Viper = List_OPFOR;
            };
            List_INDEP = List_OPFOR + List_Viper;
            private _macv = [["West","vn_b_men"],["West","vn_b_men_sf"],["West","vn_b_macv"],["West","B_MACV"]] call _tryFindFaction;
            if ((_macv select 1) != "") then {
                List_NATO = [_macv select 0, _macv select 1, "Infantry", ""] call _unitsFromFaction;
            };
        } else {
            diag_log "DynBulwarks: SOG Prairie Fire CfgGroups not found, will try CfgVehicles scan";
        };
    };
    case 8: {
        // CSLA Iron Curtain CDLC - Czechoslovak People's Army
        private _csla = [["East","CSLA"],["East","csla_faction"],["East","csla"]] call _tryFindFaction;
        if ((_csla select 1) != "") then {
            diag_log format ["DynBulwarks: Using CSLA Iron Curtain factions (CfgGroups, faction=%1)", _csla select 1];
            List_OPFOR = [_csla select 0, _csla select 1, "Infantry", ""] call _unitsFromFaction;
            List_Viper = List_OPFOR;
            List_INDEP = List_OPFOR;
        } else {
            diag_log "DynBulwarks: CSLA CfgGroups not found, will try CfgVehicles scan";
        };
    };
    default {
        // Vanilla (CSAT / AAF / NATO / Viper)
        diag_log "DynBulwarks: Using Vanilla factions";
        List_OPFOR = call _vanillaOPFOR;
        List_Viper = call _vanillaViper;
        List_INDEP = call _vanillaINDEP;
        List_NATO  = call _vanillaNATO;
    };
};

// --- CfgVehicles fallback: scan for ALL infantry matching a side + classname prefix ---
// Uses the config "side" property (0=East, 1=West, 2=Indep, 3=Civ) and optional prefix filter
_scanInfantryBySide = {
    params ["_sideNum", "_prefix"];
    private _result = [];
    private _cfgVeh = configFile >> "CfgVehicles";
    private _prefixLen = count _prefix;
    for "_i" from 0 to (count _cfgVeh - 1) do {
        private _item = _cfgVeh select _i;
        if (isClass _item) then {
            if (getNumber (_item >> "scope") == 2 && {getNumber (_item >> "isMan") == 1} && {getNumber (_item >> "side") == _sideNum}) then {
                private _cn = configName _item;
                if (_prefixLen == 0 || {(toLower _cn) select [0, _prefixLen] == toLower _prefix}) then {
                    _result pushBack _cn;
                };
            };
        };
    };
    _result
};

// Faction prefix for classname filtering (broad: catches ALL units from the mod/DLC)
// side 0=East, 1=West, 2=Indep
private _factionScanParams = switch (_factionParam) do {
    //          [OPFOR side, OPFOR prefix,  Viper side, Viper prefix,  NATO side, NATO prefix]
    case 1: {  [0, "CUP_O_",              0, "CUP_O_",              1, "CUP_B_"] };
    case 2: {  [0, "rhs_",                0, "rhs_",                1, "rhs_"] };
    case 3: {  [0, "O_T_",                0, "O_T_",                1, "B_T_"] };
    case 4: {  [2, "I_E_",                2, "I_E_",                1, ""] };
    case 5: {  [0, "O_W_",                2, "I_W_",                1, "B_W_"] };
    case 6: {  [0, "gm_gc",               0, "gm_gc",               1, "gm_ge"] };
    case 7: {  [0, "vn_o_",               0, "vn_o_",               1, "vn_b_"] };
    case 8: {  [0, "csla_",               0, "csla_",               1, ""] };
    default {  [-1, "",                    -1, "",                   -1, ""] };
};

// Apply CfgVehicles fallback for empty lists (always runs for non-vanilla factions)
if (_factionParam != 0 && {(_factionScanParams select 0) >= 0}) then {
    if (count List_OPFOR == 0) then {
        diag_log "DynBulwarks: OPFOR list empty after CfgGroups, scanning CfgVehicles...";
        List_OPFOR = [_factionScanParams select 0, _factionScanParams select 1] call _scanInfantryBySide;
        diag_log format ["DynBulwarks: CfgVehicles scan found %1 OPFOR units", count List_OPFOR];
    };
    if (count List_Viper == 0) then {
        diag_log "DynBulwarks: Viper list empty after CfgGroups, scanning CfgVehicles...";
        List_Viper = [_factionScanParams select 2, _factionScanParams select 3] call _scanInfantryBySide;
        diag_log format ["DynBulwarks: CfgVehicles scan found %1 Viper units", count List_Viper];
        // If Viper still empty, reuse OPFOR
        if (count List_Viper == 0) then { List_Viper = List_OPFOR; };
    };
    if (count List_INDEP == 0) then {
        List_INDEP = List_OPFOR + List_Viper;
    };
    if (count List_NATO == 0 && {(_factionScanParams select 4) >= 0} && {(_factionScanParams select 5) != ""}) then {
        diag_log "DynBulwarks: NATO list empty after CfgGroups, scanning CfgVehicles...";
        List_NATO = [_factionScanParams select 4, _factionScanParams select 5] call _scanInfantryBySide;
        diag_log format ["DynBulwarks: CfgVehicles scan found %1 NATO units", count List_NATO];
    };
};

// Last resort: if still empty after faction-specific scan, use vanilla
if (count List_OPFOR == 0) then { diag_log "DynBulwarks: OPFOR list still empty, using vanilla fallback"; List_OPFOR = call _vanillaOPFOR; };
if (count List_Viper == 0) then { diag_log "DynBulwarks: Viper list still empty, using vanilla fallback"; List_Viper = call _vanillaViper; };
if (count List_INDEP == 0) then { diag_log "DynBulwarks: INDEP list empty, using vanilla fallback"; List_INDEP = call _vanillaINDEP; };
if (count List_NATO == 0)  then { diag_log "DynBulwarks: NATO list empty, using vanilla fallback";  List_NATO  = call _vanillaNATO; };

// Replace bandits/thugs with selected faction's regular infantry for non-vanilla factions
// Early waves are still easier due to AI skill scaling and pistol-only enforcement
if (_factionParam != 0) then {
    List_Bandits = List_OPFOR;
    List_ParaBandits = List_OPFOR;
    diag_log "DynBulwarks: Bandits replaced with faction infantry";
};

diag_log format ["DynBulwarks: List_Bandits=%1 List_OPFOR=%2 List_Viper=%3 List_INDEP=%4 List_NATO=%5", count List_Bandits, count List_OPFOR, count List_Viper, count List_INDEP, count List_NATO];

// Vehicle faction filter - uses LOOT_FACTION parameter
private _vehFactionParam = ["LOOT_FACTION", 0] call BIS_fnc_getParamValue;

// Handle "Match enemy faction" option (value 7)
if (_vehFactionParam == 7) then {
    _vehFactionParam = switch (_factionParam) do {
        case 1: { 2 };   // CUP enemies -> CUP vehicles
        case 2: { 3 };   // RHS enemies -> RHS vehicles
        case 6: { 4 };   // GM enemies -> GM vehicles
        case 7: { 5 };   // SOG enemies -> SOG vehicles
        case 8: { 6 };   // CSLA enemies -> CSLA vehicles
        default { 1 };   // Vanilla/Apex/Contact/WS -> Vanilla vehicles
    };
};

private _filterVehicles = _vehFactionParam != 0;

// Filter by classname prefix (uses classname string via _this)
private _passesVehFilter = switch (_vehFactionParam) do {
    case 1: {
        // Vanilla + official DLCs: exclude known mod/CDLC prefixes
        {
            private _n = toLower _this;
            !((_n select [0,4]) == "cup_") &&
            {!((_n select [0,3]) == "rhs")} &&
            {!((_n select [0,3]) == "gm_")} &&
            {!((_n select [0,3]) == "vn_")} &&
            {!((_n select [0,5]) == "csla_")}
        }
    };
    case 2: { { (toLower _this select [0,4]) == "cup_" } };
    case 3: { { (toLower _this select [0,3]) == "rhs" } };
    case 4: { { (toLower _this select [0,3]) == "gm_" } };
    case 5: { { (toLower _this select [0,3]) == "vn_" } };
    case 6: { { (toLower _this select [0,5]) == "csla_" } };
    default { { true } };
};

diag_log format ["DynBulwarks: Vehicle faction filter = %1 (filterActive = %2)", _vehFactionParam, _filterVehicles];

_armouredVehicles = [];
_cfgVehicles = configFile >> "CfgVehicles";
_entries = count _cfgVehicles;
_realentries = _entries - 1;
for "_x" from 0 to (_realentries) do {
  _checked_veh = _cfgVehicles select _x;
  _classname = configName _checked_veh;
  if (isClass _checked_veh) then { // CHECK IF THE SELECTED ENTRY IS A CLASS
    _vehclass = getText (_checked_veh >> "vehicleClass");
    _scope = getNumber (_checked_veh >> "scope");
    _simulation_paracheck = getText (_checked_veh >> "simulation");
    _actual_vehclass = getText (_checked_veh >> "vehicleClass");
    if (_vehclass == _vehClass && _scope != 0 && _simulation_paracheck != "parachute" && {count getArray (_checked_veh >> "artilleryAmmo") == 0} && _actual_vehclass == "Armored" && {!_filterVehicles || {_classname call _passesVehFilter}}) exitWith {
      _armouredVehicles pushback _classname;
    };
  };
};
List_Armour = _armouredVehicles;


_armedCars = [];
_cfgVehicles = configFile >> "CfgVehicles";
_entries = count _cfgVehicles;
_realentries = _entries - 1;
for "_x" from 0 to (_realentries) do {
  _checked_veh = _cfgVehicles select _x;
  _classname = configName _checked_veh;
  if (isClass _checked_veh) then {
    _vehclass = getText (_checked_veh >> "vehicleClass");
    _scope = getNumber (_checked_veh >> "scope");
    _simulation_paracheck = getText (_checked_veh >> "simulation");
    _actual_vehclass = getText (_checked_veh >> "vehicleClass");
    turretWeap = false;
    if (isClass (_checked_veh >> "Turrets")) then {
      _vechTurrets = _checked_veh >> "Turrets";
      for "_turretIter" from 0 to (count _vechTurrets - 1) do {
        _weapsOnTurret = _vechTurrets select _turretIter;
        if (!(getarray (_weapsOnTurret >> "weapons") isEqualTo [])) then {
          turretWeap = true;
        };
      };
    };
    if (_vehclass == _vehClass && _scope != 0 && _actual_vehclass == "Car" && turretWeap && {!_filterVehicles || {_classname call _passesVehFilter}}) exitWith {
      _armedCars pushback _classname;
    };
  };
};
List_ArmedCars = _armedCars;

// --- Mortar list (for special mortar wave) ---
// Scan CfgVehicles for static artillery matching the hostile faction
private _hostileClassFilter = switch (_factionParam) do {
    case 0: { { private _n = _this; (_n select [0,2]) == "O_" && {!((_n select [0,4]) == "O_T_")} && {!((_n select [0,4]) == "O_W_")} } };
    case 1: { { (toLower _this) select [0,4] == "cup_" } };
    case 2: { { (toLower _this) select [0,3] == "rhs" } };
    case 3: { { (_this select [0,4]) == "O_T_" } };
    case 4: { { (_this select [0,4]) == "I_E_" } };
    case 5: { { (_this select [0,4]) in ["O_W_"] } };
    case 6: { { (toLower _this) select [0,3] == "gm_" } };
    case 7: { { (toLower _this) select [0,3] == "vn_" } };
    case 8: { { (toLower _this) select [0,5] == "csla_" } };
    default { { true } };
};

_mortars = [];
for "_x" from 0 to (count _cfgVehicles - 1) do {
    _checked_veh = _cfgVehicles select _x;
    if (isClass _checked_veh) then {
        _classname = configName _checked_veh;
        if (getNumber (_checked_veh >> "scope") == 2) then {
            if (getText (_checked_veh >> "vehicleClass") == "Static") then {
                if (count getArray (_checked_veh >> "artilleryAmmo") > 0) then {
                    if (_classname call _hostileClassFilter) then {
                        _mortars pushBack _classname;
                    };
                };
            };
        };
    };
};
// Per-faction hardcoded fallback: tries known mortar classnames if the config scan found nothing.
// This handles mods/DLCs that don't define artilleryAmmo in the standard way.
// All candidates are verified with isClass before use so wrong guesses are silently skipped.
if (count _mortars == 0) then {
    private _candidates = switch (_factionParam) do {
        case 1: { ["CUP_O_2b14_82mm_RU", "CUP_I_2b14_82mm_NAPA"] };                              // CUP Russian 2B14
        case 2: { ["rhs_2b14_82mm_msv", "rhs_2b14_82mm_vdv"] };                                   // RHS AFRF 2B14
        case 3: { ["O_T_Mortar_01_F"] };                                                            // Apex CSAT Pacific
        case 4: { ["I_E_Mortar_01_F"] };                                                            // Contact LDF (confirmed in config)
        case 5: { ["O_W_Mortar_01_F"] };                                                            // Western Sahara
        case 6: { ["gm_gc_army_m37_82mm", "gm_gc_army_m43_120mm", "gm_pl_army_m37_82mm"] };       // Global Mobilization
        case 7: { ["vn_o_vc_static_mortar_type53", "vn_o_nva_65_static_mortar_type63"] };          // S.O.G. Prairie Fire
        case 8: { ["CSLA_M252", "csla_afmc_static_mortar_m252", "csla_static_m37_82mm"] };         // CSLA Iron Curtain
        default { [] };
    };
    _mortars = _candidates select { isClass (configFile >> "CfgVehicles" >> _x) };
    if (count _mortars > 0) then {
        diag_log format ["DynBulwarks: Mortar hardcoded fallback for faction %1: %2", _factionParam, _mortars];
    };
};
if (count _mortars == 0) then { _mortars = ["O_Mortar_01_F"]; };
List_Mortars = _mortars;
diag_log format ["DynBulwarks: List_Mortars=%1", List_Mortars];

// --- Hostile pistol (for early pistol-only waves) ---
// Scan CfgWeapons for handguns (type 2) matching the hostile faction prefix
private _pistolPrefix = switch (_factionParam) do {
    case 1: { "cup_" };
    case 2: { "rhs_" };
    case 3: { "" };      // Apex uses vanilla weapons
    case 4: { "" };      // Contact uses vanilla weapons
    case 5: { "" };      // Western Sahara uses vanilla weapons
    case 6: { "gm_" };
    case 7: { "vn_" };
    case 8: { "csla_" };
    default { "" };
};

HOSTILE_PISTOL = "hgun_P07_F";
HOSTILE_PISTOL_MAG = "16Rnd_9x21_Mag";

if (_pistolPrefix != "") then {
    private _pistols = [];
    private _cfgWeapons = configFile >> "CfgWeapons";
    for "_wi" from 0 to (count _cfgWeapons - 1) do {
        private _item = _cfgWeapons select _wi;
        if (isClass _item) then {
            private _cn = configName _item;
            if (getNumber (_item >> "scope") == 2 && {getNumber (_item >> "type") == 2}) then {
                if ((toLower _cn) select [0, count _pistolPrefix] == _pistolPrefix) then {
                    private _mags = getArray (_item >> "magazines");
                    if (count _mags > 0) then {
                        _pistols pushBack [_cn, _mags select 0];
                    };
                };
            };
        };
    };
    if (count _pistols > 0) then {
        private _picked = selectRandom _pistols;
        HOSTILE_PISTOL = _picked select 0;
        HOSTILE_PISTOL_MAG = _picked select 1;
    };
};
diag_log format ["DynBulwarks: HOSTILE_PISTOL=%1 MAG=%2", HOSTILE_PISTOL, HOSTILE_PISTOL_MAG];

// --- Support aircraft (for paratroop drop / supply drop) ---
// Find a faction-appropriate BLUFOR transport aircraft
// Aircraft prefix + side + min transportSoldier per faction
// Format: [prefix, side, minTransport]
private _aircraftParams = switch (_factionParam) do {
    case 1: { ["cup_b_",    1, 2] };    // CUP BLUFOR aircraft
    case 2: { ["rhs_",      1, 2] };    // RHS BLUFOR aircraft
    case 3: { ["B_T_",      1, 2] };    // Apex BLUFOR Pacific aircraft
    case 4: { ["",          -1, 0] };   // Contact - no faction aircraft, use vanilla
    case 5: { ["B_W_",      1, 1] };    // Western Sahara BLUFOR aircraft
    case 6: { ["gm_ge_",    1, 1] };    // GM West German aircraft
    case 7: { ["vn_b_air_", 1, 1] };    // SOG Prairie Fire BLUFOR aircraft
    case 8: { ["csla_",     1, 1] };    // CSLA aircraft
    default { ["",          -1, 0] };   // Vanilla - use default
};

SUPPORT_AIRCRAFT = "B_T_VTOL_01_vehicle_F";

private _aircraftPrefix = _aircraftParams select 0;
private _aircraftSide = _aircraftParams select 1;
private _aircraftMinTransport = _aircraftParams select 2;

if (_aircraftPrefix != "" && {_aircraftSide >= 0}) then {
    private _aircraft = [];
    for "_ai" from 0 to (count _cfgVehicles - 1) do {
        private _item = _cfgVehicles select _ai;
        if (isClass _item) then {
            private _cn = configName _item;
            if (getNumber (_item >> "scope") == 2 && {getNumber (_item >> "side") == _aircraftSide}) then {
                private _sim = getText (_item >> "simulation");
                if (_sim in ["airplaneX", "helicopterX", "helicopterRTD"]) then {
                    if ((toLower _cn) select [0, count _aircraftPrefix] == toLower _aircraftPrefix) then {
                        if (getNumber (_item >> "transportSoldier") > _aircraftMinTransport) then {
                            _aircraft pushBack _cn;
                        };
                    };
                };
            };
        };
    };
    if (count _aircraft > 0) then {
        SUPPORT_AIRCRAFT = selectRandom _aircraft;
    };
};
diag_log format ["DynBulwarks: SUPPORT_AIRCRAFT=%1", SUPPORT_AIRCRAFT];
