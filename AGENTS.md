# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this is

`bash-notes`: single-file bash note-taking script. Notes are plain files in
`$NOTESDIR`, indexed by a JSON database (`$DB`) managed with `jq`. Optional git
sync of the data dir to a remote. Built for use from rofi/i3 (spawns a terminal
running the editor). Only runtime dependency: `jq` (plus `git` if sync is on,
`/usr/share/dict/words` for random titles).

## Layout and build

`notes.sh` is a **generated file**. Never edit it directly. Edit `SOURCE/`, then
run `make`, and commit both the sources and the rebuilt `notes.sh` together.

`make` concatenates, in this order:

1. `SOURCE/head.sh`: shebang, license header, debug setup, `set_defaults()`,
   rc file sourcing, PID file handling, `export_config`, `firstrun`
2. `SOURCE/CORE/helpers.sh`: `check_noteID`, `helptext`, `configtext`,
   `random_title`, `exitwait`
3. `SOURCE/CORE/git.sh`: `gitsync`/`gitadd`/`gitedit`/`gitremove`, plus
   top-level code that inits the data repo when `USEGIT` and `GITREMOTE` are set
4. `SOURCE/CORE/core-*.sh` (glob order): one command per file (add, backup,
   edit, list, remove, show)
5. `SOURCE/main.sh`: `getopt` parsing and dispatch

`rofi-notes.sh` is a hand-written rofi + kitty front end (show/add/edit/delete
menus), not part of the build. It calls `notes` from `PATH`.

On the maintainer's machine both scripts are installed as symlinks into the
repo, so a `make` (or an edit to `rofi-notes.sh`) is live immediately:

    ~/bin/notes               -> notes.sh
    ~/bin/rofi-notes.sh       -> rofi-notes.sh   (bound to Super+F5..F8 in Hyprland)

Since it is plain concatenation, top-level code runs in that order. A function
is callable from `main.sh` no matter which file defines it.

Check the build is in sync:

    diff <(cat SOURCE/head.sh SOURCE/CORE/helpers.sh SOURCE/CORE/git.sh SOURCE/CORE/core-* SOURCE/main.sh) notes.sh

## Conventions

- `set_defaults()` in `head.sh` doubles as the template for `--userconf`:
  `export_config` extracts it with sed between the `set_defaults() {` line and
  the `} # end set_defaults, do not change this line.` marker, and rewrites
  `VAR=${VAR:-default}` into `VAR=default`. Keep that marker line and that
  assignment shape intact.
- New options: add to the `getopt` short/long lists in `main.sh`, the `case`
  dispatch, `helptext`, and the usage block in `README.md`.
- DB writes go through `$TMPDB` then `mv` over `$DB`.
- Honour `$PLAIN` for output formatting.
- Indentation is mixed (tabs in most files, 4 spaces in `helpers.sh`/`git.sh`).
  Match the file you are editing.
- Existing `# shellcheck disable=` comments are deliberate. Run
  `shellcheck -S warning notes.sh` after changes and do not add new warnings.
- Bump `VERSION` in `head.sh` and the README ChangeLog for user-visible releases.

## Testing

No test suite. Verify by running in a sandbox so the real data dir, rc file,
and a GUI terminal are never touched:

    S=$(mktemp -d)
    printf 'y\n' | BASEDIR=$S RCFILE=$S/rc TERMINAL=/bin/true ./notes.sh -l   # firstrun
    printf 'x'   | BASEDIR=$S RCFILE=$S/rc TERMINAL=/bin/true ./notes.sh -a"title"
    jq . $S/db.json

Caveats: `exitwait` blocks on a keypress (feed stdin). The PID file
(`/var/tmp/notes.pid`) and `$TMPDB` (`/tmp/db.json`) are global, and starting
the script **kills any running instance**, including the user's.

## Repo facts

- License: CC BY-NC 4.0 (see README and `head.sh` header). No `LICENSE` file.
- `origin` pushes to both the personal git server and GitHub in one `git push`.
- `TODO` file is a scratch list, the real roadmap lives in the README "TO DO".
