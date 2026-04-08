/**
*  enemyRPGvsInfantry
*
*  ArmA 3 AI only uses rocket launchers against armoured targets by default.
*  This script periodically finds EAST units carrying a launcher, selects
*  a nearby player as target, and issues commandFire to override that restriction.
*
*  Runs every 20-50 seconds, picks up to 2 RPG units per tick.
*  Only fires if a player is within 250 m and the wave is active (not build phase).
*
*  Domain: Server
**/

while {true} do {
    sleep (20 + random 30);

    // Skip during build phase — no hostiles active
    if (bulwarkBox getVariable ["buildPhase", true]) then { continue };

    private _allHCs = entities "HeadlessClient_F";
    private _allHPs = allPlayers - _allHCs;
    private _alivePlayers = _allHPs select { alive _x };
    if (count _alivePlayers == 0) then { continue };

    // Find EAST infantry on foot that have a launcher loaded
    private _rpgUnits = allUnits select {
        alive _x &&
        side _x == east &&
        secondaryWeapon _x != "" &&
        isNull objectParent _x
    };
    if (count _rpgUnits == 0) then { continue };

    // Shuffle and cap at 2 so we don't fire every RPG at once
    _rpgUnits = _rpgUnits call BIS_fnc_arrayShuffle;
    private _fireCount = (count _rpgUnits) min 2;

    for "_i" from 0 to (_fireCount - 1) do {
        private _unit = _rpgUnits select _i;
        private _launcher = secondaryWeapon _unit;

        // Find nearest alive player within 250 m
        private _nearestPlayer = objNull;
        private _nearestDist = 250;
        {
            private _d = _unit distance _x;
            if (_d < _nearestDist) then {
                _nearestDist = _d;
                _nearestPlayer = _x;
            };
        } forEach _alivePlayers;

        if (!isNull _nearestPlayer) then {
            _unit selectWeapon _launcher;
            _unit doTarget _nearestPlayer;
            _unit commandFire _nearestPlayer;
            diag_log format ["DynBulwarks: enemyRPGvsInfantry — unit %1 firing %2 at player (dist=%3m)", _unit, _launcher, round _nearestDist];
        };
    };
};
