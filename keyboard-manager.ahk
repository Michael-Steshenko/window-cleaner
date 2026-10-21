#Requires AutoHotkey v2.0
#SingleInstance Force

; -- Requirments --
; 1. This script uses PowerToys FancyZones for window management,
; we assume the layouts have no padding ("Space around zones" disabled)
; for exact screen-edge boundary detection.

; Check if UI access is enabled in AutoHotkey, if not try enabling it
; needed for capturing hyperkey input when an elevated app is focused.
; Make sure the script is installed for "all users"
; (winget install AutoHotkey.AutoHotkey --scope machine)
if (!A_IsCompiled && !A_IsAdmin && !InStr(A_AhkPath, "_UIA")) {
    try {
        Run '*uiAccess "' A_ScriptFullPath '"'
        ExitApp
    } catch {
        MsgBox("Warning: AutoHotkey is running without UI access, did you install AutoHotkey for all users (Program Files)?`n`nYour Hyper Key might not work in administrator windows unless you enable UI access or run the script as admin. ",
            "UI access required", "Icon!")
    }
}

; Performance optimizations
ListLines 0
KeyHistory 0
SendMode "Input"
#WinActivateForce
SetWinDelay -1

; ============================================================================
; Virtual Desktop Helper - uses public IVirtualDesktopManager API
; ============================================================================
global VDManager := ComObject("{AA509086-5CA9-4C25-8F95-589D3C07B48A}", "{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}")
global VDIsWindowOnCurrentDesktop := NumGet(NumGet(VDManager.Ptr, 0, "Ptr"), 3 * A_PtrSize, "Ptr")

IsWindowOnCurrentDesktop(hwnd) {
    result := 0
    try DllCall(VDIsWindowOnCurrentDesktop, "Ptr", VDManager.Ptr, "Ptr", hwnd, "Int*", &result)
    return result
}

; ============================================================================
; F18 as Hyper Key (CapsLock remapped to F18 via PowerToys/Registry)
; ============================================================================
global F18Time := 0
global F18Down := false
global LastMinimizedHwnd := 0

*F18:: {
    global F18Time, F18Down
    F18Time := A_TickCount
    F18Down := true
}

*F18 Up:: {
    global F18Time, F18Down, LastMinimizedHwnd
    F18Down := false
    LastMinimizedHwnd := 0

    ; Release LWin if it was held down by a window management shortcut
    if GetKeyState("LWin")
        Send "{Blind}{LWin Up}"

    ; If no other hotkeys fired between Down and Up, it was a tap.
    ; SendEvent, not Send (SendInput): an Escape sent via SendInput from this
    ; PowerToys-triggered hotkey never reaches (not sure why) an active InputHook
    ; (e.g. Apple Music mode)
    if (A_PriorHotkey = "*F18" && A_TickCount - F18Time < 400)
        SendEvent "{Escape}"
}

; Normalize to *.exe for process matching/launching
NormalizeExe(name) {
    SplitPath name, &exe
    return InStr(exe, ".exe") ? exe : exe ".exe"
}

; Check if window is a real app window (visible, has title, not IME)
IsRealWindow(hwnd) {
    title := WinGetTitle("ahk_id " hwnd)
    if (title = "" || InStr(title, "Default IME") || InStr(title, "MSCTFIME"))
        return false
    return WinGetStyle("ahk_id " hwnd) & 0x10000000  ; WS_VISIBLE
}

; Expand environment variables in a string (e.g. %LOCALAPPDATA%)
ExpandEnvVars(str) {
    while RegExMatch(str, "%([^%]+)%", &match)
        str := StrReplace(str, match[0], EnvGet(match[1]))
    return str
}

