"""Run the production taxi rope readiness helper in SQF-VM, without Arma physics."""

import argparse
import re
import subprocess
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--sqfvm", default="sqfvm", help="SQF-VM executable (default: sqfvm on PATH)"
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    command = [
        args.sqfvm,
        "--automated",
        "--suppress-welcome",
        "--no-execute-print",
        "--no-work-print",
        "--max-runtime",
        "30000",
        "--virtual",
        f"{root}|/",
        "--input-sqf",
        str(root / "tools/tests/sqf/taxi_rope_readiness.sqf"),
    ]
    try:
        result = subprocess.run(
            command, cwd=root, capture_output=True, text=True, timeout=40, check=False
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        print(f"Unable to run SQF-VM: {exc}")
        return 1
    output = result.stdout + result.stderr
    print(output, end="" if output.endswith("\n") else "\n")
    complete = re.search(r"TAXI_ROPE_COMPLETE: (\d+) cases, (\d+) failures", output)
    # Some SQF-VM versions exit zero even after script errors. Require actual
    # per-case execution and the completed suite, in addition to the exit code.
    if (
        result.returncode != 0
        or complete is None
        or int(complete.group(1)) == 0
        or int(complete.group(2)) != 0
        or output.count("TAXI_ROPE_PASS:") != int(complete.group(1))
        or "TAXI_ROPE_FAIL:" in output
        or re.search(r"\[(?:ERR|FAT)\]", output)
    ):
        print("Taxi rope readiness regression suite failed or did not complete.")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
