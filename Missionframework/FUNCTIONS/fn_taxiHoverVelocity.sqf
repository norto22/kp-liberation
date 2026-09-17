/*
    Pure hover command: [target-minus-current ASL vector, previous command
    vector, elapsed seconds] -> velocity vector in m/s. Keep the previous
    command in PFH state, initially [0,0,0]; do not use current physics velocity.
    Gain 0.6/s, total speed <= 2 m/s, total acceleration <= 2 m/s^2.
    Invalid input (including an out-of-bounds prior command) fails to rest.
*/
if (isNil "_this" || {!(_this isEqualType [])} || {count _this != 3}) exitWith {[0,0,0]};
params ["_error", "_previous", "_elapsed"];
if (isNil "_error" || {!(_error isEqualType [])} || {count _error != 3}
    || {isNil "_previous"} || {!(_previous isEqualType [])} || {count _previous != 3}) exitWith {[0,0,0]};
private _invalid = false;
{
    if (isNil "_x" || {!(_x isEqualType 0)} || {!((_x - _x) isEqualTo 0)}) exitWith {_invalid = true;};
} forEach (_error + _previous + [_elapsed]);
if (_invalid) exitWith {[0,0,0]};
if (vectorMagnitude _previous > 2.00001) exitWith {[0,0,0]};

// Scale before measuring length, avoiding overflow for very large finite errors.
private _scale = 1;
{_scale = _scale max (abs _x);} forEach _error;
private _scaledError = _error vectorMultiply (1 / _scale);
private _scaledLength = vectorMagnitude _scaledError;
private _desired = if (_scaledLength > 0 && {_scale > (2 / (0.6 * _scaledLength))}) then {
    _scaledError vectorMultiply (2 / _scaledLength)
} else {
    _error vectorMultiply 0.6
};
private _delta = _desired vectorDiff _previous;
private _deltaLength = vectorMagnitude _delta;
private _maxDelta = 2 * ((_elapsed max 0) min 0.1);
if (_deltaLength > _maxDelta) then {
    _delta = _delta vectorMultiply (_maxDelta / _deltaLength);
};
_previous vectorAdd _delta
