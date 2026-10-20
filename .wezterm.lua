-- WezTerm Configuration
local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

--------------------------------------------------------------------------------
-- 1. Window & Visual Settings
--------------------------------------------------------------------------------
-- Unified top bar: tabs and window buttons on the same line (like Windows Terminal)
config.window_decorations = 'INTEGRATED_BUTTONS | RESIZE'
config.integrated_title_button_style = 'Windows'
config.integrated_title_button_alignment = 'Right'
config.show_tab_index_in_tab_bar = false
config.use_fancy_tab_bar = true

-- Windows 11 Fluent frame styling (Tabbed backdrop & opacity)
config.win32_system_backdrop = 'Tabbed'
config.window_background_opacity = 0.95

-- font_size controls the overall height of the fancy title bar and tabs
-- Titlebar background uses the default color so it matches the unselected tab background
config.window_frame = {
  font_size = 12.0,
}

-- Disable confirmation popups when closing window or tabs
config.window_close_confirmation = 'NeverPrompt'
config.skip_close_confirmation_for_processes_named = {
  'bash',
  'sh',
  'zsh',
  'fish',
  'tmux',
  'nu',
  'cmd.exe',
  'pwsh.exe',
  'powershell.exe',
  'wsl.exe',
  'wslhost.exe',
}

-- Disable "Really kill this tab and all contained panes?" prompt
wezterm.on('mux-is-process-stateful', function(proc)
  return false
end)

-- Scroll position indicator (scrollbar)
-- Dynamically shown only when scrollback history exists (via update-status)
config.enable_scroll_bar = false
config.min_scroll_bar_height = '2cell'

-- Sleek window padding; right padding controls scrollbar width (thin indicator)
config.window_padding = {
  left = 4,
  right = '6px',
  top = 16,
  bottom = 0,
}

-- Windows Terminal exact colors (Campbell) and font (Cascadia Mono)
config.colors = {
  foreground = '#CCCCCC',
  background = '#0C0C0C',
  cursor_bg = '#FFFFFF',
  cursor_fg = '#0C0C0C',
  cursor_border = '#FFFFFF',
  selection_fg = '#FFFFFF',
  selection_bg = '#767676',
  scrollbar_thumb = '#666666',

  ansi = {
    '#0C0C0C', -- black
    '#C50F1F', -- red
    '#13A10E', -- green
    '#C19C00', -- yellow
    '#0037DA', -- blue
    '#881798', -- purple
    '#3A96DD', -- cyan
    '#CCCCCC', -- white
  },
  brights = {
    '#767676', -- brightBlack
    '#E74856', -- brightRed
    '#16C60C', -- brightGreen
    '#F9F1A5', -- brightYellow
    '#3B78FF', -- brightBlue
    '#B4009E', -- brightPurple
    '#61D6D6', -- brightCyan
    '#F2F2F2', -- brightWhite
  },
}

config.font = wezterm.font_with_fallback({
  'JetBrains Mono',
  'Cascadia Mono',
  'Segoe UI Emoji',
  'Segoe UI Symbol',
  'Consolas',
})
config.font_size = 12.0

--------------------------------------------------------------------------------
-- 2. Keyboard Protocol (Kitty protocol for agy Shift+Tab / Shift+Enter)
--------------------------------------------------------------------------------
config.enable_kitty_keyboard = true

--------------------------------------------------------------------------------
-- 3. Profiles: PowerShell, CMD, Arch Linux
--------------------------------------------------------------------------------
-- Default shell on startup
config.default_prog = { 'pwsh.exe', '-NoLogo' }

-- Launch Menu (shown when right-clicking the "+" button or pressing Ctrl+Shift+L)
config.launch_menu = {
  {
    label = 'PowerShell',
    args = { 'pwsh.exe', '-NoLogo' },
  },
  {
    label = 'CMD',
    args = { 'cmd.exe' },
  },
  {
    label = 'Arch',
    args = { 'wsl.exe', '-d', 'archlinux', '--cd', '~' },
  },
}

--------------------------------------------------------------------------------
-- 4. Remember Last Working Directory (Lightweight, No Plugins)
--------------------------------------------------------------------------------
local last_cwd_file = wezterm.home_dir .. '/.wezterm_last_cwd'

-- Read last CWD at startup
local function get_last_cwd()
  local f = io.open(last_cwd_file, 'r')
  if f then
    local path = f:read('*l')
    f:close()
    if path and #path > 0 then
      return path
    end
  end
  return nil
