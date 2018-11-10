/*
	Simple Regular Expression Tester for AutoHotkey v2 using RegExMatch()
	Tested with build: AutoHotkey_2.0-a100-52515e2
*/
#singleinstance force
#Include Class_RichEdit.ahk

;Default Values
	defText := 'History`n`nThe first public beta of AutoHotkey was released on November 10, 2003[10] after author Chris Mallett`'s proposal to integrate hotkey support into AutoIt v2 failed to generate response from the AutoIt community.[11][12] So the author began his own program from scratch basing the syntax on AutoIt v2 and using AutoIt v3 for some commands and the compiler.[13] Later, AutoIt v3 switched from GPL to closed source because of "other projects repeatedly taking AutoIt code" and "setting themselves up as competitors."[14]`n`nIn 2010, AutoHotkey v1.1 (originally called AutoHotkey_L) became the platform for ongoing development of AutoHotkey.[15] Another port of the program is AutoHotkey.dll.[16]`n`nhttps://en.wikipedia.org/wiki/AutoHotkey`n'
	defRegex := "A[^\s]*?y"

;Gui Stuff
	font := "Consolas", w := 800, _w := 200 ;button width
	gui := guiCreate(, "Regular Expression Tester for AutoHotkey v2"), gui.SetFont(, font)
	gui.Add("Text", , "RegEx String:"), 	regex  := gui.Add("Edit", "-wrap r1 w" w, defRegex) 	;setup regex box
	gui.Add("Text", , "Text:"), 			text   := New RichEdit(gui, "r35 w" w, defText) 		;setup RichEdit box
	gui.Add("Text", , "Results:"), 			result := gui.Add("Edit", "+readonly r15 w" w) 			;setup result box
	n2r := gui.Add("CheckBox", "checked", "Convert ``n (\n) to ``r (\r)"), n2r.move( "y" gui.MarginY " x" w - gui.MarginX - n2r.pos.w)
	gcToolTip.Add(n2r, "Enabling this option is recommended`nbecause this RichEdit box only uses ``r (\r).")
	btn := gui.Add("Button", "yp0 w" _w " x" w / 2 + gui.MarginX - _w / 2 " Default", "Test RegEx (F5)") ;test button
	gui.OnEvent("Close", ()=>ExitApp()), 	btn.OnEvent("Click", ()=>doRegEx())	;Run doRegEx() whenever changes are detected
	gui.show(), doRegEx()

f5::doRegEx()
;*To do: add navigation to next/prev match, add replace box, replace by function?

;called by RegExFunc in RichEdit for each match ... to do: add RTF directly
onMatch(oRE, _, sp, len) =>	oRE.SetSel(sp - 1, sp + len - 1) && oRE.SetFont({BkColor:"YELLOW"})

;perform RegEx, highlight and print results
doRegEx() {
	global gui, regex, text, result, n2r
	rstr := regex.value, result.value := ""	;reset the result box
	
	;replace escaped `(backticks)
	list := n2r.value ? {"``n":"`r", "\n":"\r", "``t":"`t", "``r":"`r"} : {"``n":"`n", "``t":"`t", "``r":"`r"}
	for k, v in list
		qreplace(rstr, k, v)

	;attempt RegExMatch
	try	
		if pos := RegExMatch(text.text, rstr, m) { ;if we have a match
			
			;highlight matches - to do: restore scroll position.  				*To do: use RTF directly
            sel := text.GetSel(), text.text := text.text   						;save caret position and reset formatting
            match := text.RegExFunc(rstr, (param*) => onMatch(text, param*)) 	;highlight matches with onMatch()
            text.SetSel(sel.S, sel.E) 											;restore caret position

            ;prepare matchedText for result output
            for k, v in match
				matchedText .= (k==1 ? "" : chr(0x2DDF)) . v 
			matchedText := Sort(matchedText, "F mySort D" chr(0x2DDF))			;sort lengthwise and alphabetically
			_match := StrSplit(matchedText, chr(0x2DDF)), _mDict := {}			;count duplicates
            for k, v in _match													;
				_mDict.HasKey(v) ? _mDict[v] += 1 : _mDict[v] := 1				;*To do: can probably make this better	
			matchedText := Sort(matchedText, "U F mySort D" chr(0x2DDF))		;remove duplicates and keep sort order by re-sorting
			_match := StrSplit(matchedText, chr(0x2DDF)), matchedText := ""		;
            for k, v in _match 													;prep output
				_v := "`t" StrReplace(v, "`r", "`n`t")
				, matchedText .= format("{:-12}{:}", (k == 1 ? "" : "`n") "[" k "] x " . _mDict[v],  _v) 

			;print results
			result.value .=   "First match at: " . pos . "`n"
							. "Total matches : " . match.Count() . "`n"
							. "Unique matches: " . _match.Count() . "`n" . matchedText . "`n`n"
							. "Number of captured subpatterns: " . m.Count() . "`n"
			Loop m.Count() 
				result.value .= "[" A_Index "]" . (m.Name(A_Index) ? " (" m.Name(A_Index) ")" : "") 	;if it has a name show it
				. " pos: " m.Pos(A_Index) . ", len: " m.Len(A_Index) " => " . m.value(A_Index) "`n"

			if m.Mark()	;untested, included for completeness sake
				result.value .= "Name of last encountered (*MARK:NAME): " m.Mark() "`n"
		}
		else result.value .= "No matches found.`n", text.text := text.text ;reset format
			
	;RegExMatch exceptions : straight from AutoHotkey documentation
	catch e 
		result.value := e.message != "PCRE execution error." ? e.message : 'PCRE execution error. (' e.extra ')`n`nLikely errors: "too many possible empty-string matches" (-22), "recursion too deep" (-21), and "reached match limit" (-8). If these happen, try to redesign the pattern to be more restrictive, such as replacing each * with a ?, +, or a limit like {0,3} wherever feasible.'
	
	;helper functions
	mySort(a, b) => StrLen(a) != StrLen(b) ? StrLen(a) - StrLen(b) : ((a > b) + !(a = b) - 1.5) * (a != b) * 2 ;sort by length then by alphabetical order
	qreplace(byref str, a, b) => str := StrReplace(str, a, b)	;by reference StrReplace wrapper
}

;helper class for adding gui tooltips
class gcToolTip {
	static gTT := {}
	Add(guictrl, tt, to := 4000) { ;gui, tooltip, timeout
		this.gTT.Count() == 0 && OnMessage(0x200, (param*) => this.WM_MOUSEMOVE(param*))
		this.gTT[guictrl.Hwnd] := {tooltip:tt, timeout:to}
	}
	WM_MOUSEMOVE(_, __, ___, Hwnd) {
		static PrevHwnd
		if (Hwnd != PrevHwnd)
			PrevHwnd := Hwnd, ToolTip(), this.gTT.HasKey(Hwnd) && ToolTip(this.gTT[Hwnd].tooltip)
	}
}
