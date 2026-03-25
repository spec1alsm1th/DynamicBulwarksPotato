while {true} do {
  _allHCs = entities "HeadlessClient_F";
  _allHPs = allPlayers - _allHCs;
  {
    _playerInvToCheck = _x;
    if ((lifeState _x) == "INCAPACITATED") then {
      _playerItems = items _x + backpackItems _x + vestItems _x;
      // Find any medikit-type item (vanilla "Medikit", SOG "vn_b_medikit", etc.)
      private _foundMedikit = "";
      {
        if (toLower _x find "medikit" >= 0) exitWith { _foundMedikit = _x; };
      } forEach _playerItems;
      if (_foundMedikit != "" && !(_playerInvToCheck getVariable "RevByMedikit")) then {
        // Set flag immediately to prevent re-triggering during the 15s countdown
        _playerInvToCheck setVariable ["RevByMedikit", true, true];
        ["SpecialWarning", ["Medikit self-revive in 15 seconds..."]] remoteExec ["BIS_fnc_showNotification", _playerInvToCheck];
        [_playerInvToCheck, _foundMedikit] spawn {
          params ["_p", "_medikitClass"];
          sleep 15;
          if (alive _p && lifeState _p == "INCAPACITATED") then {
            [_p, false] remoteExec ["setUnconscious", 0];
            ["#rev", 1, _p] remoteExecCall ["BIS_fnc_reviveOnState", _p];
            _p switchMove "PlayerStand";
            _p removeItem _medikitClass;
            [_p] remoteExec ["bulwark_fnc_revivePlayer", 2];
            _p setVariable ["RevByMedikit", false, true];
          } else {
            // Bled out or teammate already revived — clear the flag
            _p setVariable ["RevByMedikit", false, true];
          };
        };
      };
    };
  } forEach _allHPs;
  sleep 1;
};
