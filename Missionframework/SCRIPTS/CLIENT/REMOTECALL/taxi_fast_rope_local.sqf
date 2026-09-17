// Run ACE's moveOut and rope animation where the passenger is local.
if (!isRemoteExecuted || {remoteExecutedOwner != 2}) exitWith {};
params ["_unit", "_taxi", ["_checkOnly", false]];
if (_checkOnly) exitWith {
    [format ["Taxi %1 passenger %2 ACE fast-roping: addon=%3, canFastRope=%4, fastRope=%5", netId _taxi, name _unit, isClass (configFile >> "CfgPatches" >> "ace_fastroping"), !isNil "ace_fastroping_fnc_canFastRope", !isNil "ace_fastroping_fnc_fastRope"], "TAXI"] remoteExecCall ["KPLIB_fnc_log", 2];
};
if (!local _unit || {!alive _unit} || {vehicle _unit != _taxi}) exitWith {};
if ((_taxi getVariable ["KPLIB_taxi_phase", ""]) != "inserting" || {damage _taxi > 0.5}) exitWith {};
if (_taxi getVariable ["KPLIB_taxi_aborted", false]) exitWith {};
if (isNil "ace_fastroping_fnc_canFastRope") exitWith {};
if ([_unit, _taxi] call ace_fastroping_fnc_canFastRope) then {
    [_unit, _taxi] call ace_fastroping_fnc_fastRope;
};
