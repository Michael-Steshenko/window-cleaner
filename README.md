# window-cleaner

Configurations and installation instructions for tools that I use for development on Windows

## Tools

### WinGet

Using as my default package manager

On a system with no Microsoft store:

- Install MS Store via `ms reset -i`, app installer should be available in a few minutes.
- Install `App Installer` from MS Store from `ms-windows-store://pdp/?productId=9nblggh4nns1`, this is needed to run `msixbundle` packages and also includes the `Winget` package manager.

### WSL

Install Arch btw.  
Ubuntu is annoying and has old packages.

Recommended, set up things in arch in the following order:

- Install sudo and neovim: `pacman -Syu sudo neovim`
- create a non-root user with a password and set it as default user:
  - Create the default user:

  ```
  # Create the user with a home directory (-m), bash shell (-s), and add to the wheel group (-G)
  useradd -m -G wheel -s /bin/bash michael

  # Set the password for the new user
  passwd michael
  ```

  - Add this to your `~/.bashrc`:

  ```bash
  # set default editor
  export EDITOR=nvim
  export VISUAL=nvim

  # Report current working directory to terminal via OSC 7 (for WezTerm path detection)
  __vte_osc7() {
      printf '\e]7;file://%s%s\e\\' "$HOSTNAME" "$PWD"
  }
  PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }__vte_osc7"
  ```

  - Run `visudo` and uncomment: `%wheel ALL=(ALL:ALL) ALL`
  - `nvim /etc/wsl.conf` and add the following:

  ```
  [user]
  default=michael
  ```

  - in `PS` run `wsl --shutdown`

### Neovim

We can symlink the config files from WSL Neovim to Windows Neovim, this seems to be a cleaner solution then invoking WSL neovim in Windows, but I haven't had the chance to use it much yet.  
To install: `winget install Neovim.Neovim`

#### VSCode Neovim extension

Use the WSL version of Neovim for this, Neovim seems to work better on Linux, see WSL section for installing WSL + WSL Neovim.

#### VS VIM extension

There is no embedded Neovim for VS, we use a VIM emulator instead.

- Install the `VSVim` extension from the `VS` `Extenstion Manager`
- Sync VSVim and system clipboards:
  - edit or create `C:\Users\Michael\_vsvimrc`
  - add the following: `set clipboard=unnamed`
  - restart VS

### MinGit

