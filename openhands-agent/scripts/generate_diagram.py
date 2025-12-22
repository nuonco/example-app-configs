# /// script
# dependencies = [
#     "tomli",
# ]
# ///

import glob
import os
import re
import tomli
import sys


def get_dependencies(content):
    # Pattern to match .nuon.components.<component_name>.outputs
    # We want to capture <component_name>
    pattern = r"\.nuon\.components\.([a-zA-Z0-9_-]+)\.outputs"
    return set(re.findall(pattern, content))


def main():
    components_dir = "components"
    if not os.path.exists(components_dir):
        print(f"Directory {components_dir} not found.")
        return

    components = {}

    # Find all toml files in components directory
    toml_files = glob.glob(os.path.join(components_dir, "*.toml"))

    for file_path in toml_files:
        try:
            with open(file_path, "rb") as f:
                data = tomli.load(f)

            name = data.get("name")
            comp_type = data.get("type")

            if not name:
                continue

            # Store component info
            components[name] = {
                "type": comp_type,
                "file": os.path.basename(file_path),
                "deps": set(),
            }

            # 1. Check [vars] block
            vars_block = data.get("vars", {})
            for key, value in vars_block.items():
                if isinstance(value, str):
                    deps = get_dependencies(value)
                    components[name]["deps"].update(deps)

            # 2. Check [[var_file]] block
            var_files = data.get("var_file", [])
            for vf in var_files:
                contents_path = vf.get("contents")
                if contents_path:
                    # Resolve path relative to the toml file
                    full_path = os.path.join(os.path.dirname(file_path), contents_path)
                    if os.path.exists(full_path):
                        with open(full_path, "r") as f:
                            file_content = f.read()
                            deps = get_dependencies(file_content)
                            components[name]["deps"].update(deps)
                    else:
                        print(
                            f"Warning: var_file {full_path} not found for component {name}",
                            file=sys.stderr,
                        )

        except Exception as e:
            print(f"Error parsing {file_path}: {e}", file=sys.stderr)

    # Generate Mermaid Chart
    print("```mermaid")
    print("graph TD")

    # Define nodes
    for name, info in components.items():
        # Format label: name<br/>filename
        label = f"{name}<br/>{info['file']}"
        print(f'  {name}["{label}"]')

    print("")

    # Define edges
    for name, info in components.items():
        for dep in info["deps"]:
            if dep in components:
                print(f"  {dep} --> {name}")
            else:
                # Dependency might be external or not in the list, we can optionally show it
                # But prompt implied "diagram of the component dependencies", usually implies internal ones.
                # However, to be safe, if it's not found, we ignore it or maybe warn.
                # Given the constraints, we only map between found components.
                pass

    print("")

    # styling
    # "image components should have their own color distinct from terraform components."

    # Find types
    # Terraform components usually have 'terraform' in type or assume default
    # Image components have 'container_image'

    tf_components = []
    img_components = []

    for name, info in components.items():
        if info["type"] == "container_image":
            img_components.append(name)
        else:
            tf_components.append(name)

    if tf_components:
        # Light purple fill, dark purple stroke (matching the user's previous example somewhat)
        print(f"  class {','.join(tf_components)} tfClass;")

    if img_components:
        # Orange fill (matching the user's previous example somewhat)
        print(f"  class {','.join(img_components)} imgClass;")

    print("")
    print("  classDef tfClass fill:#D6B0FC,stroke:#8040BF,color:#000;")
    print("  classDef imgClass fill:#FCA04A,stroke:#CC803A,color:#000;")

    print("```")


if __name__ == "__main__":
    main()
