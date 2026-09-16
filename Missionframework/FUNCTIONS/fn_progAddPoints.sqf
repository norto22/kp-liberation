/*
    File: fn_progAddPoints.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2026-09-16
    Last Update: 2026-09-16
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Adds (or subtracts, for a penalty) points to a player's progression
        entry. Total is floored at 0 - progression never goes negative.
        Server-authoritative: no-op on clients.

    Parameter(s):
        _uid    - Player UID to credit/penalize [STRING, defaults to ""]
        _amount - Points to add. Negative for a penalty [NUMBER, defaults to 0]

    Returns:
        New points total for _uid [NUMBER]
*/

params [
    ["_uid", "", [""]],
    ["_amount", 0, [0]]
];

if (!isServer || {_uid == ""}) exitWith {0};

private _index = KPLIB_progression findIf {(_x select 0) isEqualTo _uid};

private _newTotal = 0;
if (_index == -1) then {
    _newTotal = 0 max _amount;
    KPLIB_progression pushBack [_uid, _newTotal];
} else {
    _newTotal = 0 max ((KPLIB_progression select _index select 1) + _amount);
    (KPLIB_progression select _index) set [1, _newTotal];
};

publicVariable "KPLIB_progression";

_newTotal
