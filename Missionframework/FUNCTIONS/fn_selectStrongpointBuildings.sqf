/*
    File: fn_selectStrongpointBuildings.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2026-09-17
    Last Update: 2026-09-17
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Selects which buildings near a sector become fortified strongpoints, based on
        live building density rather than a mission-editor marker convention. The
        central strongpoint is the closest to the sector centre among the largest
        candidates; additional strongpoints are the next-largest candidates that stay
        a minimum distance from every already-selected strongpoint.

    Parameter(s):
        _buildingData - Array of [building, positions] pairs near the sector     [ARRAY, defaults to []]
        _sectorpos    - Sector centre position                                   [ARRAY, defaults to [0, 0, 0]]

    Returns:
        Selected [building, positions] pairs, central strongpoint first, or [] [ARRAY]
*/

params [
    ["_buildingData", [], [[]]],
    ["_sectorpos", [0, 0, 0], [[]], [2, 3]]
];

if (_buildingData isEqualTo []) exitWith {[]};

private _targetCount = 0;
{
    if ((count _buildingData) >= _x) then {_targetCount = _targetCount + 1;};
} forEach KPLIB_strongpoint_building_thresholds;
_targetCount = _targetCount min KPLIB_strongpoint_max_count;

if (_targetCount == 0) exitWith {[]};

private _candidates = _buildingData select {count (_x select 1) >= KPLIB_strongpoint_min_buildingpos};

if (_candidates isEqualTo []) exitWith {[]};

private _scored = _candidates apply {[count (_x select 1), _x]};
_scored sort false;
private _sorted = _scored apply {_x select 1};

private _top5 = _sorted select [0, (5 min (count _sorted))];
private _central = _top5 select 0;
private _bestDist = (_central select 0) distance _sectorpos;
{
    private _d = (_x select 0) distance _sectorpos;
    if (_d < _bestDist) then {_bestDist = _d; _central = _x;};
} forEach _top5;

private _remaining = _sorted select {(_x select 0) != (_central select 0)};
private _selected = [_central];

{
    if (count _selected >= _targetCount) exitWith {};
    private _candBuilding = _x select 0;
    private _farEnough = true;
    {
        if ((_candBuilding distance (_x select 0)) < KPLIB_strongpoint_spacing) exitWith {_farEnough = false;};
    } forEach _selected;
    if (_farEnough) then {_selected pushBack _x;};
} forEach _remaining;

_selected
