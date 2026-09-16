/*
    File: prog_playtime.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2026-09-16
    Last Update: 2026-09-16
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Awards a small periodic progression point trickle to every
        currently connected player, once the save has finished loading.
        Mirrors playtime.sqf's structure but runs as its own independently
        tunable loop.
*/

waitUntil { !isNil "save_is_loaded" };
waitUntil { save_is_loaded };

while { true } do {
    sleep KPLIB_prog_points_playtime_interval;
    {
        [getPlayerUID _x, KPLIB_prog_points_playtime_amount] call KPLIB_fnc_progAddPoints;
    } forEach allPlayers;
};