end

local last_cwd = get_last_cwd()
if last_cwd then
  config.default_cwd = last_cwd
end

-- 5. Profile Detection & Tab Titles (PowerShell, Arch, CMD)
--------------------------------------------------------------------------------
local function get_pane_profile(pane)
  if not pane then
    return 'PowerShell'
  end

  -- 1. Check WSL / domain name (e.g. WSL:archlinux)
  local domain = ''
  if type(pane.get_domain_name) == 'function' then
    pcall(function() domain = (pane:get_domain_name() or ''):lower() end)
  elseif type(pane.domain_name) == 'string' then
    domain = pane.domain_name:lower()
  end
  if domain:find('arch') or domain:find('wsl') then
    return 'Arch'
  end

  -- 2. Check process tree (walk up parents to find root shell: pwsh, cmd, wsl)
  -- On Windows, WezTerm returns the most recent descendant as foreground process.
  -- Walking up the parent process chain via ppid reliably finds the underlying shell even if an app (like agy.exe) is running.
  local proc_info = nil
  if type(pane.get_foreground_process_info) == 'function' then
    pcall(function() proc_info = pane:get_foreground_process_info() end)
  end
  local current = proc_info
  local depth = 0
  while current and depth < 10 do
    local exe = (current.executable or current.name or ''):lower()
    if exe:find('wsl') then
      return 'Arch'
    elseif exe:find('pwsh') or exe:find('powershell') then
      return 'PowerShell'
    elseif exe:find('cmd%.exe') or exe == 'cmd' then
      return 'CMD'
    end

    if current.ppid and current.ppid > 0 and wezterm.procinfo and wezterm.procinfo.get_info_for_pid then
      local parent = nil
      pcall(function()
        parent = wezterm.procinfo.get_info_for_pid(current.ppid)
      end)
      if parent and parent.pid ~= current.pid then
        current = parent
      else
        break
      end
    else
      break
    end
    depth = depth + 1
  end

  -- 3. Check foreground process name directly
  local proc_name = ''
  if type(pane.get_foreground_process_name) == 'function' then
    pcall(function() proc_name = (pane:get_foreground_process_name() or ''):lower() end)
  elseif type(pane.foreground_process_name) == 'string' then
    proc_name = pane.foreground_process_name:lower()
  end
  if proc_name:find('wsl') then
    return 'Arch'
  elseif proc_name:find('pwsh') or proc_name:find('powershell') then
    return 'PowerShell'
  elseif proc_name:find('cmd') then
    return 'CMD'
  end

  -- 4. Check CWD (Linux/WSL paths vs Windows paths)
  local cwd_uri = nil
  if type(pane.get_current_working_dir) == 'function' then
    pcall(function() cwd_uri = pane:get_current_working_dir() end)
  elseif pane.current_working_dir then
    cwd_uri = pane.current_working_dir
  end
  if cwd_uri then
    local host = cwd_uri.host or ''
    local path = cwd_uri.file_path or ''
    if (host ~= '' and host ~= 'localhost') or path:find('^/home') or (not path:find('^[A-Za-z]:') and not path:find('^/[A-Za-z]:')) then
      return 'Arch'
    end
  end

  -- 5. Check pane title heuristic (e.g. WSL prompt emits user@host:path)
  local title = ''
  if type(pane.get_title) == 'function' then
    pcall(function() title = pane:get_title() or '' end)
  elseif type(pane.title) == 'string' then
    title = pane.title
  end
  if title:find('^[^@]+@[^:]+:') then
    return 'Arch'
  end

  return 'PowerShell'
end

