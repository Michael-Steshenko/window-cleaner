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
Just google install instructions

### Windows Terminal
A wrapper for all the CLI that you need in Windows
https://docs.microsoft.com/en-us/windows/terminal/get-started

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
