# bash notes

## a simple note taking script written in bash

I've found myself in need of a simple way to take notes, and since the other solutions available didn't meet my needs, I've decided to write my own script.

It's a simple (enough) bash script, the only dependence (yet) is [jq](https://stedolan.github.io/jq/).

here's all the functions that are now available:

```bash
Usage:
  notes.sh [PARAMS] ...

notes parameters are:
  -h | --help                   : This help text
  -p | --plain                  : Output is in plain text
                                  (without this option the output is formatted)
                                  (this option must precede all others)
  -l | --list                   : List existing notes
  -a | --add=["<title>"]        : Add new note
  -e | --edit=[<note>]          : Edit note
  -d | --delete=[<note> | all]  : Delete single note or all notes at once
  -s | --show=[<note>]          : Display note using your favourite PAGER
  -r | --restore=[<dir>]        : Restore a previous backup from dir
  -v | --version                : Print version
  --userconf                    : Export User config file
  --backup [<dest>]             : Backup your data in your destination folder

if a non option is passed and is a valid note ID, the note will be displayed.
```

All the basic functionalities are present and working, it probably needs some polishing and some testing, so if you want to give it a try, let me know what you think.

### Settings

When you first run it, notes.sh will create all the files it needs to operate.
By default the directory will be populated in `~/.local/share/bash-notes`.

If you want to modify the predefined settings, you can export a user configuration file by running

```bash
notes.sh --userconf
```

And you'll have all your settings in `~/.config/bash-notes.rc`. This file will be sourced every time you run the script.

You can change all these settings by editing the file:

```bash
# Binaries to use
JQ=${JQ:-/usr/bin/jq}
EDITOR=${EDITOR:-/usr/bin/vim}
TERMINAL=${TERMINAL:-/usr/bin/alacritty}
# add options for your terminal. Remember to add the last option to execute
# your editor program, otherwise the script will fail.
# see example in the addnote function
TERM_OPTS="--class notes --title notes -e "
# Setting PAGER here overrides whatever is set in your default shell
# comment this option to use your default pager if set in your shell.
PAGER=${PAGER:-/usr/bin/more}

# set this to true to have output in plain text
# or use the -p option on the command line before every other option
PLAIN=false
# base directory for program files
BASEDIR=${BASEDIR:-~/.local/share/bash-notes}
# notes database in json format
DB=${BASEDIR}/db.json
# directory containing the actual notes
NOTESDIR=${BASEDIR}/notes
```

Most are pretty self explanatory, the only one that might need clarification is `TERM_OPTS` which is used to set the terminal window that will run the editor while writing the note.

Special attention is needed when specifying the options, in my case, using [alacritty](https://github.com/alacritty/alacritty), the option that allows to run some software in the newly created window is `-e`, so I need to specify this as the last option.

### Functionalities

bash-notes can:

 * write a new note `--add="Your note title"` or in short `-a"Your note title"`

 * modify an existing note `--edit=[note ID]`, short version `-e[note ID]`

 * delete a note `--delete=[note ID]`, or `-d[note ID]`

 * delete all notes `--delete=all`, or `-dall`

 * list existing notes `--list` or `-l` in short

 * display a note `--show=[note ID]`, or `-s[note ID]`.

   It's also possible to simply pass [note ID] as an argument to the script and the corresponding note will be displayed.

   ```bash
   notes.sh 1
   ```

The *note id* is assigned when the note is created, and that's how you refer to the note in the program.

##### Plain listing vs "colorful"

The `--plain` or `-p` option in short, dictates how the output from the script is formatted, here's a sample listing of all the notes:

```bash
notes.sh -l
listing all notes

[ID]    [TITLE]         [CREATED]
[1]     ciao nota       25/03/2023 18:53 +0100CET
[2]     hello there     25/03/2023 19:02 +0100CET
```

And here's the same listing with the plain option:

```bash
notes.sh -pl
1 - ciao nota - 25/03/2023 18:53 +0100CET
2 - hello there - 25/03/2023 19:02 +0100CET
```

It's just a proof of concept at the moment, but the idea is to use a more interesting output maybe using markup, and strip it down in plain mode. After all is still a work in progress.
The plain option must precede all other options or it won't work. I'll try and fix this behavior in the future.

I'd love to implement some kind of searching functionality, but I'll have to look into that.

##### Backups

Since version 0.3, this script can also handle backups of all your notes, you can specify a backup folder with

```bash
notes.sh --backup=/some/dir
```

and the script will create the directory if it doesn't exists and backup all your data, including the rc file if you made one.

If you want to restore a backup you can do so with

```bash
notes.sh --restore=/some/dir
```

And the script will take care of putting everything back where it belongs. 

> ##### A bit of a warning on restoring backups
>
> *Keep in mind that all your existing notes will be overwritten in the process.*

### Installing

Simply copy the script in your $PATH and make it executable, something like this should work:

```bash
mv notes.sh ~/bin/
chmod 755 ~/bin/notes.sh
```

Adapt to your needs as you see fit.

The first time you run the script it will take care of creating all the files and folders it needs in the standard directories.

### Debugging

If the script doesn't work for you for some reasons, you can turn on debugging by running the script like this:

```bash
DEBUG=true notes.sh [options]
```

And then you'll be able to check all that happened in the log file at `/tmp/debug_bash-notes.log`

### Vision

Ok, maybe vision is a bit of a stretch, but I've written this script to use it in my daily workflow with [rofi](https://github.com/davatorium/rofi) and [i3wm](https://github.com/i3/i3). I'll adapt the way it works to better suit this need of mine.

There are of course things I'd love to add, but my main goal is for it to work the way I planned to use it.

### TO DO

* add a way to search the notes
* ~~add a way to display a note without running vim~~ *(done in version 0.3)*
* markdown support?
   * maybe implement an export feature that builds the html or pdf file from the note
     (pandoc??)
* write a bash completion script to enable autocomplete in the shell
* other ideas may come [...]

### Contributing

It'd mean so much to receive some feedback, patches if you feel like contributing, I'm not expecting much as this is a personal project, but feel free to interact as much as you want.

### ChangeLog

 * v0.3 - backups management. Some UX improvements
     * create and restore backups of all your notes and settings.
     * display notes using predefined PAGER variable or define your own program to use. 

 * v0.2 - debugging implemented
     - you can now generate a debug log in case something doesn't work
 * v0.1 - first public upload
     - all major functionalities are present and working

### Mantainer

 * [danix](https://danix.xyz) - it's just me, really...

### LICENSE

> bash-notes © 2023 by danix is licensed under CC BY-NC 4.0. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/