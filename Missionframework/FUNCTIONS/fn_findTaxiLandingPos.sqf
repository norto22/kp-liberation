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
private _emptyCandidates = 0;
private _tested = 0;
// Sample the whole search area, nearest first. BIS_fnc_findSafePos's broad
// object-distance filter can reject every seed before our geometry checks run.
private _offset = random 30;
for "_ring" from 1 to 10 do {
    for "_bearing" from 0 to 330 step 30 do {
        private _seed = _ground getPos [_maxRange * _ring / 10, _bearing + _offset];
        private _candidate = _seed findEmptyPosition [0, 10, _class];
        _tested = _tested + 1;
        if !(_candidate isEqualTo []) then {
            _emptyCandidates = _emptyCandidates + 1;
            _candidate = [_candidate select 0, _candidate select 1, 0];
            if ((_candidate distance2D _ground) <= _maxRange && {[_candidate, _class, _taxi] call KPLIB_fnc_isTaxiLandingClear}) exitWith {
                _result = _candidate;
            };
        };
        if !(_result isEqualTo []) exitWith {};
    };
    if !(_result isEqualTo []) exitWith {};
};
if (_result isEqualTo []) then {
    [format ["Taxi landing search near %1 failed: %2 seeds checked, %3 aircraft-sized empty candidates rejected by terrain/geometry checks", _ground, _tested, _emptyCandidates], "TAXI"] call KPLIB_fnc_log;
};
_result
