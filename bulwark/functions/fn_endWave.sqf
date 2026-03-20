/**
*  fn_endWave
*
*  Wave ended (mission complete)
*
*  Domain: Server
**/

diag_log format ["DynBulwarks: endWave — wave %1 complete, entering build phase (downTime=%2)", attkWave, _downTime];
// variable to prevent players rejoining during a wave
playersInWave = [];
publicVariable "playersInWave";

bulwarkBox setVariable ["buildPhase", true, true];

["TaskSucceeded",["Complete","Wave " + str attkWave + " complete!"]] remoteExec ["BIS_fnc_showNotification", 0];
RESPAWN_TIME = 0;
publicVariable "RESPAWN_TIME";
[RESPAWN_TIME] remoteExec ["setPlayerRespawnTime", 0];

{
	// Revive players that died at the end of the round.
	if (lifeState _x == "DEAD") then {
		forceRespawn _x;
	};
} foreach allPlayers;

{
	// Revive players that are INCAPACITATED.
	if (lifeState _x == "INCAPACITATED") then {
		["#rev", 1, _x] remoteExecCall ["BIS_fnc_reviveOnState",_x];
	};
} foreach allPlayers;

// Try to force the spectator mode off when players are revived.
["Terminate"] remoteExec ["BIS_fnc_EGSpectator", 0];

// Kill any surviving wave units — handles defector wave (WEST-classname units in EAST groups
// may not register as EAST side, so missionLoop exits while they are still alive)
{
	if (alive _x) then { _x setDamage 1; };
} forEach (waveUnits select 0);

//Kill all mind controlled AI
{
	 _x setDamage 1;
}foreach MIND_CONTROLLED_AI;
MIND_CONTROLLED_AI = [];
publicVariable "MIND_CONTROLLED_AI";

diag_log format ["DynBulwarks: endWave — sleeping %1s (build phase)", _downTime];
sleep _downTime;
diag_log "DynBulwarks: endWave — build phase over";
