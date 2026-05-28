#!/usr/bin/env python3
"""Collect per-test LTP "Summary:" counters from a QEMU log."""

from __future__ import annotations

import argparse
import re
import signal
from pathlib import Path


FIELDS = ("passed", "failed", "broken", "skipped", "warnings")
TEST_RE = re.compile(r"^== TEST (.+) ==\s*$")
SUMMARY_RE = re.compile(r"^Summary:\s*$")
STAT_RE = re.compile(r"^(passed|failed|broken|skipped|warnings)\s+(-?\d+)\s*$")


def parse_log(path: Path) -> list[dict[str, int | str]]:
    rows: list[dict[str, int | str]] = []
    current_name: str | None = None
    current_counts = {field: 0 for field in FIELDS}
    current_summaries = 0
    in_summary = False

    def finish_current() -> None:
        nonlocal current_name, current_counts, current_summaries
        if current_name is not None and current_summaries:
            row: dict[str, int | str] = {
                "test": current_name,
                "summaries": current_summaries,
            }
            row.update(current_counts)
            rows.append(row)
        current_name = None
        current_counts = {field: 0 for field in FIELDS}
        current_summaries = 0

    with path.open("r", encoding="utf-8", errors="replace") as log_file:
        for raw_line in log_file:
            line = raw_line.rstrip("\n\r")

            test_match = TEST_RE.match(line)
            if test_match:
                finish_current()
                current_name = test_match.group(1)
                in_summary = False
                continue

            if current_name is None:
                continue

            if SUMMARY_RE.match(line):
                current_summaries += 1
                in_summary = True
                continue

            if not in_summary:
                continue

            stat_match = STAT_RE.match(line.strip())
            if stat_match:
                key, value = stat_match.groups()
                current_counts[key] += int(value)
            elif line.strip():
                in_summary = False

    finish_current()
    return rows


def print_table(rows: list[dict[str, int | str]]) -> None:
    headers = ("test", "summaries", *FIELDS)
    totals = {field: 0 for field in ("summaries", *FIELDS)}

    for row in rows:
        for field in totals:
            totals[field] += int(row[field])

    widths = {
        "test": max([len("test"), *(len(str(row["test"])) for row in rows)], default=4),
    }
    for field in ("summaries", *FIELDS):
        widths[field] = max(len(field), len(str(totals[field])), *(len(str(row[field])) for row in rows))

    print(" ".join(header.ljust(widths[header]) if header == "test" else header.rjust(widths[header]) for header in headers))
    print(" ".join("-" * widths[header] for header in headers))

    for row in rows:
        print(
            " ".join(
                str(row[header]).ljust(widths[header])
                if header == "test"
                else str(row[header]).rjust(widths[header])
                for header in headers
            )
        )

    print(" ".join("-" * widths[header] for header in headers))
    print(
        " ".join(
            "TOTAL".ljust(widths["test"])
            if header == "test"
            else str(totals[header]).rjust(widths[header])
            for header in headers
        )
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Summarize per-test LTP Summary counters; tests without Summary are skipped."
    )
    parser.add_argument("log", type=Path, help="Path to log.log/log2.log/log3.log")
    args = parser.parse_args()

    rows = parse_log(args.log)
    print_table(rows)
    return 0


if __name__ == "__main__":
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    raise SystemExit(main())
