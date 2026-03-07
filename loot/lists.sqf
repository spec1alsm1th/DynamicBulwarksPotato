/**
*  loot/lists
*
*  Populates global arrays with spawnable loot classes
*
*  Domain: Server
**/

// Read loot/equipment faction parameter
private _lootFactionParam = ["LOOT_FACTION", 0] call BIS_fnc_getParamValue;

// Handle "Match enemy faction" option (value 7)
if (_lootFactionParam == 7) then {
    private _hostileFaction = ["HOSTILE_FACTION", 0] call BIS_fnc_getParamValue;
    _lootFactionParam = switch (_hostileFaction) do {
        case 1: { 2 };   // CUP enemies -> CUP loot
        case 2: { 3 };   // RHS enemies -> RHS loot
        case 6: { 4 };   // GM enemies -> GM loot
        case 7: { 5 };   // SOG enemies -> SOG loot
        case 8: { 6 };   // CSLA enemies -> CSLA loot
        default { 1 };   // Vanilla/Apex/Contact/WS -> Vanilla loot
    };
};

private _filterLoot = _lootFactionParam != 0;

// Filter function: checks classname prefix to determine if item belongs to selected faction
private _passesLootFilter = switch (_lootFactionParam) do {
    case 1: {
        // Vanilla + official DLCs: exclude known mod/CDLC prefixes
        {
            private _n = toLower (configName _this);
            !((_n select [0,4]) == "cup_") &&
            {!((_n select [0,3]) == "rhs")} &&
            {!((_n select [0,3]) == "gm_")} &&
            {!((_n select [0,3]) == "vn_")} &&
            {!((_n select [0,5]) == "csla_")}
        }
    };
    case 2: { { (toLower (configName _this) select [0,4]) == "cup_" } };
    case 3: { { (toLower (configName _this) select [0,3]) == "rhs" } };
    case 4: { { (toLower (configName _this) select [0,3]) == "gm_" } };
    case 5: { { (toLower (configName _this) select [0,3]) == "vn_" } };
    case 6: { { (toLower (configName _this) select [0,5]) == "csla_" } };
    default { { true } };
};

diag_log format ["DynBulwarks: Loot faction filter = %1 (filterActive = %2)", _lootFactionParam, _filterLoot];

_hats = [];
_uniforms = [];
_vests = [];
_primaries = [];
_secondaries = [];
_launchers = [];
_optics = [];
_railAttach = [];
_items = [];
_mines = [];
_backpacks = [];
_glasses = [];
_faces = [];
_grenades = [];
_charges = [];
_count =  count (configFile >> "CfgWeapons");
for "_x" from 0 to (_count-1) do {
	_weap = ((configFile >> "CfgWeapons") select _x);
	if (isClass _weap) then {
		if (getnumber (_weap >> "scope") == 2 && {!_filterLoot || {_weap call _passesLootFilter}}) then {
			if (isClass (_weap >> "ItemInfo")) then {
				_infoType = (getnumber (_weap >> "ItemInfo" >> "Type"));
				switch (_infoType) do {
					case 605: {_hats = _hats + [configName _weap];};
					case 801: {_uniforms = _uniforms + [configName _weap];};
					case 701: {_vests = _vests + [configName _weap];};
					case 201: {_optics = _optics + [configName _weap];};
					case 301: {_railAttach = _railAttach + [configName _weap];};
					case 601: {_items = _items + [configName _weap];};
					case 620: {_items = _items + [configName _weap];}; // Toolkit
					case 619: {_items = _items + [configName _weap];}; // Medikit
					case 621: {_items = _items + [configName _weap];}; // UAV terminal
					case 616: {_items = _items + [configName _weap];}; // NVG
					case 401: {_items = _items + [configName _weap];}; // First Aid Kit
				};
			};
			if (!isClass (_weap >> "LinkedItems")) then {
				if (count(getarray (_weap >> "magazines")) !=0 ) then {
					_type = getnumber (_weap >> "type");
					switch (_type) do {
						case 1: {_primaries = _primaries + [configName _weap];};
						case 3: {_secondaries = _secondaries + [configName _weap];};
						case 4: {_launchers = _launchers + [configName _weap];};
					};
    		};
      };
			if ( isClass(_weap >> "LinkedItems" >> "LinkedItemsUnder") && !isClass(_weap >> "LinkedItems" >> "LinkedItemsAcc") && !isClass(_weap >> "LinkedItems" >> "LinkedItemsMuzzle") && !isClass(_weap >> "LinkedItems" >> "LinkedItemsOptic")) then {
				if (count(getarray (_weap >> "magazines")) !=0 ) then {
					_primaries = _primaries + [configName _weap];
				};
			};
    };
  };
};

