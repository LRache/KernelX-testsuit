#!/usr/bin/env python3
import argparse
import csv
import shutil
import sys
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parent

ENV_COLUMNS = (
    "riscv_glibc",
    "riscv_musl",
    "loongarch_glibc",
    "loongarch_musl",
)

ENV_GROUPS = {
    "riscv": ("riscv_glibc", "riscv_musl"),
    "loongarch": ("loongarch_glibc", "loongarch_musl"),
}

ENV_CHOICES = tuple(ENV_GROUPS) + ENV_COLUMNS

DEFAULT_OUTPUTS = {
    "riscv_glibc": ROOT / "testcode-rv" / "ltp_testcode_glibc.sh",
    "riscv_musl": ROOT / "testcode-rv" / "ltp_testcode_musl.sh",
    "loongarch_glibc": ROOT / "testcode-la" / "ltp_testcode_glibc.sh",
    "loongarch_musl": ROOT / "testcode-la" / "ltp_testcode_musl.sh",
}

DEFAULT_BUSYBOX = {
    "riscv_glibc": "/glibc/busybox",
    "riscv_musl": "/musl/busybox",
    "loongarch_glibc": "/glibc/busybox",
    "loongarch_musl": "/musl/busybox",
}


def parse_args():
    parser = argparse.ArgumentParser(
        description="Export LTP test scripts from ltp_test_status.csv."
    )
    parser.add_argument(
        "--env",
        required=True,
        choices=ENV_CHOICES,
        help="Environment or arch to export. Arch values export both glibc and musl.",
    )
    scope = parser.add_mutually_exclusive_group(required=True)
    scope.add_argument(
        "--passed",
        action="store_true",
        help="Export tests whose status starts with PASS only.",
    )
    scope.add_argument(
        "--half",
        action="store_true",
        help="Export tests whose status starts with PASS or HALF.",
    )
    scope.add_argument(
        "--test",
        action="store_true",
        help="Export tests whose status starts with TEST only.",
    )
    parser.add_argument(
        "--csv",
        type=Path,
        default=ROOT / "ltp_test_status.csv",
        help="Input CSV path.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Output file for a single env, or output directory when --env is an arch. Defaults to the arch testcode directory.",
    )
    parser.add_argument(
        "--busybox",
        help="Busybox path used in the shebang. Defaults to /glibc/busybox or /musl/busybox.",
    )
    parser.add_argument(
        "--backup",
        action="store_true",
        help="Create a timestamped backup before overwriting output.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print generated script to stdout instead of writing output.",
    )
    return parser.parse_args()


def should_export(status, scope):
    value = (status or "").strip().upper()
    if scope == "passed":
        return value.startswith("PASS")
    if scope == "half":
        return value.startswith("PASS") or value.startswith("HALF")
    if scope == "test":
        return value.startswith("TEST")
    raise ValueError(f"unknown export scope: {scope}")


def load_tests(csv_path, env, scope):
    with csv_path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames:
            raise SystemExit(f"{csv_path} is empty")
        required = {"name", env}
        missing = sorted(required - set(reader.fieldnames))
        if missing:
            raise SystemExit(f"{csv_path} missing columns: {', '.join(missing)}")

        tests = []
        for row in reader:
            name = (row.get("name") or "").strip()
            if not name:
                continue
            if should_export(row.get(env), scope):
                tests.append(name)
        return tests


def render_script(tests, busybox):
    lines = [
        f"#!{busybox} sh",
        "",
        "cd ./ltp/testcases/bin",
        "",
        "export LTPROOT=../..",
        "PATH=$PATH:/glibc/ltp/testcases/bin"
        "",
        "set -ex",
        "",
    ]
    lines.extend(f"./{name}" for name in tests)
    lines.append("")
    return "\n".join(lines)


def backup_output(output_path):
    if not output_path.exists():
        return None
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_path = output_path.with_name(f"{output_path.name}.bak.{timestamp}")
    shutil.copy2(output_path, backup_path)
    return backup_path


def write_script(output_path, content, create_backup):
    old_mode = output_path.stat().st_mode if output_path.exists() else 0o755
    backup_path = backup_output(output_path) if create_backup else None
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content, encoding="utf-8", newline="\n")
    output_path.chmod(old_mode & 0o777)
    return backup_path


def selected_envs(env):
    return ENV_GROUPS.get(env, (env,))


def resolve_output_path(output_arg, env, multi_env):
    if not output_arg:
        return DEFAULT_OUTPUTS[env]

    output_path = output_arg if output_arg.is_absolute() else Path.cwd() / output_arg
    if multi_env:
        return output_path / DEFAULT_OUTPUTS[env].name
    return output_path


def main():
    args = parse_args()
    csv_path = args.csv if args.csv.is_absolute() else Path.cwd() / args.csv
    scope = "test" if args.test else "half" if args.half else "passed"
    envs = selected_envs(args.env)
    multi_env = len(envs) > 1

    for env in envs:
        output_path = resolve_output_path(args.output, env, multi_env)
        busybox = args.busybox or DEFAULT_BUSYBOX[env]
        tests = load_tests(csv_path, env, scope)
        content = render_script(tests, busybox)

        if args.dry_run:
            if multi_env:
                print(f"==> {env}: {output_path}", file=sys.stderr)
            sys.stdout.write(content)
            continue

        backup_path = write_script(output_path, content, create_backup=args.backup)
        print(f"exported {len(tests)} tests for {env} to {output_path}")
        if backup_path:
            print(f"backup: {backup_path}")


if __name__ == "__main__":
    main()
