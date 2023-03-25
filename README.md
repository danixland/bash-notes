# bash notes

## a simple note taking script written in bash

I've found myself in need of a simple way to take notes, and since the other solutions available didn't meet my needs, I've decided to write my own script.

It's a simple (enough) bash script, the only dependance (yet) is [jq](https://stedolan.github.io/jq/).

here's all the functions that are now available:

```bash
-h | --help			: This help text
-p | --plain			: Output is in plain text (without this option the output is colored)
-l | --list			: List existing notes
-a | --add "<title>"		: Add new note
-m | --modify <note> 		: Modify note
-d | --delete [<note> | all]	: Delete note
-v | --version			: Print version
--userconf			: Export User config file
```

All the basic functionalities are present and working, it probably needs some polishing and some testing, so if you want to give it a try, let me know what you think.

### Settings

When you first run it, notes.sh will create all the files it needs to operate.
By default the directory will be populated in `~/.local/share/bash-notes`.

If you want to modify the predefined settings, you can export a user configuration file by running

```notes.sh --userconf```

And you'll have all your settings in `~/.config/bash-notes.rc`. This file will be sourced everytime you run the script.

You can change all these settings:

```Bash
# Binaries to use
JQ=/usr/bin/jq
EDITOR=/usr/bin/vim
TERMINAL=/usr/bin/alacritty
# add options for your terminal. Remember to add the last option to execute
# your editor program, otherwise the script will fail.
# see example in the addnote function
TERM_OPTS="--class notes --title notes -e "

# base directory for program files
BASEDIR=~/.local/share/bash-notes
# notes database in json format
DB=${BASEDIR}/db.json
# directory containing the actual notes
NOTESDIR=${BASEDIR}/notes
```

Most are pretty self explanatory, the only one that might need clarification is `TERM_OPTS` which is used to set the terminal window that will run the editor while writing the note.

Special attention is needed when specifying the options, in my case, using [alacritty](https://github.com/alacritty/alacritty), the option that allows to run some software in the newly created window is `-e`, so I need to specify this as the last option.

### Functionalities

bash-notes can:
 * write a new note `--add "Your note title"` or in short `-a "Your note title"`
 * modify an existing note `--edit [note ID]`, short version `-e [note ID]`
 * delete a note `--delete [note ID]`, or `-d [note ID]`
 * delete all notes `--delete all`, or `-d all`
 * list existing notes `--list` or `-l` in short

The *note id* is assigned when the note is created, and that's how you refer to the note in the program.

The `--plain` or `-p` option in short, dictates how the output from the script is formatted, here's a sample listing of all the notes:

```
notes.sh -l
listing all notes

[ID]    [TITLE]         [CREATED]
[1]     ciao nota       25/03/2023 18:53 +0100CET
[2]     hello there     25/03/2023 19:02 +0100CET
```

And here's the same listing with the plain option:

```
notes.sh -pl
1 - ciao nota - 25/03/2023 18:53 +0100CET
2 - hello there - 25/03/2023 19:02 +0100CET
```

It's just a proof of concept at the moment, but the idea is to use a more interesting output maybe using markup, and strip it down in plain mode. After all is still a work in progress.
The plain option must precede all other options or it won't work. I'll try and fix this behaviour in the future.

I'd love to implement some kind of searching functionality, but I'll have to look into that.

### Installing

Simply copy the script in your $PATH and make it executable, something like this should work:

```
mv notes.sh ~/bin/
chmod 755 ~/bin/notes.sh
```

Adapt to your needs as you see fit.

### Vision

Ok, maybe vision is a bit of a stretch, but I've written this script to use it in my daily workflow with [rofi](https://github.com/davatorium/rofi) and [i3wm](https://github.com/i3/i3). I'll adapt the way it works to better suit this need of mine.

There are of course things I'd love to add, but my main goal is for it to work the way I planned to use it.

### TO DO

 * add a way to search the notes
 * add a way to display a note without running vim
 * markdown?
 	- maybe implement an export feature that builds the html file from the note
 * write a bash completion script to enable autocomplete in the shell
 * other ideas may come [...]

### Contributing

It'd mean so much to receive some feedback, patches if you feel like contributing, I'm not expecting much as this is a personal project, but feel free to interact as much as you want.

### Mantainer

 * [danix](https://danix.xyz) - it's just me, really...
 
### LICENSE

> bash-notes © 2023 by danix is licensed under CC BY-NC 4.0. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/