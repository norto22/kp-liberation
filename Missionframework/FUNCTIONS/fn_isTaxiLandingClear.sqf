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
private _clearance = 25 max ((sizeOf _class) / 2 + 10);
if (surfaceIsWater _ground) exitWith {false};
// Another taxi already committed to this footprint owns it until departure.
private _reserved = false;
{
    if (_x != _pad && {_x getVariable ["KPLIB_taxi_landing_pad", false]}) exitWith {_reserved = true;};
} forEach (nearestObjects [_ground, ["HeliH"], _clearance * 2, true]);
if (_reserved) exitWith {false};

// Native static-object proximity accounts for bounding spheres, including large
// buildings whose centres are outside the landing footprint. Never use this
// command's returned ASL altitude as an ATL pad position.
if ((_ground isFlatEmpty [_clearance min 50, -1, 0.1, _clearance, 0, false, _pad]) isEqualTo []) exitWith {false};

private _fnc_isTaxiPart = {
    params ["_object"];
    !isNull _taxi && {_object == _taxi || {vehicle _object == _taxi} || {attachedTo _object == _taxi}}
};
// isFlatEmpty does not reliably account for vehicles or people. Keep vehicles
// outside the rotor footprint and people out of the immediate touchdown area.
private _blocked = false;
{
    if (!(_x isKindOf "HeliH") && {!([_x] call _fnc_isTaxiPart)}) then {
        private _objectRadius = (sizeOf (typeOf _x)) / 2;
        private _separation = if (_x isKindOf "Man") then {5} else {_clearance};
        if ((_ground distance2D _x) < (_separation + _objectRadius)) exitWith {_blocked = true;};
    };
    if (_blocked) exitWith {};
} forEach (nearestObjects [_ground, ["AllVehicles", "Thing"], _clearance + 100, true]);
if (_blocked) exitWith {false};

// Check the ground-to-sky column across the footprint. This rejects roofs,
// bridges and overhangs even when their model origin is far from the candidate.
private _samples = [+_ground];
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
!_blocked
