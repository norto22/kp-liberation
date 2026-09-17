private [ "_vehmarkers", "_markedveh", "_cfg", "_vehtomark", "_supporttomark", "_marker" ];

_vehmarkers = [];
_markedveh = [];
_cfg = configFile >> "cfgVehicles";
_vehtomark = [];

_support_to_skip = [
    KPLIB_recycle_building,
    KPLIB_air_vehicle_building,
    "B_Slingload_01_Repair_F",
    "B_Slingload_01_Fuel_F",
    "B_Slingload_01_Ammo_F"
];

{
    _vehtomark append _x;
} forEach [KPLIB_b_light_classes, KPLIB_b_heavy_classes, KPLIB_b_air_classes, KPLIB_b_support_classes];

_vehtomark = _vehtomark - _support_to_skip;

while { true } do {

    _markedveh = [];
    {
        private _veh = _x;
        private _owner = _veh getVariable ["KPLIB_owner", ""];

        if (alive _veh && (toLower (typeof _veh)) in _vehtomark && (count (crew _veh)) == 0 && (_veh distance2d startbase) > 500) then {
            _markedveh pushback _veh;

            // Abandonment tracking (Player Progression): only for owned, not-yet-flagged vehicles
            if (_owner != "" && !(_veh getVariable ["KPLIB_abandoned_flagged", false])) then {
                private _nearFob = (KPLIB_all_fobs findIf {_veh distance2d _x < KPLIB_fob_range}) != -1;
                private _nearSector = (blufor_sectors findIf {_veh distance2d (markerPos _x) < KPLIB_capture_size}) != -1;

                if (_nearFob || _nearSector) then {
                    // Safe-parking exemption: never eligible near a FOB or friendly sector
                    _veh setVariable ["KPLIB_abandon_timer_start", -1];
                } else {
                    private _firstSeen = _veh getVariable ["KPLIB_abandon_timer_start", -1];
                    if (_firstSeen == -1) then {
                        _veh setVariable ["KPLIB_abandon_timer_start", time];
                    } else {
                        if ((time - _firstSeen) >= KPLIB_prog_abandon_seconds) then {
                            _veh setVariable ["KPLIB_abandoned_flagged", true, true];
                        };
                    };
                };
            };

            // Owner warning hint: independent of the shared flag above (that flag can already be
            // set by another client's tick first), latched locally so it only shows once per vehicle
            if (_owner == getPlayerUID player && !(_veh getVariable ["KPLIB_abandon_warned_locally", false])) then {
                private _firstSeenLocal = _veh getVariable ["KPLIB_abandon_timer_start", -1];
                if (_firstSeenLocal != -1 && {(time - _firstSeenLocal) >= KPLIB_prog_abandon_seconds}) then {
                    _veh setVariable ["KPLIB_abandon_warned_locally", true];
                    hint format [localize "STR_KPLIB_PROG_ABANDON_WARNING", mapGridPosition _veh];
                };
            };
        } else {
            // No longer crewless/far from base (e.g. reclaimed): clear any abandonment tracking
            if (_owner != "") then {
                if (_veh getVariable ["KPLIB_abandoned_flagged", false]) then {
                    _veh setVariable ["KPLIB_abandoned_flagged", false, true];
                };
                _veh setVariable ["KPLIB_abandon_timer_start", -1];
                _veh setVariable ["KPLIB_abandon_warned_locally", false];
            };
        };
    } foreach vehicles;

    if ( count _markedveh != count _vehmarkers ) then {
        { deleteMarkerLocal _x; } foreach _vehmarkers;
        _vehmarkers = [];

        {
            _marker = createMarkerLocal [ format [ "markedveh%1" ,_x], markers_reset ];
            _marker setMarkerColorLocal "ColorKhaki";
            _marker setMarkerTypeLocal "mil_dot";
            _marker setMarkerSizeLocal [ 0.75, 0.75 ];
            _vehmarkers pushback _marker;
        } foreach _markedveh;
    };

    {
        _marker = _vehmarkers select (_markedveh find _x);
        _marker setMarkerPosLocal getpos _x;
        _marker setMarkerTextLocal  (getText (_cfg >> typeOf _x >> "displayName"));
        _marker setMarkerColorLocal (["ColorKhaki", "ColorRed"] select (_x getVariable ["KPLIB_abandoned_flagged", false]));

    } foreach _markedveh;

    sleep 5;
};
