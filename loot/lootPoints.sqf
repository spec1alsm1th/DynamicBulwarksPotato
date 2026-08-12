_target = _this select 0;
_player = _this select 1;
_lootPoints = ("MONEY_PICKUP_POINTS" call BIS_fnc_getParamValue);

if (_lootPoints > 0) then {
	[_player, _lootPoints] remoteExecCall ["killPoints_fnc_add", 2];
};
[_player, "pointsLootSound"] remoteExec ["sound_fnc_say3DGlobal", 0];
_target remoteExec ["deleteVehicle", 2];
