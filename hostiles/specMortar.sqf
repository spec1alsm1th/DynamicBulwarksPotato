_distFromBulwark = "BULWARK_RADIUS" call BIS_fnc_getParamValue;

_mortarPos = [bulwarkRoomPos, _distFromBulwark - 15, _distFromBulwark - 5, 3, 0, 10, 0] call BIS_fnc_findSafePos;
private _mortarClass = if (!isNil "List_Mortars" && {count List_Mortars > 0}) then { selectRandom List_Mortars } else { "O_Mortar_01_F" };
specMortar = [_mortarPos, 0, _mortarClass, EAST] call bis_fnc_spawnvehicle;
mortarGunner = specMortar select 1 select 0;
mainZeus addCuratorEditableObjects [[specMortar select 0], true];

// Get the mortar's actual artillery ammo type from config
private _artAmmo = getArray (configFile >> "CfgVehicles" >> _mortarClass >> "artilleryAmmo");
private _ammoType = if (count _artAmmo > 0) then {
    _artAmmo select 0
} else {
    // Faction-specific ammo fallback when artilleryAmmo is not defined in config
    private _cn = toLower _mortarClass;
    if ((_cn select [0,3]) == "vn_") then {
        if (_cn find "type63" >= 0) then { "vn_mortar_type63_mag_he_x8" } else { "vn_mortar_type53_mag_he_x8" }
    } else { if ((_cn select [0,3]) == "rhs") then {
        "rhs_mag_3vo18_10"
    } else { if ((_cn select [0,4]) == "cup_") then {
        "CUP_82mm_GRAD_HE"
    } else {
        "8Rnd_82mm_Mo_shells"
    }}}
};

sleep 3;

{
  _x reveal [mortarGunner, 4];
}forEach allPlayers;

sleep 20;

while {alive mortarGunner} do {
  _bulwarkArtPos = getPos bulwarkBox;
  specMortar doArtilleryFire [[(_bulwarkArtPos select 0) + (random [-45, 0, 45]), (_bulwarkArtPos select 1) + (random [-45, 0, 45]), _bulwarkArtPos select 2], _ammoType, 1];
  sleep 30;
};
