"""noctalia-changes: what you changed in noctalia's settings GUI.

Noctalia 5 keeps hand-written configuration and GUI changes apart:

    <wrapper>/noctalia/config.toml        our config.toml, read-only in the store
    ~/.local/state/noctalia/settings.toml everything the GUI writes, wins over it

So the second file *is* the list of your changes - no snapshotting and no
diffing needed (noctalia 4 needed both). This tool shows that file, and with
--save copies its contents into the repo's config.toml, keeping the comments
there intact.

    noctalia-changes            show what you changed in the GUI
    noctalia-changes --save     write it into the repo's config.toml
    noctalia-changes --clear    forget the GUI changes (after a rebuild)

Keys listed after `# ignore:` in config.toml are never shown or saved.
"""

import os
import shutil
import sys
from pathlib import Path

import tomlkit

REPO_CONFIG = Path.home() / "flakeos/modules/programs/noctalia/config.toml"

# Noctalia's own bookkeeping, never ours.
ALWAYS_IGNORED = ["config_version"]

USAGE = "usage: noctalia-changes [--save|--clear]"


def state_file() -> Path:
    """Where noctalia saves GUI changes (same order noctalia resolves it)."""
    for var, suffix in (
        ("NOCTALIA_STATE_HOME", "noctalia"),
        ("XDG_STATE_HOME", "noctalia"),
    ):
        root = os.environ.get(var)
        if root:
            return Path(root) / suffix / "settings.toml"
    return Path.home() / ".local/state/noctalia/settings.toml"


def ignored_keys(config_text: str) -> list[str]:
    """The dotted keys from the `# ignore:` comments in config.toml."""
    keys = list(ALWAYS_IGNORED)
    for line in config_text.splitlines():
        line = line.strip()
        if line.startswith("# ignore:"):
            keys += line.removeprefix("# ignore:").split()
    return keys


def strip_ignored(table, keys: list[str], path: str = ""):
    """A copy of `table` without the ignored keys (and without empty leftovers)."""
    kept = {}
    for key, value in table.items():
        dotted = f"{path}.{key}" if path else key
        if any(dotted == k or dotted.startswith(k + ".") for k in keys):
            continue
        if isinstance(value, dict):
            value = strip_ignored(value, keys, dotted)
            if not value:
                continue
        kept[key] = value
    return kept


def merge_into(target, changes):
    """Write `changes` into the tomlkit document `target`, in place.

    Tables are merged key by key, so comments and keys already in config.toml
    stay where they are. Anything else (a number, a string, a list such as a
    bar's widgets) replaces the old value as a whole.
    """
    for key, value in changes.items():
        if isinstance(value, dict):
            if key not in target or not isinstance(target[key], dict):
                target[key] = tomlkit.table()
            merge_into(target[key], value)
        else:
            target[key] = value


def main() -> int:
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode not in ("", "--save", "--clear") or len(sys.argv) > 2:
        print(USAGE, file=sys.stderr)
        return 1

    if not REPO_CONFIG.is_file():
        print(f"{REPO_CONFIG} is missing - is the repo somewhere else?",
              file=sys.stderr)
        return 1

    overrides = state_file()
    if not overrides.is_file():
        print("Nothing changed in the settings GUI yet "
              f"({overrides} does not exist).")
        return 0

    if mode == "--clear":
        backup = overrides.with_suffix(".toml.bak")
        shutil.copyfile(overrides, backup)
        overrides.unlink()
        print(f"Removed {overrides} (a copy is in {backup.name}).")
        print("Noctalia notices within a second and falls back to the "
              "config.toml from the last rebuild.")
        return 0

    repo_text = REPO_CONFIG.read_text()
    changes = strip_ignored(
        tomlkit.parse(overrides.read_text()), ignored_keys(repo_text)
    )

    if not changes:
        print("Nothing changed in the settings GUI (that isn't ignored).")
        return 0

    print(tomlkit.dumps(changes), end="")

    if mode == "--save":
        document = tomlkit.parse(repo_text)
        merge_into(document, changes)
        REPO_CONFIG.write_text(tomlkit.dumps(document))
        print()
        print(f"Added to {REPO_CONFIG}. Next:")
        print("  cd ~/flakeos")
        print("  git add -A")
        print("  git diff HEAD                 # check what changed")
        print("  nrs                           # rebuild")
        print("  noctalia-changes --clear      # drop the GUI copy")
        print()
        print("The last step matters: until then the same settings sit in "
              "both places, and the GUI copy wins - so later changes to "
              "config.toml would look like they do nothing.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
