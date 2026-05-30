#!/usr/bin/env python3
"""Manage third-party Copilot skills in the dotfiles skills directory."""

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import warnings
from pathlib import Path

DOTFILES_ROOT = Path(__file__).parent
SKILLS_DIR = DOTFILES_ROOT / "skills"
REGISTRY_FILE = DOTFILES_ROOT / "third-party-skills.json"


def normalize_repo_url(repo: str) -> str:
    """Accept https://github.com/... or org/repo format and return full URL."""
    if repo.startswith(("http://", "https://", "git@", "git://", "file://", "ssh://")):
        return repo
    if "/" in repo and not repo.startswith("/"):
        return f"https://github.com/{repo}"
    raise ValueError(f"Cannot interpret repo reference: {repo!r}. Use a full URL or 'org/repo'.")


def clone_repo(url: str, dest: Path) -> None:
    result = subprocess.run(
        ["git", "clone", "--depth=1", url, str(dest)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"ERROR: Failed to clone {url}:\n{result.stderr}", file=sys.stderr)
        sys.exit(1)


def find_skill_in_repo(repo_root: Path, skill_name: str) -> Path | None:
    """Search repo for a skill folder whose SKILL.md name field or folder name matches skill_name."""
    candidates = []
    for skill_md in repo_root.rglob("SKILL.md"):
        folder = skill_md.parent
        # Match by folder name
        if folder.name == skill_name:
            candidates.append(folder)
            continue
        # Match by 'name:' field inside SKILL.md
        try:
            content = skill_md.read_text()
            for line in content.splitlines():
                if line.strip().startswith("name:"):
                    name_val = line.split(":", 1)[1].strip()
                    if name_val == skill_name:
                        candidates.append(folder)
                        break
        except OSError:
            continue
    if not candidates:
        return None
    return candidates[0]


def load_registry() -> dict:
    if REGISTRY_FILE.exists():
        return json.loads(REGISTRY_FILE.read_text())
    return {}


def save_registry(registry: dict) -> None:
    REGISTRY_FILE.write_text(json.dumps(registry, indent=2) + "\n")


def repo_relative_path(repo_root: Path, skill_folder: Path) -> str:
    return str(skill_folder.relative_to(repo_root))


def copy_skill(src: Path, dest: Path) -> None:
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(src, dest)


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_add(args: argparse.Namespace) -> None:
    url = normalize_repo_url(args.repo)
    skill_name = args.name

    dest_dir = SKILLS_DIR / skill_name
    if dest_dir.exists():
        print(f"ERROR: Skill '{skill_name}' already exists at {dest_dir}. Use 'update' instead.")
        sys.exit(1)

    with tempfile.TemporaryDirectory() as tmpdir:
        repo_root = Path(tmpdir) / "repo"
        print(f"Cloning {url} …")
        clone_repo(url, repo_root)

        skill_folder = find_skill_in_repo(repo_root, skill_name)
        if skill_folder is None:
            print(f"ERROR: Could not find skill '{skill_name}' in {url}.", file=sys.stderr)
            print("Hint: Skill folder must contain a SKILL.md with 'name: <skill>' or the folder itself must be named the skill name.", file=sys.stderr)
            sys.exit(1)

        rel_path = repo_relative_path(repo_root, skill_folder)
        print(f"Found skill at {rel_path}")

        copy_skill(skill_folder, dest_dir)
        print(f"Copied skill to {dest_dir}")

    registry = load_registry()
    registry[skill_name] = {"url": url, "path": rel_path}
    save_registry(registry)
    print(f"Registered '{skill_name}' in {REGISTRY_FILE.name}")


def cmd_update(args: argparse.Namespace) -> None:
    skill_name = args.name
    registry = load_registry()

    if skill_name not in registry:
        print(f"ERROR: Skill '{skill_name}' is not in the registry ({REGISTRY_FILE.name}).", file=sys.stderr)
        sys.exit(1)

    entry = registry[skill_name]
    url = entry["url"]
    recorded_path = entry["path"]

    with tempfile.TemporaryDirectory() as tmpdir:
        repo_root = Path(tmpdir) / "repo"
        print(f"Cloning {url} …")
        clone_repo(url, repo_root)

        # Try recorded path first
        skill_folder: Path | None = None
        recorded_abs = repo_root / recorded_path
        if recorded_abs.exists() and (recorded_abs / "SKILL.md").exists():
            skill_folder = recorded_abs
        else:
            print(f"WARNING: Skill not found at recorded path '{recorded_path}', scanning repo …")
            skill_folder = find_skill_in_repo(repo_root, skill_name)
            if skill_folder is None:
                print(f"ERROR: Could not find skill '{skill_name}' anywhere in {url}.", file=sys.stderr)
                sys.exit(1)
            new_rel = repo_relative_path(repo_root, skill_folder)
            if new_rel != recorded_path:
                warnings.warn(
                    f"Skill '{skill_name}' found at '{new_rel}' instead of recorded '{recorded_path}'. "
                    "Registry will be updated.",
                    stacklevel=1,
                )
                entry["path"] = new_rel

        rel_path = repo_relative_path(repo_root, skill_folder)
        print(f"Updating from {rel_path}")

        dest_dir = SKILLS_DIR / skill_name
        copy_skill(skill_folder, dest_dir)
        print(f"Updated skill at {dest_dir}")

    save_registry(registry)
    print(f"Registry updated in {REGISTRY_FILE.name}")


def cmd_delete(args: argparse.Namespace) -> None:
    skill_name = args.name
    registry = load_registry()

    dest_dir = SKILLS_DIR / skill_name
    removed_any = False

    if dest_dir.exists():
        shutil.rmtree(dest_dir)
        print(f"Removed skill folder: {dest_dir}")
        removed_any = True
    else:
        print(f"WARNING: Skill folder '{dest_dir}' not found (already removed?).")

    if skill_name in registry:
        del registry[skill_name]
        save_registry(registry)
        print(f"Removed '{skill_name}' from {REGISTRY_FILE.name}")
        removed_any = True
    else:
        print(f"WARNING: Skill '{skill_name}' was not in registry.")

    if not removed_any:
        print(f"ERROR: Nothing to delete for skill '{skill_name}'.", file=sys.stderr)
        sys.exit(1)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Manage third-party Copilot skills.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  skill-manager.py add mattpocock/skills my-skill
  skill-manager.py add https://github.com/mattpocock/skills my-skill
  skill-manager.py update my-skill
  skill-manager.py delete my-skill
""",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_add = sub.add_parser("add", help="Install a new third-party skill")
    p_add.add_argument("repo", help="Git repo URL or org/repo shorthand")
    p_add.add_argument("name", help="Name of the skill to install")
    p_add.set_defaults(func=cmd_add)

    p_update = sub.add_parser("update", help="Update an installed third-party skill")
    p_update.add_argument("name", help="Name of the skill to update")
    p_update.set_defaults(func=cmd_update)

    p_delete = sub.add_parser("delete", help="Remove an installed third-party skill")
    p_delete.add_argument("name", help="Name of the skill to delete")
    p_delete.set_defaults(func=cmd_delete)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
