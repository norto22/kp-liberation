// Run ACE's moveOut and rope animation where the passenger is local.
if (!isRemoteExecuted || {remoteExecutedOwner != 2}) exitWith {};
params ["_unit", "_taxi", ["_checkOnly", false], ["_requestId", ""]];
if (_checkOnly) exitWith {
    [format ["Taxi %1 passenger %2 ACE fast-roping: addon=%3, canFastRope=%4, fastRope=%5", netId _taxi, name _unit, isClass (configFile >> "CfgPatches" >> "ace_fastroping"), !isNil "ace_fastroping_fnc_canFastRope", !isNil "ace_fastroping_fnc_fastRope"], "TAXI"] remoteExecCall ["KPLIB_fnc_log", 2];
};

private _fnc_refuse = {
    params ["_reason"];
    _unit setVariable ["KPLIB_taxi_rope_result", [_requestId, "refused", _reason], true];
};
if (!canSuspend) exitWith {["unscheduled_request"] call _fnc_refuse;};
if (isNil "ace_fastroping_fnc_canFastRope" || {isNil "ace_fastroping_fnc_fastRope"}) exitWith {
    ["missing_ace_fastroping"] call _fnc_refuse;
};

private _deadline = diag_tickTime + 5;
private _ready = false;
private _cancelled = false;
private _state = [];
waitUntil {
    sleep 0.1;
    _cancelled = !local _unit || {!alive _unit} || {vehicle _unit != _taxi}
        || {!alive _taxi} || {damage _taxi > 0.5}
        || {_taxi getVariable ["KPLIB_taxi_aborted", false]}
        || {(_taxi getVariable ["KPLIB_taxi_phase", ""]) in ["leaving_lz", "returning", "departing", "complete"]};
    _state = [_taxi] call KPLIB_fnc_getTaxiRopeState;
    _ready = !_cancelled
        && {(_taxi getVariable ["KPLIB_taxi_phase", ""]) == "inserting"}
        && {_state select 0}
        && {[_unit, _taxi] call ace_fastroping_fnc_canFastRope};
    _ready || _cancelled || diag_tickTime > _deadline
};
if (!_ready) exitWith {
    [format ["cancelled=%1, readiness=%2, phase=%3, ropes=%4", _cancelled, _state, _taxi getVariable ["KPLIB_taxi_phase", ""], count (_taxi getVariable ["ace_fastroping_deployedRopes", []])]] call _fnc_refuse;
};

// Make the final check and dispatch atomic on the owner. In particular, never
// trust the earlier server speed check after network/scheduler delays.
private _sent = false;
isNil {
    _state = [_taxi] call KPLIB_fnc_getTaxiRopeState;
    if (local _unit && {alive _unit} && {vehicle _unit == _taxi}
        && {alive _taxi} && {damage _taxi <= 0.5}
        && {!(_taxi getVariable ["KPLIB_taxi_aborted", false])}
        && {(_taxi getVariable ["KPLIB_taxi_phase", ""]) == "inserting"}
        && {_state select 0} && {[_unit, _taxi] call ace_fastroping_fnc_canFastRope}) then {
        unassignVehicle _unit;
        [_unit, _taxi] call ace_fastroping_fnc_fastRope;
        _unit setVariable ["KPLIB_taxi_rope_result", [_requestId, "started", "ready"], true];
        _sent = true;
    };
};
if (!_sent) then {["readiness_changed_before_dispatch"] call _fnc_refuse;};
