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
  top = 2,
  bottom = 2,
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
    label = 'Command Prompt',
    args = { 'cmd.exe' },
  },
  {
    label = 'Arch Linux',
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
end)

--------------------------------------------------------------------------------
-- 5. Helper: Open Window / Tab in Current Environment & Path
--------------------------------------------------------------------------------
local function get_current_env_and_cwd(pane)
  local proc = (pane:get_foreground_process_name() or ''):lower()

  local cwd_uri = pane:get_current_working_dir()
  local cwd = cwd_uri and cwd_uri.file_path or nil
  if cwd then
    cwd = cwd:gsub('^/([A-Za-z]:)', '%1')
  end

  local args = { 'pwsh.exe', '-NoLogo' }
  if proc:find('wsl') then
    if cwd and cwd ~= '' then
      args = { 'wsl.exe', '-d', 'archlinux', '--cd', cwd }
    else
      args = { 'wsl.exe', '-d', 'archlinux', '--cd', '~' }
    end
    cwd = nil -- wsl.exe handles directory switching via --cd
  elseif proc:find('cmd') then
    args = { 'cmd.exe' }
  end

  return args, cwd
end

wezterm.on('spawn-window-current-env', function(window, pane)
  local args, cwd = get_current_env_and_cwd(pane)
  wezterm.mux.spawn_window {
    args = args,
    cwd = cwd,
  }
end)

wezterm.on('spawn-tab-current-env', function(window, pane)
  local args, cwd = get_current_env_and_cwd(pane)
  window:mux_window():spawn_tab {
    args = args,
    cwd = cwd,
  }
end)

--------------------------------------------------------------------------------
-- 6. Keybindings
--------------------------------------------------------------------------------
config.keys = {
  -- Ctrl + N: Open new window in same environment (WSL / PWSH / CMD) and same path
  {
    key = 'n',
    mods = 'CTRL',
    action = act.EmitEvent('spawn-window-current-env'),
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
