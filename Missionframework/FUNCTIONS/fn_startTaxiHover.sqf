/*
    Start a server-local, physics-enabled hold at a measured terrain-relative
    altitude. Returns the CBA PFH handle, or -1 on refusal. The caller owns removal.
*/
params ["_taxi", "_pilot", ["_height", 32]];
if (!isServer || {!local _taxi} || {!local _pilot} || {!alive _taxi} || {!alive _pilot}
    || {!canMove _taxi} || {!isEngineOn _taxi} || {isNil "CBA_fnc_addPerFrameHandler"}) exitWith {-1};

private _anchor = getPosASL _taxi;
_anchor set [2, (_anchor select 2) + _height - ((getPosATL _taxi) select 2)];
if !([_taxi, _anchor] call KPLIB_fnc_isTaxiHoverPathClear) exitWith {
    _taxi setVariable ["KPLIB_taxi_hover_failure", "descent_blocked", true];
    -1
};

_pilot disableAI "MOVE";
_taxi setVariable ["KPLIB_taxi_hover_failure", "", true];
_taxi setVariable ["KPLIB_taxi_hover_active", true, true];
private _handle = -1;
// CBA callbacks do not capture this function's locals; all state is in _args.
isNil {
    _handle = [{
        params ["_args", "_handle"];
        _args params ["_vehicle", "_driver", "_anchor", "_lastTime", "_lastCommand", "_nextCheck", "_deadline"];
        private _failure = "";
        if (!local _vehicle || {!local _driver}) then {_failure = "locality_lost";};
        if (!alive _vehicle || {!alive _driver} || {!canMove _vehicle} || {!isEngineOn _vehicle}) then {_failure = "aircraft_unavailable";};
        if ((vectorUp _vehicle) select 2 < 0.5) then {_failure = "attitude_lost";};
        if (_failure != "") exitWith {
            [_handle] call CBA_fnc_removePerFrameHandler;
            _vehicle setVariable ["KPLIB_taxi_hover_active", false, true];
            _vehicle setVariable ["KPLIB_taxi_hover_failure", _failure, true];
            if (local _driver) then {_driver enableAI "MOVE";};
        };

        // An interrupted/finished parent flight must not leave a permanent hold.
        private _phase = _vehicle getVariable ["KPLIB_taxi_phase", ""];
        if !(_phase in ["stabilizing_hover", "inserting", "leaving_lz"]) exitWith {
            [_handle] call CBA_fnc_removePerFrameHandler;
            _vehicle setVariable ["KPLIB_taxi_hover_active", false, true];
            _driver enableAI "MOVE";
        };
        if (diag_tickTime > _deadline) then {
            if !(_vehicle getVariable ["KPLIB_taxi_aborted", false]) then {
                _vehicle setVariable ["KPLIB_taxi_aborted", true, true];
            };
            if ((_vehicle getVariable ["KPLIB_taxi_hover_failure", ""]) != "watchdog_timeout") then {
                _vehicle setVariable ["KPLIB_taxi_hover_failure", "watchdog_timeout", true];
            };
            private _ropeStates = [];
            {
                if (_x isEqualType [] && {count _x >= 7} && {(_x select 3) isEqualType objNull}) then {
                    private _riders = {_x isKindOf "CAManBase"} count attachedObjects (_x select 3);
                    _ropeStates pushBack [_x select 5, _x select 6, _riders];
                } else {_ropeStates pushBack [];};
            } forEach (_vehicle getVariable ["ace_fastroping_deployedRopes", []]);
            if (_ropeStates call KPLIB_fnc_taxiRopesClear) then {_failure = "watchdog_timeout";};
        };
        if (_failure != "") exitWith {
            [_handle] call CBA_fnc_removePerFrameHandler;
            _vehicle setVariable ["KPLIB_taxi_hover_active", false, true];
            _driver enableAI "MOVE";
        };

        private _now = diag_tickTime;
        private _command = [_anchor vectorDiff getPosASL _vehicle, _lastCommand, _now - _lastTime] call KPLIB_fnc_taxiHoverVelocity;
        if (_now >= _nextCheck) then {
            private _lookAhead = (getPosASL _vehicle) vectorAdd (_command vectorMultiply 0.5);
            if !([_vehicle, _lookAhead] call KPLIB_fnc_isTaxiHoverPathClear) then {_failure = "hover_obstructed";};
            _args set [5, _now + 0.2];
        };
        if (_failure != "") exitWith {
            _vehicle setVelocity [0, 0, 0];
            [_handle] call CBA_fnc_removePerFrameHandler;
            _vehicle setVariable ["KPLIB_taxi_hover_active", false, true];
            _vehicle setVariable ["KPLIB_taxi_hover_failure", _failure, true];
            _driver enableAI "MOVE";
        };
        _vehicle setVelocity _command;
        _args set [3, _now];
        _args set [4, _command];
    }, 0, [_taxi, _pilot, _anchor, diag_tickTime, [0, 0, 0], diag_tickTime, diag_tickTime + KPLIB_taxi_hover_timeout + 60]] call CBA_fnc_addPerFrameHandler;
};
if (_handle < 0) then {
    _taxi setVariable ["KPLIB_taxi_hover_active", false, true];
    _taxi setVariable ["KPLIB_taxi_hover_failure", "registration_failed", true];
    _pilot enableAI "MOVE";
};
_handle
