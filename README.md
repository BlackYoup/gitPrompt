## Git Prompt

A set of functions to display a personalized prompt for GIT on Linux.

Here is what it can display:

+ Current Branch ``(branchName)``
+ Number of unpushed (↑) or unpulled (↓) commits ``↑2↓1``
+ If current branch is durty ``*``
+ If current branch have "ready to commit" files ``+``
+ If current branch have stashed changes ``~``

![image of git promp](http://i.gyazo.com/debaab4c53bc834bb146b73fa8f162d0.png)

## Installation

You have to load the script file by putting the following line in your ``~/.bashrc``

``
    source ~/path/to/file/gitPrompt.sh
``

## Configuration

### Colors

These can be customized too, just change them in the $PS1 exported variable. You can visit [this site](http://www.tux-planet.fr/les-codes-de-couleurs-en-bash/) for a list of available shell colors. (Couldn't find an english site with color examples)

### Git fetch

This command is used once per hour to get changes from the distant repository. You can change this by setting the ``refreshGitFetch`` variable to another value (in seconds)

### Origin

By default, functions will use ``origin`` for the distant repository name. You can configure ``distantRepoName`` if you want to use something else

## How it works

These functions use the git commands output and parse them to extract values. It rely on ``/tmp/gitPrompt.save`` which save the timestamp when it fetch the origin.

It uses the ``git log origin/branch..branch`` or ``git log branch..origin/branch`` to check ahead or behinds commits. (origin or whatever the value you setted). See [#Origin](#Origin)

To detect awaiting commits when there is no remote branch (local branch), it compares master to current branch's HEAD ``(git log master..HEAD)``

## TODO
+ Fix errors which appears randomly
