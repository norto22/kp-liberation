/*
    Server-only taxi feedback. Recipient is one client owner ID or a taxi whose
    player crew and requesting group should hear the update. Arguments remain
    structured until the receiving client localizes and formats the message.
*/
if (!isServer) exitWith {false};
params [
    ["_recipient", objNull, [0, objNull]],
    ["_key", "", [""]],
    ["_formatArgs", [], [[]]],
    ["_isError", false, [false]]
];
if ((_key find "STR_TAXI_MSG_") != 0) exitWith {false};
private _owners = [];
if (_recipient isEqualType 0) then {
    // Zero/negative remoteExec targets broadcast; only concrete client IDs are valid.
    if ((_recipient - _recipient) isEqualTo 0 && {_recipient >= 2} && {_recipient == floor _recipient}) then {_owners pushBack _recipient;};
} else {
    if (!isNull _recipient) then {
        private _requestGroup = _recipient getVariable ["KPLIB_taxi_group", grpNull];
        private _crew = crew _recipient;
        {
            if (_x in _crew || {!isNull _requestGroup && {group _x == _requestGroup}}) then {
                private _owner = owner _x;
                if (_owner >= 2) then {_owners pushBackUnique _owner;};
            };
        } forEach allPlayers;
    };
};
{
    [_key, _formatArgs, _isError] remoteExec ["taxi_status_local", _x];
} forEach _owners;
!(_owners isEqualTo [])
