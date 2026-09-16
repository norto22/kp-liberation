/*
    File: fn_progShowRankData.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2026-09-16
    Last Update: 2026-09-16
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Reads the built-in custom veterancy progression data of the current
        player and displays it in the player menu dialog. Fallback for when
        the optional third-party KP_Ranks addon isn't loaded (KPLIB_KPR
        false) - see fn_showRankData.sqf for the KP_Ranks-backed version.

    Parameter(s):
        NONE

    Returns:
        Function reached the end [BOOL]
*/

// Dialog controls
private _dialog = findDisplay 75803;
private _ctrlRank = _dialog displayCtrl 758032;
private _ctrlScore = _dialog displayCtrl 758034;
private _ctrlPlaytime = _dialog displayCtrl 758036;
private _ctrlNoRanks = _dialog displayCtrl 758037;

// Disable no ranks hint
_ctrlNoRanks ctrlShow false;

// Show data in dialog
private _progEntry = [getPlayerUID player] call KPLIB_fnc_progGetPlayerData;
private _progPoints = _progEntry select 1;

_ctrlRank ctrlSetText (KPLIB_prog_tier_names select ([_progPoints] call KPLIB_fnc_progGetTier));
_ctrlScore ctrlSetText str _progPoints;
_ctrlPlaytime ctrlSetText ([stats_playtime] call KPLIB_fnc_secondsToTimer);

true
