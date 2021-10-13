#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


; Custom keyboard shortcuts script

; ahk symbols representation for windows keyboard action keys:
; Control	^
; Alt		!
; Shift		+
; Windows Key	#

; win+b - open blutooth settings, and connect to the first blutooth device (untested with multiple blutooth devices connected)
; If the script doesn't navigate correctly or doesn't connect to the blutooth device, you may want to try increasing Sleep times
#b::
	Process,Close,SystemSettings.exe
	run explorer.exe ms-settings:bluetooth
	
	Sleep 1000		

	Send, {Tab}
	Sleep 10
	Send, {Enter}
	Sleep 200	
	
	; send shift + tab
	Send, {Shift down}
	Send, {Tab}
	Send, {Shift up}
	Sleep 10	

	Send, {Enter}
Return

