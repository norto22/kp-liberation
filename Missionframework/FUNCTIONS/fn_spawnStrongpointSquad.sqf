/*
    File: fn_spawnStrongpointSquad.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2026-09-17
    Last Update: 2026-09-17
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Garrisons a single strongpoint building: places an opfor_heavygunner defender
        on the exterior position that best covers each approach lane and aims it down
        that lane, then fills the remaining budget with defenders facing outward from
        the building centre. Replaces the random 360-degree facing ordinary building
        defenders get with directed facing, which is what makes a strongpoint a real
        difficulty increase rather than just a denser pile of random-facing soldiers.

    Parameter(s):
        _type         - Type of infantry. Either "militia" or "army"     [STRING, defaults to "army"]
        _amount       - Requested amount of defenders to spawn          [NUMBER, defaults to 0]
        _buildingData - [building, positions] pair for the strongpoint  [ARRAY, defaults to []]
        _sector       - Sector this strongpoint belongs to              [STRING, defaults to ""]
        _hmgMax       - Maximum number of HMG-role defenders to place   [NUMBER, defaults to 1]

    Returns:
        Spawned units [ARRAY]
*/

params [
    ["_type", "army", [""]],
    ["_amount", 0, [0]],
    ["_buildingData", [], [[]]],
    ["_sector", "", [""]],
    ["_hmgMax", 1, [0]]
];

if (_sector isEqualTo "") exitWith {["Empty string given"] call BIS_fnc_error; []};

_buildingData params [["_building", objNull, [objNull]], ["_buildingPositions", [], [[]]]];

private _classnames = [[] call KPLIB_fnc_getSquadComp, militia_squad] select (_type == "militia");
private _positions = +_buildingPositions;
private _buildingCentre = getPosATL _building;

_amount = _amount min (floor ((count _positions) * 0.6));

private _grp = createGroup [KPLIB_side_enemy, true];
private _units = [];
private _lanes = [_building] call KPLIB_fnc_getBuildingApproachLanes;
private _hmgCount = 0;

{
    private _lane = _x;
    if (_hmgCount >= _hmgMax || {_amount <= 0} || {_positions isEqualTo []}) exitWith {};

    private _bestIdx = -1;
    private _bestDiff = 1e10;
    private _bestDist = -1;
    {
        private _vd = _x vectorDiff _buildingCentre;
        private _posBearing = (_vd select 0) atan2 (_vd select 1);
        if (_posBearing < 0) then {_posBearing = _posBearing + 360;};

        private _d = abs (_posBearing - _lane);
        if (_d > 180) then {_d = 360 - _d;};

        private _dist = _x distance _buildingCentre;
        if ((_d < _bestDiff) || {(_d == _bestDiff) && (_dist > _bestDist)}) then {
            _bestDiff = _d;
            _bestDist = _dist;
            _bestIdx = _forEachIndex;
        };
    } forEach _positions;

    if (_bestIdx != -1) then {
        if (count (units _grp) >= 10) then {
            _grp = createGroup [KPLIB_side_enemy, true];
        };

        private _pos = _positions deleteAt _bestIdx;
        private _unit = [opfor_heavygunner, _buildingCentre, _grp] call KPLIB_fnc_createManagedUnit;
        _unit setDir _lane;
        _unit setPos _pos;
        [_unit, _sector] spawn building_defence_ai;
        _units pushBack _unit;

        _hmgCount = _hmgCount + 1;
        _amount = _amount - 1;
    };
} forEach _lanes;

for "_i" from 1 to _amount do {
    if (_positions isEqualTo []) exitWith {};

    if (count (units _grp) >= 10) then {
        _grp = createGroup [KPLIB_side_enemy, true];
    };

    private _pos = _positions deleteAt (floor (random (count _positions)));
    private _vd = _pos vectorDiff _buildingCentre;
    private _outDir = (_vd select 0) atan2 (_vd select 1);
    if (_outDir < 0) then {_outDir = _outDir + 360;};

    private _unit = [selectRandom _classnames, _buildingCentre, _grp] call KPLIB_fnc_createManagedUnit;
    _unit setDir _outDir;
    _unit setPos _pos;
    [_unit, _sector] spawn building_defence_ai;
    _units pushBack _unit;
};

_units
