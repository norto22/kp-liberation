/*
    Pure cleanup gate. Call with an array of rope states, each containing
    [occupied BOOL, broken BOOL, attachedRiderCount NUMBER]. Broken ropes can
    still carry attached riders; neither breakage nor occupancy alone proves
    that it is safe to cut ropes or move the aircraft. Invalid input fails closed.
*/
if (isNil "_this" || {!(_this isEqualType [])}) exitWith {false};
private _clear = true;
{
    if (isNil "_x" || {!(_x isEqualType [])} || {count _x != 3}) exitWith {_clear = false;};
    _x params ["_occupied", "_broken", "_attachedRiderCount"];
    if (isNil "_occupied" || {!(_occupied isEqualType false)}
        || {isNil "_broken"} || {!(_broken isEqualType false)}
        || {isNil "_attachedRiderCount"} || {!(_attachedRiderCount isEqualType 0)}) exitWith {_clear = false;};
    if (!((_attachedRiderCount - _attachedRiderCount) isEqualTo 0)
        || {_attachedRiderCount != 0}
        || {_occupied && {!_broken}}) exitWith {_clear = false;};
} forEach _this;
_clear
