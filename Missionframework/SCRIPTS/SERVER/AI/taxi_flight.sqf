params [
    ["_taxi", objNull, [objNull]],
    ["_lzPos", [0, 0, 0], [[]], [2, 3]],
    ["_fobPos", [0, 0, 0], [[]], [2, 3]]
];

if (isNull _taxi) exitWith {};

KPLIB_taxi_recall_requested = false;
KPLIB_taxi_boarding_mode = false;
KPLIB_taxi_target_position = _lzPos;
publicVariable "KPLIB_taxi_recall_requested";
publicVariable "KPLIB_taxi_boarding_mode";
publicVariable "KPLIB_taxi_target_position";

private _grp = group (driver _taxi);
private _pilot = driver _taxi;

private _fnc_clearWaypoints = {
    while {(count (waypoints _grp)) != 0} do {deleteWaypoint ((waypoints _grp) select 0);};
};

// Fly a MOVE waypoint toward _targetPos and wait for arrival/death/recall. A plain MOVE
// waypoint does not auto-land a helicopter (unlike GETOUT/TR UNLOAD), so this is used for
// both the long transit legs and to approach/hold near an LZ.
private _fnc_flyTo = {
    params ["_targetPos"];
    [] call _fnc_clearWaypoints;
    private _wp = _grp addWaypoint [_targetPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "FULL";
    _wp setWaypointCompletionRadius 40;
    waitUntil {
        sleep 1;
        !alive _taxi || !alive _pilot || ((_taxi distance2D _targetPos) < 60) || KPLIB_taxi_recall_requested
    };
};

private _fnc_isRopeCapable = {
    KPLIB_ace && {(getNumber (configFile >> "CfgVehicles" >> typeOf _taxi >> "ace_fastroping_enabled")) > 0}
};

// Small infantry squad spawned near the actual LZ, using the same composition/creation
// pattern spawn_battlegroup.sqf's infantry branch uses, then handed off to battlegroup_ai
// for pursuit behaviour. Deliberately does NOT reuse spawn_battlegroup/getOpforSpawnPoint,
// whose spawn-point search only resolves existing sectors_opfor markers and silently
// no-ops for an arbitrary player-chosen LZ.
private _fnc_alertnessHook = {
    if ((random 100) < KPLIB_taxi_alertness_chance && {[] call KPLIB_fnc_getOpforCap < KPLIB_battlegroup_cap}) then {
        private _spawnPos = _lzPos getPos [300 + random 300, random 360];
        private _infGrp = createGroup [KPLIB_side_enemy, true];
        {
            [_x, _spawnPos, _infGrp, "PRIVATE", 0.5] call KPLIB_fnc_createManagedUnit;
        } forEach ([] call KPLIB_fnc_getSquadComp);
        [_infGrp] spawn battlegroup_ai;
    };
};

private _fnc_cargoCount = {
    {(assignedVehicleRole _x) select 0 == "cargo"} count (crew _taxi)
};

private _hoverStart = time;
private _ropesEverUsed = false;

// ---- Initial flight to the requested LZ and insertion ----
private _hoverPos = [(_lzPos select 0), (_lzPos select 1), (_lzPos select 2) + 20];
[_hoverPos] call _fnc_flyTo;

if (alive _taxi && alive _pilot && !KPLIB_taxi_recall_requested) then {

    if ([] call _fnc_isRopeCapable) then {
        // ---- ACE fast-rope insertion ----
        private _friesValue = getNumber (configFile >> "CfgVehicles" >> typeOf _taxi >> "ace_fastroping_enabled");
        if (_friesValue == 2) then {
            [_taxi] call ace_fastroping_fnc_equipFRIES;
        };
        [_taxi] call ace_fastroping_fnc_deployRopes;
        [_taxi, false, true] call ace_fastroping_fnc_deployAI;

        _hoverStart = time;
        waitUntil {
            sleep 1;
            private _ropes = _taxi getVariable ["ace_fastroping_deployedRopes", []];
            private _inUse = _ropes findIf {_x select 5};
            if (_inUse != -1) then {_ropesEverUsed = true;};
            (_ropesEverUsed && {_inUse == -1})
            || !alive _taxi
            || KPLIB_taxi_recall_requested
            || (time > _hoverStart + KPLIB_taxi_hover_timeout)
            || (damage _taxi > 0.5)
        };

        // Grace period only on the ropes-clear branch - not on recall/timeout/damage.
        if (
            alive _taxi
            && _ropesEverUsed
            && !KPLIB_taxi_recall_requested
            && (damage _taxi <= 0.5)
            && (time <= _hoverStart + KPLIB_taxi_hover_timeout)
        ) then {
            sleep KPLIB_taxi_rope_clear_grace;
            waitUntil {
                sleep 1;
                private _ropes = _taxi getVariable ["ace_fastroping_deployedRopes", []];
                ((_ropes findIf {_x select 5}) == -1) || !alive _taxi || KPLIB_taxi_recall_requested || (damage _taxi > 0.5)
            };
        };

        if (alive _taxi) then {
            stats_taxi_insertions = stats_taxi_insertions + 1;
            [] call _fnc_alertnessHook;
        };
    } else {
        // ---- Fallback: no rope capability - land and unload normally ----
        [] call _fnc_clearWaypoints;
        private _wp = _grp addWaypoint [_lzPos, 0];
        _wp setWaypointType "TR UNLOAD";
        _wp setWaypointCompletionRadius 40;
        waitUntil {sleep 1; ((_taxi distance2D _lzPos) < 40) || !alive _taxi};

        _hoverStart = time;
        waitUntil {
            sleep 1;
            (([] call _fnc_cargoCount) == 0)
            || !alive _taxi
            || KPLIB_taxi_recall_requested
            || (time > _hoverStart + KPLIB_taxi_hover_timeout)
            || (damage _taxi > 0.5)
        };

        if (alive _taxi) then {
            stats_taxi_insertions = stats_taxi_insertions + 1;
            [] call _fnc_alertnessHook;
        };
    };
};

// ---- Post-insertion: stand by for a recall (Task 7), either extraction or return to FOB ----
private _terminal = false;
while {alive _taxi && !_terminal} do {

    waitUntil {sleep 1; !alive _taxi || KPLIB_taxi_recall_requested};
    if (!alive _taxi) exitWith {};

    KPLIB_taxi_recall_requested = false;
    publicVariable "KPLIB_taxi_recall_requested";

    private _target = KPLIB_taxi_target_position;
    private _returnToFob = !KPLIB_taxi_boarding_mode;

    [_target] call _fnc_flyTo;

    if (alive _taxi && _returnToFob) then {
        _terminal = true;
    };

    if (alive _taxi && !_returnToFob) then {
        // ---- Boarding pickup at a field LZ - land/hold low and wait for the squad ----
        _hoverStart = time;
        waitUntil {
            sleep 1;
            !alive _taxi
            || (([] call _fnc_cargoCount) > 0)
            || KPLIB_taxi_recall_requested
            || (time > _hoverStart + KPLIB_taxi_hover_timeout)
            || (damage _taxi > 0.5)
        };
        if (alive _taxi && (([] call _fnc_cargoCount) > 0)) then {
            waitUntil {
                private _before = [] call _fnc_cargoCount;
                sleep 3;
                (([] call _fnc_cargoCount) == _before) || !alive _taxi || KPLIB_taxi_recall_requested || (damage _taxi > 0.5)
            };
        };
    };
};

// ---- Cleanup: release the pool slot ----
if (!alive _taxi) then {
    KPLIB_taxi_slots_active = (KPLIB_taxi_slots_active - 1) max 0;
    KPLIB_taxi_cooldown_until pushBack (time + KPLIB_taxi_respawn_cooldown);
    publicVariable "KPLIB_taxi_slots_active";
    publicVariable "KPLIB_taxi_cooldown_until";
} else {
    KPLIB_taxi_slots_active = (KPLIB_taxi_slots_active - 1) max 0;
    publicVariable "KPLIB_taxi_slots_active";
    _taxi setVariable ["KPLIB_taxi_active", false, true];
    {deleteVehicle _x} forEach (crew _taxi);
    deleteVehicle _taxi;
};
