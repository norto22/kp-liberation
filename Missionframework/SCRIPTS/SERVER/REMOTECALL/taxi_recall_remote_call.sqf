if (!isServer) exitWith {false};

params [
    ["_lzPos", [0, 0, 0], [[]], [2, 3]]
];

if (KPLIB_taxi_slots_active <= 0) exitWith {false};

if (_lzPos isEqualTo [0, 0, 0]) exitWith {
    // Return to FOB
    KPLIB_taxi_boarding_mode = false;
    publicVariable "KPLIB_taxi_boarding_mode";
    KPLIB_taxi_recall_requested = true;
    publicVariable "KPLIB_taxi_recall_requested";
    true
};

// Extraction at a new field LZ - re-validate against the nearest FOB's max range, the
// same bound Task 5's call-in enforces.
private _nearestFobDist = 1e6;
{
    private _dist = _lzPos distance2D _x;
    if (_dist < _nearestFobDist) then {_nearestFobDist = _dist;};
} forEach KPLIB_all_fobs;

if (_nearestFobDist > KPLIB_taxi_lz_max_range) exitWith {false};

KPLIB_taxi_target_position = _lzPos;
publicVariable "KPLIB_taxi_target_position";
KPLIB_taxi_boarding_mode = true;
publicVariable "KPLIB_taxi_boarding_mode";
KPLIB_taxi_recall_requested = true;
publicVariable "KPLIB_taxi_recall_requested";

true
