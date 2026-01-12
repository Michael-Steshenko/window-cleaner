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
; F18 as Hyper Key (CapsLock remapped to F18 via PowerToys/Registry)
; ============================================================================
global F18Time := 0
global F18UsedAsModifier := false

*F18:: {
    global F18Time, F18UsedAsModifier
    F18Time := A_TickCount
    F18UsedAsModifier := false
}

*F18 Up:: {
    global F18Time, F18UsedAsModifier
    if (!F18UsedAsModifier && A_TickCount - F18Time < 400)
        Send "{Escape}"
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
                Run(apps[1])
                ; Wait for window to appear and focus it
                for exe in exeSet {
                    if WinWait("ahk_exe " exe, , 3) {
                        WinActivate("ahk_exe " exe)
                        break
                    }
                }
            }
        }
        return
    }

    ; Activate bottom-most window (least recently focused) for round-robin cycling
    target := allWindows[allWindows.Length]
    if (WinGetMinMax("ahk_id " target) = -1)
        WinRestore("ahk_id " target)
    WinActivate("ahk_id " target)
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

VSCodePath := EnvGet("LOCALAPPDATA") "\Programs\Microsoft VS Code\Code.exe"
VisualStudioProcessName := "devenv"
WindowsTerminalProcessName := "wt"

; Hyper Key combinations
F18 & 1:: LaunchOrCycle("1Password")
F18 & 2:: LaunchOrCycle(["Chrome", "MSEdge"])
F18 & 3:: LaunchOrCycle([VSCodePath, VisualStudioProcessName])
F18 & 4:: LaunchOrCycle(WindowsTerminalProcessName)
F18 & t:: LaunchOrCycle([EnvGet("LOCALAPPDATA") "\Discord\Update.exe --processStart Discord.exe", "Discord"])
F18 & e:: LaunchOrCycle("explorer.exe")
F18 & m:: LaunchOrCycle("Thunderbird")
F18 & v:: LaunchOrCycle("vmware.exe")
F18 & q:: WinClose("A")