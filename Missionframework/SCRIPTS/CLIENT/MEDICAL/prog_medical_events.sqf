/*
    File: prog_medical_events.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2026-09-16
    Last Update: 2026-09-16
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Awards progression points to a player for successful ACE Medical
        treatment (ace_treatmentSucceded fires for any completed treatment
        action, including revives). Only ever spawned when KPLIB_ace is
        true (see init_client.sqf); still guards itself as defense-in-depth.
*/

if (KPLIB_ace) then {
    ["ace_treatmentSucceded", {
        params ["_caller"];

        if (isPlayer _caller) then {
            [getPlayerUID _caller, KPLIB_prog_points_medical] remoteExec ["KPLIB_fnc_progAddPoints", 2];
        };
    }] call CBA_fnc_addEventHandler;
};
