;#SETUP START
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force
ListLines Off
SetBatchLines -1
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
#KeyHistory 0
#WinActivateForce

Process, Priority,, H

SetWinDelay -1
SetControlDelay -1

;include the library
#Include VD.ahk
; VD.init() ;COMMENT OUT `static dummyStatic1 := VD.init()` if you don't want to init at start of script

;you should WinHide invisible programs that have a window.
WinHide, % "Malwarebytes Tray Application"
;#SETUP END

VD.createUntil(3) ;create until we have at least 3 VD

return

; Move window
;ctrl + shift + left
^+Left::
n := VD.getCurrentDesktopNum()
if n = 1
{
    Return
}
n -= 1
VD.MoveWindowToDesktopNum("A",n)
Return

;ctrl + shift + right
^+Right::
n := VD.getCurrentDesktopNum()
if n = % VD.getCount()
{
    Return
}
n += 1
VD.MoveWindowToDesktopNum("A",n)
Return

; Move window and switch VD
;ctrl + Win + shift + left
^#+Left::
n := VD.getCurrentDesktopNum()
if n = 1
{
    Return
}
n -= 1
VD.MoveWindowToDesktopNum("A",n), VD.goToDesktopNum(n)
Return

;ctrl + Win + shift + right
^#+Right::
n := VD.getCurrentDesktopNum()
if n = % VD.getCount()
{
    Return
}
n += 1
VD.MoveWindowToDesktopNum("A",n), VD.goToDesktopNum(n)
Return