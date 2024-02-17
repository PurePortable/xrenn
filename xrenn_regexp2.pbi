; RegExp 1.03
; https://ru.wikipedia.org/wiki/Регулярные_выражения

CompilerIf #PB_Compiler_IsMainFile
	EnableExplicit
	#REGEX_TEST = 1
	#REGEX_MATCHES = 1
	#REGEX_XREPLACE = 1
	#REGEX_XTEST = 1
CompilerEndIf

;=======================================================================================================================
CompilerIf Not Defined(REGEX_TEST,#PB_Constant)
	#REGEX_TEST     = 0 ; Компилировать процедуру RegexTest
CompilerEndIf
CompilerIf Not Defined(REGEX_MATCHES,#PB_Constant)
	#REGEX_MATCHES  = 0 ; Компилировать процедуру RegexMatches
CompilerEndIf
CompilerIf Not Defined(REGEX_XREPLACE,#PB_Constant)
	#REGEX_XREPLACE = 0 ; Компилировать процедуру XReplace
CompilerEndIf
CompilerIf Not Defined(REGEX_XTEST,#PB_Constant)
	#REGEX_XTEST    = 0 ; Компилировать процедуру XTest
CompilerEndIf

;=======================================================================================================================

ImportC ""
	;pb_pcre_exec(*pcre, *extra, subject.p-utf8, length, startoffset, options, *ovector, ovecsize)
	pb_pcre_exec(*pcre, *extra, *subject, length, startoffset, options, *ovector, ovecsize)
EndImport

Procedure.i RegexCreate( Pattern.s, IgnoreCase.l=#True )
	If IgnoreCase : IgnoreCase = #PB_RegularExpression_NoCase : EndIf
	ProcedureReturn CreateRegularExpression(#PB_Any, Pattern, IgnoreCase)
EndProcedure

Procedure RegexFree( Regex )
	FreeRegularExpression(Regex)
EndProcedure

Procedure.s RegexReplace( Regex, Subject.s, Replacement.s )
	Protected GroupNumber, GroupCount, MatchPos, Offset=1
	Protected Replacing.s, Result.s
	If ExamineRegularExpression(Regex,Subject)
		While NextRegularExpressionMatch(Regex)
			MatchPos = RegularExpressionMatchPosition(Regex)
			Replacing = ReplaceString(Replacement,"\0",RegularExpressionMatchString(Regex)) ; обратная ссылка \0
			GroupCount = CountRegularExpressionGroups(Regex)
			If GroupCount>9 : GroupCount=9 : EndIf ; только обратные ссылки \1 .. \9
			For GroupNumber=1 To GroupCount
				Replacing = ReplaceString(Replacing,"\"+Str(GroupNumber),RegularExpressionGroup(Regex,GroupNumber))
			Next
			For GroupNumber=GroupCount+1 To 9 ; отсутствующие группы на пустые строки
				Replacing = ReplaceString(Replacing,"\"+Str(GroupNumber),"")
			Next
			; Result + часть строки между началом и первым совпадением или между двумя совпадениями + результат подстановки групп
			Result + Mid(Subject,Offset,MatchPos-Offset) + Replacing
			Offset = MatchPos+RegularExpressionMatchLength(Regex)
		Wend
		ProcedureReturn Result + Mid(Subject,Offset) ; Result + остаток строки
	EndIf
	ProcedureReturn Subject ; без изменений
EndProcedure

CompilerIf #REGEX_TEST
	Procedure RegexTest( Regex, Subject.s )
		ProcedureReturn MatchRegularExpression(Regex,Subject)
	EndProcedure
CompilerEndIf

CompilerIf #REGEX_MATCHES
	Procedure.i RegexMatches( Regex, Subject.s, Array Matches.s(1), glob=#False )
		Protected Result = #False
		Protected Index, Count = 0
		Protected Size = ArraySize(Matches())
		If ExamineRegularExpression(Regex,Subject)
			If glob
				While NextRegularExpressionMatch(Regex)
					Result = #True
					Count + 1
					If Count > Size : Break : EndIf
					Matches(Count) = RegularExpressionMatchString(Regex)
				Wend
				Matches(0) = Subject
			ElseIf NextRegularExpressionMatch(Regex)
				Result = #True
				Count = CountRegularExpressionGroups(Regex)
				;PrintT("Matches: "+Str(Count))
				If Count > Size : Count = Size : EndIf
				For Index=1 To Count
					Matches(Index) = RegularExpressionGroup(Regex,Index)
				Next
				Matches(0) = RegularExpressionMatchString(Regex)
			EndIf
			For Index=Count+1 To Size
				Matches(Index) = ""
			Next
			ProcedureReturn Result
		EndIf
		For Index=0 To Size
			Matches(Index) = ""
		Next
		ProcedureReturn Result
	EndProcedure
CompilerEndIf
;=======================================================================================================================
; Процедуры для быстрого вызова
CompilerIf #REGEX_XREPLACE
	Procedure.s XReplace( str.s, pat.s, rpl.s )
		Protected r = RegexCreate(pat)
		If r
			str = RegexReplace(r,str,rpl)
			FreeRegularExpression(r)
		EndIf
		ProcedureReturn str
	EndProcedure
CompilerEndIf

CompilerIf #REGEX_XTEST
	Procedure.i XTest( str.s, pat.s )
		Protected r = RegexCreate(pat)
		Protected t = 0
		If r
			t = MatchRegularExpression(r,str)
			FreeRegularExpression(r)
		EndIf
		ProcedureReturn t
	EndProcedure
CompilerEndIf

;=======================================================================================================================

CompilerIf #PB_Compiler_IsMainFile
	Define rex, r.s, s.s, i
	Define Dim m.s(0)

	r = "(\d+)-(\d+)"
	s = "йцукенгшщзхъ-123-456-фывапролджэ-789-654-ячсмитьбю"
	rex = RegexCreate( r )
	Debug s
	;Debug RegexMatches( rex, s, m() )
	RegexMatches( rex, s, m(), #False )
	For i=0 To ArraySize(m())
		Debug Str(i)+": "+m(i)
	Next
CompilerEndIf

; IDE Options = PureBasic 5.51 (Windows - x86)
; CursorPosition = 77
; FirstLine = 66
; Folding = --
; Executable = Regexp.exe
; EnableExeConstant
; EnableUnicode