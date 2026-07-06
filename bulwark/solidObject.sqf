_object  = _this select 0;
_loopCount = 0;
_foundAIArr = [];
// Re-check held state every tick — the loop must stop when a player picks the object back up
while {!isNull _object && !(_object getVariable ["buildItemHeld", false])} do {
    if (_loopcount >= 20) then {
        _loopCount = 0;
        _foundAIArr = [];
    };
    _loopCount = _loopCount + 1;
    _objRadius = (_object getVariable "Radius") + 1;
    _nearAI = _object nearEntities _objRadius;
    {
      if (suicideWave && (alive _x) && (side _x == east)) then {
        _x setDamage 1;
        deleteVehicle _object;
      }else{
        if (side _x == east && !(_x in _foundAIArr) && (alive _x)) then {
          doStop _x;
          _x disableAI "MOVE";
          _aiDir = _object getDir _x;
          _x setDir _aiDir;
          _aiGoToPos = _object getRelPos [random [-10,0,10], _aiDir];
          _x setBehaviour "CARELESS";
          _x setUnitPos "UP";
          _x playActionNow "FastF";
          _x forceSpeed 6;
          _safePos = [_aiGoToPos, 0, 8, 2, 0] call BIS_fnc_findSafePos;
          _x enableAI "MOVE";
          _x doMove _safePos;
          _foundAIArr pushBack _x;
        };
      };
    } foreach _nearAI;
    sleep 0.1;
};
