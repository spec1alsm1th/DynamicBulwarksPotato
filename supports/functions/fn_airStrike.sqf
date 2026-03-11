/**
*  fn_airStrike
*
*  Calls a faction-appropriate CAS jet to attack the passed location with missiles.
*
*  Domain: Server
**/
params ["_player", "_targetPos"];

if (count _targetPos == 0) then {
  [_player, "airStrike"] remoteExec ["BIS_fnc_addCommMenuItem", _player]; // refund if aimed at sky
} else {
  private _smoker = "SmokeShellRed" createVehicle [_targetPos select 0, _targetPos select 1, 10];
  _smoker setVelocity [0,0,-100];
  _smoker setVectorDirandUp [[0,0,-1],[0.1,0.1,1]];

  // Select faction-appropriate armed CAS jet
  private _factionParam = "HOSTILE_FACTION" call BIS_fnc_getParamValue;
  private _preferredCAS = switch (_factionParam) do {
    case 7: { ["vn_b_air_f4c_bmb", "vn_b_air_f100d_bmb"] }; // SOG PF: F-4 Phantom / F-100 Super Sabre
    case 1: { ["CUP_B_A10_CAS_US_DynamicLoadout", "CUP_B_AV8B_GR7_BAF"] }; // CUP: A-10 / AV-8B
    case 2: { ["RHS_A10", "rhsusf_f16cm_boc_USAF"] };          // RHS: A-10 / F-16
    default { ["B_Plane_CAS_01_DynamicLoadout_F"] };
  };

  private _casClass = "B_Plane_CAS_01_DynamicLoadout_F";
  { if (isClass (configFile >> "CfgVehicles" >> _x)) exitWith { _casClass = _x; }; } forEach _preferredCAS;

  private _angle = round random 360;
  private _group = createGroup WEST;
  private _cas = _group createUnit ["ModuleCAS_F", _targetPos, [], 0, ""];
  _cas setDir _angle;
  _cas setVariable ["vehicle", _casClass, true];
  _cas setVariable ["type", 1, true]; // type 1 = missile attack
};
