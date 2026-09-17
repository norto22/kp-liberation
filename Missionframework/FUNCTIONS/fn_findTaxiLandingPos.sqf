/*
    Find clear terrain for the requested helicopter. Returns [x,y,0] ATL, or []
    when no suitable site exists. Never fall back to an unchecked position.
*/
params [
    ["_center", [], [[]]],
    ["_class", "", [""]],
    ["_maxRange", 300, [0]],
    ["_taxi", objNull, [objNull]]
];
if (count _center < 2 || {_class == ""}) exitWith {[]};
private _ground = [_center select 0, _center select 1, 0];
if ([_ground, _class, _taxi] call KPLIB_fnc_isTaxiLandingClear) exitWith {_ground};

private _result = [];
private _clearance = 25 max ((sizeOf _class) / 2 + 10);
for "_attempt" from 1 to 30 do {
    private _candidate = [_ground, 25, _maxRange, _clearance min 50, 0, 0.1, 0, [], [[0, 0], [0, 0]]] call BIS_fnc_findSafePos;
    if !(_candidate isEqualTo [0, 0]) then {
        _candidate = [_candidate select 0, _candidate select 1, 0];
        if ((_candidate distance2D _ground) <= _maxRange && {[_candidate, _class, _taxi] call KPLIB_fnc_isTaxiLandingClear}) exitWith {
            _result = _candidate;
        };
    };
    if !(_result isEqualTo []) exitWith {};
};
_result
