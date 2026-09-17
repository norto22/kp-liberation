if (!isServer) exitWith {false};

params [
    ["_fobPos", [0, 0, 0], [[]], [2, 3]],
    ["_classChoice", "light", [""]],
    ["_lzPos", [0, 0, 0], [[]], [2, 3]]
];

private _clientID = if (isRemoteExecuted) then {remoteExecutedOwner} else {2};
if !(_fobPos in KPLIB_all_fobs) exitWith {
    [_clientID, "STR_TAXI_MSG_INVALID_FOB", [], true] call KPLIB_fnc_taxiNotify;
    false
};
private _dist = _lzPos distance2D _fobPos;
if (_dist < KPLIB_taxi_lz_min_range || _dist > KPLIB_taxi_lz_max_range) exitWith {
    [_clientID, "STR_TAXI_MSG_OUT_OF_RANGE", [KPLIB_taxi_lz_min_range, KPLIB_taxi_lz_max_range], true] call KPLIB_fnc_taxiNotify;
    false
};

private _cooldownCount = {_x > time} count KPLIB_taxi_cooldown_until;
if (KPLIB_taxi_slots_active >= (KPLIB_taxi_pool_size - _cooldownCount)) exitWith {
    [_clientID, "STR_TAXI_MSG_POOL_BUSY", [], true] call KPLIB_fnc_taxiNotify;
    false
};

// Pick a clear landing site near the FOB, before charging for the flight.
private _taxiClass = if (_classChoice == "armed") then {taxi_typename_armed} else {taxi_typename_light};
if !(isClass (configFile >> "CfgVehicles" >> _taxiClass)) exitWith {
    [_clientID, "STR_TAXI_MSG_SPAWN_FAILED", [], true] call KPLIB_fnc_taxiNotify;
    false
};
private _pickupPos = [_fobPos, _taxiClass, 300] call KPLIB_fnc_findTaxiLandingPos;
if (_pickupPos isEqualTo []) exitWith {
    [_clientID, "STR_TAXI_MSG_NO_LANDING_SITE", [], true] call KPLIB_fnc_taxiNotify;
    [format ["Taxi request rejected: no clear ground landing site near FOB %1", _fobPos], "TAXI"] call KPLIB_fnc_log;
    false
};

// Arrive from the rear rather than materialising beside the waiting squad.
// Try alternate bearings so another player cannot be standing at the spawn point.
private _rearBearing = _fobPos getDir (getPosATL startbase);
private _spawnPos = [];
for "_bearingOffset" from 0 to 330 step 30 do {
    private _candidate = _fobPos getPos [2500, _rearBearing + _bearingOffset];
    if (({(_x distance2D _candidate) < 1500} count allPlayers) == 0) exitWith {
        _spawnPos = _candidate;
    };
};
if (_spawnPos isEqualTo []) exitWith {
    [_clientID, "STR_TAXI_MSG_NO_SPAWN_SITE", [], true] call KPLIB_fnc_taxiNotify;
    false
};
_spawnPos set [2, 150];

// Gather this FOB's storage areas and their fuel crates, same lookup shape as
// recalculate_resources.sqf's per-FOB resource scan.
private _storageAreas = (_fobPos nearObjects KPLIB_fob_range) select {(_x getVariable ["KPLIB_storage_type", -1]) == 0};
private _fuelCrates = [];
{
    _fuelCrates append ((attachedObjects _x) select {(typeOf _x) == KPLIB_fuel_crate});
} forEach _storageAreas;

private _availableFuel = 0;
{_availableFuel = _availableFuel + (_x getVariable ["KPLIB_crate_value", 0]);} forEach _fuelCrates;

private _cost = ceil ((_dist / 1000) * KPLIB_taxi_fuel_cost_per_km) max KPLIB_taxi_fuel_cost_min;
if (_availableFuel < _cost) exitWith {
    [_clientID, "STR_TAXI_MSG_NO_FUEL", [_cost, _availableFuel], true] call KPLIB_fnc_taxiNotify;
    false
};

// Confirm the aircraft and pilot exist before charging the FOB.
private _taxi = createVehicle [_taxiClass, _spawnPos, [], 0, "FLY"];
if (isNull _taxi) exitWith {
    [_clientID, "STR_TAXI_MSG_SPAWN_FAILED", [], true] call KPLIB_fnc_taxiNotify;
    false
};
[_taxi] call KPLIB_fnc_forceBluforCrew;
if (isNull driver _taxi) exitWith {
    {deleteVehicle _x;} forEach crew _taxi;
    deleteVehicle _taxi;
    [_clientID, "STR_TAXI_MSG_SPAWN_FAILED", [], true] call KPLIB_fnc_taxiNotify;
    false
};

// Deduct cost directly from crate values, same crate-emptying technique as
// manage_logistics.sqf's resource-transfer loop.
private _remaining = _cost;
{
    if (_remaining <= 0) exitWith {};
    private _crateValue = _x getVariable ["KPLIB_crate_value", 0];
    if (_crateValue > _remaining) then {
        _x setVariable ["KPLIB_crate_value", _crateValue - _remaining, true];
        _remaining = 0;
    } else {
        detach _x;
        deleteVehicle _x;
        _remaining = _remaining - _crateValue;
    };
} forEach _fuelCrates;

please_recalculate = true;

_taxi setDir (_spawnPos getDir _pickupPos);
_taxi flyInHeight 100;
// Equip the Ghost Hawk before boarding; ACE adds FRIES on the next frame.
if (KPLIB_ace && {!isNil "ace_fastroping_fnc_equipFRIES"}) then {
    _taxi addItemCargoGlobal ["ACE_rope36", 4];
    if (getNumber (configFile >> "CfgVehicles" >> _taxiClass >> "ace_fastroping_enabled") == 2) then {
        [_taxi] call ace_fastroping_fnc_equipFRIES;
    };
};
private _requesters = allPlayers select {owner _x == _clientID};
if !(_requesters isEqualTo []) then {
    _taxi setVariable ["KPLIB_taxi_group", group (_requesters select 0)];
};
_taxi setVariable ["KPLIB_taxi_active", true, true];

KPLIB_taxi_slots_active = KPLIB_taxi_slots_active + 1;
publicVariable "KPLIB_taxi_slots_active";
[_clientID, "STR_TAXI_MSG_ACCEPTED", [_cost, mapGridPosition _fobPos]] call KPLIB_fnc_taxiNotify;

[_taxi, _lzPos, _fobPos, _pickupPos, _spawnPos] spawn taxi_flight;

true
