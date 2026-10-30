# git: saving, syncing and two machines

**How it works:** git keeps the history of the repo. A **commit** is a saved
snapshot with a short message. **Push** uploads your commits to GitHub,
**pull** downloads commits made on the other machine. GitHub is the meeting
point between zeus and hermes.

Three reasons to care on this system in particular:

1. **The flake only sees files git knows about.** A new file you didn't
   `git add` is silently ignored — no error, your change just doesn't happen.
2. **`git checkout <file>` is your undo.** Including `git checkout flake.lock`,
   which undoes an entire system update in one command.
3. **The repo *is* the machine.** Pushed to GitHub, your whole computer is
   backed up in a form that can be rebuilt onto bare hardware in an hour.

Zed's git panel (Mod+Z, the icon down the left side) does all of this with
buttons and is genuinely nicer for reviewing a change. The commands below are
the same thing in a terminal.

## Contents

- [The everyday loop](#the-everyday-loop)
- [Looking at what changed](#looking-at-what-changed)
- [Undoing things](#undoing-things)
- [The SSH key](#the-ssh-key)
- [Two machines](#two-machines)
  - [The normal flow](#the-normal-flow)
  - [When a pull refuses](#when-a-pull-refuses)
  - [When both machines changed the same lines](#when-both-machines-changed-the-same-lines)
  - [flake.lock, the one file that conflicts](#flakelock-the-one-file-that-conflicts)
- [Your own GitHub repo](#your-own-github-repo)
- [Living without git](#living-without-git)
- [Cheat sheet](#cheat-sheet)

---

## The everyday loop

```sh
cd ~/flakeos
```

- **See what changed:**
  ```sh
  git status
  ```
  Anything under `Untracked files` is **invisible to the build**. That is the
  one line in this output that can cost you an hour.
- **Mark everything for the next commit** (new files included):
  ```sh
  git add -A
  ```
- **Save a snapshot:**
  ```sh
  git commit -m "what I changed"
  ```
- **Upload to GitHub:**
  ```sh
  git push
  ```
- **On the other machine, get the changes** (then `nrs`):
  ```sh
  git pull
  ```

A reasonable habit: `git add -A` whenever you make a new file (you have to
anyway), and commit once you've rebuilt and confirmed the change works. The
commit message is for you in six months — "noctalia: bigger clock" beats
"changes".

## Looking at what changed

| command | shows |
|---|---|
| `git status` | which files changed, and which are untracked |
| `git diff` | the actual changes, line by line, not yet staged |
| `git diff HEAD` | every change since the last commit, staged or not |
| `git diff flake.lock` | **what an update moved**. Big, but it is the record |
| `git log --oneline` | the history, one line per commit |
| `git log --oneline -10` | the last ten |
| `git show <hash>` | everything one commit changed |
| `git log -p <file>` | the full history of one file |
| `git log --oneline -- modules/programs/noctalia/` | commits that touched one folder |

`git diff HEAD` after `noctalia-changes --save` or `dconf-changes … --save` is
the right way to check what a tool just wrote into your repo before you
rebuild.

## Undoing things

| want to | do |
|---|---|
| throw away changes to one file | `git checkout <file>` |
| throw away **all** uncommitted changes | `git checkout .` |
| undo an entire system update | `git checkout flake.lock` then `nrs` |
| unstage a file but keep the edit | `git restore --staged <file>` |
| undo the last commit, keep the changes | `git reset --soft HEAD~1` |
| see a file as it was in an old commit | `git show <hash>:<path>` |
| get a file back the way it was three commits ago | `git checkout HEAD~3 -- <path>` |

`git checkout <file>` is destructive and silent — the edit is gone. Zed's git
panel is better for this, because you can see each change before discarding
it.

**Note:** `git checkout` throwing away your edits does *not* change your
running system. You still need `nrs` for that.

## The SSH key

Pushing uses your SSH key at `~/.ssh/id_ed25519` — never a password or a
token. It is already wired up in the repo:

- `modules/programs/git/gitconfig` sends every push to GitHub over SSH, even
  though the repo was cloned with an `https://` URL.
- `modules/programs/git/git.nix` already trusts GitHub's host key, so there is
  no "are you sure you want to continue connecting?" to answer.

So once the key is on the machine, pushing from Zed just works. Check the key:

```sh
ssh -T git@github.com
```

It should answer **"Hi <your GitHub name>!"** — whichever GitHub account the
key belongs to. If it says "Permission denied (publickey)", the key is missing
or has the wrong permissions:

```sh
chmod 700 ~/.ssh
```
```sh
chmod 600 ~/.ssh/id_ed25519
```

**Never share `~/.ssh/id_ed25519`** (the one without `.pub`), and never put it
in the repo. If it leaks, anyone can push as you. Before reinstalling a
machine, copy `~/.ssh` somewhere the install won't erase — on zeus that's
`/mnt/data`. The reinstall guide has the exact steps:
[install.md](install.md#reinstalling-a-configured-host-example-zeus).

No key yet, or you want your own GitHub repo?
[Your own GitHub repo](#your-own-github-repo).

---

## Two machines

Relevant once you run flakeos on more than one PC; skip it otherwise.

**How it works:** each machine has its own copy of the repo, and they only
line up once one machine pushes and the other pulls. `gitconfig` sets
`pull.rebase = true`, so when both machines made commits, a pull puts *your*
local commits on top of the ones from GitHub and the history stays a straight
line.

### The normal flow

- **Before editing on a machine, get the latest state first.** This avoids
  most trouble:
  ```sh
  git pull
  ```
- Changed something on machine A: commit and push there. Then on machine B:
  ```sh
  git pull
  ```
  ```sh
  nrs
  ```
- Both machines made commits: `git pull` on B stacks B's commits on top, then
  `git push` from B and `git pull` on A.

### When a pull refuses

B has uncommitted changes, so the pull stops with *"cannot pull with rebase:
You have unstaged changes"*. Two options:

- Commit them first (the tidy way), or
- park them for the duration of the pull:
  ```sh
  git pull --autostash
  ```
  That stashes your changes, pulls, and puts them back on top.

### When both machines changed the same lines

The pull stops with a conflict. git marks the spot in the file:

```
<<<<<<< HEAD
what GitHub has
=======
what you have
>>>>>>> your commit
```

Edit the file so it says what you actually want (delete the markers), then:

```sh
git add <file>
```
```sh
git rebase --continue
```

Or give up and go back to how it was before the pull:

```sh
git rebase --abort
```

`git rebase --abort` always works and always leaves you exactly where you
started. Reach for it without embarrassment.

### flake.lock, the one file that conflicts

`flake.lock` is a normal file in git, so after a pull both machines have the
same one and build identical systems. They only drift apart if one machine
runs `nup` and doesn't push.

So: **run `nup` on one machine, push, pull on the other.** If you ran it on
both, see
[Updating two machines](updating.md#updating-two-machines) for the three
commands that sort it out.

---

## Your own GitHub repo

Relevant if you cloned someone else's flakeos, or want a second place to keep
yours. `git push` to a repo you don't own will fail with "permission denied".

GitHub only accepts uploads with a key. An **SSH key** is a pair of files: the
private half (`~/.ssh/id_ed25519`) never leaves your PC, the public half
(`id_ed25519.pub`) goes to GitHub.

- On github.com: **New repository**, name it e.g. `flakeos`, and leave it
  **empty** — no README, no licence.
- Make a key. Press Enter at every question (default place, no passphrase):
  ```sh
  ssh-keygen -t ed25519 -C "you@example.com"
  ```
- Show the public half:
  ```sh
  cat ~/.ssh/id_ed25519.pub
  ```
- Copy the whole line. On GitHub: your picture → **Settings** → **SSH and GPG
  keys** → **New SSH key**, give it a name (your hostname is a good one),
  paste, **Add SSH key**.
- Test it. It should say "Hi &lt;you&gt;! You've successfully authenticated":
  ```sh
  ssh -T git@github.com
  ```
- Point your repo at yours (put in your GitHub name):
  ```sh
  cd ~/flakeos
  ```
  ```sh
  git remote set-url origin https://github.com/YOUR-NAME/flakeos.git
  ```
- First commit and upload. `-u` remembers the target, so later a plain
  `git push` is enough:
  ```sh
  git add -A
  ```
  ```sh
  git commit -m "my flakeos"
  ```
  ```sh
  git push -u origin main
  ```

Your name and e-mail in commits come from `modules/programs/git/gitconfig`
(`[user]`), not from GitHub. Set those first if you haven't — they are baked
into every commit you make.

## Living without git

You can run flakeos with no git at all: delete `.git` and `.gitignore`, and
the flake simply takes every file in the folder.

- \+ never `git add`, no "Git tree is dirty" warnings
- − **no history**: no undo, no `git diff`, no `git checkout flake.lock`.
  Backups are entirely up to you
- − no Zed git panel, no GitHub, nothing on this page works
- − `.gitignore` stops working, so every rebuild copies the whole folder into
  the Nix store, `logs/` included. Harmless, just untidy; delete old logs now
  and then

Given that `git checkout flake.lock` is the main undo for a bad update, this
is not a trade worth making unless you have a very good reason. `git init` in
`~/flakeos` starts a fresh, empty history if you change your mind.

## Cheat sheet

```sh
cd ~/flakeos

git status                  # what changed; UNTRACKED = invisible to the build
git add -A                  # tell git about everything, new files included
git commit -m "message"     # save a snapshot
git push                    # upload to GitHub
git pull                    # get the other machine's commits
git pull --autostash        # ...even with uncommitted changes here

git diff                    # what I changed
git diff HEAD               # ...including what's staged
git log --oneline -10       # recent history

git checkout <file>         # throw away my changes to one file
git checkout flake.lock     # undo an update (then: nrs)
git rebase --abort          # back out of a conflicted pull

ssh -T git@github.com       # is my key working? -> "Hi <your name>!"
```
