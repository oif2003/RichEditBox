/*
	Simple Regular Expression Tester for AutoHotkey v2 using RegExMatch()
	Tested with build: AutoHotkey_2.0-a100-52515e2
*/
#singleinstance force
#Include Class_RichEdit.ahk

;Default Values
	defaultText := 'History`n`n'
      . 'The first public beta of AutoHotkey was released on November 10, 2003[10] after author Chris Mallett`'s proposal to integrate hotkey support into AutoIt v2 failed to generate response from the AutoIt community.[11][12] So the author began his own program from scratch basing the syntax on AutoIt v2 and using AutoIt v3 for some commands and the compiler.[13] Later, AutoIt v3 switched from GPL to closed source because of "other projects repeatedly taking AutoIt code" and "setting themselves up as competitors."[14]`n`n'
      . 'In 2010, AutoHotkey v1.1 (originally called AutoHotkey_L) became the platform for ongoing development of AutoHotkey.[15] Another port of the program is AutoHotkey.dll.[16]`n`n'
      . 'https://en.wikipedia.org/wiki/AutoHotkey`n'

	defaultRegex := "A[^\s]*?y"
	defaultStartpos := 1
	width := 800
    bwidth := 200
	font := "Consolas"

;Gui Stuff
	gui := guiCreate()
	gui.SetFont(, font)
	
	;setup regex box
	gui.Add("Text", , "RegEx String:")
	regex := gui.Add("Edit", "-wrap r1 w" width, defaultRegex)
	
	;setup start position box
	gui.Add("Text", , "Start Position:")
	startpos := gui.Add("Edit", "-wrap r1 w" width, defaultStartpos)

	;setup text box
	gui.Add("Text", , "Text:")
    text := New RichEdit(gui, "r30 w" width, defaultText)

	;setup result box
	gui.Add("Text", , "Results:")
	result := gui.Add("Edit", "+readonly r15 w" width)
    
    ;test button
    button := gui.Add("Button", "w" bwidth " x" Width/2+gui.MarginX-bwidth/2 " Default", "Test RegEx")

	;Run doRegEx() whenever changes are detected
	button.OnEvent("Click", ()=>doRegEx())
    
	gui.show()
	
	;first run
	doRegEx()


;this function is called by RegExFunc in RichEdit for each match
onMatch(oRE, mt, sp, len) {
      oRE.SetSel(sp - 1, sp + len - 1)
      Font := {BkColor:"YELLOW"}
      oRE.SetFont(Font)
}

;sort by length then by alphabetical order
mySort(a, b) {
	lenA := StrLen(a), lenB := StrLen(b)
	if lenA > lenB
		return 1
	else if lenA < lenB
		return -1
	else
		if a > b
			return 1
		else if a < b
			return -1
		else
			return 0
}

;When values in regex, startpos, or text changes this function is triggered
doRegEx() {
	global gui, regex, text, result, startpos
	
	;reset the result box
	result.value := ""
	
	;force use of \ as escape character
	if InStr(regex.value, "``") {
		result.value .= "Must use \ (backslash) as escape character instead of `` (backtick)."
		return
	}
	
	;get startpos value
	if startpos.value == "" {
		spv := 1
	}
	else {
		spv := startpos.value
		if !(spv is "Integer") || spv == 0 {
			result.value .= "Start Position must be a non-zero integer. (Blank = 1)"
			return
		}
	}
	
	;attempt RegExMatch
	try {
		pos := RegExMatch(text.text, regex.value, m, spv)
		;match found
		if pos {
            
            ;save caret position
            sel := text.GetSel()
            ;reset highlight and dump formatting (highlights)
            text.text := text.text
            ;highlight matches (actual highlighting is done in onMatch())            
            match := text.RegExFunc(regex.value, (param*)=>onMatch(text, param*))
            matchCount := match.Count()
            ;restore caret position
            text.SetSel(sel.S, sel.E)
            
            ;sort matches by length then by alphabetical order.  remove duplicatess
            for k, v in match
                  matchedText .= (k==1 ? "" : chr(0x2DDF)) v 
            matchedText := Sort(matchedText, "U F mySort D" chr(0x2DDF))

            ;prepare matchedText
			_match := StrSplit(matchedText, chr(0x2DDF))
            matchedText := ""
            for k, v in _match {
                  _v := "`t" StrReplace(v, "`n", "`n`t")
                  matchedText .= (k==1 ? "" : "`n") "[" k "]`t" _v
            }
            
			;print results
			result.value .= "First match at: " pos "`n"
			result.value .= "Total matches : " matchCount "`n"
			result.value .= "Unique matches: " _match.Count() "`n"
			result.value .= matchedText "`n`n"
			result.value .= "Number of captured subpatterns: " m.Count() "`n"
			numDigits := floor(log(m.count())) + 1		;get number of digits of m.count()
			Loop m.Count() {
				nameStr := m.Name(A_Index) ? " (" m.Name(A_Index) ")" : ""
				result.value .= "[" format("{:0" numDigits "}", A_Index) "]" nameStr 
								. " pos: " m.Pos(A_Index)
								. ", len: " m.Len(A_Index) " => "
				result.value .=  m.value(A_Index) "`n"
			}
			
			;untested, included for completeness sake
			if m.Mark()
				result.value .= "Name of last encountered (*MARK:NAME): " m.Mark() "`n"
		}
		;no matches
		else {
			result.value .= "No matches found.`n"
            
            ;reset format
            text.text := text.text
		}
	}
	;RegExMatch exceptions : straight from AutoHotkey documentation
	catch e {
		result.value .= e.message 
		if e.message == "PCRE execution error." {
			result.value .= " (" e.extra ")`n"
			result.value .= '`nLikely errors: "too many possible empty-string matches" (-22), "recursion too deep" (-21), and "reached match limit" (-8). If these happen, try to redesign the pattern to be more restrictive, such as replacing each * with a ?, +, or a limit like {0,3} wherever feasible.'
		}
	}
}