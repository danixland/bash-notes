# bash notes

### a simple note taking app written in bash

I've found myself in need of a simple way to take notes, and since the other solutions available didn't meet my needs, I've decided to write my own app.

It's a simple (enough) bash script, the only dependance (yet) is [jq](https://stedolan.github.io/jq/).

here's all the functions that I'm planning to implement:

```bash
-h | --help			: This help text
-p | --plain			: Output is in plain text (without this option the output is colored)
-l | --list			: List existing notes
-a | --add <title>		: Add new note
-m | --modify <note> 		: Modify note
-d | --date <note> 		: Modify date for note
-r | --remove <note>		: Remove note
-v | --version			: Print version
--userconf			: Export User config file
```

not all functionalities are present at the moment