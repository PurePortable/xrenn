; FindNum 1.00

CompilerIf #PB_Compiler_IsMainFile
	EnableExplicit
CompilerEndIf

;=======================================================================================================================
Procedure.s FindNum(Array posnum(1),s.s,idx.i)
	Protected cnt.i, pos.i, c.s
	Protected i.i=1, j.i = Len(s)
	posnum(0) = 0
	posnum(1) = 0
	If idx=0 : ProcedureReturn "" : EndIf
	If idx<0
		While j>=1
			c = Mid(s,j,1)
			If c>="0" And c<="9"
				pos = j
				cnt-1
				j-1
				While j>=1
					c = Mid(s,j,1)
					If c<"0" Or c>"9"
						Break
					EndIf
					j-1
				Wend
				If cnt = idx
					posnum(0) = j+1
					posnum(1) = pos+1
					ProcedureReturn Mid(s,j+1,pos-j)
				EndIf
			Else
				j-1
			EndIf
		Wend
	Else
		While i<=j
			c = Mid(s,i,1)
			If c>="0" And c<="9"
				pos = i
				cnt+1
				i+1
				While i<=j
					c = Mid(s,i,1)
					If c<"0" Or c>"9"
						Break
					EndIf
					i+1
				Wend
				If cnt = idx
					posnum(0) = pos
					posnum(1) = i
					ProcedureReturn Mid(s,pos,i-pos)
				EndIf
			Else
				i+1
			EndIf
		Wend
	EndIf
	ProcedureReturn ""
EndProcedure
;=======================================================================================================================
Procedure.s GetNum(s.s,idx.i)
	Protected Dim posnum.i(1)
	ProcedureReturn FindNum(posnum(),s,idx)
EndProcedure
;=======================================================================================================================

CompilerIf #PB_Compiler_IsMainFile
	
	Define Dim pn.i(1), num.s
	Debug FindNum(pn(),"478qwerty566",-2)
	Debug Str(pn(0))+".."+Str(pn(1))
	Debug FindNum(pn(),"00",-1)
	Debug Str(pn(0))+".."+Str(pn(1))
	
CompilerEndIf

; IDE Options = PureBasic 5.73 LTS (Windows - x86)
; Folding = -
; EnableXP
; EnableExeConstant