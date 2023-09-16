# Dotfiles
> A Windows setup scripts to setup a perfect Windows 11 installation from scratch

## Why
I reset my Windows machine pretty often and I was tired of doing everything in here manually every time, that's why I decided to create a script to do all of this for me.

## Installation
To setup a fresh Windows 11 installation, clone or download/extract the repository and open a Powershell as Administrator in the root folder.

If needed, enable the bypass execution policy for the process by using
```
Set-ExecutionPolicy -Scope Process Bypass
```

Finally to run the main script using default settings just do
```
.\setup.ps1
```
However, you can add options to alter the installation
Here is the list of flags and what they do:
| Flag                 | Explanation                                            |
|----------------------|--------------------------------------------------------|
| `-KeepOneDrive`      | Will not uninstall OneDrive                            |
| `-GitConfig`         | Copies the .gitconfig file from the root folder        |
| `-SSHFolder`         | Copies the folder given as argument as the .ssh folder |
| `-GPGKey`            | Installs the key given as argument to gpg              |
| `-FirefoxExtensions` | Installs extensions in the script to Firefox           |
| `-VSCode`            | Installs VSCode, extensions and settings               |
| `-WSL`               | Installs WSL (Windows Subsystem for Linux)             |

And let the magic happen (Click yes on admin prompts when needed)
