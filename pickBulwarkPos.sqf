/*
    pickBulwarkPos.sqf
    Host/admin picks bulwark position by clicking on map.
    Publishes DB_specBulwarkPos to the server.
*/

if (!hasInterface) exitWith {};

// Only allow server host / admin to pick
if !(isServer || serverCommandAvailable "#kick") exitWith {};

openMap true;
hint "Click on the map to choose Bulwark location.";

onMapSingleClick {
    params ["_units", "_pos", "_alt", "_shift"];

    // Show marker locally for the host
    if (getMarkerColor "specBulwarkLoc" == "") then {
        createMarkerLocal ["specBulwarkLoc", _pos];
        "specBulwarkLoc" setMarkerTypeLocal "mil_dot";
        "specBulwarkLoc" setMarkerTextLocal "Bulwark Location";
    };
    "specBulwarkLoc" setMarkerPosLocal _pos;

    // Publish to server (server will then create/update the global marker)
    DB_specBulwarkPos = _pos;
    publicVariableServer "DB_specBulwarkPos";

    onMapSingleClick "";   // remove handler
    openMap false;
    hint format ["Bulwark location set: %1", _pos];
};
