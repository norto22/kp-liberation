/*
    File: fn_progAwardNearby.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2026-09-16
    Last Update: 2026-09-16
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Credits a flat amount of progression points to every alive player
        within KPLIB_prog_award_radius of a position, for scripted completion
        events (sector capture, FOB build, secondary objectives, ...) that
        have no single directly-attributed player. Capped at
        KPLIB_prog_nearby_award_cap players per event. Server-only.

    Parameter(s):
        _pos    - Center position to search from [POSITION, defaults to [0, 0, 0]]
        _amount - Points to award each nearby player [NUMBER, defaults to 0]

    Returns:
        Function reached the end [BOOL]
*/

params [
    ["_pos", [0, 0, 0], [[], objNull], [2, 3]],
    ["_amount", 0, [0]]
];

if (!isServer) exitWith {false};

private _players = [_pos, KPLIB_prog_award_radius] call KPLIB_fnc_getNearbyPlayers;
_players resize (KPLIB_prog_nearby_award_cap min (count _players));

{
    [getPlayerUID _x, _amount] call KPLIB_fnc_progAddPoints;
} forEach _players;

true
