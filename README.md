# window-cleaner
A place for me to keep a set of tools, configurations and installation instructions for tools that I use for Windows development

## Tools

### Scoop
Scoop is a windows command line package manager, for installation refer: https://scoop.sh

### Neo Vim
`scoop install nvim`

### MinGit
Git CSM automatically installs git bash and git GUI, which I don't need, instead I use Scoop package manager to install MinGit:  
`scoop install mingit`  
now we can use the git command from command prompt and powershell.

### WSL 2
Windows subsystem for linux  
Just google install instructions

### Windows Terminal
A wrapper for all the CLI that you need in Windows  
https://docs.microsoft.com/en-us/windows/terminal/get-started

### PowerToys
Microsoft PowerToys is a set of utilities for power users to tune and streamline their Windows 10 experience for greater productivity.
I use this for remapping keyboard shortcuts that windows does not let me remap or disable and for FancyZones - a windows window layout manager.
The [config](./powertoys_config.ptb) file is in the repository: 
Check my [test document](./abc/test.md)!

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
- Launch your wsl instance.
- $ sudo vim ~/.bashrc
- Enter your password.
- Press i to go into edit mode. Go to the end of the file using arrow key.
- Add your variable as API_KEY=123 at the end of the file. If your variable has spaces, use quotes.Example - API_KEY= 'My Key'
- Press esc key to get out of edit mode.
- Enter :wq and press enter . This will save and close the file.
- $ source ~/.bashrc will load your recent changes into your current shell.

### Better PowerShell autocomplete command history
Tested with PS7, this configuration is for [all powershell users for all hosts](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.4#profile-types-and-locations)
- `nvim $PSHOME\Profile.ps1`
- add this line: `Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView`
- restart powershell

### Disabling windows magnifier
I was unable to disable the win + "+" and win + "-" shortcuts (Windows 11 Enterprise OS build: 22000.675), even when the shortcut was disabled in windows settings it would get re-enabled when the shorcut was pressed and would open magnifier, but we can disable magnifier itself:
- run Command Prompt (Admin)
- Run the following commands to change the ownership of the Magnify.exe app and grant full permissions to Administrators and rename it. Without these steps you’re unable to rename or make any change to the Magnify.exe file.
- `takeown /f C:\Windows\System32\Magnify.exe`  
- `cacls C:\Windows\System32\Magnify.exe /G administrators:F`  
- `mv C:\Windows\System32\Magnify.exe C:\Windows\System32\Magnify.exe.bak`
