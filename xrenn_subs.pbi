;=======================================================================================================================
; Добавить к массиву
; Нулевой элемент массива не используется!
Procedure.l AddArray(Array arr.s(1), text.s)
	Protected size.i = ArraySize(arr())+1
	ReDim arr(size)
	arr(size) = text
	ProcedureReturn size
EndProcedure
;=======================================================================================================================
;Procedure.i CreatePath(Directory.s)
;	ProcedureReturn Bool(SHCreateDirectory_(#Null, Directory.s) = #ERROR_SUCCESS )
;EndProcedure
;=======================================================================================================================
Procedure.i CompareLeft(s.s,t1.s,t2.s="",t3.s="",t4.s="")
	Protected l.i
	s = UCase(s)
	l = Len(t1)
	If l And Left(s,l)=UCase(t1)
		ProcedureReturn l+1
	EndIf
	l = Len(t2)
	If l And Left(s,l)=UCase(t2)
		ProcedureReturn l+1
	EndIf
	l = Len(t3)
	If l And Left(s,l)=UCase(t3)
		ProcedureReturn l+1
	EndIf
	l = Len(t4)
	If l And Left(s,l)=UCase(t4)
		ProcedureReturn l+1
	EndIf
EndProcedure
;=======================================================================================================================
Procedure.i CheckChdir(s.s)
	ProcedureReturn CompareLeft(s,"@PUSHD ","@CHDIR /D ","@CHDIR/D ")
;	s = UCase(s)
;	If Left(s,10) = "@CHDIR /D "
;		ProcedureReturn 11
;	EndIf
;	If Left(s,7) = "@PUSHD "
;		ProcedureReturn 8
;	EndIf
;	ProcedureReturn 0
EndProcedure
;=======================================================================================================================
Procedure.i UndoList(Array undos.s(1),dirname.s)
	Protected entry.s
	Protected dir = ExamineDirectory(#PB_Any,dirname,"*.xrenn")
	While NextDirectoryEntry(dir)
		entry = DirectoryEntryName(dir)
		If DirectoryEntryType(dir)=#PB_DirectoryEntry_File
			AddArray(undos(),entry)
		EndIf
	Wend
	FinishDirectory(dir)
	;undos(0) = dirname
	If ArraySize(undos())
		SortArray(undos(),#PB_Sort_Descending,1,ArraySize(undos()))
	EndIf
	ProcedureReturn ArraySize(undos())
EndProcedure
;=======================================================================================================================
Procedure.i SplitMask2(mask.s,Array masks.s(1),Array xmasks.s(1))
	Protected x.i, xmask.s
	x = FindString(mask,"\")
	If x
		xmask = Mid(mask,x+1)
		mask = Left(mask,x-1)
	EndIf
	x = FindString(mask,";")
	While x
		AddArray(masks(),Left(mask,x-1))
		mask = Mid(mask,x+1)
		x = FindString(mask,";")
	Wend
	If mask
		AddArray(masks(),mask)
	EndIf
	x = FindString(xmask,";")
	While x
		AddArray(xmasks(),Left(xmask,x-1))
		xmask = Mid(xmask,x+1)
		x = FindString(xmask,";")
	Wend
	If xmask
		AddArray(xmasks(),xmask)
	EndIf
	ProcedureReturn ArraySize(masks())
EndProcedure
;=======================================================================================================================
;Procedure Min(n1.i,n2.i)
;	If n1 < n2
;		ProcedureReturn n1
;	EndIf
;	ProcedureReturn n2
;EndProcedure
;=======================================================================================================================
Procedure.i ParamDelim(par.s)
	Protected i.i, c.s
	Protected n = Len(par)
	For i=1 To n
		c = Mid(par,i,1)
		If c=":" Or c="="
			ProcedureReturn i
		EndIf
	Next
	ProcedureReturn 0
EndProcedure
;=======================================================================================================================
Procedure.s ParamKey(par.s)
	Protected x = ParamDelim(par)
	If x : ProcedureReturn UCase(Left(par,x-1)) : EndIf
	ProcedureReturn UCase(par)
EndProcedure
;=======================================================================================================================
Procedure.s ParamVal(par.s)
	Protected x = ParamDelim(par)
	;If x : ProcedureReturn Trim(Mid(par,x+1),Chr(34)) : EndIf
	If x : ProcedureReturn Mid(par,x+1) : EndIf ; !!! Изменение: после GetParams кавычек быть не может.
	ProcedureReturn ""
EndProcedure
;=======================================================================================================================
; Blank Trim = удалить справа и слева пробельные символы
Procedure.s BTrim( f.s )
	Protected c.s
	c = Left(f,1)
	While c=#TAB$ Or c=" "
		f = Mid(f,2)
		c = Left(f,1)
	Wend
	c = Right(f,1)
	While c=#TAB$ Or c=" "
		f = Left(f,Len(f)-1)
		c = Right(f,1)
	Wend
	ProcedureReturn f
EndProcedure
;=======================================================================================================================
; Для обработки имён файлов.
; Quote Trim = BTrim + удаление всех кавычек.
Procedure.s QTrim( f.s )
	ProcedureReturn ReplaceString(BTrim(f),Chr(34),"")
EndProcedure
;=======================================================================================================================
; Для обработки имён файлов.
; File Trim = удалить пробелы в начале имени и точки и пробелы в конце имени
Procedure.s FTrim(f.s)
	Protected c.s
	c = Left(f,1)
	While c=" "
		f = Mid(f,2)
		c = Left(f,1)
	Wend
	c = Right(f,1)
	While c=" " Or c="."
		f = Left(f,Len(f)-1)
		c = Right(f,1)
	Wend
	ProcedureReturn f
EndProcedure
;=======================================================================================================================

; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 64
; FirstLine = 39
; Folding = --
; EnableXP
; DisableDebugger
; EnableExeConstant