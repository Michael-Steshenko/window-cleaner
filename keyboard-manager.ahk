#Requires AutoHotkey v2.0
#SingleInstance Force

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
; Global variables
; ============================================================================
global CapsLockPressed := false
global CapsLockTime := 0

; Disable default CapsLock behavior
SetCapsLockState "AlwaysOff"

; CapsLock down - act as Hyper (Ctrl+Win+Alt+Shift)
*CapsLock:: {
    global CapsLockPressed, CapsLockTime
    if (!CapsLockPressed) {
        CapsLockPressed := true
        CapsLockTime := A_TickCount
        ; Send down all Hyper modifiers
        Send "{Ctrl down}{LWin down}{Alt down}{Shift down}"
    }
}

; CapsLock up - release Hyper or send Escape if tapped
*CapsLock Up:: {
    global CapsLockPressed, CapsLockTime
    duration := A_TickCount - CapsLockTime

    ; Release all Hyper modifiers
    Send "{Shift up}{Alt up}{LWin up}{Ctrl up}"

    if (CapsLockPressed && duration < 400) {
        Send "{Escape}"
    }
    CapsLockPressed := false
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

; Function to launch or cycle through app windows
; If app is on another virtual desktop, does nothing (prevents duplicate launch error)
LaunchOrCycle(apps) {
    if (Type(apps) = "String")
        apps := [apps]

    ; Build a set of target exe names
    exeSet := Map()
    for app in apps {
        exe := StrLower(NormalizeExe(app))
        if (exe = "wt.exe")
            exe := "windowsterminal.exe"
        exeSet[exe] := true
    }

    allWindows := []
    existsOnOtherVD := false

    ; Get ALL windows in Z-order, then filter to our apps
    DetectHiddenWindows true
    for hwnd in WinGetList() {
        try {
            winExe := StrLower(WinGetProcessName("ahk_id " hwnd))
            winClass := WinGetClass("ahk_id " hwnd)

            ; Check if this window belongs to one of our target apps
            isMatch := exeSet.Has(winExe)
            ; Special case for explorer - match by class
            if (exeSet.Has("explorer.exe") && winClass = "CabinetWClass")
                isMatch := true

            if (isMatch) {
                if (IsWindowOnCurrentDesktop(hwnd)) {
                    if (IsRealWindow(hwnd))
                        allWindows.Push(hwnd)
                } else {
                    existsOnOtherVD := true
                }
            }
        }
    }
    DetectHiddenWindows false

    ; App on another VD - show tooltip in center of active monitor
    if (allWindows.Length = 0 && existsOnOtherVD) {
        CoordMode("ToolTip", "Screen")
        MonitorGetWorkArea(MonitorGetPrimary(), &left, &top, &right, &bottom)
        ToolTip("App is on another desktop", left + (right - left) // 2 - 113, top + (bottom - top) // 2 + 22)
        SetTimer(() => ToolTip(), -1000)
        return
    }

    ; Nothing open - launch
    if (allWindows.Length = 0) {
        try Run(apps[1])
        return
    }

    ; Activate the bottom-most window in Z-order (least recently focused)
    ; This cycles through all windows in round-robin fashion
    target := allWindows[allWindows.Length]

    try {
        if (WinGetMinMax("ahk_id " target) = -1)
            WinRestore("ahk_id " target)
        WinActivate("ahk_id " target)
    }
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
; note that we are not allowed to define the same hotkey twice,
; so comment out hotkeys here if you want to map them to something else
^#!+::     ; Office
^#!+W::    ; Word
;^#!+T::   ; Teams
^#!+Y::    ; Yammer
^#!+O::    ; Outlook
^#!+P::    ; PowerPoint
^#!+L::    ; LinkedIn
^#!+X::    ; Excel
^#!+N::    ; OneNote
^#!+D::    ; OneDrive
{
    Send "{Blind}{vkE8}" ; do nothing
    Return
}

VSCodePath := EnvGet("LOCALAPPDATA") "\Programs\Microsoft VS Code\Code.exe"

VisualStudioProcessName := "devenv"
WindowsTerminalProcessName := "wt"

; Hyper key combinations (Ctrl+Win+Alt+Shift+Key)
^#!+1:: LaunchOrCycle("1Password")
^#!+2:: LaunchOrCycle(["Chrome", "MSEdge"])
^#!+3:: LaunchOrCycle([VSCodePath, VisualStudioProcessName])
^#!+4:: LaunchOrCycle(WindowsTerminalProcessName)
^#!+T:: LaunchOrCycle([EnvGet("LOCALAPPDATA") "\Discord\Update.exe --processStart Discord.exe", "Discord"])
^#!+E:: LaunchOrCycle("explorer.exe")
^#!+M:: LaunchOrCycle("Thunderbird")
^#!+V:: LaunchOrCycle("vmware.exe")

; Quit focused window (Alt+F4 alternative)
^#!+Q:: WinClose("A")