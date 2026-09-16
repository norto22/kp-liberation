/*
    File: fn_progGetPlayerData.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2026-09-16
    Last Update: 2026-09-16
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Gets a player's progression entry from KPLIB_progression, creating it
        (with 0 points) if it doesn't exist yet.

        The returned array is a snapshot, not a live reference - callers that
        change the points value must write it back into KPLIB_progression
        themselves (see KPLIB_fnc_progAddPoints for the canonical way to do this).

    Parameter(s):
        _uid - Player UID to look up [STRING, defaults to ""]

    Returns:
        [_uid, _points] [ARRAY]
*/

params [
    ["_uid", "", [""]]
];

private _index = KPLIB_progression findIf {(_x select 0) isEqualTo _uid};

if (_index == -1) then {
    private _entry = [_uid, 0];
    KPLIB_progression pushBack _entry;
    _entry
} else {
    KPLIB_progression select _index
};
