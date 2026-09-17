if (!isServer || !isRemoteExecuted) exitWith {false};
params [["_lzPos", [0, 0, 0], [[]], [2, 3]]];

private _callers = allPlayers select {owner _x == remoteExecutedOwner};
private _clientID = remoteExecutedOwner;
if (_callers isEqualTo []) exitWith {
    [_clientID, "STR_TAXI_MSG_NO_ACTIVE_TAXI", [], true] call KPLIB_fnc_taxiNotify;
    false
};
private _caller = _callers select 0;
private _taxis = vehicles select {
    _x getVariable ["KPLIB_taxi_active", false]
    && {(_x getVariable ["KPLIB_taxi_group", grpNull]) == group _caller}
};
if (_taxis isEqualTo []) exitWith {
    [_clientID, "STR_TAXI_MSG_NO_ACTIVE_TAXI", [], true] call KPLIB_fnc_taxiNotify;
    false
};
_taxis = _taxis select {
    (_x getVariable ["KPLIB_taxi_phase", ""]) == "holding_for_lz"
    || {!(_x getVariable ["KPLIB_taxi_aborted", false])
        && {(_x getVariable ["KPLIB_taxi_hover_failure", ""]) == ""}
        && {!((_x getVariable ["KPLIB_taxi_phase", ""]) in ["returning", "departing", "complete"])}}
};
if (_taxis isEqualTo []) exitWith {
    [_clientID, "STR_TAXI_MSG_ALREADY_RETURNING", [], true] call KPLIB_fnc_taxiNotify;
    false
};
private _taxi = _taxis select 0;
{
    if ((_caller distance2D _x) < (_caller distance2D _taxi)) then {_taxi = _x;};
} forEach _taxis;
private _extraction = !(_lzPos isEqualTo [0, 0, 0]);
if (_extraction && {({(_lzPos distance2D _x) <= KPLIB_taxi_lz_max_range} count KPLIB_all_fobs) == 0}) exitWith {
    [_clientID, "STR_TAXI_MSG_EXTRACT_RANGE", [KPLIB_taxi_lz_max_range], true] call KPLIB_fnc_taxiNotify;
    false
};

// Per-aircraft requests prevent a second taxi from redirecting this flight.
_taxi setVariable ["KPLIB_taxi_recall", [_lzPos, _extraction]];
if (_extraction) then {
    [_taxi, "STR_TAXI_MSG_RECALL_ACCEPTED", [mapGridPosition _lzPos]] call KPLIB_fnc_taxiNotify;
} else {
    [_clientID, "STR_TAXI_MSG_RETURNING"] call KPLIB_fnc_taxiNotify;
};
true
