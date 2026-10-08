#!/usr/bin/env python3
"""Compare/apply the managed UPower values without replacing unrelated settings."""

import argparse
import configparser
import datetime
from pathlib import Path
import re
import shutil
import subprocess


DEFAULTS = {
    "UsePercentageForPolicy": "true",
    "PercentageLow": "20.0",
    "PercentageCritical": "5.0",
    "PercentageAction": "2.0",
    "CriticalPowerAction": "Auto",
}


def parse(text):
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.optionxform = str
    parser.read_string(text)
    return dict(parser.items("UPower")) if parser.has_section("UPower") else {}


def equivalent(key, current, desired):
    if key.startswith("Percentage"):
        try:
            return float(current) == float(desired)
        except ValueError:
            return False
    if key == "UsePercentageForPolicy":
        return current.lower() == desired.lower()
    return current == desired


def differences(text, desired):
    current = parse(text)
    return {
        key: (current.get(key, DEFAULTS[key]), value)
        for key, value in desired.items()
        if not equivalent(key, current.get(key, DEFAULTS[key]), value)
    }


def render(text, desired):
    lines = text.splitlines(keepends=True)
    output = []
    in_section = False
    found_section = False
    seen = set()

    def append_missing():
        if output and not output[-1].endswith("\n"):
            output[-1] += "\n"
        for key, value in desired.items():
            if key not in seen:
                output.append(f"{key}={value}\n")

    for line in lines:
        section = re.match(r"^\s*\[([^]]+)\]", line)
        if section:
            if in_section:
                append_missing()
            in_section = section.group(1) == "UPower"
            found_section |= in_section
        entry = re.match(r"^\s*([^#;\s=]+)\s*=", line) if in_section else None
        if entry and entry.group(1) in desired:
            key = entry.group(1)
            output.append(f"{key}={desired[key]}\n")
            seen.add(key)
        else:
            output.append(line)
    if in_section:
        append_missing()
    elif not found_section:
        if output and not output[-1].endswith("\n"):
            output[-1] += "\n"
        output.append("\n[UPower]\n")
        append_missing()
    return "".join(output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("check", "apply"))
    parser.add_argument("template", type=Path)
    parser.add_argument("--target", type=Path, default=Path("/etc/UPower/UPower.conf"))
    args = parser.parse_args()
    desired = parse(args.template.read_text())
    if set(desired) != set(DEFAULTS):
        parser.error("template must contain exactly the managed UPower keys")
    try:
        low, critical, action = (float(desired[key]) for key in (
            "PercentageLow", "PercentageCritical", "PercentageAction"))
        valid = 100 >= low > critical > action > 0
    except ValueError:
        valid = False
    if not valid or desired["UsePercentageForPolicy"] != "true" or desired["CriticalPowerAction"] != "Auto":
        parser.error("invalid UPower policy or thresholds")
    # Do not silently invent a configuration if the service is not installed.
    text = args.target.read_text()
    changed = differences(text, desired)
    for key, (current, wanted) in changed.items():
        print(f"  {key}: {current} -> {wanted}")
    if args.mode == "apply" and changed:
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
        backup = args.target.with_name(args.target.name + ".bak." + stamp)
        shutil.copy2(args.target, backup)
        args.target.write_text(render(text, desired))
        print(f"Backup: {backup}")
        subprocess.run(["systemctl", "restart", "upower.service"], check=True)


if __name__ == "__main__":
    main()
