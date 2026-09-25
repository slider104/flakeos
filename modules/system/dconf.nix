{
  # dconf: the settings database GTK / GNOME apps write into. Programs like
  # rnote, Shortwave and virt-manager have no config file at all - everything
  # you change in their menus lands here, in ~/.config/dconf/user, and is gone
  # on a fresh install.
  #
  # This config can put *defaults* into dconf too (see theme/theme.nix and
  # programs/virt-manager). They are read from /etc/dconf/db/..., below your
  # own changes: a default is what you get until you change it, and your
  # change wins from then on.
  #
  # `dconf-changes` (below) is the bridge: it shows what you changed and
  # writes it into the repo, so the next machine starts out the same way.
  # See README.md, "Keeping GTK app settings (dconf)".
  flake.nixosModules.dconf = {pkgs, ...}: let
    dconfChanges = pkgs.writeShellApplication {
      name = "dconf-changes";
      runtimeInputs = [pkgs.dconf pkgs.gawk];
      text = ''
        repo="$HOME/flakeos"
        profile=/etc/dconf/profile/user

        usage() {
          cat <<'USAGE'
        dconf-changes - settings you changed in a GTK app, ready for the repo

          dconf-changes                 which programs did I change something in?
          dconf-changes <program>       show those changes
          dconf-changes <program> --save   write them into
                                           modules/programs/<program>/dconf/<program>

        Options:
          --all   also show keys this config already sets to the same value
          --help  this text
        USAGE
        }

        name=""
        save=false
        all=false
        for arg in "$@"; do
          case "$arg" in
            --save) save=true ;;
            --all) all=true ;;
            -h | --help)
              usage
              exit 0
              ;;
            -*)
              echo "dconf-changes: unknown option $arg" >&2
              usage >&2
              exit 1
              ;;
            *)
              if [ -n "$name" ]; then
                echo "dconf-changes: one program at a time, please" >&2
                exit 1
              fi
              name="$arg"
              ;;
          esac
        done

        tmp=$(mktemp -d)
        trap 'rm -rf "$tmp"' EXIT

        # Two views of the same database, each through a profile that contains
        # only one half of it:
        #   user.ini - only what YOU changed  (~/.config/dconf/user)
        #   def.ini  - only what THIS CONFIG installs  (/etc/dconf/db/...)
        # Plain `dconf dump` shows the two mixed together, which is why it
        # can't tell you what is yours.
        printf 'user-db:user\n' > "$tmp/user-profile"
        : > "$tmp/def-profile"
        grep '^file-db:' "$profile" >> "$tmp/def-profile" || true
        DCONF_PROFILE="$tmp/user-profile" dconf dump / > "$tmp/user.ini"
        DCONF_PROFILE="$tmp/def-profile" dconf dump / > "$tmp/def.ini"

        if [ ! -s "$tmp/user.ini" ]; then
          echo "You haven't changed anything in a GTK app yet (your half of dconf is empty)."
          exit 0
        fi

        # No program named: list what has changes, so you can pick one.
        if [ -z "$name" ]; then
          echo "Settings you changed yourself:"
          echo
          gawk '
            /^\[/ { sec = substr($0, 2, length($0) - 2); next }
            index($0, "=") > 0 { n[sec]++ }
            END {
              for (s in n) printf "  %-55s %d key(s)\n", "/" s "/", n[s]
            }
          ' "$tmp/user.ini" | sort
          echo
          echo "The program's name is usually in the middle of the path."
          echo "Then run:  dconf-changes <program>"
          exit 0
        fi

        # Everything under a path whose name contains what you typed
        # (rnote -> /com/github/flxzt/rnote/), minus the keys this config
        # already sets to the very same value.
        gawk -v name="$name" -v all="$all" '
          FNR == NR {
            if ($0 ~ /^\[/) { dsec = substr($0, 2, length($0) - 2); next }
            i = index($0, "="); if (i == 0) next
            def[dsec SUBSEP substr($0, 1, i - 1)] = substr($0, i + 1)
            next
          }
          /^\[/ { sec = substr($0, 2, length($0) - 2); next }
          {
            i = index($0, "="); if (i == 0) next
            k = substr($0, 1, i - 1); v = substr($0, i + 1)
            if (index(tolower(sec), tolower(name)) == 0) next
            if (all != "true" && (sec SUBSEP k) in def && def[sec SUBSEP k] == v) next
            if (!(sec in seen)) { seen[sec] = 1; order[++n] = sec }
            out[sec] = out[sec] k "=" v "\n"
          }
          END { for (j = 1; j <= n; j++) printf "[%s]\n%s\n", order[j], out[order[j]] }
        ' "$tmp/def.ini" "$tmp/user.ini" > "$tmp/changes.ini"

        if [ ! -s "$tmp/changes.ini" ]; then
          if grep -qi "^\[.*$name" "$tmp/user.ini"; then
            echo "Nothing new for '$name': everything you changed is already in the repo."
          else
            echo "Found nothing for '$name'. Run dconf-changes without a name to see the list." >&2
            exit 1
          fi
          exit 0
        fi

        # The path to reset later: the part all the sections have in common.
        resetPath=$(gawk '
          /^\[/ {
            s = substr($0, 2, length($0) - 2)
            if (p == "") { p = s; next }
            while (substr(s, 1, length(p)) != p) p = substr(p, 1, length(p) - 1)
          }
          END { sub(/\/$/, "", p); print p }
        ' "$tmp/changes.ini")

        if [ "$save" = false ]; then
          cat "$tmp/changes.ini"
          echo "Keep it:  dconf-changes $name --save"
          exit 0
        fi

        moduleDir="$repo/modules/programs/$name"
        if [ ! -d "$moduleDir" ]; then
          echo "dconf-changes: there is no $moduleDir" >&2
          echo "Name it exactly like its folder in modules/programs/:" >&2
          ls "$repo/modules/programs" >&2
          exit 1
        fi

        keyfile="$moduleDir/dconf/$name"
        mkdir -p "$moduleDir/dconf"
        if [ ! -e "$keyfile" ]; then
          {
            echo "# Settings for $name, saved with 'dconf-changes $name --save'."
            echo "# Loaded by $name.nix as a dconf default. Comments and hand-made"
            echo "# edits survive the next --save; delete a line to stop keeping it."
          } > "$keyfile"
        fi

        # Merge instead of overwrite: your own comments and any key you are not
        # changing right now stay exactly where they are. A key that is in both
        # gets the new value; a key that is only new is appended to its section.
        gawk -v changes="$tmp/changes.ini" '
          BEGIN {
            while ((getline line < changes) > 0) {
              if (line ~ /^\[/) {
                nsec = substr(line, 2, length(line) - 2)
                if (!(nsec in nseen)) { nseen[nsec] = 1; norder[++nn] = nsec }
                continue
              }
              i = index(line, "="); if (i == 0) continue
              k = substr(line, 1, i - 1)
              val[nsec SUBSEP k] = substr(line, i + 1)
              keys[nsec] = keys[nsec] k "\n"
            }
            close(changes)
          }
          function flush(s,   rest, k, m) {
            if (s == "" || !(s in keys)) return
            m = split(keys[s], rest, "\n")
            for (k = 1; k <= m; k++)
              if (rest[k] != "" && !((s SUBSEP rest[k]) in done))
                print rest[k] "=" val[s SUBSEP rest[k]]
            delete keys[s]
          }
          /^\[/ {
            flush(sec)
            sec = substr($0, 2, length($0) - 2)
            handled[sec] = 1
            print
            next
          }
          {
            i = index($0, "=")
            if (i > 0) {
              k = substr($0, 1, i - 1)
              if ((sec SUBSEP k) in val) {
                print k "=" val[sec SUBSEP k]
                done[sec SUBSEP k] = 1
                next
              }
            }
            print
          }
          END {
            flush(sec)
            for (j = 1; j <= nn; j++) {
              s = norder[j]
              if (s in handled) continue
              print ""
              print "[" s "]"
              flush(s)
            }
          }
        ' "$keyfile" > "$tmp/merged" && mv "$tmp/merged" "$keyfile"

        echo "Saved to ''${keyfile#"$repo"/}"
        echo
        cat "$tmp/changes.ini"
        echo "Next:"
        echo "  1. git diff          look at what was added"
        echo "  2. nrs               build it into the system"
        echo "  3. dconf reset -f /$resetPath/"
        echo "     Drops your own copy so the repo's version is the one in use."
        echo "     It also drops everything else under /$resetPath/ that you did"
        echo "     not save (window sizes, recent files). Close $name first."
      '';
    };
  in {
    programs.dconf.enable = true;
    environment.systemPackages = [dconfChanges];
  };
}
