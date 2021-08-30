# window-cleaner
A place for me to keep a set of tools, configurations and installation instructions for tools that I use for Windows development

## Tools

### Scoop
Scoop is a windows command line package manager, for installation refer: https://scoop.sh/

### MinGit
Git CSM automatically installs git bash and git GUI, which I don't need, instead I use Scoop package manager to install MinGit:  
```scoop install mingit```  
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

### AutoHotKey
Automation scripting language for Windows.  
I use it to create custom windows keyboard shorcuts, for example, I use a shortcut to access the Bluetooth devices settings page to quickly switch between bluetooth audio output devices.   
See Bluetooth-Devices.ahk in this repository. (Tested on Windows 11 Preview)

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

### Disabling windows magnifier
I was unable to disable the win + "+" and win + "-" shortcuts (Windows 11 Preview), even when the shortcut was disabled in windows settings it would get re-enabled when the shorcut was pressed and would open magnifier, but we can disable magnifier itself:
- run Command Prompt (Admin)
- Run the following two commands to change the ownership of the Magnify.exe app and grant full permissions to Administrators. Without this step you’re unable to rename or make any change to the Magnify.exe file.  
```takeown /f C:\Windows\System32\Magnify.exe```  
```cacls C:\Windows\System32\Magnify.exe /G administrators:F```  
- Open your File Explorer and go to your system directory: C:\Windows\System32. locate the Magnify.exe file. Right-click on it and rename the filename to Magnify.exe.bak.

###
