#!/usr/bin/env python3
"""
Build script to generate docs/index.html from demo directories.

Reads metadata from:
- metadata.toml: display_name, description
- sandbox.toml: [public_repo].repo
- .meta.yaml: tags, links

Uses docs/index.j2.html as a Jinja2 template.
"""

import json
import sys
from pathlib import Path

try:
    import tomllib
except ImportError:
    import tomli as tomllib

import yaml
from jinja2 import Environment, FileSystemLoader

REPO_ROOT = Path(__file__).parent.parent
DOCS_DIR = REPO_ROOT / "docs"
SKIP_DIRS = {".git", "scripts", "docs", ".github"}
TEMPLATE_FILE = "index.j2.html"
OUTPUT_FILE = "index.html"


def parse_toml(path: Path) -> dict:
    """Parse a TOML file."""
    if not path.exists():
        return {}
    with open(path, "rb") as f:
        return tomllib.load(f)


def parse_yaml(path: Path) -> dict:
    """Parse a YAML file."""
    if not path.exists():
        return {}
    with open(path) as f:
        return yaml.safe_load(f) or {}


def extract_sandbox_repo(sandbox: dict) -> str | None:
    """Extract the sandbox repo from sandbox.toml."""
    public_repo = sandbox.get("public_repo", {})
    repo = public_repo.get("repo")
    if repo:
        return f"https://github.com/{repo}"
    return None


def build_demo(demo_dir: Path) -> dict | None:
    """Build a demo entry from a directory."""
    metadata = parse_toml(demo_dir / "metadata.toml")
    sandbox = parse_toml(demo_dir / "sandbox.toml")
    meta = parse_yaml(demo_dir / ".meta.yaml")

    if not metadata:
        print(f"  Skipping {demo_dir.name}: no metadata.toml", file=sys.stderr)
        return None

    return {
        "name": demo_dir.name,
        "title": metadata.get("display_name", demo_dir.name),
        "description": metadata.get("description", ""),
        "sandbox": extract_sandbox_repo(sandbox),
        "tags": meta.get("tags", []),
        "links": meta.get("links", {}),
        "github": f"https://github.com/nuonco/example-app-configs/tree/main/{demo_dir.name}",
    }


def main():
    demos = []
    all_tags = set()

    print("Building index.html from template...", file=sys.stderr)

    for entry in sorted(REPO_ROOT.iterdir()):
        if not entry.is_dir():
            continue
        if entry.name in SKIP_DIRS or entry.name.startswith("."):
            continue

        demo = build_demo(entry)
        if demo:
            demos.append(demo)
            all_tags.update(demo["tags"])
            print(f"  ✓ {demo['name']}", file=sys.stderr)

    site_data = {
        "demos": demos,
        "tags": sorted(all_tags),
    }

    env = Environment(loader=FileSystemLoader(DOCS_DIR))
    template = env.get_template(TEMPLATE_FILE)
    html = template.render(site_data=site_data)

    output_path = DOCS_DIR / OUTPUT_FILE
    output_path.write_text(html)

    print(f"\nGenerated {output_path} with {len(demos)} demos and {len(all_tags)} tags", file=sys.stderr)


if __name__ == "__main__":
    main()
