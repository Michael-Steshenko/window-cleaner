; apple-music.ahk - Apple Music Mode for keyboard-manager.ahk
; Launches/focuses yabloko and drives it through its loopback HTTP server
#Requires AutoHotkey v2.0

ShowOSD(text, icon := "", duration := 1500) {
    static OSD_GUI := Gui("+AlwaysOnTop +ToolWindow -Caption +Disabled -SysMenu -DPIScale")
    static OSD_TextControl := ""
    static FontOptions := "s20 cWhite w700", FontName := "Segoe UI"
    ; One shared hide callback, so each SetTimer call restarts the countdown instead of
    ; an older timer hiding a newer message early
    static HideOSD := () => OSD_GUI.Hide()

    if (OSD_TextControl = "") {
        OSD_GUI.BackColor := "101010"
        OSD_GUI.SetFont(FontOptions, FontName)
        ; Default margins scale with the font (38x23px at s20/150%), dwarfing a lone icon
        OSD_GUI.MarginX := 14, OSD_GUI.MarginY := 4
        OSD_TextControl := OSD_GUI.Add("Text", "Center cWhite")
        WinSetTransparent(220, OSD_GUI)
    }

    if (text = "") {
        SetTimer(HideOSD, 0)
        OSD_GUI.Hide()
        return
    }

    text := (icon ? icon " " : "") text
    ; A Text control keeps the size it was created with, so measure this message in a
    ; throwaway GUI (a Text control added with no size fits its text) and resize to it
    measure := Gui("-DPIScale")
    measure.SetFont(FontOptions, FontName)
    measure.Add("Text", , text).GetPos(, , &w, &h)
    measure.Destroy()
    OSD_TextControl.Move(, , w, h)
    OSD_TextControl.Value := text
    OSD_GUI.Show("AutoSize NoActivate xCenter yCenter")
    SetTimer(HideOSD, -duration)
}

; Send an action to the yabloko HTTP server (favorite, undo-favorite, suggest-less)
AM_Request(action) {
    global ConfigFile
    port := IniRead(ConfigFile, "AppleMusic", "YablokoPort", "8787")
    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("POST", "http://127.0.0.1:" port "/" action, false)
        http.SetTimeouts(2000, 2000, 5000, 10000)
        http.Send()
    } catch {
        return "NO_SERVER"
    }
    switch http.Status {
        case 200: return "done"
        case 409: return "NO_PAGE"     ; nothing playing
        case 503: return "NOT_READY"   ; MusicKit not loaded yet
        default: return "FAILED"
    }
}

AM_Action(action) {
    static actions := Map(
        "favorite", {endpoint: "favorite", icon: "★"},
        "unfavorite", {endpoint: "undo-favorite", icon: "☆"},
        "suggest_less", {endpoint: "suggest-less", icon: "👎"}
    )
    a := actions[action]
    ; Show the icon right away; the request blocks until yabloko answers, so send it from
    ; a timer thread (lets the OSD paint first) and only replace the icon on failure
    ShowOSD(a.icon)
    SetTimer(() => AM_ReportResult(AM_Request(a.endpoint)), -1)
}

AM_ReportResult(result) {
    switch result {
        case "done": return
        case "NO_SERVER": ShowOSD("Start Yabloko", "❌")
        case "NO_PAGE": ShowOSD("Nothing playing", "❌")
        case "NOT_READY": ShowOSD("Yabloko not ready", "❌")
        default: ShowOSD("Failed", "❌")
    }
}

AM_LaunchOrFocus() {
    ; Try to activate an existing (visible) yabloko window
    if (hwnd := WinExist("ahk_exe yabloko.exe")) {
        NavigateToWindow(hwnd)
        return
    }
    ; Not running, or its window is hidden (closing hides it). Running the exe again
    ; either starts it or makes the running instance show and focus its window.
    global ConfigFile
    exe := ExpandEnvVars(IniRead(ConfigFile, "AppleMusic", "YablokoExe", ""))
    if (exe = "") {
        ShowOSD("No YablokoExe`nin config.ini", "❌")
        return
    }
    if !FileExist(exe) {
        ShowOSD("yabloko.exe not found`ncheck config.ini", "❌")
        return
    }
    try {
        Run('"' exe '"')
        if (hwnd := WinWait("ahk_exe yabloko.exe", , 10)) {
            WinActivate("ahk_id " hwnd)
            WinWaitActive("ahk_id " hwnd, , 1)
            MoveCursorToWindowCenter(hwnd)
        }
    }
}

AppleMusicMode() {
    ; OSD stays up for exactly as long as the mode waits for a key
    timeout := 2
    ShowOSD("Apple Music Mode", , timeout * 1000)

    ih := InputHook("L1 T" timeout)
    ; Every key ends the mode, so non-text keys (arrows, Tab, ...) can be reported too.
    ; Modifiers are excluded so Shift+letter still works, and CapsLock/F18 (the Hyper
    ; key, whose tap sends the Escape that cancels the mode) so they don't end it first
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LShift}{RShift}{LCtrl}{RCtrl}{LAlt}{RAlt}{LWin}{RWin}{CapsLock}{F18}", "-E")
    ih.Start()
    ih.Wait()

    key := (ih.EndReason = "EndKey") ? ih.EndKey : ih.Input
    if (key = "Escape" || ih.EndReason = "Timeout") {
        ShowOSD("") ; hide OSD
    } else if (key = "a" || key = "A") {
        AM_LaunchOrFocus()
        ShowOSD("") ; hide OSD
    } else if (key = "f" || key = "F") {
        AM_Action("favorite")
    } else if (key = "u" || key = "U") {
        AM_Action("unfavorite")
    } else if (key = "l" || key = "L") {
        AM_Action("suggest_less")
    } else {
        ShowOSD("Invalid key: " key, "❌")
    }
}