_count =  count (configFile >> "CfgVehicles");
for "_x" from 0 to (_count-1) do {
    _item=((configFile >> "CfgVehicles") select _x);
    if (isClass _item) then {
        if (getnumber (_item >> "scope") == 2 && {!_filterLoot || {_item call _passesLootFilter}}) then {
            if (gettext (_item >> "vehicleClass") == "Backpacks") then {
                _backpacks = _backpacks + [configname _item]
            };
        };
    };
};

_count =  count (configFile >> "CfgGlasses");
for "_x" from 0 to (_count-1) do {
    _item=((configFile >> "CfgGlasses") select _x);
    if (isClass _item) then {
        if (getnumber (_item >> "scope") == 2 && {!_filterLoot || {_item call _passesLootFilter}}) then {
            _glasses = _glasses + [configName _item];
        };
    };
};
_count =  count (configFile >> "CfgFaces" >> "Man_A3");
for "_x" from 0 to (_count-1) do {
    _item=((configFile >> "CfgFaces" >> "Man_A3") select _x);
    if (isClass _item) then {_faces = _faces + [configName _item];};
};

_count =  count (configFile >> "CfgMagazines");
for "_x" from 0 to (_count-1) do {
    _item=((configFile >> "CfgMagazines") select _x);
	if (isClass _item && {!_filterLoot || {_item call _passesLootFilter}}) then {
		if(getNumber (_item >> "value") == 5) then {
			if(["mine", getText (_item >> "displayName")] call BIS_fnc_inString) then {
				_mines = _mines + [configName _item];
			}
		};
	};
};

_count =  count (configFile >> "CfgMagazines");
_chargeType = getText (configfile >> "CfgMagazines" >> "DemoCharge_Remote_Mag" >> "type");
for "_x" from 0 to (_count-1) do {
  _item=((configFile >> "CfgMagazines") select _x);
	if (isClass _item && {!_filterLoot || {_item call _passesLootFilter}}) then {
		if (gettext (_item >> "type") == _chargeType && ["remote", configName _item] call BIS_fnc_inString) then {
			_charges = _charges + [configName _item];
		};
	};
};

_count =  count (configFile >> "CfgMagazines");
for "_x" from 0 to (_count-1) do {
    _item=((configFile >> "CfgMagazines") select _x);
	if (isClass _item && {!_filterLoot || {_item call _passesLootFilter}}) then {
		if(getNumber (_item >> "type") == 16 || getNumber (_item >> "type") == 256) then {
			if(["grenade", getText (_item >> "displayName")] call BIS_fnc_inString && !(["smoke", getText (_item >> "displayName")] call BIS_fnc_inString)) then {
				_grenades = _grenades + [configName _item];
			}
		};
	};
};

List_Hats = [] + _hats;
List_Uniforms = [] + _uniforms;
List_Vests = [] + _vests;
List_Backpacks = [] + _backpacks;
List_Primaries = [] + _primaries;
List_Secondaries = [] + _secondaries;
List_Launchers = [] + _launchers;
List_Optics = [] + _optics + _railAttach;
List_Items = [] + _items + ['ItemGPS','ItemCompass','ItemMap', 'ItemWatch', 'ItemRadio'];
List_Mines = [] + _mines;
List_Glasses = [] + _glasses;
List_Faces = [] + _faces;
List_Grenades = [] + _grenades;
List_Charges = [] + _charges;

List_AllWeapons = List_Primaries + List_Secondaries + List_Launchers;
List_AllClothes = List_Hats + List_Uniforms + List_Glasses;
