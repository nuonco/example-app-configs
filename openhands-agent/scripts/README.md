# Scripts

Utility scripts for the Nuon application. All Python scripts should be run with [uv](https://github.com/astral-sh/uv).

## Python Scripts

### generate_diagram.py

Generates a MermaidJS diagram showing component dependencies by parsing `components/*.toml` files.

```bash
uv run scripts/generate_diagram.py
```

### check_policy_overlap.py

Checks for overlapping IAM actions across policy documents in a permission TOML file.

```bash
uv run scripts/check_policy_overlap.py permissions/maintenance.toml
```

### inputs-table.py

Generates a markdown table of all inputs defined in `inputs.toml`.

```bash
uv run scripts/inputs-table.py
```

### secrets-table.py

Generates a markdown table of all secrets in the `secrets/` directory.

```bash
uv run scripts/secrets-table.py
```
