civClassArr = [];
_spawnedCivs = [];
_currentWave = attkWave;
_distFromBulwark = "BULWARK_RADIUS" call BIS_fnc_getParamValue;

//Create array of all Civ classes
_civSide = 3;
// On SOG PF (Cam Lao Nam) restrict the pool to era-appropriate villagers.
// Other factions keep the unrestricted pool.
private _factionParam = ["HOSTILE_FACTION", 0] call BIS_fnc_getParamValue;
private _eraPrefix = if (_factionParam == 7) then { "vn_c_" } else { "" };

// Unfiltered pool, kept as a fallback if the era filter matches nothing
private _allCivClasses = [];

_cfgVehiclesConfig = configFile >> "CfgVehicles";
_cfgVehiclesConfigCount = count _cfgVehiclesConfig;
for [{_i = 0}, {_i < _cfgVehiclesConfigCount}, {_i = _i + 1}] do
{
  _config = _cfgVehiclesConfig select _i;
  if (isClass _config) then
  {
    _typeMan = getNumber (_config >> "isMan");
    if (_typeMan != 0) then
    {
      _side = getNumber (_config >> "side");
      // scope 2 = public class; base/private classes are not spawnable
      if (_side == _civSide && {getNumber (_config >> "scope") == 2}) then
      {
        // Drop armed civilians — "Throw"/"Put" are the harmless grenade/mine slots
        private _weapons = (getArray (_config >> "weapons")) - ["Throw", "Put"];
        if (count _weapons == 0) then
        {
          private _className = configName _config;
          _allCivClasses pushBack _className;
          if (_eraPrefix == "" || {_className select [0, count _eraPrefix] == _eraPrefix}) then
          {
            civClassArr pushBack _className;
          };
        };
      }
    }
  };
};

if (count civClassArr == 0) then {
  diag_log format ["DynBulwarks: civWave — no civilians matched era prefix '%1', falling back to unfiltered pool", _eraPrefix];
  civClassArr = _allCivClasses;
};
if (count civClassArr == 0) then {
  diag_log "DynBulwarks: civWave — no civilian classes found at all, falling back to C_man_1";
  civClassArr = ["C_man_1"];
};
diag_log format ["DynBulwarks: civWave — %1 civilian class(es) in pool (faction=%2, prefix='%3')", count civClassArr, _factionParam, _eraPrefix];
if (count lootHouses == 0) exitWith {
  diag_log "DynBulwarks: civWave — no lootHouses, skipping civilian spawn";
};

for [{_i=0}, {_i<20}, {_i=_i+1}] do {
  //find random location for Civ to spawn
  private _attempts = 0;
  _civRoom = while {true} do {
    _attempts = _attempts + 1;
    if (_attempts > 50) exitWith { getPos (selectRandom lootHouses) };
    _civBulding = selectRandom lootHouses;
    _civRooms = _civBulding buildingPos -1;
    _civRoom = selectRandom _civRooms;
    if(!isNil "_civRoom") exitWith {_civRoom};
  };

  //spawn Civ
  _civClass = selectRandom civClassArr;
  _civgroup = createGroup [civilian, true];
  _civUnit = _civgroup createUnit [_civClass, _civRoom, [], 0.5, "FORM"];
  mainZeus addCuratorEditableObjects [[_civUnit], true];
  _civUnit addEventHandler ["Killed", killPoints_fnc_civKilled];
  _spawnedCivs pushBack _civUnit;
};

while {EAST countSide allUnits > 0} do {
  {
    _civGoToPos = [bulwarkRoomPos, 0, _distFromBulwark - 5,0,0,70,0] call BIS_fnc_findSafePos;
    _x doMove _civGoToPos;
    _x allowFleeing 0;
    _x setBehaviour "CARELESS";
  } forEach _spawnedCivs;
  sleep 20;
};

{
  _nBuilding = nearestBuilding _x;
  _civRooms = _nBuilding buildingPos -1;
  _civRoom = selectRandom _civRooms;
  if(!isNil "_civRoom") then {
    _x doMove _civRoom;
  };
} forEach _spawnedCivs;

waitUntil {_currentWave != attkWave};

{
  deleteVehicle _x;
} forEach _spawnedCivs;
