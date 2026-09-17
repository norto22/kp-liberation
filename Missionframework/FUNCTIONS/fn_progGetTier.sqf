/*
    File: fn_progGetTier.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2026-09-16
    Last Update: 2026-09-16
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Pure function. Resolves a points total to its veterancy tier index
        against KPLIB_prog_tier_thresholds.

    Parameter(s):
        _points - Total progression points [NUMBER, defaults to 0]

    Returns:
        Tier index into KPLIB_prog_tier_names/KPLIB_prog_tier_thresholds [NUMBER]
*/

params [
    ["_points", 0, [0]]
];

private _tier = 0;

{
    if (_points >= _x) then {_tier = _forEachIndex};
} forEach KPLIB_prog_tier_thresholds;

_tier
