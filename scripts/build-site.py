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
ONBOARDING_OUTPUT_FILE = "onboarding-apps.json"
REPO_URL = "https://github.com/nuonco/example-app-configs"
BRANCH = "main"


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
        "cloud": meta.get("cloud", ""),
        "categories": meta.get("category", []),
        "infra": meta.get("infra", ""),
        "stack": meta.get("stack", []),
        "features": meta.get("features", []),
        "tags": meta.get("tags", []),
        "links": meta.get("links", {}),
        "github": f"https://github.com/nuonco/example-app-configs/tree/main/{demo_dir.name}",
    }


def build_onboarding_entry(demo_dir: Path) -> dict | None:
    """Build an onboarding catalog entry if the app opts in via metadata.toml."""
    metadata = parse_toml(demo_dir / "metadata.toml")
    onboarding = metadata.get("onboarding") or {}
    if not onboarding.get("enabled"):
        return None

    meta = parse_yaml(demo_dir / ".meta.yaml")

    return {
        "slug": demo_dir.name,
        "display_name": metadata.get("display_name", demo_dir.name),
        "description": metadata.get("description", ""),
        "category": onboarding.get("category", ""),
        "difficulty": onboarding.get("difficulty", ""),
        "tags": meta.get("tags", []),
        "cloud_provider": onboarding.get("cloud_provider", ""),
        "repo": REPO_URL,
        "directory": demo_dir.name,
        "branch": BRANCH,
    }


def main():
    demos = []
    onboarding_apps = []
    all_tags = set()
    all_clouds = set()
    all_categories = set()
    all_infra = set()
    all_stack = set()
    all_features = set()

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
            if demo["cloud"]:
                all_clouds.add(demo["cloud"])
            all_categories.update(demo["categories"])
            if demo["infra"]:
                all_infra.add(demo["infra"])
            all_stack.update(demo["stack"])
            all_features.update(demo["features"])
            print(f"  ✓ {demo['name']}", file=sys.stderr)

        onboarding_entry = build_onboarding_entry(entry)
        if onboarding_entry:
            onboarding_apps.append(onboarding_entry)

    site_data = {
        "demos": demos,
        "tags": sorted(all_tags),
        "clouds": sorted(all_clouds),
        "categories": sorted(all_categories),
        "infra": sorted(all_infra),
        "stack": sorted(all_stack),
        "features": sorted(all_features),
    }

    env = Environment(loader=FileSystemLoader(DOCS_DIR))
    template = env.get_template(TEMPLATE_FILE)
    html = template.render(site_data=site_data)

    output_path = DOCS_DIR / OUTPUT_FILE
    output_path.write_text(html)

    print(f"\nGenerated {output_path} with {len(demos)} demos and {len(all_tags)} tags", file=sys.stderr)

    onboarding_path = DOCS_DIR / ONBOARDING_OUTPUT_FILE
    onboarding_path.write_text(json.dumps(onboarding_apps, indent=2) + "\n")
    print(f"Generated {onboarding_path} with {len(onboarding_apps)} onboarding apps", file=sys.stderr)


if __name__ == "__main__":
    main()
