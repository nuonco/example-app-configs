#!/usr/bin/env python3
"""Generate a markdown table of secrets from the secrets/ directory."""

import os
import tomllib
from pathlib import Path


def main():
    secrets_dir = Path(__file__).parent.parent / "secrets"
    secrets = []

    for toml_file in secrets_dir.rglob("*.toml"):
        with open(toml_file, "rb") as f:
            data = tomllib.load(f)

        secrets.append(
            {
                "name": data.get("name", ""),
                "display_name": data.get("display_name", ""),
                "description": data.get("description", ""),
                "k8s_sync": data.get("kubernetes_sync", False),
                "k8s_namespace": data.get("kubernetes_secret_namespace", ""),
                "k8s_secret": data.get("kubernetes_secret_name", ""),
            }
        )

    if not secrets:
        print("No secrets found.")
        return

    print(
        "| Name | Display Name | Description | K8s Sync | K8s Namespace | K8s Secret |"
    )
    print("| --- | --- | --- | --- | --- | --- |")
    for s in sorted(secrets, key=lambda x: x["name"]):
        print(
            f"| `{s['name']}` | {s['display_name']} | {s['description']} | {s['k8s_sync']} | `{s['k8s_namespace']}` | `{s['k8s_secret']}` |"
        )


if __name__ == "__main__":
    main()
