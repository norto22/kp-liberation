/*
    File: logistic_convoy_distress_response.sqf
    (formerly logistic_convoy_ambush.sqf)

    Description:
        Shared distress-call resolution for a convoy's physical truck,
        called by both trigger sources: the existing chance-roll ambush
        check in manage_logistics.sqf, and the continuous hostile-proximity
        watchdog (logistic_convoy_watchdog.sqf). The truck and crew already
        exist and are already alive (spawned by logistic_convoy_spawn_truck)
        - this script no longer creates a wrecked truck or a pre-killed
        driver, the crew actually fights.

        Never writes KPLIB_logistics directly (see the plan's "Context for
        Implementer" - the tick loop's write-back would silently clobber a
        direct write). Instead reports its outcome through
        KPLIB_convoy_distress_outcomes, which manage_logistics.sqf's tick
        loop consumes and applies inside its own safe forEach.

    Parameter(s):
        _convoyIndex - Index of this route in KPLIB_logistics                [NUMBER, defaults to -1]
        _truck       - The convoy's physical truck                          [OBJECT, defaults to objNull]
        _crewGroup   - The truck's crew group                               [GROUP, defaults to grpNull]
        _triggerType - "ambush" (dice-roll) or "proximity" (watchdog)       [STRING, defaults to ""]

    Returns:
        Nothing
*/

params [
    ["_convoyIndex", -1, [0]],
    ["_truck", objNull, [objNull]],
    ["_crewGroup", grpNull, [grpNull]],
    ["_triggerType", "", [""]]
];

if (_convoyIndex < 0 || isNull _truck) exitWith {};

if ((count KPLIB_convoy_distress_active) >= KPLIB_convoy_distress_max_concurrent) exitWith {
    if (KPLIB_asymmetric_debug > 0) then {[format ["Logistic convoy %1: distress call suppressed (%2 already active)", _convoyIndex, count KPLIB_convoy_distress_active], "ASYMMETRIC"] call KPLIB_fnc_log;};
};

if (_convoyIndex in KPLIB_convoy_distress_active) exitWith {};

KPLIB_convoy_distress_active pushBack _convoyIndex;

if (KPLIB_asymmetric_debug > 0) then {[format ["Logistic convoy %1: distress call starting (trigger: %2)", _convoyIndex, _triggerType], "ASYMMETRIC"] call KPLIB_fnc_log;};

private _truckPos = getPos _truck;
[0, _truckPos, _convoyIndex] remoteExec ["asymm_notifications"];

// Crew holds and defends instead of driving - supersede the MOVE waypoint.
while {(count (waypoints _crewGroup)) != 0} do {deleteWaypoint ((waypoints _crewGroup) select 0);};
{
    private _wp = _crewGroup addWaypoint [_truckPos, 10];
    _wp setWaypointType "SAD";
    _wp setWaypointCompletionRadius 10;
} forEach [0, 1, 2];
private _cycleWp = _crewGroup addWaypoint [_truckPos, 10];
_cycleWp setWaypointType "CYCLE";
_cycleWp setWaypointCompletionRadius 10;

private _attackerGroup = [_truckPos] call KPLIB_fnc_spawnGuerillaGroup;
{
    private _wp = _attackerGroup addWaypoint [_truckPos, 150];
    _wp setWaypointType "SAD";
    _wp setWaypointCompletionRadius 10;
} forEach [0, 1, 2];
private _attackerCycleWp = _attackerGroup addWaypoint [_truckPos, 150];
_attackerCycleWp setWaypointType "CYCLE";
_attackerCycleWp setWaypointCompletionRadius 10;

private _waitingTime = KPLIB_convoy_distress_duration;
while {(({alive _x} count (units _attackerGroup)) > 0) && (_waitingTime > 0)} do {
    uiSleep 1;
    private _playerNear = false;
    {
        if (((_x distance _truckPos) < 250) && (alive _x)) exitWith {_playerNear = true};
    } forEach allPlayers;
    if !(_playerNear) then {
        _waitingTime = _waitingTime - 1;
    };
};

private _survivorCount = {alive _x} count (units _attackerGroup);
private _lost = (_waitingTime <= 0) && (_survivorCount > 0);

{deleteVehicle _x} forEach (units _attackerGroup);
deleteGroup _attackerGroup;

if (_lost) then {
    [2, [0, 0, 0], _convoyIndex] remoteExec ["asymm_notifications"];

    private _cargo = (KPLIB_logistics select _convoyIndex) select 6;
    private _supplyCrates = ceil ((_cargo select 0) / 100);
    private _ammoCrates = ceil ((_cargo select 1) / 100);
    private _fuelCrates = ceil ((_cargo select 2) / 100);
    private _gain = (_survivorCount * 2) + (_supplyCrates * 2) + (_ammoCrates * 3) + (_fuelCrates * 2);

    KPLIB_guerilla_strength = KPLIB_guerilla_strength + _gain;

    KPLIB_convoy_distress_outcomes pushBack [_convoyIndex, "lose"];
    if (KPLIB_asymmetric_debug > 0) then {[format ["Logistic convoy %1: distress call lost, guerilla strength +%2", _convoyIndex, _gain], "ASYMMETRIC"] call KPLIB_fnc_log;};
} else {
    [1, [0, 0, 0], _convoyIndex] remoteExec ["asymm_notifications"];

    // Won - resume driving toward the original destination.
    if (alive _truck) then {
        private _convoyEntry = KPLIB_logistics select _convoyIndex;
        private _destPos = if ((_convoyEntry select 7) == 2) then {_convoyEntry select 3} else {_convoyEntry select 2};
        while {(count (waypoints _crewGroup)) != 0} do {deleteWaypoint ((waypoints _crewGroup) select 0);};
        private _resumeWp = _crewGroup addWaypoint [_destPos, 0];
        _resumeWp setWaypointType "MOVE";
        _resumeWp setWaypointCompletionRadius 50;
    };

    KPLIB_convoy_distress_outcomes pushBack [_convoyIndex, "win"];
    if (KPLIB_asymmetric_debug > 0) then {[format ["Logistic convoy %1: distress call defended, route preserved", _convoyIndex], "ASYMMETRIC"] call KPLIB_fnc_log;};
};

KPLIB_convoy_distress_active = KPLIB_convoy_distress_active - [_convoyIndex];
