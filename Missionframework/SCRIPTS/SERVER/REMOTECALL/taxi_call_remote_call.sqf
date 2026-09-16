if (!isServer) exitWith {false};

params [
    ["_fobPos", [0, 0, 0], [[]], [2, 3]],
    ["_classChoice", "light", [""]],
    ["_lzPos", [0, 0, 0], [[]], [2, 3]]
];

private _dist = _lzPos distance2D _fobPos;
if (_dist < KPLIB_taxi_lz_min_range || _dist > KPLIB_taxi_lz_max_range) exitWith {false};

private _cooldownCount = {_x > time} count KPLIB_taxi_cooldown_until;
if (KPLIB_taxi_slots_active >= (KPLIB_taxi_pool_size - _cooldownCount)) exitWith {false};

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
if (_availableFuel < _cost) exitWith {false};

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

private _taxiClass = if (_classChoice == "armed") then {taxi_typename_armed} else {taxi_typename_light};

private _taxi = _taxiClass createVehicle [(_fobPos select 0), (_fobPos select 1), (_fobPos select 2) + 0.2];
[_taxi] call KPLIB_fnc_forceBluforCrew;
_taxi setVariable ["KPLIB_taxi_active", true, true];

KPLIB_taxi_slots_active = KPLIB_taxi_slots_active + 1;
publicVariable "KPLIB_taxi_slots_active";

[_taxi, _lzPos, _fobPos] spawn taxi_flight;

true
