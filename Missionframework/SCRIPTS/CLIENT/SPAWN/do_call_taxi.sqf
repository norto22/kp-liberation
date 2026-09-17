#define TAXI_DISPLAY (findDisplay 5204)
#define TAXI_FOB_LIST_IDC 201
#define TAXI_CONFIRM_IDC 202

private ["_dialog", "_fobPositions"];

if (isNil "KPLIB_taxi_class_choice") then { KPLIB_taxi_class_choice = "light"; };

_dialog = createDialog "liberation_taxi";
if (!_dialog) exitWith {["STR_TAXI_MSG_DIALOG_FAILED", [], true] call taxi_status_local;};
["STR_TAXI_MSG_SELECT_LZ"] call taxi_status_local;
taxi_call_confirmed = 0;
taxi_lz_position = [0, 0, 0];
_fobPositions = +KPLIB_all_fobs;

waitUntil { dialog };

lbClear TAXI_FOB_LIST_IDC;
{
    lbAdd [TAXI_FOB_LIST_IDC, format ["FOB %1 - %2", (KPLIB_fob_alphabet select _forEachIndex), mapGridPosition _x]];
} forEach _fobPositions;
lbSetCurSel [TAXI_FOB_LIST_IDC, 0];

[ "taxi_map_event", "onMapSingleClick", { taxi_lz_position = _pos } ] call BIS_fnc_addStackedEventHandler;

while { dialog && alive player && taxi_call_confirmed == 0 } do {
    "spawn_marker" setMarkerPosLocal taxi_lz_position;

    private _sel = lbCurSel TAXI_FOB_LIST_IDC;
    private _confirmOk = false;
    if (_sel >= 0 && {!(taxi_lz_position isEqualTo [0, 0, 0])} && {_sel < count _fobPositions}) then {
        private _fobPos = _fobPositions select _sel;
        private _dist = taxi_lz_position distance2D _fobPos;
        if (_dist >= KPLIB_taxi_lz_min_range && _dist <= KPLIB_taxi_lz_max_range) then {
            _confirmOk = true;
            KPLIB_ui_notif = "";
        } else {
            KPLIB_ui_notif = format [localize "STR_TAXI_RANGE_HINT", KPLIB_taxi_lz_min_range, KPLIB_taxi_lz_max_range];
        };
    };
    (TAXI_DISPLAY displayCtrl TAXI_CONFIRM_IDC) ctrlEnable _confirmOk;

    uiSleep 0.2;
};

KPLIB_ui_notif = "";

// Capture the selection while the listbox still exists.
private _selectedFob = lbCurSel TAXI_FOB_LIST_IDC;

if ( dialog ) then {
    closeDialog 0;
};

"spawn_marker" setMarkerPosLocal markers_reset;

[ "taxi_map_event", "onMapSingleClick" ] call BIS_fnc_removeStackedEventHandler;

if (taxi_call_confirmed == 1 && alive player && {_selectedFob >= 0} && {_selectedFob < count _fobPositions}) then {
    private _fobPos = _fobPositions select _selectedFob;
    ["STR_TAXI_MSG_REQUESTING"] call taxi_status_local;
    [_fobPos, KPLIB_taxi_class_choice, taxi_lz_position] remoteExec ["taxi_call_remote_call", 2];
};
