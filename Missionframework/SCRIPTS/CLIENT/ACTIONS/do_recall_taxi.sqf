private _mode = if (count _this > 3) then {_this select 3} else {"fob"};

if (_mode == "fob") exitWith {
    [] remoteExec ["taxi_recall_remote_call", 2];
};

// _mode == "lz": open the standard map and let the player click a new extraction LZ,
// same onMapSingleClick stacked-handler pattern as do_halo.sqf.
taxi_recall_lz_position = [0, 0, 0];
openMap [true, false];

[ "taxi_recall_map_event", "onMapSingleClick", { taxi_recall_lz_position = _pos } ] call BIS_fnc_addStackedEventHandler;

hint localize "STR_TAXI_RECALL_LZ_HINT";

waitUntil {sleep 0.2; !visibleMap || !(taxi_recall_lz_position isEqualTo [0, 0, 0])};

[ "taxi_recall_map_event", "onMapSingleClick" ] call BIS_fnc_removeStackedEventHandler;

if (visibleMap) then { openMap [false, false]; };

if !(taxi_recall_lz_position isEqualTo [0, 0, 0]) then {
    [taxi_recall_lz_position] remoteExec ["taxi_recall_remote_call", 2];
};