-- Save CWD whenever navigating to a new folder & toggle scrollbar dynamically
local cached_cwd = last_cwd
wezterm.on('update-status', function(window, pane)
  -- 1. Dynamic scrollbar: only show when there is offscreen scrollback and not in alt-screen (e.g. vim/agy)
  local dims = pane:get_dimensions()
  local has_scrollback = dims.scrollback_rows > dims.viewport_rows and not pane:is_alt_screen_active()
  local overrides = window:get_config_overrides() or {}
  if overrides.enable_scroll_bar ~= has_scrollback then
    overrides.enable_scroll_bar = has_scrollback
    window:set_config_overrides(overrides)
  end

  -- 2. Save CWD whenever navigating to a new folder
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    local path = cwd_uri.file_path
    if path and path ~= '' and path ~= cached_cwd then
      path = path:gsub('^/([A-Za-z]:)', '%1')
      if path:match('^[A-Za-z]:') then
        cached_cwd = path
        local f = io.open(last_cwd_file, 'w')
        if f then
          f:write(path)
          f:close()
        end
      end
    end
  end

  -- 3. Enforce profile name as tab title across all tabs (PowerShell, Arch, CMD)
  pcall(function()
    local mux_win = window:mux_window()
    if mux_win then
      for _, t in ipairs(mux_win:tabs()) do
        local tab_pane = (t.active_pane and t:active_pane()) or (t.panes and t:panes()[1])
        if tab_pane then
          local profile = get_pane_profile(tab_pane)
          if t:get_title() ~= profile then
            t:set_title(profile)
          end
        end
      end
    end
  end)
end)

-- Profile icons and brand colors (matching Windows Terminal)
local function get_profile_icon_and_color(profile)
  local lower = (profile or ''):lower()
  if lower:find('pwsh') or lower:find('powershell') then
    return (wezterm.nerdfonts.md_powershell or wezterm.nerdfonts.custom_powershell or '>_'), '#5391FE'
  elseif lower:find('cmd') or lower:find('command') then
    return (wezterm.nerdfonts.cod_terminal_cmd or wezterm.nerdfonts.cod_terminal or '>_'), '#C0C0C0'
  elseif lower:find('arch') then
    return (wezterm.nerdfonts.linux_archlinux or wezterm.nerdfonts.md_arch or wezterm.nerdfonts.fa_linux or 'A'), '#1793D1'
  elseif lower:find('wsl') or lower:find('linux') or lower:find('bash') or lower:find('zsh') then
    return (wezterm.nerdfonts.fa_linux or '$'), '#E95420'
  end
  return (wezterm.nerdfonts.cod_terminal or '>_'), '#FFFFFF'
end

