#singleinstance force
#include Class_RichEdit.ahk

;	It can handle RTF format
re1DefautText := 	  "{\rtf1\ansi\ansicpg1252\deff0\nouicompat{\fonttbl{\f0\fnil\fcharset0 Consolas;}}"
					. "{\colortbl `;\red255\green255\blue0;\red0\green0\blue255;}"
					. "{\*\generator Riched20 10.0.17134}\viewkind4\uc1 "
					. "\pard\cf1\highlight2\ul\b\i\lang1033 This is a RichEdit Box\par"
					. "}"
					
gui := guicreate()
gui.setfont("s10", "Consolas")
eb := gui.add("edit", "r10 w400", "This is an Edit Box")

; 	This is how you create them
; 	be sure the first argument is the gui object.  Syntax is similar to what you would use for Edit box
; 	implemented options:  +/-wrap, readonly, uppercase, lowercase,styles & exstyles
; 	(see Class_RichEdit's constructor __New())
re1 := new richedit(gui, "r10 w400", re1DefautText)
re2 := new richedit(gui, "r5 w400 readonly", "This is a read-only RichEdit Box`n")

;	These are the only supported events for .onEvent()
;	for other RichEdit specific events, see Class_RichEdit.ahk's SetEventMask()
re1.OnEvent("change", ()=>output("RichEdit content has changed.")) 
re1.OnEvent("focus", ()=>output("RichEdit has gained focus.")) 
re1.OnEvent("losefocus", ()=>output("RichEdit has lost focus.")) 

gui.show()

;	Supported properties:
;		Gui - parent gui object (the one you passed when creating this RichEdit control
;		Hwnd - the control's hwnd
;		Also supports: Enabled, Focused, Name, Pos, Type, Visible, Value, and Text (equivalent to Value)
;
;		For RTF specific features, see Class_RichEdit.ahk for usage of
;			SetFont, GetRTF, SetSel, .... etc

output("Its size and position: w" re1.pos.w " h" re1.pos.h " x" re1.pos.x " y" re1.pos.y)


output(msg) {
	global gui, re2
	re2.value .= msg "`n" ;you can also use re2.text here
	PostMessage(0x115, 7, ,re2.hwnd , "ahk_id " gui.hwnd) ;scroll to end of control
}