; Get true visual bounds of window (excluding invisible DWM drop shadows)
GetWindowVisualRect(hwnd) {
    try {
        if (WinGetMinMax("ahk_id " hwnd) = 1) {
            WinGetPos(&wx, &wy, &ww, &wh, hwnd)
            midX := wx + ww // 2
            midY := wy + wh // 2
            Loop MonitorGetCount() {
                MonitorGetWorkArea(A_Index, &mLeft, &mTop, &mRight, &mBottom)
                if (midX >= mLeft && midX <= mRight && midY >= mTop && midY <= mBottom)
                    return { left: mLeft, top: mTop, right: mRight, bottom: mBottom }
            }
        }

        rect := Buffer(16, 0)
        ; DWMWA_EXTENDED_FRAME_BOUNDS = 9
        if (DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9, "Ptr", rect, "UInt", 16) = 0) {
            return {
                left: NumGet(rect, 0, "Int"),
                top: NumGet(rect, 4, "Int"),
                right: NumGet(rect, 8, "Int"),
                bottom: NumGet(rect, 12, "Int")
            }
        }
        WinGetPos(&x, &y, &w, &h, hwnd)
        return { left: x, top: y, right: x + w, bottom: y + h }
    }
    return { left: 0, top: 0, right: 0, bottom: 0 }
}

; Check if cursor is currently within the visual bounds of the window
IsCursorInsideWindow(hwnd) {
    try {
        if (WinGetMinMax("ahk_id " hwnd) = -1)
            return false

        pt := Buffer(8, 0)
        DllCall("GetCursorPos", "Ptr", pt)
        curX := NumGet(pt, 0, "Int")
        curY := NumGet(pt, 4, "Int")

        vRect := GetWindowVisualRect(hwnd)
        return (curX >= vRect.left && curX <= vRect.right && curY >= vRect.top && curY <= vRect.bottom)
    }
    return false
}

; Move mouse cursor to the middle of the specified window
MoveCursorToWindowCenter(hwnd) {
    try {
        if (WinGetMinMax("ahk_id " hwnd) = -1)
            return

        Loop 10 {
            vRect := GetWindowVisualRect(hwnd)
            if (vRect.right > vRect.left && vRect.bottom > vRect.top)
                break
            Sleep 20
        }

        if (vRect.right <= vRect.left || vRect.bottom <= vRect.top)
            return

        midX := (vRect.left + vRect.right) // 2
        midY := (vRect.top + vRect.bottom) // 2

        DllCall("SetCursorPos", "Int", midX, "Int", midY)
        CoordMode("Mouse", "Screen")
        MouseMove(midX, midY, 0)
    }
}

; Navigate to target window: focus it and move cursor to middle.
; If target is already the focused window and cursor is already inside it, do nothing.
NavigateToWindow(target) {
    activeHwnd := WinActive("A")
    alreadyFocused := (activeHwnd && (activeHwnd = target))

    if (!alreadyFocused) {
        if (WinGetMinMax("ahk_id " target) = -1)
            WinRestore("ahk_id " target)
        WinActivate("ahk_id " target)
        WinWaitActive("ahk_id " target, , 0.5)
    }

    cursorInside := IsCursorInsideWindow(target)
    if !(alreadyFocused && cursorInside)
        MoveCursorToWindowCenter(target)
}