-- Format tab title event: displays Windows Terminal profile icon + tab name in pure white
wezterm.on('format-tab-title', function(tab, tabs, panes, cfg, hover, max_width)
  local profile = (tab.tab_title and #tab.tab_title > 0) and tab.tab_title or get_pane_profile(tab.active_pane)
  local icon, icon_color = get_profile_icon_and_color(profile)
  return {
    { Text = '   ' },
    { Foreground = { Color = icon_color } },
    { Text = icon },
    { Foreground = { Color = '#FFFFFF' } },
    { Text = '  ' .. profile .. '     ' },
  }
end)

--------------------------------------------------------------------------------
-- 6. Helper: Open Window / Tab in Current Environment & Path
--------------------------------------------------------------------------------
local function get_current_env_and_cwd(pane)
  local profile = get_pane_profile(pane)

  local cwd_uri = nil
  if type(pane.get_current_working_dir) == 'function' then
    pcall(function() cwd_uri = pane:get_current_working_dir() end)
  elseif pane.current_working_dir then
    cwd_uri = pane.current_working_dir
  end
  local cwd = cwd_uri and cwd_uri.file_path or nil
  if cwd then
    cwd = cwd:gsub('^/([A-Za-z]:)', '%1')
  end

  local args = { 'pwsh.exe', '-NoLogo' }
  if profile == 'Arch' then
    local cd_target = '~'
    if cwd and cwd ~= '' then
      local drive, rest = cwd:match('^/mnt/([A-Za-z])/(.*)')
      if drive and rest then
        cd_target = drive:upper() .. ':\\' .. rest:gsub('/', '\\')
      elseif cwd:match('^[A-Za-z]:') then
        cd_target = cwd:gsub('/', '\\')
      else
        cd_target = cwd
      end
    end
    args = { 'wsl.exe', '-d', 'archlinux', '--cd', cd_target }
    cwd = nil -- wsl.exe handles directory switching via --cd
  elseif profile == 'CMD' then
    args = { 'cmd.exe' }
  end

  return args, cwd, profile
end

wezterm.on('spawn-window-current-env', function(window, pane)
  local args, cwd, profile = get_current_env_and_cwd(pane)
  local mux_tab, mux_pane, mux_win = wezterm.mux.spawn_window {
    args = args,
    cwd = cwd,
  }
  if mux_tab and profile then
    mux_tab:set_title(profile)
  end
end)

wezterm.on('spawn-tab-current-env', function(window, pane)
  local args, cwd, profile = get_current_env_and_cwd(pane)
  local mux_tab, mux_pane, mux_win = window:mux_window():spawn_tab {
    args = args,
    cwd = cwd,
  }
  if mux_tab and profile then
    mux_tab:set_title(profile)
  end
end)

--------------------------------------------------------------------------------
-- 7. Command Palette & Environment Picker Helpers
--------------------------------------------------------------------------------
-- Inject "Shell: <Profile> (New Window)" actions into the Command Palette (Ctrl+Shift+P)
wezterm.on('augment-command-palette', function(window, pane)
  local entries = {}
  for _, item in ipairs(config.launch_menu) do
    local is_wsl = false
    if item.args then
      for _, arg in ipairs(item.args) do
        if tostring(arg):lower():find('wsl') then
          is_wsl = true
          break
        end
      end
    end

    local icon_name = 'cod_terminal'
    local lower = item.label:lower()
    if lower:find('pwsh') or lower:find('power') then
      icon_name = 'md_powershell'
    elseif lower:find('cmd') then
      icon_name = 'cod_terminal_cmd'
    elseif lower:find('arch') or is_wsl then
      icon_name = 'linux_archlinux'
    end

    local display_label = item.label .. (is_wsl and ' (WSL)' or '')
    table.insert(entries, {
      brief = 'Shell: ' .. display_label .. ' (New Window)',
      icon = icon_name,
      action = act.SpawnCommandInNewWindow {
        args = item.args,
      },
    })
  end
  return entries
end)

local function build_env_choices()
  local choices = {}
  for idx, item in ipairs(config.launch_menu) do
    local is_wsl = false
    if item.args then
      for _, arg in ipairs(item.args) do
        if tostring(arg):lower():find('wsl') then
          is_wsl = true
          break
        end
      end
    end
    local icon = get_profile_icon_and_color(item.label)
    local display_label = item.label .. (is_wsl and ' (WSL)' or '')
    table.insert(choices, {
      id = tostring(idx),
      label = icon .. '  ' .. display_label,
    })
  end
  return choices
end

--------------------------------------------------------------------------------
-- 8. Keybindings
--------------------------------------------------------------------------------
config.keys = {
  -- Ctrl + N: Open new window in same environment (WSL / PWSH / CMD) and same path
  {
    key = 'n',
    mods = 'CTRL',
    action = act.EmitEvent('spawn-window-current-env'),
  },
  -- Ctrl + Shift + N: Quick environment picker to spawn a new window
  {
    key = 'n',
    mods = 'CTRL|SHIFT',
    action = act.InputSelector {
      title = 'Open New Window In...',
      choices = build_env_choices(),
      fuzzy = true,
      action = wezterm.action_callback(function(window, pane, id, label)
        if not id then return end
        local item = config.launch_menu[tonumber(id)]
        if item then
          window:perform_action(act.SpawnCommandInNewWindow {
            args = item.args,
          }, pane)
        end
      end),
    },
  },
  -- Ctrl + T: Open new tab in same environment and same path
  {
    key = 't',
    mods = 'CTRL',
    action = act.EmitEvent('spawn-tab-current-env'),
  },
  -- Ctrl + Shift + L: Open launch menu (profile switcher)
  {
    key = 'l',
    mods = 'CTRL|SHIFT',
    action = act.ShowLauncher,
  },
  -- Ctrl + W: Close tab without confirmation popup
  {
    key = 'w',
    mods = 'CTRL',
    action = act.CloseCurrentTab { confirm = false },
  },
  -- Ctrl + Shift + W: Close tab without confirmation popup
  {
    key = 'w',
    mods = 'CTRL|SHIFT',
    action = act.CloseCurrentTab { confirm = false },
  },
  -- Ctrl + C: Copy if text is selected, otherwise send interrupt (like Windows Terminal)
  {
    key = 'c',
    mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
      local has_selection = window:get_selection_text_for_pane(pane) ~= ''
      if has_selection then
        window:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', pane)
        window:perform_action(act.ClearSelection, pane)
      else
        window:perform_action(act.SendKey { key = 'c', mods = 'CTRL' }, pane)
      end
    end),
  },
  -- Ctrl + V: Paste from clipboard (like Windows Terminal)
  {
    key = 'v',
    mods = 'CTRL',
    action = act.PasteFrom 'Clipboard',
  },
}

return config
