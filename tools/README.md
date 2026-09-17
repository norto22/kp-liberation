# `tools/` — Python dev & CI checks

> **Not to be confused with [`_tools/`](../_tools)** — that (leading underscore)
> is the **Node/gulp mission build** that assembles and packs the PBOs.
> **This** `tools/` directory is the **Python** static-analysis tooling that
> guards code quality. They are independent toolchains.

These checks run entirely off the source files — **no Arma 3 engine required** —
so they work locally and in CI. They exist to keep the codebase tidy after the `KPLIB_` namespace unification sweep and make future renames verifiable mechanically:
CI turns red only on *newly introduced* breakage, never on pre-existing legacy quirks.

## Setup

```bash
pip install -r tools/requirements.txt
```

## The checks

| Script | What it does | Gates CI? |
|--------|--------------|-----------|
| `sqf_lint.py` | Runs the `sqflint` analyzer over every `Missionframework/**/*.sqf`; fails only on findings **not** in the committed baseline. | Yes — on *new* findings |
| `refcheck.py` | Resolves every `CfgFunctions` class→file mapping and every `execVM`/`preprocessFile`/`#include` path; flags broken references and orphan files. | Yes — on **any** error or warning |
| `namespace_keys.py` | Inventories all `setVariable`/`getVariable` string keys (now all `KPLIB_`-prefixed) and pairs writers with readers. | No — informational |
| `sweep.py` | Rename-sweep engine used for the namespace unification (Pass A dir recase, Pass B module renames, Pass C identifier unification). | No — one-shot tool |
| `rename_map.py` | Explicit rename map and exclusion table consumed by `sweep.py`. | No — data module |

Run from the repo root:

```bash
python tools/sqf_lint.py        # gate against the baseline
python tools/refcheck.py        # reference integrity
python tools/namespace_keys.py  # print the key inventory
```

### Updating the SQF lint baseline

The taxi landing code uses the [`landAt` helipad overload](https://community.bistudio.com/wiki/landAt) with the Arma 3 2.20 pickup/unload modes and wait time: `[helipad, mode, waitTime]`. The installed analyzer only knows the older object/number overloads; its argument-type finding for this call is explicitly baselined.

The same applies to [`flyInHeight [height, forced]`](https://community.bistudio.com/wiki/flyInHeight), used to request a forced 20 m fast-rope hover, matching ACE's fast-rope waypoint approach. The analyzer only knows the numeric overload.

The baseline (`sqf_lint_baseline.txt`) records the *expected* sqflint findings
on the current tree (legacy warnings + sqflint's false-positives on modern
commands like `findIf`). Regenerate it after an intentional, reviewed change:

```bash
python tools/sqf_lint.py --update-baseline
```

A finding **not** in the baseline (e.g. a new unbalanced bracket) fails the
check and names the offending file. Baseline format: one tab-separated
`relpath<TAB>severity<TAB>message` line per finding, sorted.

> sqflint is superlinear on the large equipment-*data* files (e.g.
> `arsenal_presets/unsung.sqf`, 167 KB), so files over ~40 KB and any that
> exceed the per-file timeout are skipped and listed in the output (never
> silently).

### Reference integrity (`refcheck.py`)

`refcheck.py` resolves every `CfgFunctions` mapping and `execVM`/`preprocess`/
`#include` path. It exits non-zero (**CI red**) on **any** finding — there is no
baseline; every reference problem must be fixed to get the check green:

- a **missing** target (ERROR),
- a **case mismatch** (WARNING — harmless in a packed PBO, broken on a
  case-sensitive Linux server),
- an unregistered `fn_*` function (WARNING).

Orphan detection is limited to `fn_*` files not in `CfgFunctions`; loose scripts
load via dynamic paths and can't be traced statically.

> `refcheck` is **green** on the current tree. It strips `//` and `/* */`
> comments before scanning, so commented-out / example `execVM` paths in
> docblocks are not treated as references. Unlike `refcheck`, the `sqf_lint`
> check keeps a baseline: its 338 findings include sqflint's own false positives
> on modern commands, which can't all be "fixed" — so it gates on *new* findings
> only.

## Tests

```bash
uv run --no-project --with pytest pytest tools/tests -q
```

### Taxi SQF regression tests

The focused fast-rope regression suite executes the production SQF decision
helpers in [SQF-VM](https://github.com/SQFvm/runtime). Install SQF-VM separately,
then run:

```bash
python tools/run_taxi_sqf_tests.py --sqfvm /path/to/sqfvm
```

The suite checks hook reach, the reported 34 m hover, safety boundaries, broken
ropes with attached riders, and invalid input. CI runs the suite using a pinned,
checksum-verified SQF-VM release. It returns nonzero on failed assertions, script errors, or an
incomplete VM run. It does not simulate Arma flight, ACE deployment, rope
physics, locality, or passengers; those still require an in-game check.
