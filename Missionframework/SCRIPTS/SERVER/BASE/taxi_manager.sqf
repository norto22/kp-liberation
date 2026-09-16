waitUntil {!isNil "save_is_loaded"};
waitUntil {save_is_loaded};

KPLIB_taxi_slots_active = 0;
KPLIB_taxi_cooldown_until = [];
publicVariable "KPLIB_taxi_slots_active";
publicVariable "KPLIB_taxi_cooldown_until";

// Track up to KPLIB_taxi_pool_size taxi slots: how many are active in the field
// (KPLIB_taxi_slots_active, adjusted by taxi_call_remote_call/taxi_flight) and which
// are cooling down after a loss (KPLIB_taxi_cooldown_until, timestamps pushed by
// taxi_flight on !alive). This loop's only job is expiring cooldowns once their time
// passes, freeing that slot back into the available pool.
while {true} do {
    sleep 5;

    KPLIB_taxi_cooldown_until = KPLIB_taxi_cooldown_until select {_x > time};
    publicVariable "KPLIB_taxi_cooldown_until";
};
