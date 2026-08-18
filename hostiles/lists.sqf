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

// Enemy gear faction. _gearParam is the raw lobby value; it is read here so
// both the unit override below and the vehicle filter further down can see it.
private _gearParam = ["ENEMY_GEAR_FACTION", 0] call BIS_fnc_getParamValue;
diag_log format ["DynBulwarks: ENEMY_GEAR_FACTION parameter = %1", _gearParam];

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
        // CUP factions. Verified against CUP Units 1.19 configs: the Takistani
        // ARMY has no CfgGroups entry at all (cup_creatures_people_military_taki
        // ships no CfgGroups), and the US faction is CUP_B_US_Army, not CUP_B_US.
        // Both old names silently failed, dropping every CUP game to the
        // CfgVehicles prefix scan. Try real names in preference order instead.
        private _cupTK = [["East","CUP_O_TK"],["East","CUP_O_TK_MILITIA"],["East","CUP_O_TK_INS"]] call _tryFindFaction;
        if ((_cupTK select 1) != "") then {
            diag_log format ["DynBulwarks: Using CUP factions (CfgGroups, TK=%1)", _cupTK select 1];
            List_OPFOR = [_cupTK select 0, _cupTK select 1, "Infantry", ""] call _unitsFromFaction;
            List_Viper = ["East", "CUP_O_RU", "Infantry", ""] call _unitsFromFaction;
            List_INDEP = ["East", "CUP_O_ChDKZ", "Infantry", ""] call _unitsFromFaction;
            private _cupUS = [["West","CUP_B_US_Army"],["West","CUP_B_US"],["West","CUP_B_USMC"]] call _tryFindFaction;
            if ((_cupUS select 1) != "") then {
                List_NATO = [_cupUS select 0, _cupUS select 1, "Infantry", ""] call _unitsFromFaction;
            };
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

// --- Enemy gear faction: unit source override ---
// When ENEMY_GEAR_FACTION names a specific faction, enemy infantry comes from
// that faction's CfgGroups entry instead of the HOSTILE_FACTION selection.
// Units keep their own config loadouts, which is what preserves role kit.
// List_NATO and List_Defectors are deliberately untouched: friendly paratroops
// stay under FRIENDLY_FACTION's control.
if (_gearParam > 2) then {
    private _gearOPFOR = [];
    private _gearViper = [];
    switch (_gearParam) do {
        case 3: {   // CUP (all)
            private _tk = [["East","CUP_O_TK"],["East","CUP_O_TK_MILITIA"],["East","CUP_O_TK_INS"]] call _tryFindFaction;
            if ((_tk select 1) != "") then { _gearOPFOR = [_tk select 0, _tk select 1, "Infantry", ""] call _unitsFromFaction; };
            _gearViper = ["East", "CUP_O_RU", "Infantry", ""] call _unitsFromFaction;
        };
        case 4: {   // CUP - Takistani (the army has no CfgGroups; militia does)
            private _tk = [["East","CUP_O_TK"],["East","CUP_O_TK_MILITIA"],["East","CUP_O_TK_INS"]] call _tryFindFaction;
            if ((_tk select 1) != "") then { _gearOPFOR = [_tk select 0, _tk select 1, "Infantry", ""] call _unitsFromFaction; };
            _gearViper = _gearOPFOR;
        };
        case 5: {   // CUP - Russian
            _gearOPFOR = ["East", "CUP_O_RU", "Infantry", ""] call _unitsFromFaction;
            _gearViper = _gearOPFOR;
        };
        case 6: {   // CUP - ChDKZ
            _gearOPFOR = ["East", "CUP_O_ChDKZ", "Infantry", ""] call _unitsFromFaction;
            _gearViper = _gearOPFOR;
        };
        case 7: {   // RHS (all)
            _gearOPFOR = ["East", "rhs_faction_msv", "rhs_group_rus_msv_infantry", ""] call _unitsFromFaction;
            _gearViper = ["East", "rhs_faction_vdv", "rhs_group_rus_vdv_infantry", ""] call _unitsFromFaction;
        };
        case 8: {   // RHS - AFRF
            _gearOPFOR = ["East", "rhs_faction_msv", "rhs_group_rus_msv_infantry", ""] call _unitsFromFaction;
            _gearViper = ["East", "rhs_faction_vdv", "rhs_group_rus_vdv_infantry", ""] call _unitsFromFaction;
        };
        case 9: {   // RHS - USAF
            _gearOPFOR = ["West", "rhs_faction_usarmy_d", "rhs_group_nato_usarmy_d_infantry", ""] call _unitsFromFaction;
            _gearViper = _gearOPFOR;
        };
        case 10: {  // RHS - GREF
            private _gref = [["East","rhsgref_faction_chdkz"],["Indep","rhsgref_faction_nationalist"],["West","rhsgref_faction_cdf_ground"]] call _tryFindFaction;
            if ((_gref select 1) != "") then {
                _gearOPFOR = [_gref select 0, _gref select 1, "Infantry", ""] call _unitsFromFaction;
                _gearViper = _gearOPFOR;
            };
        };
        case 11: {  // Global Mobilization
            private _gm = [["East","gm_gc"],["East","gm_gc_army"],["East","gm_gc_mil"]] call _tryFindFaction;
            if ((_gm select 1) != "") then {
                _gearOPFOR = [_gm select 0, _gm select 1, "Infantry", ""] call _unitsFromFaction;
                _gearViper = _gearOPFOR;
            };
        };
        case 12: {  // S.O.G. Prairie Fire
            private _pavn = [["East","vn_o_pavn"],["East","O_PAVN"],["East","vn_o_army_pavn"]] call _tryFindFaction;
            if ((_pavn select 1) != "") then {
                _gearOPFOR = [_pavn select 0, _pavn select 1, "Infantry", ""] call _unitsFromFaction;
                private _vc = [["East","vn_o_vc"],["Indep","vn_i_vc"],["East","O_VC"]] call _tryFindFaction;
                if ((_vc select 1) != "") then {
                    _gearViper = [_vc select 0, _vc select 1, "Infantry", ""] call _unitsFromFaction;
                } else {
                    _gearViper = _gearOPFOR;
                };
            };
        };
        case 13: {  // CSLA Iron Curtain
            private _csla = [["East","CSLA"],["East","csla_faction"],["East","csla"]] call _tryFindFaction;
            if ((_csla select 1) != "") then {
                _gearOPFOR = [_csla select 0, _csla select 1, "Infantry", ""] call _unitsFromFaction;
                _gearViper = _gearOPFOR;
            };
        };
        case 15: {  // RHS - SAF (Serbian Armed Forces). RHS ships them on more
                    // than one side, so try each rather than assuming East.
            private _saf = [["East","rhssaf_faction_army_opfor"],["Indep","rhssaf_faction_army"],["Indep","rhssaf_faction_un"]] call _tryFindFaction;
            if ((_saf select 1) != "") then {
                _gearOPFOR = [_saf select 0, _saf select 1, "Infantry", ""] call _unitsFromFaction;
                _gearViper = _gearOPFOR;
            };
        };
        case 14: {  // Northern Fronts CW
            {
                private _pick = if (["Indep", _x] call _isFactionLoaded) then { _x } else { _x + "_W" };
                if (["Indep", _pick] call _isFactionLoaded) then {
                    private _catUnits = ["Indep", _pick, "Infantry", ""] call _unitsFromFaction;
                    { _gearOPFOR pushBackUnique _x } forEach _catUnits;
                };
            } forEach ["NFCW_80", "NFCW_88"];
            _gearViper = _gearOPFOR;
        };
    };

    // CfgGroups faction names are not reliable across mod versions - the SOG and GM
    // lookups have been failing on every run and only survive because HOSTILE_FACTION
    // falls back to a CfgVehicles prefix scan. Do the same here rather than silently
    // leaving the enemy gear faction with no effect.
    if (count _gearOPFOR == 0) then {
        private _prefix = switch (_gearParam) do {
            case 3: { "CUP_O_" };
            case 4: { "CUP_O_TK" };
            case 5: { "CUP_O_RU" };
            case 6: { "CUP_O_ChDKZ" };
            case 7: { "rhs_" };
            case 8: { "rhs_" };
            case 9: { "rhsusf_" };
            case 10: { "rhsgref_" };
            case 11: { "gm_gc" };
            case 12: { "vn_o_" };
            case 13: { "csla_" };
            case 14: { "NFCW" };
            case 15: { "rhssaf_" };
            default { "" };
        };
        if (_prefix != "") then {
            diag_log format ["DynBulwarks: ENEMY_GEAR_FACTION %1 CfgGroups lookup empty, scanning CfgVehicles for prefix %2", _gearParam, _prefix];
            // side 0 = East, 2 = Indep, 1 = West. Try each; mods place factions differently.
            {
                if (count _gearOPFOR == 0) then {
                    _gearOPFOR = [_x, _prefix] call _scanInfantryBySide;
                };
            } forEach [0, 2, 1];
            _gearViper = _gearOPFOR;
            diag_log format ["DynBulwarks: ENEMY_GEAR_FACTION %1 prefix scan found %2 units", _gearParam, count _gearOPFOR];
        };
    };

    if (count _gearOPFOR > 0) then {
        List_OPFOR = _gearOPFOR;
        List_Viper = if (count _gearViper > 0) then { _gearViper } else { _gearOPFOR };
        List_INDEP = List_OPFOR + List_Viper;
        diag_log format ["DynBulwarks: ENEMY_GEAR_FACTION %1 -> %2 OPFOR / %3 Viper units", _gearParam, count List_OPFOR, count List_Viper];
    } else {
        diag_log format ["DynBulwarks: ENEMY_GEAR_FACTION %1 produced no units, keeping HOSTILE_FACTION lists (OPFOR=%2)", _gearParam, count List_OPFOR];
    };
};

// Defectors keep the HOSTILE_FACTION-derived friendly models (e.g. RHS US Army when
// HOSTILE_FACTION = RHS), so they still read as turncoats of the enemy's own war.
// Captured BEFORE the friendly override below, which only affects paratroops.
List_Defectors = List_NATO;

// --- Friendly faction override (independent of HOSTILE_FACTION) ---
// List_NATO drives PARATROOP_CLASS (editMe.sqf); DEFECTOR_CLASS now reads
// List_Defectors instead. The friendly spawners use createGroup [WEST, true],
// and createUnit inherits the group's side, so an Independent-side mod faction
// still fights on the players' side.
private _friendlyParam = ["FRIENDLY_FACTION", 0] call BIS_fnc_getParamValue;
if (_friendlyParam != 0) then {
    private _friendlyUnits = [];
    switch (_friendlyParam) do {
        case 1: {
            // Northern Fronts Cold War — Finnish Defence Forces, summer only.
            // Winter (_W) mirrors both eras exactly, so the fallback should never fire.
            {
                _x params ["_era", "_categories"];
                private _pick = if (["Indep", _era] call _isFactionLoaded) then { _era } else { _era + "_W" };
                if (["Indep", _pick] call _isFactionLoaded) then {
                    if (_pick != _era) then { diag_log format ["DynBulwarks: NFCW summer era %1 missing, falling back to %2", _era, _pick]; };
                    {
                        private _catUnits = ["Indep", _pick, _x, ""] call _unitsFromFaction;
                        { _friendlyUnits pushBackUnique _x } forEach _catUnits;
                    } forEach _categories;
                } else {
                    diag_log format ["DynBulwarks: NFCW era %1 not found in CfgGroups (neither summer nor winter)", _era];
                };
            } forEach [
                ["NFCW_80", ["Infantry", "InfantryBord", "InfantryLocal"]],
                ["NFCW_88", ["Infantry"]]   // urban groups live in here
            ];
        };
    };
    if (count _friendlyUnits > 0) then {
        List_NATO = _friendlyUnits;
        diag_log format ["DynBulwarks: FRIENDLY_FACTION %1 -> %2 friendly units", _friendlyParam, count List_NATO];
    } else {
        diag_log format ["DynBulwarks: FRIENDLY_FACTION %1 produced no units, keeping default List_NATO (%2)", _friendlyParam, count List_NATO];
    };
};

// Replace bandits/thugs with selected faction's regular infantry for non-vanilla factions
// Early waves are still easier due to AI skill scaling and pistol-only enforcement
if (_factionParam != 0) then {
    List_Bandits = List_OPFOR;
    List_ParaBandits = List_OPFOR;
    diag_log "DynBulwarks: Bandits replaced with faction infantry";
};

diag_log format ["DynBulwarks: List_Bandits=%1 List_OPFOR=%2 List_Viper=%3 List_INDEP=%4 List_NATO=%5 List_Defectors=%6", count List_Bandits, count List_OPFOR, count List_Viper, count List_INDEP, count List_NATO, count List_Defectors];

// Vehicle faction filter - uses the ENEMY_GEAR_FACTION parameter.
// _gearResolved is what "match enemy faction" resolved to.
private _gearResolved = _gearParam;
if (_gearParam == 0) then {
    // "Match enemy faction" resolves to the mod-level option for whatever
    // HOSTILE_FACTION picked. This reproduces the old LOOT_FACTION default.
    _gearResolved = switch (_factionParam) do {
        case 1: { 3 };    // CUP enemies   -> CUP (all)
        case 2: { 7 };    // RHS enemies   -> RHS (all)
        case 6: { 11 };   // GM enemies    -> Global Mobilization
        case 7: { 12 };   // SOG enemies   -> S.O.G. Prairie Fire
        case 8: { 13 };   // CSLA enemies  -> CSLA Iron Curtain
        default { 2 };    // Vanilla/Apex/Contact/Western Sahara -> vanilla + DLC
    };
    diag_log format ["DynBulwarks: ENEMY_GEAR_FACTION 'match enemy faction' resolved to %1", _gearResolved];
};

// Option 1 "All loaded content" is the only value that disables filtering.
private _filterVehicles = _gearResolved != 1;

// Mod-level classname prefix test. Used directly by the mod-level options and
// as the fallback when a per-faction config-faction match finds nothing.
private _vehPrefixFilter = switch (_gearResolved) do {
    case 2: {
        // Vanilla + official DLC: exclude known mod/CDLC prefixes
        {
            private _n = toLower _this;
            !((_n select [0,4]) == "cup_") &&
            {!((_n select [0,3]) == "rhs")} &&
            {!((_n select [0,3]) == "gm_")} &&
            {!((_n select [0,3]) == "vn_")} &&
            {!((_n select [0,5]) == "csla_")}
        }
    };
    case 3: { { (toLower _this select [0,4]) == "cup_" } };
    case 4: { { (toLower _this select [0,4]) == "cup_" } };
    case 5: { { (toLower _this select [0,4]) == "cup_" } };
    case 6: { { (toLower _this select [0,4]) == "cup_" } };
    case 7: { { (toLower _this select [0,3]) == "rhs" } };
    case 8: { { (toLower _this select [0,4]) == "rhs_" } };
    case 9: { { (toLower _this select [0,7]) == "rhsusf_" } };
    case 10: { { (toLower _this select [0,8]) == "rhsgref_" } };
    case 11: { { (toLower _this select [0,3]) == "gm_" } };
    case 12: { { (toLower _this select [0,3]) == "vn_" } };
    case 13: { { (toLower _this select [0,5]) == "csla_" } };
    // NFCW ships no armour of its own, so armour comes from RHS.
    case 14: { { (toLower _this select [0,3]) == "rhs" } };
    case 15: { { (toLower _this select [0,7]) == "rhssaf_" } };
    default { { true } };
};

// Per-faction options additionally require the vehicle's config "faction" to be
// one of these. Empty means "no faction restriction, prefix test only".
private _vehFactionNames = switch (_gearResolved) do {
    case 4: { ["cup_o_tk", "cup_o_tk_militia", "cup_o_tk_ins"] };
    case 5: { ["cup_o_ru", "cup_o_ru_air", "cup_o_rus"] };
    case 6: { ["cup_o_chdkz", "cup_o_chdkz_ins"] };
    case 8: { ["rhs_faction_msv", "rhs_faction_vdv", "rhs_faction_vmf", "rhs_faction_vv", "rhs_faction_vpvo", "rhs_faction_rva"] };
    case 9: { ["rhs_faction_usarmy_d", "rhs_faction_usarmy_wd", "rhs_faction_usmc_d", "rhs_faction_usmc_wd", "rhs_faction_socom"] };
    case 10: { ["rhsgref_faction_cdf_ground", "rhsgref_faction_chdkz", "rhsgref_faction_nationalist", "rhsgref_faction_un"] };
    case 15: { ["rhssaf_faction_army_opfor", "rhssaf_faction_army", "rhssaf_faction_un"] };
    default { [] };
};

// Combined test. _this is the classname string; the config lookup is done here
// so callers keep passing a classname exactly as before.
private _passesVehFilter = {
    private _cn = _this;
    private _ok = _cn call _vehPrefixFilter;
    if (_ok && {count _vehFactionNames > 0}) then {
        private _f = toLower getText (configFile >> "CfgVehicles" >> _cn >> "faction");
        _ok = _f in _vehFactionNames;
    };
    _ok
};

diag_log format ["DynBulwarks: Vehicle faction filter = %1 (filterActive = %2, factionNames = %3)", _gearResolved, _filterVehicles, _vehFactionNames];

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

// A per-faction filter that matches nothing must not silently remove all armour.
// Re-scan with the mod-level prefix test only.
if (count List_Armour == 0 && {count _vehFactionNames > 0}) then {
    diag_log format ["DynBulwarks: no armour matched faction names %1, falling back to the mod-level prefix filter", _vehFactionNames];
    _vehFactionNames = [];
    private _retry = [];
    for "_x" from 0 to (count _cfgVehicles - 1) do {
        private _cv = _cfgVehicles select _x;
        if (isClass _cv) then {
            private _cn = configName _cv;
            if (getText (_cv >> "vehicleClass") == "Armored" && {getNumber (_cv >> "scope") != 0} && {getText (_cv >> "simulation") != "parachute"} && {count getArray (_cv >> "artilleryAmmo") == 0} && {!_filterVehicles || {_cn call _passesVehFilter}}) then {
                _retry pushBack _cn;
            };
        };
    };
    List_Armour = _retry;
    diag_log format ["DynBulwarks: armour fallback scan found %1 classes", count List_Armour];
};

// Per-faction armour override: scan CfgVehicles for matching prefixes
private _armourOverride = switch (_factionParam) do {
	case 7: {
		private _prefixes = ["vn_o_armor_btr50pk_", "vn_o_armor_t54b_", "vn_o_armor_pt76a_", "vn_o_armor_pt76b_"];
		private _results = [];
		for "_x" from 0 to (count _cfgVehicles - 1) do {
			private _cv = _cfgVehicles select _x;
			if (isClass _cv) then {
				private _cn = configName _cv;
				if (getNumber (_cv >> "scope") >= 2 && {_prefixes findIf {_cn select [0, count _x] == _x} > -1}) then {
					_results pushBack _cn;
				};
			};
		};
		_results
	};
	default { [] };
};
if (count _armourOverride > 0) then {
	List_Armour = _armourOverride;
	diag_log format ["DynBulwarks: Armour hardcoded override for faction %1: %2", _factionParam, List_Armour];
};
diag_log format ["DynBulwarks: List_Armour=%1", List_Armour];

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

// Per-faction hardcoded car list: scan CfgVehicles for matching prefix
private _carOverride = switch (_factionParam) do {
	case 7: {
		private _results = [];
		for "_x" from 0 to (count _cfgVehicles - 1) do {
			private _cv = _cfgVehicles select _x;
			if (isClass _cv) then {
				private _cn = configName _cv;
				if ((_cn select [0, 13]) == "vn_o_wheeled_" && {getNumber (_cv >> "scope") >= 2}) then {
					_results pushBack _cn;
				};
			};
		};
		_results
	};
	default { [] };
};
if (count _carOverride > 0) then {
	List_ArmedCars = _carOverride;
	diag_log format ["DynBulwarks: ArmedCars hardcoded override for faction %1: %2", _factionParam, List_ArmedCars];
};
diag_log format ["DynBulwarks: List_ArmedCars=%1", List_ArmedCars];

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
// Friendly faction override. SUPPORT_AIRCRAFT otherwise follows HOSTILE_FACTION, so
// with RHS enemies the supply drop and paratroops arrive in a random RHS transport.
// NFCW has no transport of its own — its only aircraft are the Military Aviation
// compat jets (BAe Hawk, Fouga Magister), neither of which carries cargo or troops.
// Finland operated the Mi-8T from 1973, which fits the mod's 1980/1988 window.
if (_friendlyParam == 1) then {
    // C-160 Transall first: a Western Cold War tactical transport with a rear ramp,
    // which suits an airdrop far better than a helicopter. Mi-8/Mi-17 as fallbacks —
    // Finland operated the Mi-8T from 1973, so either fits the 1980/1988 window.
    private _fdfTransports = ["sab_c160_b", "rhsgref_cdf_b_reg_Mi8amt", "rhsgref_cdf_b_reg_Mi17Sh"];
    private _pick = "";
    {
        if (isClass (configFile >> "CfgVehicles" >> _x)) exitWith { _pick = _x; };
    } forEach _fdfTransports;
    if (_pick != "") then {
        SUPPORT_AIRCRAFT = _pick;
        diag_log format ["DynBulwarks: FRIENDLY_FACTION 1 - SUPPORT_AIRCRAFT overridden to %1", _pick];
    } else {
        diag_log format ["DynBulwarks: FRIENDLY_FACTION 1 - no Mi-8 class found, keeping %1", SUPPORT_AIRCRAFT];
    };
};

diag_log format ["DynBulwarks: SUPPORT_AIRCRAFT=%1", SUPPORT_AIRCRAFT];
