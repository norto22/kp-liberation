/*
    Pure fast-rope readiness decision. Hook heights are measured above their
    local ground; speed is a nonnegative magnitude in m/s, distance is in m.
    Returns [ready, reason, requiredHookLength]. Required length includes a
    0.5 m slack margin and is zero when hooks/input cannot be evaluated.
*/
if (isNil "_this" || {!(_this isEqualType [])}) exitWith {[false, "invalid_input", 0]};
if (count _this != 5) exitWith {[false, "invalid_input", 0]};
params ["_hookHeights", "_availableRopeLength", "_aircraftHeight", "_speedMS", "_distanceToLZ"];
if (isNil "_hookHeights" || {!(_hookHeights isEqualType [])}) exitWith {[false, "invalid_input", 0]};

private _invalid = false;
{
    // A finite scalar subtracts from itself to zero; reject infinity and NaN.
    if (isNil "_x" || {!(_x isEqualType 0)} || {!((_x - _x) isEqualTo 0)}) exitWith {_invalid = true;};
} forEach [_availableRopeLength, _aircraftHeight, _speedMS, _distanceToLZ];
if (_invalid) exitWith {[false, "invalid_input", 0]};
if (_availableRopeLength <= 0 || {_speedMS < 0} || {_distanceToLZ < 0}) exitWith {[false, "invalid_input", 0]};
if (_hookHeights isEqualTo []) exitWith {[false, "no_hooks", 0]};

private _highestHook = 0;
{
    if (isNil "_x" || {!(_x isEqualType 0)} || {!((_x - _x) isEqualTo 0)} || {_x < 0}) exitWith {_invalid = true;};
    _highestHook = _highestHook max _x;
} forEach _hookHeights;
if (_invalid) exitWith {[false, "invalid_input", 0]};
private _requiredHookLength = _highestHook + 0.5;
if (_aircraftHeight <= 5) exitWith {[false, "too_low", _requiredHookLength]};
if (_requiredHookLength > _availableRopeLength) exitWith {[false, "rope_too_short", _requiredHookLength]};
if (_speedMS >= 3) exitWith {[false, "moving", _requiredHookLength]};
if (_distanceToLZ >= 50) exitWith {[false, "outside_lz", _requiredHookLength]};
[true, "ready", _requiredHookLength]
