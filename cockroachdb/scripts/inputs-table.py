#!/usr/bin/env python3
"""Generate a markdown table of inputs from inputs.toml."""

import tomllib
from pathlib import Path


def main():
    inputs_file = Path(__file__).parent.parent / "inputs.toml"

    with open(inputs_file, "rb") as f:
        data = tomllib.load(f)

    groups = {g["name"]: g for g in data.get("group", [])}
    inputs = data.get("input", [])

    if not inputs:
        print("No inputs found.")
        return

    print("| Name | Display Name | Description | Group | Type | Default |")
    print("| --- | --- | --- | --- | --- | --- |")
    for i in sorted(inputs, key=lambda x: (x.get("group", ""), x.get("name", ""))):
        name = i.get("name", "")
        display_name = i.get("display_name", "")
        description = i.get("description", "")
        group = i.get("group", "")
        input_type = i.get("type", "string")
        default = i.get("default", "")
        default_display = f"`{default}`" if default else "_none_"
        print(
            f"| `{name}` | {display_name} | {description} | {group} | {input_type} | {default_display} |"
        )


if __name__ == "__main__":
    main()
