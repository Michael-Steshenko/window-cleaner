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

; win+b open blutooth settings, and backout using key inputs to the screen that lets you connect to a paired device with one click
; If you don't reach that page, you may try to increase Sleep time, to let Settings app fully load
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
