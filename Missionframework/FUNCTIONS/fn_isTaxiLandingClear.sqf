/*
    Validate a ground landing footprint, not merely distance to an object's centre.
    The helicopter and its temporary pad can be ignored during approach checks.
    Returns BOOL. Does not move objects, clear vegetation, or accept rooftops.
*/
params [
    ["_pos", [], [[]]],
    ["_class", "", [""]],
    ["_taxi", objNull, [objNull]],
    ["_pad", objNull, [objNull]]
];
if (count _pos < 2 || {_class == ""}) exitWith {false};
private _ground = [_pos select 0, _pos select 1, 0];
// sizeOf may be zero before this aircraft model is instantiated. A 16 m radius
// is the fallback, with a 3 m margin around larger loaded aircraft models.
private _clearance = 16 max ((sizeOf _class) / 2 + 3);
if (surfaceIsWater _ground) exitWith {false};
// Another taxi already committed to this footprint owns it until departure.
private _reserved = false;
{
    if (_x != _pad && {_x getVariable ["KPLIB_taxi_landing_pad", false]}) exitWith {_reserved = true;};
} forEach (nearestObjects [_ground, ["HeliH"], _clearance * 2, true]);
if (_reserved) exitWith {false};

// Check the landing gear's terrain, not a perfectly flat rotor-sized clearing.
// Disable native object proximity: large bounding spheres (notably power lines)
// reject usable roads and fields. Collision geometry is checked below instead.
// The returned position is ASL; do not use it as an ATL pad position.
if ((_ground isFlatEmpty [-1, -1, 0.2, 8, 0, false, _pad]) isEqualTo []) exitWith {false};

private _fnc_isTaxiPart = {
    params ["_object"];
    !isNull _taxi && {_object == _taxi || {vehicle _object == _taxi} || {attachedTo _object == _taxi}}
};
// Keep people out of the immediate touchdown area. Other objects are checked
// against actual geometry, not a large circle around even tiny dropped items.
private _blocked = false;
{
    if !([_x] call _fnc_isTaxiPart) exitWith {_blocked = true;};
} forEach (nearestObjects [_ground, ["Man"], 5, true]);
if (_blocked) exitWith {false};

// Check the ground-to-sky column across the footprint. This rejects roofs,
// bridges and overhangs even when their model origin is far from the candidate.
// A grid also covers the interior, which the old perimeter-only rays missed.
private _samples = [+_ground];
for "_dx" from -_clearance to _clearance step 4 do {
    for "_dy" from -_clearance to _clearance step 4 do {
        if ((_dx * _dx + _dy * _dy) <= (_clearance * _clearance)) then {
            _samples pushBack [(_ground select 0) + _dx, (_ground select 1) + _dy, 0];
        };
    };
};
for "_bearing" from 0 to 315 step 45 do {
    _samples pushBack (_ground getPos [_clearance, _bearing]);
};
{
    private _point = _x;
    if (surfaceIsWater _point) exitWith {_blocked = true;};
    private _top = ATLToASL [_point select 0, _point select 1, 100];
    private _bottom = ATLToASL [_point select 0, _point select 1, 0.2];
    private _hits = lineIntersectsSurfaces [_top, _bottom, _taxi, _pad, true, -1, "GEOM", "NONE"];
    {
        private _object = _x select 3;
        if (isNull _object) then {_object = _x select 2;};
        if (!isNull _object && {!(_object isKindOf "Man")} && {!([_object] call _fnc_isTaxiPart)}) exitWith {_blocked = true;};
    } forEach _hits;
    if (_blocked) exitWith {};
} forEach _samples;
if (_blocked) exitWith {false};

// Cross the lower fuselage/rotor space as well, to catch thin walls or trunks
// that can fall between the vertical grid samples.
{
    private _height = _x;
    for "_bearing" from 0 to 135 step 45 do {
        private _from = _ground getPos [_clearance, _bearing];
        private _to = _ground getPos [_clearance, _bearing + 180];
        _from set [2, _height];
        _to set [2, _height];
        private _hits = lineIntersectsSurfaces [ATLToASL _from, ATLToASL _to, _taxi, _pad, true, -1, "GEOM", "NONE"];
        {
            private _object = _x select 3;
            if (isNull _object) then {_object = _x select 2;};
            if (!isNull _object && {!(_object isKindOf "Man")} && {!([_object] call _fnc_isTaxiPart)}) exitWith {_blocked = true;};
        } forEach _hits;
        if (_blocked) exitWith {};
    };
    if (_blocked) exitWith {};
} forEach [2, 4];
!_blocked