; Function to launch or cycle through app windows
LaunchOrCycle(apps) {
    apps := (Type(apps) = "String") ? [apps] : apps

    ; Build a set of target exe names (with special cases)
    exeSet := Map()
    for app in apps {
        exe := StrLower(NormalizeExe(app))
        exeSet[(exe = "wt.exe") ? "windowsterminal.exe" : exe] := true
    }

    allWindows := []
    existsOnOtherVD := false
    hasExplorer := exeSet.Has("explorer.exe")

    ; Get all windows in Z-order, filter to our target apps
    DetectHiddenWindows true
    for hwnd in WinGetList() {
        try {
            winExe := StrLower(WinGetProcessName("ahk_id " hwnd))
            isMatch := exeSet.Has(winExe) || (hasExplorer && WinGetClass("ahk_id " hwnd) = "CabinetWClass")

            if (isMatch) {
                if (!IsWindowOnCurrentDesktop(hwnd))
                    existsOnOtherVD := true
                else if (IsRealWindow(hwnd))
                    allWindows.Push(hwnd)
            }
        }
    }
    DetectHiddenWindows false

    ; No windows on current VD
    if (allWindows.Length = 0) {
        if (existsOnOtherVD) {
            CoordMode("ToolTip", "Screen")
            MonitorGetWorkArea(MonitorGetPrimary(), &left, &top, &right, &bottom)
            ToolTip("App is on another desktop", left + (right - left) // 2 - 113, top + (bottom - top) // 2 + 22)
            SetTimer(() => ToolTip(), -1000)
        } else {
            try {
                Run(ExpandEnvVars(apps[1]))
                ; Wait for window to appear and focus it
                waitTitle := hasExplorer ? "ahk_class CabinetWClass" : ""
                if (waitTitle != "") {
                    if (hwnd := WinWait(waitTitle, , 3)) {
                        WinActivate("ahk_id " hwnd)
                        WinWaitActive("ahk_id " hwnd, , 1)
                        MoveCursorToWindowCenter(hwnd)
                    }
                } else {
                    for exe in exeSet {
                        if (hwnd := WinWait("ahk_exe " exe, , 3)) {
                            WinActivate("ahk_id " hwnd)
                            WinWaitActive("ahk_id " hwnd, , 1)
                            MoveCursorToWindowCenter(hwnd)
                            break
                        }
                    }
                }
            }
        }
        return
    }

    ; Check if active window is one of our target apps
    activeHwnd := WinActive("A")
    activeIsTarget := false
    for hwnd in allWindows {
        if (hwnd = activeHwnd) {
            activeIsTarget := true
            break
        }
    }

    ; If active window is a target app, cycle to next; otherwise activate the most recent one
    if (activeIsTarget)
        target := allWindows[allWindows.Length]  ; Bottom of Z-order (least recent)
    else
        target := allWindows[1]  ; Top of Z-order (most recent)

    NavigateToWindow(target)
}

; ============================================================================
; Hotkey Definitions
; ============================================================================

; Disable ctrl + alt + shift + win launching office
; We need check every order of the last key, because these are all modifier keys
+!^LWin::
#^!Shift::
#^+Alt::
#!+Ctrl:: {
    Send "{Blind}{vkE8}" ; do nothing
    Return
}

; Disable all microsoft app shortcuts
^#!+::     ; Office
^#!+W::    ; Word
;^#!+T::    ; Teams
^#!+Y::    ; Yammer
^#!+O::    ; Outlook
^#!+P::    ; PowerPoint
^#!+L::    ; LinkedIn
^#!+X::    ; Excel
^#!+N::    ; OneNote
^#!+D::    ; OneDrive
{
    Return
}

ConfigFile := A_ScriptDir "\config.ini"

ReadAppConfig(key) {
    global ConfigFile
    return IniRead(ConfigFile, "Apps", key)
}

ReadAppList(key) {
    raw := ReadAppConfig(key)
    list := []
    for item in StrSplit(raw, ",") {
        trimmed := Trim(item)
        if (trimmed != "")
            list.Push(trimmed)
    }
    return list
}

VSCodePath := EnvGet("LOCALAPPDATA") "\Programs\Microsoft VS Code\Code.exe"
VisualStudioProcessName := "devenv"
terminalApps := ReadAppList("Terminal")

#HotIf F18Down

; Hyper Key combinations
*1:: LaunchOrCycle("1Password")
*2:: LaunchOrCycle(["Chrome", "MSEdge"])
*3:: LaunchOrCycle([VSCodePath, VisualStudioProcessName])
*4:: LaunchOrCycle(terminalApps)
*5:: LaunchOrCycle(EnvGet("LOCALAPPDATA") "\Programs\Obsidian\Obsidian.exe")
; For discord the path does not match the app name,
; we need to provide both the path to "Update.exe" and "Discord"
*t:: LaunchOrCycle([EnvGet("LOCALAPPDATA") "\Discord\Update.exe --processStart Discord.exe", "Discord"])
*e:: LaunchOrCycle("explorer.exe")
*m:: LaunchOrCycle("Thunderbird")
*v:: LaunchOrCycle("vmware.exe")
*q:: WinClose("A")
*a:: AppleMusicMode()

; Window Management, Hyper + h/j/k/l maps to Win + arrow keys

