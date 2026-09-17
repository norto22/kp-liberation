params [
    ["_taxi", objNull, [objNull]],
    ["_lzPos", [0, 0, 0], [[]], [2, 3]],
    ["_fobPos", [0, 0, 0], [[]], [2, 3]],
    ["_pickupPos", [0, 0, 0], [[]], [2, 3]],
    ["_spawnPos", [0, 0, 0], [[]], [2, 3]]
];
if (!isServer || isNull _taxi) exitWith {};

private _pilot = driver _taxi;
private _grp = group _pilot;
private _flightCrew = crew _taxi;
private _damageAbort = false;
_taxi setVariable ["KPLIB_taxi_recall", []];

// Enemy contacts must not replace the transport route with attack runs.
_grp setBehaviour "CARELESS";
_grp setCombatMode "BLUE";
{
    _x disableAI "AUTOCOMBAT";
    _x disableAI "TARGET";
    _x disableAI "AUTOTARGET";
} forEach _flightCrew;

private _fnc_passengers = {
    // Include FFV and player-occupied crew seats; never delete a passenger.
    (crew _taxi) select {!(_x in _flightCrew) || isPlayer _x}
};
private _fnc_flyable = {alive _taxi && alive _pilot && canMove _taxi};
private _fnc_interrupted = {
    params [["_returning", false]];
    if (!_damageAbort && {damage _taxi > 0.5}) then {
        _damageAbort = true;
        _taxi setVariable ["KPLIB_taxi_aborted", true, true];
    };
    !([] call _fnc_flyable) || {!_returning && {
        _damageAbort || !((_taxi getVariable ["KPLIB_taxi_recall", []]) isEqualTo [])
    }}
};
private _fnc_clearWaypoints = {
    while {count waypoints _grp > 0} do {deleteWaypoint ((waypoints _grp) select 0);};
};
private _fnc_flyTo = {
    params ["_targetPos", ["_height", 100], ["_returning", false]];
    if ([_returning] call _fnc_interrupted) exitWith {false};
    _pilot enableAI "MOVE";
    _taxi land "NONE";
    _taxi engineOn true;
    _taxi flyInHeight 100;
    [] call _fnc_clearWaypoints;
    private _wp = _grp addWaypoint [_targetPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "NORMAL";
    _wp setWaypointCompletionRadius 20;
    _grp setCurrentWaypoint _wp;
    _pilot doMove _targetPos;
    private _deadline = time + KPLIB_taxi_hover_timeout + ((_taxi distance2D _targetPos) / 20);
    waitUntil {
        sleep 0.5;
        if (_taxi distance2D _targetPos < 300) then {_taxi flyInHeight _height;};
        ([_returning] call _fnc_interrupted) || _taxi distance2D _targetPos < 30 || time > _deadline
    };
    // Clear the waypoint on EVERY exit, including damage and timeout.
    [] call _fnc_clearWaypoints;
    doStop _pilot;
    !([_returning] call _fnc_interrupted) && {_taxi distance2D _targetPos < 30}
};
private _fnc_land = {
    params ["_pos", ["_returning", false]];
    private _pad = createVehicle ["Land_HelipadEmpty_F", _pos, [], 0, "CAN_COLLIDE"];
    private _arrived = [_pos, 30, _returning] call _fnc_flyTo;
    private _landed = false;
    if (_arrived) then {
        _taxi land "LAND";
        private _deadline = time + KPLIB_taxi_hover_timeout;
        waitUntil {
            sleep 1;
            _landed = isTouchingGround _taxi && {abs speed _taxi < 2};
            _landed || ([_returning] call _fnc_interrupted) || time > _deadline
        };
    };
    deleteVehicle _pad;
    _landed && {!([_returning] call _fnc_interrupted)}
};
private _fnc_board = {
    private _deadline = time + KPLIB_taxi_hover_timeout;
    private _lastPassengers = [];
    private _lastChange = time;
    private _ready = false;
    waitUntil {
        sleep 1;
        private _passengers = ([] call _fnc_passengers) select {alive _x};
        if !(_passengers isEqualTo _lastPassengers) then {
            _lastPassengers = _passengers;
            _lastChange = time;
        };
        _ready = !(_passengers isEqualTo []) && {time >= _lastChange + 15};
        _ready || ([false] call _fnc_interrupted) || time > _deadline
    };
    _ready && {!([false] call _fnc_interrupted)}
};
private _fnc_ropesClear = {
    private _ropes = _taxi getVariable ["ace_fastroping_deployedRopes", []];
    ({(_x select 5) && {!(_x select 6)}} count _ropes) == 0
};
private _fnc_insert = {
    private _config = configFile >> "CfgVehicles" >> typeOf _taxi;
    private _ropeCapable = KPLIB_ace && {!isNil "ace_fastroping_fnc_deployRopes"}
        && {getNumber (_config >> "ace_fastroping_enabled") > 0};

    // Unsupported preset aircraft use a real landing instead of an empty hover.
    if (!_ropeCapable) exitWith {
        private _landingPos = [_lzPos, 0, 100, 15, 0, 0.3, 0, [], [[0, 0], [0, 0]]] call BIS_fnc_findSafePos;
        if (_landingPos isEqualTo [0, 0]) exitWith {false};
        if !([_landingPos] call _fnc_land) exitWith {false};
        private _deadline = time + KPLIB_taxi_hover_timeout;
        waitUntil {sleep 1; ([] call _fnc_passengers) isEqualTo [] || ([false] call _fnc_interrupted) || time > _deadline};
        ([] call _fnc_passengers) isEqualTo [] && {!([false] call _fnc_interrupted)}
    };

    if !([_lzPos, 20] call _fnc_flyTo) exitWith {false};
    private _deadline = time + KPLIB_taxi_hover_timeout;
    private _hoverReady = false;
    waitUntil {
        sleep 0.5;
        private _height = (getPosATL _taxi) select 2;
        _hoverReady = _height > 5 && {_height < 26} && {vectorMagnitude velocity _taxi < 3}
            && {_taxi distance2D _lzPos < 50};
        _hoverReady || ([false] call _fnc_interrupted) || time > _deadline
    };
    if (!_hoverReady || {[false] call _fnc_interrupted}) exitWith {false};
    if (getNumber (_config >> "ace_fastroping_enabled") == 2
        && {isNull (_taxi getVariable ["ace_fastroping_FRIES", objNull])}) exitWith {false};

    // Do not also call deployAI: it deploys duplicate ropes, changes passenger
    // groups, and independently cuts the ropes and resumes the pilot.
    _pilot disableAI "MOVE";
    _taxi setVariable ["KPLIB_taxi_phase", "inserting", true];
    if ((_taxi getVariable ["ace_fastroping_deployedRopes", []]) isEqualTo []) then {
        [_taxi] call ace_fastroping_fnc_prepareFRIES;
        private _prepareDeadline = time + 15;
        waitUntil {sleep 0.2;
            (_taxi getVariable ["ace_fastroping_deploymentStage", 0]) == 2
            || ([false] call _fnc_interrupted) || time > _prepareDeadline
        };
        if ((_taxi getVariable ["ace_fastroping_deploymentStage", 0]) == 2 && {!([false] call _fnc_interrupted)}) then {
            [_taxi, objNull, "ACE_rope36"] call ace_fastroping_fnc_deployRopes;
            sleep 2;
        };
    };

    private _queue = ([] call _fnc_passengers) select {alive _x};
    private _success = !(_queue isEqualTo []) && {!((_taxi getVariable ["ace_fastroping_deployedRopes", []]) isEqualTo [])};
    _deadline = time + KPLIB_taxi_hover_timeout;
    {
        if (!_success || {[false] call _fnc_interrupted} || {time > _deadline}) exitWith {_success = false;};
        private _passenger = _x;
        if (alive _passenger && {vehicle _passenger == _taxi}) then {
            // Dispatch on the unit's owner, including player clients and HCs.
            waitUntil {sleep 0.2; ([] call _fnc_ropesClear) || ([false] call _fnc_interrupted) || time > _deadline};
            if (!([false] call _fnc_interrupted) && {time <= _deadline}) then {
                [_passenger, _taxi] remoteExecCall ["taxi_fast_rope_local", _passenger];
                private _startDeadline = time + 10;
                private _started = false;
                waitUntil {sleep 0.2;
                    _started = vehicle _passenger != _taxi && {
                        !(isNull attachedTo _passenger) || {(getPosATL _passenger) select 2 < 2}
                    };
                    _started || ([false] call _fnc_interrupted) || time > _startDeadline
                };
                if (!_started) then {_success = false;};
                waitUntil {sleep 0.2;
                    (([] call _fnc_ropesClear) && {isNull attachedTo _passenger})
                    || !alive _taxi || !alive _passenger || time > _deadline
                };
            } else {_success = false;};
        };
    } forEach _queue;

    _success = _success && {([] call _fnc_passengers) isEqualTo []} && {!([false] call _fnc_interrupted)};
    if (_success) then {sleep KPLIB_taxi_rope_clear_grace;};
    // Even on abort, let anyone already on a rope reach the ground.
    waitUntil {sleep 0.2; ([] call _fnc_ropesClear) || !alive _taxi};
    _taxi setVariable ["KPLIB_taxi_phase", "leaving_lz", true];
    [_taxi] call ace_fastroping_fnc_cutRopes;
    [_taxi] call ace_fastroping_fnc_stowFRIES;
    _pilot enableAI "MOVE";
    _success && {!([false] call _fnc_interrupted)}
};

_taxi setVariable ["KPLIB_taxi_phase", "pickup", true];
private _inserted = false;
if ([_pickupPos] call _fnc_land) then {
    if ([] call _fnc_board) then {_inserted = [] call _fnc_insert;};
};

if (_inserted) then {
    stats_taxi_insertions = stats_taxi_insertions + 1;
    if ((random 100) < KPLIB_taxi_alertness_chance && {[] call KPLIB_fnc_getOpforCap < KPLIB_battlegroup_cap}) then {
        private _enemyPos = _lzPos getPos [300 + random 300, random 360];
        private _infGrp = createGroup [KPLIB_side_enemy, true];
        {[_x, _enemyPos, _infGrp, "PRIVATE", 0.5] call KPLIB_fnc_createManagedUnit;} forEach ([] call KPLIB_fnc_getSquadComp);
        [_infGrp] spawn battlegroup_ai;
    };
    // Leave the insertion site and keep this airframe available for extraction.
    _taxi setVariable ["KPLIB_taxi_phase", "standby", true];
    private _standbyPos = _fobPos getPos [500, _fobPos getDir _spawnPos];
    [_standbyPos] call _fnc_flyTo;
    private _standbyDeadline = time + KPLIB_taxi_hover_timeout;
    waitUntil {sleep 1; ([false] call _fnc_interrupted) || time > _standbyDeadline};
};

// A recall can redirect a healthy flight; damage always latches return-to-FOB.
private _recall = _taxi getVariable ["KPLIB_taxi_recall", []];
if ([] call _fnc_flyable && {!_damageAbort} && {damage _taxi <= 0.5} && {!(_recall isEqualTo [])} && {_recall select 1}) then {
    _taxi setVariable ["KPLIB_taxi_recall", []];
    _taxi setVariable ["KPLIB_taxi_phase", "extraction", true];
    private _extractPos = [_recall select 0, 0, 100, 15, 0, 0.3, 0, [], [[0, 0], [0, 0]]] call BIS_fnc_findSafePos;
    if !(_extractPos isEqualTo [0, 0]) then {
        if ([_extractPos] call _fnc_land) then {[] call _fnc_board;};
    };
};

_taxi setVariable ["KPLIB_taxi_phase", "returning", true];
_taxi setVariable ["KPLIB_taxi_recall", []];
_pilot enableAI "MOVE";
// Return to the departure FOB, never the stale insertion/extraction target.
private _home = [_pickupPos, true] call _fnc_land;
// A healthy occupied taxi still consumes its pool slot, even if unloading takes
// longer than the landing/boarding timeout. Do not abandon the service aircraft
// and grant another slot just because a passenger remains seated.
waitUntil {sleep 1;
    ([] call _fnc_passengers) isEqualTo [] || !([] call _fnc_flyable)
};

// Only retire an empty aircraft after it flies away. If passengers stay aboard,
// or the aircraft cannot get home, leave the aircraft and occupants intact.
if (_home && {([] call _fnc_passengers) isEqualTo []} && {[] call _fnc_flyable}) then {
    _taxi setVariable ["KPLIB_taxi_phase", "departing", true];
    [_spawnPos, 150, true] call _fnc_flyTo;
};
private _lost = !([] call _fnc_flyable);
KPLIB_taxi_slots_active = (KPLIB_taxi_slots_active - 1) max 0;
publicVariable "KPLIB_taxi_slots_active";
_taxi setVariable ["KPLIB_taxi_active", false, true];
_taxi setVariable ["KPLIB_taxi_phase", "complete", true];
if (_lost) then {
    KPLIB_taxi_cooldown_until pushBack (time + KPLIB_taxi_respawn_cooldown);
    publicVariable "KPLIB_taxi_cooldown_until";
};
if (alive _taxi && {([] call _fnc_passengers) isEqualTo []}
    && {({(_x distance2D _taxi) < 1500} count allPlayers) == 0}) then {
    {if (!isPlayer _x && {vehicle _x == _taxi}) then {deleteVehicle _x;};} forEach _flightCrew;
    deleteVehicle _taxi;
};
