/**
*  fn_landForces
*
*  Deploys a friendly infantry squad that advances to and defends the bulwark.
*
*  Domain: Server
**/
params ["_player"];

private _classes = if (!isNil "PARATROOP_CLASS" && {count PARATROOP_CLASS > 0}) then { PARATROOP_CLASS } else { ["B_Soldier_F"] };

private _spawnPos = [bulwarkCity, BULWARK_RADIUS + 300, BULWARK_RADIUS + 550, 5, 0, 20, 0] call BIS_fnc_findSafePos;
if (count _spawnPos < 2) then { _spawnPos = bulwarkCity; };

private _squadGroup = createGroup [WEST, true];

for "_i" from 1 to 5 do {
    private _unit = _squadGroup createUnit [
        selectRandom _classes,
        _spawnPos vectorAdd [(random 8) - 4, (random 8) - 4, 0],
        [], 1, "FORM"
    ];
    _unit setSkill ["aimingAccuracy", 0.7];
    _unit setSkill ["aimingSpeed",    0.7];
    _unit setSkill ["aimingShake",    0.8];
    _unit setSkill ["spotTime",       1];
    _unit allowFleeing 0;
    mainZeus addCuratorEditableObjects [[_unit], true];
};

private _wp1 = _squadGroup addWaypoint [position bulwarkBox, 30];
_wp1 setWaypointType "MOVE";
_wp1 setWaypointCompletionRadius 30;

private _wp2 = _squadGroup addWaypoint [position bulwarkBox, 0];
_wp2 setWaypointType "SAD";

_squadGroup setCombatMode "RED";
_squadGroup setBehaviour "AWARE";

["TaskAssigned", ["REINFORCEMENTS!", "Friendly squad is moving to your position."]] remoteExec ["BIS_fnc_showNotification", 0];