Git CSM automatically installs git bash and git GUI, which I don't need, instead I use Winget to install MinGit:  
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
   `git config --global credential.helper "/mnt/c/Users/Michael/AppData/Local/Microsoft/WinGet/Packages/Git.MinGit_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/git-credential-manager.exe"`  
  taken from [here](https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/wsl.md#configuring-wsl-with-git-for-windows-recommended)

### WezTerm

- Install: `winget install wez.wezterm`
- The configuration file [`.wezterm.lua`](./.wezterm.lua) is in this repository and symlinked to `~/.wezterm.lua` via `install.cmd`.
- Key features configured:
  - Unified title bar: tabs and Windows-style minimize/maximize/close buttons on a single top bar. (as of 17Oct26 the buttons are non resizable so they don't exactly match the title bar)
  - Preconfigured profiles: PowerShell 7, Command Prompt, and Arch Linux (WSL).
  - `Ctrl + N` / `Ctrl + T`: Opens a new window or tab inheriting both the active environment (WSL / PWSH / CMD) and the current working directory.
  - Smart `Ctrl + C`: Copies when text is selected, sends interrupt (`^C`) when nothing is selected; `Ctrl + V` pastes.
  - Automatic directory tracking: Remembers the last visited directory across restarts without third-party plugins.
  - Fast tab closing: Window and tab close confirmation modals are disabled.
  - Custom Campbell palette and Cascadia font matching Windows Terminal.
  - Dynamic scroll position indicator: Thin (6px) scrollbar automatically shown only when offscreen scrollback exists (hidden on full-screen / no history).
  - Custom tab names `PowerShell`, `CMD`, `Arch` and matching tab icons.

### Powershell 7

- Install: `winget install Microsoft.Powershell`
- The profile configuration [`Microsoft.PowerShell_profile.ps1`](./Microsoft.PowerShell_profile.ps1) is stored in this repository and symlinked to `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` via `install.cmd`.
- Profile features:
  - Better command history autocomplete (`Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView`).
  - Terminal OSC 7 working directory reporting for WezTerm path detection.
  - `agy` alias that always passes `--remote-control` flag.

### PowerToys

`winget install Microsoft.Powertoys`  
Microsoft PowerToys is a set of utilities for power users to tune and streamline their Windows 10 experience for greater productivity.  
I use this for remapping keyboard shortcuts that windows does not let me remap or disable and for FancyZones - a windows window layout manager.  
The [config](./settings_134126987218497327.ptb) file is in the repository.

### AutoHotKey

Automation scripting language for Windows. https://www.autohotkey.com  
I use it to create custom windows keyboard shorcuts.
See `keyboard-manager.ahk` in this repository.

We want out autohotkey script to be able to capture keyboard inputs even when an elevated window is in focus.
There are 2 ways to achieve this, either run the autohotkey script as admin, or enable `UI access`, I prefer to enable `UI access`, this requires installing `AutoHotkey` for all users the install command below takes care of that, which allows the script to enable `UI access` for itself automatically:

- `winget install AutoHotkey.AutoHotkey --scope machine`

To install the script to run on startup run the `install.cmd` script or manually:

- Press Win+R to open the Run dialog and type `shell:common startup` this will open a folder from which programs are launched at startup.
- Place the AHK script or shortcut to the AHK script in that folder.

> **Note:** `keyboard-manager.ahk` relies on PowerToys remapping CapsLock to F18.

### Visual Studio

`winget install Microsoft.VisualStudio.Community`

#### Disable searching in the temp folder of Visual Stuido

- Press CTRL + SHIFT + F to open the search window
- Under file types add the following line to the end of the string: `!*\AppData\Local\Temp\TFSTemp\*`
- Notice that the values in the string are semi-colon seperated.

### CLI tools for AI agents

My working theory is that AI agnets prefer Unix tools, and not all the tools are available on winget, so we use scoop.

- install [scoop](https://scoop.sh/)
- `scoop install findutils uutils-coreutils sed gawk grep ripgrep`

### Antigravity CLI (`agy`)

Custom status line script [`agyStatusline.py`](./agyStatusline.py) (folder, branch, context %, quotas).

- **Windows**: Run `install.cmd` to symlink to `~/.gemini/antigravity-cli/agyStatusline.py`, and set in `settings.json`:
  ```json
  "statusLine": {
    "type": "command",
    "command": "python -S -u C:/Users/Michael/.gemini/antigravity-cli/agyStatusline.py",
    "stack_with_default": true
  }
  ```
- **WSL**: Symlink to the Windows repo:
  ```bash
  ln -sf /mnt/c/Users/Michael/projects/window-cleaner/agyStatusline.py ~/.gemini/antigravity-cli/agyStatusline.py
  ```
  and set `"command": "python3 -S -u ~/.gemini/antigravity-cli/agyStatusline.py"` in WSL's `settings.json`.

## Configurations

### Setting up enviorment variables in WSL

- `sudo nvim ~/.bashrc`
- Add your variable as `API_KEY=123` at the end of the file. If your variable has spaces, use quotes.Example - `API_KEY= 'My Key'`

### Disable Microsoft "log in to online MS account" orange dot notification in start menu

- open gpedit.msc
- go to `Computer Configuration\Windows Settings\Security Settings\Local Policies\Security Options`
- Set `Accounts: Block Microsoft accounts` to `Users can't add or log on with Microsoft accounts`

### Disable windows magnifier

I was unable to disable the win + "+" and win + "-" shortcuts (Windows 11 Enterprise OS build: 2200winget install Microsoft.VisualStudio.Community
0.675), even when the shortcut was disabled in windows settings it would get re-enabled when the shorcut was pressed and would open magnifier, but we can disable magnifier itself:

- run PowerShell (Admin)
- Run the following commands to change the ownership of the Magnify.exe app and grant full permissions to Administrators and rename it. Without these steps you’re unable to rename or make any change to the Magnify.exe file.
- `takeown /f C:\Windows\System32\Magnify.exe`
- `cacls C:\Windows\System32\Magnify.exe /G administrators:F`
- `mv C:\Windows\System32\Magnify.exe C:\Windows\System32\Magnify.exe.bak`

### TODO

- Remove WezTerm debug logging once we're done investigating a crash: closing one WezTerm PowerShell window froze `wezterm-gui.exe` (cross-process hang on `OpenConsole.exe`) and took down every window. To catch it, `WEZTERM_LOG=info,portable_pty=debug,mux=debug` was set as a user environment variable (`HKCU\Environment`, set via `[Environment]::SetEnvironmentVariable('WEZTERM_LOG', ..., 'User')`). Logs go to `~\.local\share\wezterm\wezterm-gui.exe-log-<pid>.txt`. Remove with `[Environment]::SetEnvironmentVariable('WEZTERM_LOG', $null, 'User')`.
