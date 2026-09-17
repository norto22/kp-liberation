/*
    Check the taxi's rotor/body volume along a proposed ASL translation.
    This is a collision guard for the short hover correction, not route planning.
    Physics and collision stay enabled; no objects or terrain are removed.
*/
params ["_taxi", "_targetASL"];
if (isNull _taxi || {count _targetASL != 3}) exitWith {false};
private _delta = _targetASL vectorDiff getPosASL _taxi;
private _box = boundingBoxReal _taxi;
private _min = _box select 0;
private _max = _box select 1;
private _rotor = getNumber (configFile >> "CfgVehicles" >> typeOf _taxi >> "mainBladeRadius");
private _halfWidth = ((abs (_min select 0)) max (abs (_max select 0))) max _rotor;
_halfWidth = _halfWidth + 1;
private _rear = (_min select 1) - 1;
private _front = (_max select 1) + 1;
private _bottom = (_min select 2) - 0.5;
private _top = (_max select 2) + 0.5;

private _ignore = [_taxi] + crew _taxi + attachedObjects _taxi;
{
    if (_x isEqualType [] && {count _x >= 5}) then {
        for "_index" from 1 to 4 do {_ignore pushBack (_x select _index);};
    };
} forEach (_taxi getVariable ["ace_fastroping_deployedRopes", []]);
_ignore = _ignore select {_x isEqualType objNull && {!isNull _x}};
private _fries = _taxi getVariable ["ace_fastroping_FRIES", objNull];
private _fnc_clearLine = {
    params ["_from", "_to"];
    private _clear = true;
    {
        private _object = _x select 3;
        if (isNull _object) then {_object = _x select 2;};
        // Terrain is an obstruction too. Exclude only this taxi's own hardware
        // and riders attached to it, never every aircraft or every person.
        if (isNull _object || {!(_object in _ignore) && {!(attachedTo _object in _ignore)}}) exitWith {
            _clear = false;
            _taxi setVariable ["KPLIB_taxi_hover_blocker", [if (isNull _object) then {"terrain"} else {typeOf _object}, _x select 0]];
        };
    } forEach (lineIntersectsSurfaces [_from, _to, _taxi, _fries, true, -1, "GEOM", "NONE"]);
    _clear
};

private _clear = true;
private _samples = [
    [-_halfWidth, _rear, _bottom], [_halfWidth, _rear, _bottom],
    [-_halfWidth, _front, _bottom], [_halfWidth, _front, _bottom],
    [-_halfWidth, _rear, _top], [_halfWidth, _rear, _top],
    [-_halfWidth, _front, _top], [_halfWidth, _front, _top]
];
for "_xOffset" from -_halfWidth to _halfWidth step 4 do {
    for "_yOffset" from _rear to _front step 4 do {
        _samples pushBack [_xOffset, _yOffset, _bottom];
        _samples pushBack [_xOffset, _yOffset, _top];
    };
};
{
    private _from = AGLToASL (_taxi modelToWorld _x);
    if !([_from, _from vectorAdd _delta] call _fnc_clearLine) exitWith {_clear = false;};
} forEach _samples;
if (!_clear) exitWith {false};

// Test current and destination occupancy as well as motion, including when the
// commanded velocity is zero. A zero-length sweep alone cannot detect an obstacle.
{
    private _shift = _x;
    {
        private _height = _x;
        private _left = (AGLToASL (_taxi modelToWorld [-_halfWidth, 0, _height])) vectorAdd _shift;
        private _right = (AGLToASL (_taxi modelToWorld [_halfWidth, 0, _height])) vectorAdd _shift;
        private _back = (AGLToASL (_taxi modelToWorld [0, _rear, _height])) vectorAdd _shift;
        private _ahead = (AGLToASL (_taxi modelToWorld [0, _front, _height])) vectorAdd _shift;
        if (!([_left, _right] call _fnc_clearLine) || {!([_back, _ahead] call _fnc_clearLine)}) exitWith {_clear = false;};
    } forEach [_bottom, _top];
    if (!_clear) exitWith {};
} forEach [[0, 0, 0], _delta];
_clear
