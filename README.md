# window-cleaner

A place for me to keep a set of tools, configurations and installation instructions for tools that I use for development on Windows

## Tools

### WinGet

Using as my default package manager

### WSL

Install Arch btw.  
Ubuntu is annoying and has old packages.

Recommended, set up things in arch in the following order:

- Install sudo
- Install nvim
- create a non-root user with a password and set it as default user

### Neovim

We can symlink the config files from WSL Neovim to Windows Neovim, this seems to be a cleaner solution then invoking WSL neovim in Windows, but I haven't had the chance to use it much yet.

#### VSCode Neovim extension

Use the WSL version of Neovim for this, Neovim seems to work better on Linux, see WSL section for installing WSL + WSL Neovim.

### MinGit

Git CSM automatically installs git bash and git GUI, which I don't need, instead I use Scoop package manager to install MinGit:  
`winget install Git.MinGit`  
if you need git-lfs: `winget install GitHub.GitLFS`  
now we can use the git command from command prompt and powershell.
To be able to authenticate via the browser we can set git credential manager:  
`git config --global credential.helper manager`

### VSCode WSL extension

This lets you run VS Code’s UI on Windows, and all your commands, extensions, and even the terminal, run on Linux.

- Install the WSL extension in VS code.
- Configure the WSL version of git, to use the windows version of git credential manager.  
   (this allows you to sign in through the browsers and remembers your credentials)  
   If you use mingit the command will look something like this:  
   `git config --global credential.helper "/mnt/c/Users/Michael/scoop/apps/mingit/2.37.3.windows.1/mingw64/bin/git-credential-manager-core.exe"`  
   taken from [here](https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/wsl.md#configuring-wsl-with-git-for-windows-recommended)

### Windows Terminal

https://docs.microsoft.com/en-us/windows/terminal/get-started

### PowerToys

Microsoft PowerToys is a set of utilities for power users to tune and streamline their Windows 10 experience for greater productivity.  
I use this for remapping keyboard shortcuts that windows does not let me remap or disable and for FancyZones - a windows window layout manager.  
The [config](./settings_133565335181531224.ptb) file is in the repository.

### AutoHotKey

Automation scripting language for Windows. https://www.autohotkey.com  
I use it to create custom windows keyboard shorcuts, for example, I use a shortcut to access the Bluetooth devices settings page to quickly switch between bluetooth audio output devices.  
See Bluetooth-Devices.ahk in this repository. (Tested on Windows 11 Preview, need to update behavior for non preview builds)  
To make AHK scrips or any other file launch on Windows startup for all users:

- Press Win+R to open the Run dialog and type `shell:common startup` this will open a folder from which programs are launched at startup
- place the AHK script or shortcut to the AHK script in that folder

`move_to_diff_VD.ahk` allows moving windows to adjecent virtual desktops via keyboard shortcuts, but it has to import `_VD.ahk`.  
Importing a file that's located in `shell:common startup` doesn't work.  
If you want this script to run on startup you need to:

- place `move_to_diff_VD.ahk` in `shell:common startup` like described before.
- place `_VD.ahk` in some other folder for example `C:\Users\<my user>\Documents`
- change import path inside `move_to_diff_VD.ahk` to be `C:\Users\<my user>\Documents\_VD.ahk`

## Configurations

### Setting up enviorment variables in WSL

- $ sudo nvim ~/.bashrc
- Add your variable as API_KEY=123 at the end of the file. If your variable has spaces, use quotes.Example - API_KEY= 'My Key'
- $ source ~/.bashrc will load your recent changes into your current shell.

### Better PowerShell autocomplete command history

Tested with PS7, this configuration is for [all powershell users for all hosts](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.4#profile-types-and-locations)

- `nvim $PSHOME\Profile.ps1`
- add this line: `Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView`
- restart powershell

### Disable Microsoft "log in to online MS account" orange dot notification in start menu

- open gpedit.msc
- go to `Computer Configuration\Windows Settings\Security Settings\Local Policies\Security Options`
- Set `Accounts: Block Microsoft accounts` to `Users can't add or log on with Microsoft accounts`

### Disable windows magnifier

I was unable to disable the win + "+" and win + "-" shortcuts (Windows 11 Enterprise OS build: 22000.675), even when the shortcut was disabled in windows settings it would get re-enabled when the shorcut was pressed and would open magnifier, but we can disable magnifier itself:

- run Command Prompt (Admin)
- Run the following commands to change the ownership of the Magnify.exe app and grant full permissions to Administrators and rename it. Without these steps you’re unable to rename or make any change to the Magnify.exe file.
- `takeown /f C:\Windows\System32\Magnify.exe`
- `cacls C:\Windows\System32\Magnify.exe /G administrators:F`
- `mv C:\Windows\System32\Magnify.exe C:\Windows\System32\Magnify.exe.bak`

### Disable searching in the temp folder of Visual Stuido

- Press CTRL + SHIFT + F to open the search window
- Under file types add the following line to the end of the string: `!*\AppData\Local\Temp\TFSTemp\*`
- Notice that the values in the string are semi-colon seperated.

### TODO

- When using hyper key to switch to an app that is open on another virtual desktop, it should switch to the virtual desktop that has the app open and switch to that app instead of trying to launch it again. In apps like discord this results in a failed to launch error.
