/**
*  fn_hit
*
*  Event handler for unit hit.
*
*  Domain: Event
**/

if (isServer) then {
    _unit = _this select 0;
    _dmg = _this select 2;
    _instigator = _this select 3;
    if (isPlayer _instigator) then {
        private _hitScore = (SCORE_HIT + (SCORE_DAMAGE_BASE * _dmg)) min SCORE_KILL;
        [_instigator, _hitScore] call killPoints_fnc_add;
        _pointsArr = _unit getVariable "points";
        _pointsArr pushBack _hitScore;
        _unit setVariable ["points", _pointsArr];

        [_unit, round _hitScore, [0.1, 1, 0.1]] remoteExec ["killPoints_fnc_hitMarker", _instigator];
    };
};
