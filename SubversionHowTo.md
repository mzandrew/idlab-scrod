# basic usage #

### adding files ###
To add a file to the repository, type the following:
```
svn add src/my_new_file.vhdl
```
Then make sure it hasn't added anything crazy (like a bunch of unwanted output files) with:
```
svn status
```
Which should output a line that's:
```
A src/my_new_file.vhdl
```
among a bunch of
```
? blah1
? blah2
```
lines that indicate you haven't told it what to do with those other files yet (which is fine).

### committing files (the most common command) ###
Once you're happy with the content of a file you want to put in the repository (whether you've committed that file before or not), commit the change with the following:
```
svn commit -m "initial add of some vhdl that counts pulses coming out of the zargblaster ASIC"
```
with whatever comment text you like (-m is for comment), even if it's an empty string.  It might ask you for your googlecode.com password at this point if you haven't entered it before.  Note that you must perform the "svn add" command on that file before it will allow you to commit it.

### trunk checkout ###
If you want to checkout the latest and greatest copy of the code (the so-called "trunk" version), this is the command to use:
```
svn checkout https://idlab-scrod.googlecode.com/svn/iTOP-BLAB3A-boardstack/trunk/ idlab-scrod --username username@gmail.com
```
replacing the given username with your own.  More instructions are at http://code.google.com/p/idlab-scrod/source/checkout (including how to get your google code password, which only seems necessary once and only when you first try to commit something to the repository).

# advanced usage #

### exporting ###
If you just want a copy of the files to zip up and put on the blog or email to someone, this is the way to do it:
```
svn export https://idlab-scrod.googlecode.com/svn/iTOP-BLAB3A-boardstack/trunk/ idlab-scrod
```
Which will make a dir in the current dir called "idlab-scrod" or whatever you put at the end there and then you can do what you like with it (with the benefit being you don't have to post/transfer 70MB zip files anymore).

### trunk on the web ###
You can see the latest version of the code that's in the repository here on the web with a cutsie interface:
http://code.google.com/p/idlab-scrod/source/browse/iTOP-BLAB3A-boardstack/trunk
There are links at the top to get elsewhere in the repository (like other subprojects or the wiki files).

### branches ###
To be distinguished from the "trunk" version are "branches."  These are for allowing experimental or partially working code to be committed without disturbing the other users of the repository.  Examples would be the "USB tester" version that User#1 made, the "blinkenlights" version that User#2 made or the "16x ASICs" version that User#3 made.  After those versions compile and nominally work or the test / side-project is completed, the code from those branches can be "merged" with the main "trunk" line of development if desired.

### whole repository checkout ###
To get the whole repository (including the wiki, the trunk, all branches and tags), give this command:
```
svn checkout https://idlab-scrod.googlecode.com/svn/ idlab-scrod --username username@gmail.com
```
replacing "username" with your own google username.  Note that this is just the regular "trunk" checkout command, but with a slightly shorter URL because it's a parent of a parent directory.

### "downloads" on the web ###
I uploaded useful bit files that have been generated for this project into the "downloads" section of the website:
http://code.google.com/p/idlab-scrod/downloads/list
so that they don't clutter up the repository.

### ignoring files ###
For the files that don't belong in the repository that show up with an annoying "? filename" anytime you do a svn commit or svn status command, you can tell it to ignore them in the future with the following command:
```
svn propset svn:ignore "*" ise-project/
```
Which ignore all files not specifically added to the repository in that directory (it acts recursively).
To add specific files/directories, they must be listed one file or filespec per line (on the command-line, do this with ctrl-enter):
```
svn propset svn:ignore "work
bin
mypackets
logdir
" .
```

### copying files ###
To resurrect a "dead" file from an earlier version of the repository, do the following:
```
svn copy -r 344 boardstack-v2-with-SCROD-revA2.ucf .
```
It can also be from a different location in the current revision of the repo.

### making a tag ###
To make a reference to a useful previous state of the repository (called a "tag"), use the svn copy function:
```
svn mkdir tags
cd tags
svn mkdir r282.iTOP-module-used-at-LEPS-SPRING8/
cd r282.iTOP-module-used-at-LEPS-SPRING8/
svn copy -r 282 ../../board-stack/ ../../common-components/ .
```

### changing permissions ###
To remove the executable permission from a file in the repository, do this:
```
svn propdel svn:executable src/read_CAMAC.c 
```

To set the executable permission on a script that you want to run, do this:
```
svn propset svn:executable yes irs3b-dac-defaults-2714.py
```

### reintegrating a branch into the trunk ###

Once you have something you like in a branch of the svn, you can reintegrate it into the trunk as follows:
  1. First do a dry run to make sure that it's going to do what you expect:
```
svn merge --reintegrate --dry-run https://idlab-scrod.googlecode.com/svn/iTOP-BLAB3A-boardstack/branches/one-shot-4windows
```
  1. Then do the reintegration on your local machine:
```
svn merge --reintegrate https://idlab-scrod.googlecode.com/svn/iTOP-BLAB3A-boardstack/branches/one-shot-4windows
```
  1. Then commit it with the usual command:
```
svn commit -m "Changed the trunk to reflect the current \"best\" version."
```
  1. Assuming that's all been successful, you can delete the branch you were working on:
```
svn delete https://idlab-scrod.googlecode.com/svn/iTOP-BLAB3A-boardstack/branches/one-shot-4windows -m "Deleted one-shot 4 windows version since it has been merged into trunk."
```