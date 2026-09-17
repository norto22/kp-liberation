// Execute the production decision helper; no Arma objects or physics are mocked.
private _readiness = compile preprocessFileLineNumbers "Missionframework/FUNCTIONS/fn_taxiRopeReadiness.sqf";
private _cases = [
    ["reported 34 m hover, 31 m from LZ", [[34.2, 34.4], 36.6, 34, 0.01, 31], [true, "ready", 34.9]],
    ["above old 26 m ceiling", [[27], 30, 27, 0, 0], [true, "ready", 27.5]],
    ["exact rope reach including slack", [[20, 21], 21.5, 20, 0, 0], [true, "ready", 21.5]],
    ["longest hook must reach", [[20, 22], 21.5, 20, 0, 0], [false, "rope_too_short", 22.5]],
    ["hook order does not matter", [[22, 20], 21.5, 20, 0, 0], [false, "rope_too_short", 22.5]],
    ["rope needs half metre slack", [[21], 21.49, 20, 0, 0], [false, "rope_too_short", 21.5]],
    ["ground hook is valid", [[0], 0.5, 6, 0, 0], [true, "ready", 0.5]],
    ["height at 5 m", [[4], 30, 5, 0, 0], [false, "too_low", 4.5]],
    ["height below 5 m", [[4], 30, 4.99, 0, 0], [false, "too_low", 4.5]],
    ["height just above 5 m", [[4], 30, 5.01, 0, 0], [true, "ready", 4.5]],
    ["speed at 3 m per second", [[20], 30, 20, 3, 0], [false, "moving", 20.5]],
    ["speed above 3 m per second", [[20], 30, 20, 3.01, 0], [false, "moving", 20.5]],
    ["speed just below limit", [[20], 30, 20, 2.99, 0], [true, "ready", 20.5]],
    ["distance at 50 m", [[20], 30, 20, 0, 50], [false, "outside_lz", 20.5]],
    ["distance above 50 m", [[20], 30, 20, 0, 50.01], [false, "outside_lz", 20.5]],
    ["distance just below limit", [[20], 30, 20, 0, 49.99], [true, "ready", 20.5]],
    ["no deployed hooks", [[], 30, 20, 0, 0], [false, "no_hooks", 0]],
    ["hooks not an array", [20, 30, 20, 0, 0], [false, "invalid_input", 0]],
    ["undefined hooks", [nil, 30, 20, 0, 0], [false, "invalid_input", 0]],
    ["undefined hook among valid hooks", [[20, nil], 30, 20, 0, 0], [false, "invalid_input", 0]],
    ["nonnumeric hook among valid hooks", [[20, "bad"], 30, 20, 0, 0], [false, "invalid_input", 0]],
    ["negative hook", [[20, -1], 30, 20, 0, 0], [false, "invalid_input", 0]],
    ["zero rope length", [[20], 0, 20, 0, 0], [false, "invalid_input", 0]],
    ["negative rope length", [[20], -30, 20, 0, 0], [false, "invalid_input", 0]],
    ["nonnumeric rope length", [[20], "30", 20, 0, 0], [false, "invalid_input", 0]],
    ["undefined rope length", [[20], nil, 20, 0, 0], [false, "invalid_input", 0]],
    ["nonnumeric aircraft height", [[20], 30, "20", 0, 0], [false, "invalid_input", 0]],
    ["nonnumeric speed", [[20], 30, 20, "0", 0], [false, "invalid_input", 0]],
    ["nonnumeric distance", [[20], 30, 20, 0, "0"], [false, "invalid_input", 0]],
    ["negative speed", [[20], 30, 20, -1, 0], [false, "invalid_input", 0]],
    ["negative distance", [[20], 30, 20, 0, -1], [false, "invalid_input", 0]],
    ["missing argument", [[20], 30, 20, 0], [false, "invalid_input", 0]],
    ["nonarray arguments", 20, [false, "invalid_input", 0]]
];
private _failed = 0;
{
    _x params ["_name", "_input", "_expected"];
    private _actual = _input call _readiness;
    private _passed = !isNil "_actual";
    if (_passed) then {
        _passed = _actual isEqualType [] && {count _actual == 3};
    };
    if (_passed) then {
        _passed = (_actual select 0) isEqualTo (_expected select 0)
            && {(_actual select 1) isEqualTo (_expected select 1)}
            && {abs ((_actual select 2) - (_expected select 2)) < 0.0001};
    };
    if (_passed) then {
        diag_log format ["TAXI_ROPE_PASS: %1", _name];
    } else {
        _failed = _failed + 1;
        diag_log format ["TAXI_ROPE_FAIL: %1; expected %2; got %3", _name, _expected, if (isNil "_actual") then {"nil"} else {_actual}];
    };
} forEach _cases;
private _ropesClear = compile preprocessFileLineNumbers "Missionframework/FUNCTIONS/fn_taxiRopesClear.sqf";
private _clearCases = [
    ["no ropes remain", [], true],
    ["free rope", [[false, false, 0]], true],
    ["occupied unbroken rope awaiting rider", [[true, false, 0]], false],
    ["occupied broken rope without rider", [[true, true, 0]], true],
    ["broken rope with attached rider", [[true, true, 1]], false],
    ["unoccupied rope with attached rider", [[false, false, 1]], false],
    ["unoccupied broken rope with attached rider", [[false, true, 1]], false],
    ["multiple ropes with active rider", [[false, false, 0], [true, true, 1]], false],
    ["multiple ropes all clear", [[false, false, 0], [true, true, 0]], true],
    ["rope states not an array", 0, false],
    ["rope state not an array", [false], false],
    ["incomplete rope state", [[false, false]], false],
    ["extra rope state field", [[false, false, 0, 0]], false],
    ["invalid occupied flag", [[0, false, 0]], false],
    ["invalid broken flag", [[false, 0, 0]], false],
    ["invalid rider count", [[false, false, "0"]], false],
    ["negative rider count", [[false, false, -1]], false],
    ["undefined rider count", [[false, false, nil]], false],
    ["undefined rope state", [nil], false]
];
{
    _x params ["_name", "_input", "_expected"];
    private _actual = _input call _ropesClear;
    if (!isNil "_actual" && {_actual isEqualTo _expected}) then {
        diag_log format ["TAXI_ROPE_PASS: cleanup %1", _name];
    } else {
        _failed = _failed + 1;
        diag_log format ["TAXI_ROPE_FAIL: cleanup %1; expected %2; got %3", _name, _expected, if (isNil "_actual") then {"nil"} else {_actual}];
    };
} forEach _clearCases;
diag_log format ["TAXI_ROPE_COMPLETE: %1 cases, %2 failures", count _cases + count _clearCases, _failed];
