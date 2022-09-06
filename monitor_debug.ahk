#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Will get debug information of your main monitor.

; Initialize Monitor handle
hMon := DllCall("MonitorFromPoint"
	, "int64", 0 ; point on monitor
	, "uint", 1) ; flag to return primary monitor on failure

; Find number of Physical Monitors
DllCall("dxva2\GetNumberOfPhysicalMonitorsFromHMONITOR"
	, "int", hMon
	, "uint*", nMon)

; Get Physical Monitor from handle
VarSetCapacity(Physical_Monitor, (A_PtrSize ? A_PtrSize : 4) + 128, 0)

DllCall("dxva2\GetPhysicalMonitorsFromHMONITOR"
	, "int", hMon   ; monitor handle
	, "uint", nMon   ; monitor array size
	, "int", &Physical_Monitor)   ; point to array with monitor

hPhysMon := NumGet(Physical_Monitor)

if (!DllCall("dxva2\GetMonitorCapabilities"
	, "int", hPhysMon
	, "uint*", monCaps
	, "uint*", monColorTemps))
	MsgBox % "Monitor does not support DDC/CI."
else {
	MsgBox % "Monitor supports DDC/CI."
	if (monCaps & 0x2 = 0) ; MC_CAPS_BRIGHTNESS
		MsgBox % "Monitor does not support GetMonitorBrightness or SetMonitorBrightness functions."
}


DllCall("dxva2\GetMonitorBrightness"
	, "int", hPhysMon
	, "uint*", minBright
	, "uint*", curBright
	, "uint*", maxBright)

MsgBox % "Monitor description: " . StrGet(&Physical_Monitor+(A_PtrSize ? A_PtrSize : 4), "utf-16")
	. "`nMinimum brightness: " . minBright
	. "`nMaximum brightness: " . maxBright
	. "`nCurrent brightness: " . curBright