MoveZone(dir) {
    try {
        hwnd := WinGetID("A")
        vRect := GetWindowVisualRect(hwnd)

        midX := (vRect.left + vRect.right) // 2
        midY := (vRect.top + vRect.bottom) // 2
        foundMonitor := false
        Loop MonitorGetCount() {
            MonitorGetWorkArea(A_Index, &mLeft, &mTop, &mRight, &mBottom)
            if (midX >= mLeft && midX <= mRight && midY >= mTop && midY <= mBottom) {
                foundMonitor := true
                break
            }
        }

        ; Only block cycling if the window is visibly within a known monitor
        ; If it is off-screen, allow the shortcut through so it can snap back
        if foundMonitor {
            if (dir = "Right" && vRect.right >= mRight)
                return
            if (dir = "Left" && vRect.left <= mLeft)
                return
        }

        if !GetKeyState("LWin")
            Send "{Blind}{LWin Down}"
        Send "{Blind}{" dir "}"
    }
}

MoveDownOrMinimize() {
    global LastMinimizedHwnd
    ; Only allow one minimize per Hyper key press
    if (LastMinimizedHwnd != 0)
        return

    try {
        if !WinExist("A") || !IsRealWindow(WinGetID("A"))
            return
        hwnd := WinGetID("A")

        ; If window is currently maximized, restore it back to its normal zone
        if (WinGetMinMax("ahk_id " hwnd) = 1) {
            WinRestore("ahk_id " hwnd)
            return
        }

        vRect := GetWindowVisualRect(hwnd)
        midX := (vRect.left + vRect.right) // 2
        midY := (vRect.top + vRect.bottom) // 2
        foundMonitor := false
        Loop MonitorGetCount() {
            MonitorGetWorkArea(A_Index, &mLeft, &mTop, &mRight, &mBottom)
            if (midX >= mLeft && midX <= mRight && midY >= mTop && midY <= mBottom) {
                foundMonitor := true
                break
            }
        }

        ; In multi-row layouts: if window is in an upper row, move it DOWN
        if (foundMonitor && vRect.bottom < mBottom) {
            if !GetKeyState("LWin")
                Send "{Blind}{LWin Down}"
            Send "{Blind}{Down}"
            return
        }

        ; Otherwise, window is at bottom of the monitor (or single-row layout): MINIMIZE
        if GetKeyState("LWin")
            Send "{Blind}{LWin Up}"
        LastMinimizedHwnd := hwnd
        WinMinimize("ahk_id " hwnd)
    }
}

MoveUpOrUnminimize() {
    global LastMinimizedHwnd
    ; Unminimizing only works during the same Hyper hold where a window was minimized
    if (LastMinimizedHwnd != 0) {
        if WinExist("ahk_id " LastMinimizedHwnd) && (WinGetMinMax("ahk_id " LastMinimizedHwnd) = -1) {
            WinRestore("ahk_id " LastMinimizedHwnd)
            WinActivate("ahk_id " LastMinimizedHwnd)
            if GetKeyState("LWin")
                Send "{Blind}{LWin Up}"
            LastMinimizedHwnd := 0
            return
        }
        LastMinimizedHwnd := 0
    }

    try {
        if !WinExist("A") || !IsRealWindow(WinGetID("A"))
            return
        hwnd := WinGetID("A")
        vRect := GetWindowVisualRect(hwnd)
        midX := (vRect.left + vRect.right) // 2
        midY := (vRect.top + vRect.bottom) // 2
        foundMonitor := false
        Loop MonitorGetCount() {
            MonitorGetWorkArea(A_Index, &mLeft, &mTop, &mRight, &mBottom)
            if (midX >= mLeft && midX <= mRight && midY >= mTop && midY <= mBottom) {
                foundMonitor := true
                break
            }
        }

        ; In multi-row layouts: if window is in a lower row, move it UP
        if (foundMonitor && vRect.top > mTop) {
            if !GetKeyState("LWin")
                Send "{Blind}{LWin Down}"
            Send "{Blind}{Up}"
            return
        }

        ; If at the top row and not maximized, maximize
        if (WinGetMinMax("ahk_id " hwnd) = 0)
            WinMaximize("ahk_id " hwnd)
    }
}

*h:: MoveZone("Left")
*j:: MoveDownOrMinimize()
*k:: MoveUpOrUnminimize()
*l:: MoveZone("Right")

#HotIf

#Include apple-music.ahk