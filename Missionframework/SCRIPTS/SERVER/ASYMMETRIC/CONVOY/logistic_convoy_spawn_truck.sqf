/*
    File: logistic_convoy_spawn_truck.sqf

    Description:
        Spawns the always-physical AI-crewed truck for one traveling convoy
        leg (KPLIB_logistics state 2/4), gives it a friendly-side crew, and
        sends it driving toward the destination. Tracked in
        KPLIB_convoy_trucks so the tick loop and watchdog can find it.

        The truck's real position never gates the abstract delivery timer in
        manage_logistics.sqf - it is a visual layer only.

    Parameter(s):
        _convoyIndex - Index of this route in KPLIB_logistics [NUMBER, defaults to -1]
        _originPos   - Position to spawn the truck at         [POSITION, defaults to [0,0,0]]
        _destPos     - Position to drive the truck toward     [POSITION, defaults to [0,0,0]]

    Returns:
        Spawned truck [OBJECT]
*/

params [
    ["_convoyIndex", -1, [0]],
    ["_originPos", [0, 0, 0], [[]], [2, 3]],
    ["_destPos", [0, 0, 0], [[]], [2, 3]]
];

if (_convoyIndex < 0) exitWith {["Invalid convoy index given"] call BIS_fnc_error; objNull};

private _truck = [_originPos, KPLIB_truck_classname, false, true] call KPLIB_fnc_spawnVehicle;

if (isNull _truck) exitWith {
    [format ["Logistic convoy %1: failed to spawn physical truck", _convoyIndex], "ERROR"] call KPLIB_fnc_log;
    objNull
};

[_truck] call KPLIB_fnc_forceBluforCrew;

private _crewGroup = group (driver _truck);
private _wp = _crewGroup addWaypoint [_destPos, 0];
_wp setWaypointType "MOVE";
_wp setWaypointCompletionRadius 50;

KPLIB_convoy_trucks pushBack [_convoyIndex, _truck, _crewGroup];

[_convoyIndex, _truck, _crewGroup] spawn logistic_convoy_watchdog;

if (KPLIB_logistic_debug > 0) then {[format ["Logistic convoy %1: physical truck spawned at %2, driving to %3", _convoyIndex, _originPos, _destPos], "LOGISTIC"] call KPLIB_fnc_log;};

_truck
