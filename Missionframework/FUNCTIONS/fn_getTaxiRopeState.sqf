/*
    Gather live ACE attachment/rope data and evaluate deployment readiness.
    Return [ready, reason, requiredHookLength, availableLength, speed, height, distance].
    Called on the server and again on the passenger owner immediately before descent.
*/
params [
    ["_taxi", objNull, [objNull]],
    ["_lzPos", [], [[]]]
];
if (isNull _taxi) exitWith {[false, "invalid_aircraft", 0, 0, 0, 0, 0]};
if (_lzPos isEqualTo []) then {_lzPos = _taxi getVariable ["KPLIB_taxi_lz", []];};
if (count _lzPos < 2) exitWith {[false, "missing_lz", 0, 0, 0, 0, 0]};

private _config = configFile >> "CfgVehicles" >> typeOf _taxi;
private _attachment = _taxi getVariable ["ace_fastroping_FRIES", _taxi];
if (getNumber (_config >> "ace_fastroping_enabled") == 2 && {isNull _attachment || {_attachment == _taxi}}) exitWith {
    [false, "missing_fries", 0, 0, 0, 0, 0]
};
if (isNull _attachment) then {_attachment = _taxi;};
private _hookHeights = [];
{
    private _offset = _x;
    if (_offset isEqualType "") then {_offset = _attachment selectionPosition _offset;};
    _hookHeights pushBack ((_attachment modelToWorld _offset) select 2);
} forEach (getArray (_config >> "ace_fastroping_ropeOrigins"));

private _availableLength = getNumber (configFile >> "CfgWeapons" >> "ACE_rope36" >> "ace_logistics_rope_length");
if (_availableLength <= 0) then {_availableLength = 36;};
if !((_taxi getVariable ["ace_fastroping_deployedRopes", []]) isEqualTo []) then {
    // Do not substitute the supplied rope's length while shorter manually
    // deployed ropes are still replicating to the passenger owner.
    _availableLength = _taxi getVariable ["ace_fastroping_ropeLength", -1];
};
if (_availableLength <= 0) exitWith {[false, "missing_rope_length", 0, 0, 0, 0, 0]};
private _speed = vectorMagnitude velocity _taxi;
private _height = (getPosATL _taxi) select 2;
private _distance = _taxi distance2D _lzPos;
private _result = [_hookHeights, _availableLength, _height, _speed, _distance] call KPLIB_fnc_taxiRopeReadiness;
private _targetHeight = _taxi getVariable ["KPLIB_taxi_hover_target_height", KPLIB_taxi_hover_height];
if (_result select 0 && {abs (_height - _targetHeight) > 0.75}) then {
    _result set [0, false];
    _result set [1, "hover_altitude"];
};
_result append [_availableLength, _speed, _height, _distance];
_result
