/*
    File: fn_progApplyRecruitQuality.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2026-09-16
    Last Update: 2026-09-16
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Applies a veteran player's progression tier as a combat-skill and
        gear bonus to one of their newly created recruits/squad members/
        vehicle crew. No-op-safe for a UID with no progression entry yet
        (resolves to tier 0, baseline skill only, no gear bonus).

    Parameter(s):
        _unit - Unit to scale                                [OBJECT, defaults to objNull]
        _uid  - UID of the player this unit was created for  [STRING, defaults to ""]

    Returns:
        Function reached the end [BOOL]
*/

params [
    ["_unit", objNull, [objNull]],
    ["_uid", "", [""]]
];

if (isNull _unit || {_uid == ""}) exitWith {false};

private _points = ([_uid] call KPLIB_fnc_progGetPlayerData) select 1;
private _tier = [_points] call KPLIB_fnc_progGetTier;

private _tierCount = count KPLIB_prog_tier_names;
private _scaled = KPLIB_prog_skill_baseline;
if (_tierCount > 1) then {
    _scaled = KPLIB_prog_skill_baseline + ((_tier / (_tierCount - 1)) * (1 - KPLIB_prog_skill_baseline));
};

_unit setSkill ["aimingAccuracy", _scaled];
_unit setSkill ["spotDistance", _scaled];
_unit setSkill ["courage", _scaled];

// Sergeant tier and above also get one extra magazine of their primary weapon.
if (_tier >= 3 && {primaryWeapon _unit != ""}) then {
    _unit addMagazine (primaryWeapon _unit);
};

true
