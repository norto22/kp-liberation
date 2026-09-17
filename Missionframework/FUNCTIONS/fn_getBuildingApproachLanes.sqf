/*
    File: fn_getBuildingApproachLanes.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2026-09-17
    Last Update: 2026-09-17
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Computes the real avenues of approach into a building from nearby roads, so a
        strongpoint's HMG-role defender can be aimed down them instead of a random
        direction. Nearby road bearings are clustered into distinct lanes, so a
        mid-block building resolves to one lane and a junction building to several.
        Falls back to an outward-facing heuristic when no road is found nearby.

    Parameter(s):
        _building - Building to compute approach lanes for [OBJECT, defaults to objNull]

    Returns:
        Distinct approach bearings in degrees, 0-360, never empty [ARRAY]
*/

params [
    ["_building", objNull, [objNull]]
];

private _buildingPos = getPosATL _building;
private _roads = _buildingPos nearRoads KPLIB_strongpoint_road_search_range;

if (_roads isEqualTo []) exitWith {
    private _fallback = (getDir _building) + 180;
    if (_fallback >= 360) then {_fallback = _fallback - 360;};
    [_fallback]
};

private _lanes = [];
{
    private _vd = (getPosATL _x) vectorDiff _buildingPos;
    private _bearing = (_vd select 0) atan2 (_vd select 1);
    if (_bearing < 0) then {_bearing = _bearing + 360;};

    private _isNewLane = true;
    {
        private _d = abs (_bearing - _x);
        if (_d > 180) then {_d = 360 - _d;};
        if (_d < KPLIB_strongpoint_lane_cluster_angle) exitWith {_isNewLane = false;};
    } forEach _lanes;

    if (_isNewLane) then {_lanes pushBack _bearing;};
} forEach _roads;

_lanes
