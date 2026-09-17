/*
    File: logistic_convoy_watchdog.sqf

    Description:
        One instance runs per live physical convoy truck. Every
        KPLIB_convoy_watchdog_interval seconds it:
          1. Checks whether the truck has moved enough since last check; if
             not, nudges it, then (after enough failed nudges) repositions it
             to the position the abstract KPLIB_logistics timer implies it
             should currently be at. Never touches the timer itself.
          2. Polls for real hostile groups within
             KPLIB_convoy_distress_proximity_radius and triggers the shared
             distress response independently of the dice-roll trigger.
        Both checks are skipped while this convoy already has an active,
        unresolved distress call - the truck is intentionally stationary
        (fighting) then, not stuck, and a second trigger would be redundant.

        Exits on its own once the truck is gone; manage_logistics.sqf's tick
        loop owns actually deleting the truck/crew/KPLIB_convoy_trucks entry.

    Parameter(s):
        _convoyIndex - Index of this route in KPLIB_logistics [NUMBER, defaults to -1]
        _truck       - The physical convoy truck                [OBJECT, defaults to objNull]
        _crewGroup   - The truck's crew group                   [GROUP, defaults to grpNull]

    Returns:
        Nothing
*/

params [
    ["_convoyIndex", -1, [0]],
    ["_truck", objNull, [objNull]],
    ["_crewGroup", grpNull, [grpNull]]
];

if (_convoyIndex < 0 || isNull _truck) exitWith {};

private _lastPos = getPos _truck;
private _stuckCount = 0;

while {alive _truck} do {
    sleep KPLIB_convoy_watchdog_interval;

    if (!alive _truck) exitWith {};
    if ((KPLIB_convoy_trucks findIf {(_x select 0) == _convoyIndex}) == -1) exitWith {};

    if (!(_convoyIndex in KPLIB_convoy_distress_active)) then {
        // 1. Stuck-AI recovery
        private _moved = _truck distance _lastPos;
        if (_moved < KPLIB_convoy_watchdog_stuck_distance) then {
            _stuckCount = _stuckCount + 1;
            if (_stuckCount <= KPLIB_convoy_watchdog_nudge_attempts) then {
                if (KPLIB_logistic_debug > 0) then {[format ["Logistic convoy %1: truck stalled, nudging (attempt %2)", _convoyIndex, _stuckCount], "LOGISTIC"] call KPLIB_fnc_log;};
                private _truckDir = getDir _truck;
                _truck setVelocity ((velocity _truck) vectorAdd [(sin _truckDir) * 5, (cos _truckDir) * 5, 0]);
                (driver _truck) doMove (waypointPosition [_crewGroup, (currentWaypoint _crewGroup)]);
            } else {
                private _convoyEntry = KPLIB_logistics select _convoyIndex;
                private _remainingTicks = _convoyEntry select 8;
                private _interpPos = if ((_convoyEntry select 7) == 2) then {
                    (_convoyEntry select 3) getPos [_remainingTicks * 400, (_convoyEntry select 3) getDir (_convoyEntry select 2)]
                } else {
                    (_convoyEntry select 2) getPos [_remainingTicks * 400, (_convoyEntry select 2) getDir (_convoyEntry select 3)]
                };
                private _roadObj = [_interpPos, 400, []] call BIS_fnc_nearestRoad;
                if (!isNull _roadObj) then {
                    if (KPLIB_logistic_debug > 0) then {[format ["Logistic convoy %1: truck still stuck after %2 nudges, repositioning to %3", _convoyIndex, _stuckCount, getPos _roadObj], "LOGISTIC"] call KPLIB_fnc_log;};
                    _truck setPos (getPos _roadObj);
                    _truck setDir (getDir _roadObj);
                    if (!alive (driver _truck)) then {
                        {deleteVehicle _x} forEach (units _crewGroup);
                        [_truck] call KPLIB_fnc_forceBluforCrew;
                    };
                };
                _stuckCount = 0;
            };
        } else {
            _stuckCount = 0;
        };
        _lastPos = getPos _truck;

        // 2. Continuous hostile-proximity distress trigger
        private _nearbyHostiles = allGroups select {(side _x == KPLIB_side_enemy) && {(_truck distance2D (leader _x)) < KPLIB_convoy_distress_proximity_radius}};
        if (
            (count _nearbyHostiles) > 0 &&
            {(count KPLIB_convoy_distress_active) < KPLIB_convoy_distress_max_concurrent} &&
            {!(_convoyIndex in KPLIB_convoy_distress_active)}
        ) then {
            if (KPLIB_asymmetric_debug > 0) then {[format ["Logistic convoy %1: hostile group within %2m, triggering distress call", _convoyIndex, KPLIB_convoy_distress_proximity_radius], "ASYMMETRIC"] call KPLIB_fnc_log;};
            [_convoyIndex, _truck, _crewGroup, "proximity"] spawn logistic_convoy_distress_response;
        };
    };
};
