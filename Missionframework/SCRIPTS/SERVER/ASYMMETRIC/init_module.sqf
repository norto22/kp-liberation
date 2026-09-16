// Scripts
// Logistic convoy distress-call resolution (both trigger sources)
logistic_convoy_distress_response = compileFinal preprocessFileLineNumbers "SCRIPTS\SERVER\ASYMMETRIC\CONVOY\logistic_convoy_distress_response.sqf";
// Spawns/despawns the physical truck+crew for one convoy leg
logistic_convoy_spawn_truck = compileFinal preprocessFileLineNumbers "SCRIPTS\SERVER\ASYMMETRIC\CONVOY\logistic_convoy_spawn_truck.sqf";
// Per-truck stuck-AI recovery and hostile-proximity distress trigger
logistic_convoy_watchdog = compileFinal preprocessFileLineNumbers "SCRIPTS\SERVER\ASYMMETRIC\CONVOY\logistic_convoy_watchdog.sqf";
// IED spawner for blufor sectors
manage_asymIED = compileFinal preprocessFileLineNumbers "SCRIPTS\SERVER\ASYMMETRIC\IED\manage_asymIED.sqf";
// Spawner for guerilla ambushes in blufor sectors
asym_sector_ambush = compileFinal preprocessFileLineNumbers "SCRIPTS\SERVER\ASYMMETRIC\RANDOM\asym_sector_ambush.sqf";
// Spawner for guerilla forces who join a fight at an opfor sector
sector_guerilla = compileFinal preprocessFileLineNumbers "SCRIPTS\SERVER\ASYMMETRIC\RANDOM\sector_guerilla.sqf";

// Globals
// List sectors which are just liberated. Preventing direct ambush spawn.
asymm_blocked_sectors = [];
publicVariable "asymm_blocked_sectors";

// Start module loop
execVM "SCRIPTS\SERVER\ASYMMETRIC\asymmetric_loop.sqf";
