#Requires AutoHotkey v2.0
#SingleInstance Force


; Global variables
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

; Ignore cloaked (invisible UWP/background) windows
IsCloaked(hwnd) {
    cloaked := 0
    DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "int", 14, "int*", cloaked, "int", 4)
    return cloaked
}

; Numeric in-place sort for small arrays (stable order independent of Z-order)
SortArrayNumeric(&arr) {
    len := arr.Length
    if (len < 2)
        return
    Loop len - 1 {
        i := A_Index
        minIdx := i
        j := i + 1
        while (j <= len) {
            if (arr[j] < arr[minIdx])
                minIdx := j
            j++
        }
        if (minIdx != i) {
            tmp := arr[i], arr[i] := arr[minIdx], arr[minIdx] := tmp
        }
    }
}

; Function to launch or cycle through app windows (stateless)
LaunchOrCycle(apps) {
    if (Type(apps) = "String")
        apps := [apps]

    ; Collect current, valid, activatable window IDs for all apps
    allWindows := []
    for app in apps {
        exe := NormalizeExe(app)

        ; Special case: wt.exe launches as WindowsTerminal.exe
        ; We cannot use full path here because the exe is from MS store
        ; and the parent folder includes the version,
        ; so updating would break the hardcoded path
        if (StrLower(exe) = "wt.exe")
            exe := "WindowsTerminal.exe"

        for hwnd in WinGetList("ahk_exe " exe) {
            if (!WinExist("ahk_id " hwnd))
                continue
            if (IsCloaked(hwnd))
                continue
            if (WinGetTitle("ahk_id " hwnd) = "")
                continue
            allWindows.Push(hwnd)
        }
    }

    ; If nothing is open, launch using the original path/name
    if (allWindows.Length = 0) {
        try {
            Run apps[1]  ; Use Run with the full path as-is
        } catch as err {
            MsgBox "Failed to launch: " apps[1] "`n" err.Message
        }
        return
    }

    ; Stable order (not affected by activation/Z-order changes)
    SortArrayNumeric(&allWindows)
    activeID := WinGetID("A")

    ; Single window: activate if needed
    if (allWindows.Length = 1) {
        target := allWindows[1]
        if (activeID != target) {
            if (WinGetMinMax("ahk_id " target) = -1)
                WinRestore "ahk_id " target
            WinActivate "ahk_id " target
        }
        return
    }

    currentIndex := 0
    Loop allWindows.Length {
        if (allWindows[A_Index] = activeID) {
            currentIndex := A_Index
            break
        }
    }

    ; Next index (wrap)
    nextIndex := (currentIndex = 0) ? 1 : ((currentIndex < allWindows.Length) ? (currentIndex + 1) : 1)

    target := allWindows[nextIndex]
    if (WinGetMinMax("ahk_id " target) = -1)
        WinRestore "ahk_id " target
    if (activeID != target) {
        WinActivate "ahk_id " target
    }

}

;Disable ctrl + alt + shift + win lauching office
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

VSCodePath := "C:\Users\Michael\AppData\Local\Programs\Microsoft VS Code\Code.exe"
VisualStudioProcessName := "devenv"
WindowsTerminalProcessName := "wt"

; Hyper key combinations (Ctrl+Win+Alt+Shift+Key)
^#!+1:: LaunchOrCycle("1Password")
^#!+2:: LaunchOrCycle(["Chrome", "MSEdge"])
^#!+3:: LaunchOrCycle([VSCodePath, VisualStudioProcessName])
^#!+4:: LaunchOrCycle(WindowsTerminalProcessName)
^#!+T:: LaunchOrCycle("C:\Users\Michael\AppData\Local\Discord\Discord.exe")