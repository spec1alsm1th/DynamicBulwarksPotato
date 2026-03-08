/*
    pickBulwarkPos.sqf
    Host/admin picks bulwark position by clicking on map.
    Publishes DB_specBulwarkPos to the server.
*/

if (!hasInterface) exitWith {};

// Only allow server host / admin to pick
if !(isServer || serverCommandAvailable "#kick") exitWith {};

titleText [
    "SELECT BULWARK LOCATION" + endl +
    "Open the map and left-click to place the Bulwark." + endl +
    "Choose a spot near buildings for cover and loot access.",
    "PLAIN DOWN", 1
];
sleep 1;
openMap true;
hint parseText "<t size='1.2' font='PuristaMedium'>SELECT BULWARK LOCATION</t><br/><t>Left-click anywhere on the map to place the Bulwark.<br/>• Pick a spot near buildings for loot and cover<br/>• Enemies will attack from all directions</t>";

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
    hint "Bulwark location confirmed. Setting up...";
};
