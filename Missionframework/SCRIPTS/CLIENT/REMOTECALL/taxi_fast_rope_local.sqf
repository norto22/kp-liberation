// Run ACE's moveOut and rope animation where the passenger is local.
if (!isRemoteExecuted || {remoteExecutedOwner != 2}) exitWith {};
params ["_unit", "_taxi"];
if (!local _unit || {!alive _unit} || {vehicle _unit != _taxi}) exitWith {};
if ((_taxi getVariable ["KPLIB_taxi_phase", ""]) != "inserting" || {damage _taxi > 0.5}) exitWith {};
if (_taxi getVariable ["KPLIB_taxi_aborted", false]) exitWith {};
if (isNil "ace_fastroping_fnc_canFastRope") exitWith {};
if ([_unit, _taxi] call ace_fastroping_fnc_canFastRope) then {
    [_unit, _taxi] call ace_fastroping_fnc_fastRope;
};
