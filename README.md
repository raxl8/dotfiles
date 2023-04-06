# Dotfiles
> My (for now) Windows setup scripts to setup a perfect Windows 11 installation from scratch

## Why
I reset my Windows machine pretty often and I was tired of doing everything in here manually every time, that's why I decided to create a script to do all of this for me.

## Installation
To setup a fresh Windows 11 installation, fire up PowerShell in any directory.
Then clone this repo using
```
git clone https://github.com/raxl8/dotfiles
cd dotfiles/
```
Copy your GPG key if you have one to the `User` folder. (If you are not me, you will need to modify the key in `User/.gitconfig` accordingly)

Same goes for your ssh keys, copy them to the `User/.ssh` folder.

Finally run the main script using
```
Set-ExecutionPolicy Bypass -Scope Process
.\setup.ps1
```
And let the magic happen (Click yes on admin prompts when needed)
