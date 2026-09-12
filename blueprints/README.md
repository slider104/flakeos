# blueprints

Templates for everything you might add. **Nothing in here is used by the
system**: `flake.nix` only reads `modules/`. A blueprint only becomes real
once you copy it into `modules/`.

The folders mirror `modules/`, so each blueprint goes into the folder of the
same name.

## Which one do I need?

| I want to add… | copy | to |
|---|---|---|
| a program with a ready-made wrapper module ([list](https://nix-community.github.io/nix-wrapper-modules/)) | `programs/wrapped/` | `modules/programs/<name>/` |
| a program with a config file but no ready-made module | `programs/wrapped-custom/` | `modules/programs/<name>/` |
| a program without config to manage (Steam, launchers, GUI apps) | `programs/plain/` | `modules/programs/<name>/` |
| a program that isn't in nixpkgs, from its own flake | `programs/from-flake/` | `modules/programs/<name>/` |
| a system setting / service / hardware support | `system/example.nix` | `modules/system/<topic>.nix` |
| a bundle of things (like `gaming`) | `grouped/example.nix` | `modules/grouped/<name>.nix` |
| a person | `users/example.nix` | `modules/users/<name>.nix` |
| a machine | `hosts/example/` | `modules/hosts/<name>/` |

Not sure whether a program can be wrapped? It can if it lets you say where its
config is (a flag like `--config <file>` or an environment variable) and
doesn't write to that config itself. Otherwise → `programs/plain/`.

## Every time

1. **Copy** the blueprint to where the table says.
2. **Rename**: replace every `example` with the real name, including file
   names (`example.nix` → `<name>.nix`). Files are named after what they are,
   never `default.nix`.
3. **Use it**: a new module does nothing until something lists it. Add its
   name to a bundle in `modules/grouped/` or directly to a host's list in
   `modules/hosts/<host>/<host>.nix`. (Hosts are the exception: they are
   picked with `--flake .#<name>`.)
4. **`git add`** the new files, or the flake won't see them.
5. **Rebuild**: `nrs`.

Example, adding the image editor `pinta` to the desktop:

```sh
cp -r blueprints/programs/plain modules/programs/pinta
mv modules/programs/pinta/example.nix modules/programs/pinta/pinta.nix
# edit pinta.nix: example → pinta, use `environment.systemPackages = [pkgs.pinta];`
# edit modules/grouped/desktop.nix: add `pinta` to the list
git add -A && nrs
```
