// Accept authoritative server updates and direct local UI feedback only.
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
params [
    ["_key", "", [""]],
    ["_formatArgs", [], [[]]],
    ["_isError", false, [false]]
];
if ((_key find "STR_TAXI_MSG_") != 0 || {!isLocalized _key}) exitWith {};
private _message = format ([localize _key] + _formatArgs);
private _template = if (_isError) then {"lib_taxi_error"} else {"lib_taxi_status"};
[_template, [_message]] call BIS_fnc_showNotification;
// Keep the full text available after the popup has disappeared.
systemChat format ["%1: %2", localize "STR_TAXI_NOTIFICATION_TITLE", _message];
