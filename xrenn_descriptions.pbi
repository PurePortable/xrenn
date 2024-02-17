;========================================================================================================================
; Descriptions - модуль для работы с описаниями
; (C) Smitis, 2014-2019
; v.1.08
;========================================================================================================================

; TODO:
; - #DESCRIPTIONS_SAVE и т.п.
; - DescrSave - параметр ChangedOnly - сохранять только при изменении

CompilerIf #PB_Compiler_IsMainFile
	EnableExplicit
CompilerEndIf

CompilerIf Not Defined(DESCRIPTIONS_LOG,#PB_Constant) ; Создавать лог во временной папке description.log
	#DESCRIPTIONS_LOG = 0
CompilerEndIf
CompilerIf Not Defined(DESCRIPTIONS_APP,#PB_Constant) ; Название приложение для лога
	#DESCRIPTIONS_APP = "DESCRIPTION.EXE"
CompilerEndIf
CompilerIf Not Defined(DESCRIPTIONS_RELOAD,#PB_Constant) ; Компилоровать функцию DescrReload
	#DESCRIPTIONS_RELOAD = 0
CompilerEndIf
CompilerIf Not Defined(DESCRIPTIONS_UNC,#PB_Constant) ; ???
	#DESCRIPTIONS_UNC = 1
CompilerEndIf

Structure Description
	Key.s
	Name.s
	Text.s
EndStructure

;========================================================================================================================
Declare.s DescrFileName(fn.s="")
Declare.i DescrLoad( Array d.Description(1), descr_filename.s="", chk_path=#False )
Declare.i DescrSave( Array d.Description(1), cp.i=#PB_UTF8 )
Declare.s DescrDel( Array d.Description(1), name.s )
Declare.s DescrGet( Array d.Description(1), name.s )
Declare.s DescrSet( Array d.Description(1), name.s, text.s )
Declare.s DescrAdd( Array d.Description(1), name.s, text.s )
Declare.s DescrRen( Array d.Description(1), name1.s, name2.s="" )
Declare DescrChg(Array d.Description(1),changed=#True)
;========================================================================================================================

;Global.s DescrQuotes = Chr(34)
;Global.i DescrError = 0

;========================================================================================================================
CompilerIf #DESCRIPTIONS_RELOAD
	Procedure.i DescrReload( Array descr.Description(1) )
		descr(0)\Text = "" ; отмена изменений
		ProcedureReturn DescrLoad(descr(),descr(0)\Name)
	EndProcedure
CompilerEndIf

;========================================================================================================================
CompilerIf #DESCRIPTIONS_LOG
	Procedure.s DescrErrorText(err,op.s,diz.s="")
		Protected errtext.s = ""
		Protected buf_size = 1024
		Protected *buf
		;If err<>#ERROR_SHARING_VIOLATION And err<>#ERROR_LOCK_VIOLATION
		*buf = AllocateMemory(buf_size*SizeOf(Character))
		FormatMessage_(#FORMAT_MESSAGE_FROM_SYSTEM,#Null,err,0,*buf,buf_size,#Null)
		errtext = FormatDate("%yyyy-%mm-%dd %hh-%ii-%ss",Date()) + " " + #DESCRIPTIONS_APP + " / " + op + #CRLF$
		errtext + "ERROR: "+Str(err)+" "+PeekS(*buf)
		errtext + "DIR: " + GetCurrentDirectory() + #CRLF$
		If diz
			errtext + "FILE: " + diz + #CRLF$
		EndIf
		FreeMemory(*buf)
		;EndIf
		ProcedureReturn errtext
	EndProcedure

	Procedure DescrWriteLog(errtext.s)
		Protected log_h, log_name.s
		If errtext
			log_name = GetEnvironmentVariable("TEMP")
			If Right(log_name,1)<>"\" : log_name+"\" : EndIf
			log_name + "description.log"
			log_h = OpenFile(#PB_Any,log_name,#PB_File_Append)
			If log_h
				If Loc(log_h)=0 : WriteStringFormat(log_h,#PB_UTF8) : EndIf
				WriteStringN(log_h,errtext,#PB_UTF8)
				CloseFile(log_h)
			EndIf
		EndIf
	EndProcedure
CompilerElse
	Macro DescrErrorText(a,b,c)
	EndMacro
	Macro DescrWriteLog(a)
	EndMacro
CompilerEndIf

;========================================================================================================================
; Обработка имени файла описаний
Procedure.s DescrFileName(fn.s="")
	If fn = ""
		fn = "descript.ion"
	ElseIf Right(fn,1) = "\" ; папка
		fn + "descript.ion"
	EndIf
	If FindString(fn,"\")=0 ; если не содержит путь
		fn = GetCurrentDirectory()+fn
	EndIf
	;PrintT("(1) "+fn)
	;If Left(fn,1) <> ":" And Left(fn,2) <> "\\"
	;	If Left(fn,1) = "\" ; корень диска
	;		fn = Left(GetCurrentDirectory(),2)+fn
	;	Else
	;		fn = GetCurrentDirectory()+fn
	;	EndIf
	;EndIf
	;PrintT("(2) "+fn)
	Protected size.i = GetFullPathName_(@fn,0,#Null,#Null)
	Protected buf.s = Space(size)
	GetFullPathName_(@fn,size,@buf,#Null)
	;CompilerIf #DESCRIPTIONS_UNC
	;	fn = "\\?\"+LCase(buf)
	;CompilerElse
	;	fn = LCase(buf)
	;CompilerEndIf
	;PrintN(buf)
	ProcedureReturn PeekS(@buf)
EndProcedure

;========================================================================================================================
Procedure.i DescrLoad(Array descr.Description(1),descr_filename.s="",chk_path=#False)
	Protected x
	Protected descr_codepage=#PB_UTF8, descr_size, descr_h
	Protected name.s, text.s
	Protected rpt, err, errtext.s
	
	descr_filename = DescrFileName(descr_filename) ; полный путь к файлу описаний
	DescrWriteLog(descr_filename)
	DescrSave(descr()) ; сохранение возможных изменений в предыдущих описаниях
	Dim descr(0) ; обнуление массива описаний
	descr(0)\Name = LCase(descr_filename)
	descr(0)\Text = "" ; no change
	descr(0)\Key = Str(descr_codepage) ; codepage

	Repeat ; делаем несколько попыток открыть файл описаний, на случай, если он залочен
		descr_h = ReadFile(#PB_Any,descr_filename,#PB_File_SharedRead)
		If descr_h : Break : EndIf ; Успешно
		err = GetLastError_()
		If err=#ERROR_FILE_NOT_FOUND
			; Нет файла, будет пустой массив описаний
			ProcedureReturn descr_codepage
		EndIf
		CompilerIf #DESCRIPTIONS_LOG
			If err And errtext=""
				errtext = DescrErrorText(err,"LOAD",descr_filename)
			EndIf
		CompilerEndIf
		rpt+1
		If (err<>#ERROR_SHARING_VIOLATION And err<>#ERROR_LOCK_VIOLATION) Or rpt>=10
			; Цикл будет продолжен в том случае, если файл залочен и повторов было меньше заданного
			; Иначе - выход с ошибкой в errtext
			Break
		EndIf
		Delay(5)
	ForEver
	CompilerIf #DESCRIPTIONS_LOG
		DescrWriteLog(errtext)
	CompilerEndIf
	If descr_h
		descr_codepage = ReadStringFormat(descr_h)
		While Eof(descr_h) = 0
			text = Trim(ReadString(descr_h,descr_codepage))
			If Left(text,1) = Chr(34)
				x = FindString(text,Chr(34),2)
				If x
					name = Mid(text,2,x-2)
					text = Trim(Mid(text,x+1))
				Else
					name = Mid(text,2)
					text = ""
				EndIf
			Else
				x = FindString(text," ")
				If x
					name = Left(text,x-1)
					text = Trim(Mid(text,x+1))
				Else
					name = text
					text = ""
				EndIf
			EndIf
			;PrintN("Read: "+Chr(34)+descr_name+Chr(34)+" = "+Chr(34)+descr_text+Chr(34))
			If name And text ; <> "" ???
				descr_size = ArraySize(descr())+1
				ReDim descr(descr_size)
				descr(descr_size)\Key = UCase(name)
				descr(descr_size)\Name = name
				descr(descr_size)\Text = text
			EndIf
		Wend
		CloseFile(descr_h)
	EndIf
	ProcedureReturn descr_codepage
EndProcedure

;========================================================================================================================
Procedure.i DescrSave(Array descr.Description(1),cp.i=#PB_UTF8)
	Protected i
	Protected descr_cnt, descr_size=ArraySize(descr()), descr_h, descr_codepage=#PB_UTF8, descr_attributes
	Protected descr_filename.s = descr(0)\Name
	Protected name.s, text.s
	Protected rpt, err, errtext.s
	If descr(0)\Text=""
		; Не было изменений
		ProcedureReturn
	EndIf
	If descr(0)\Name = "" ; Новый файл
		descr(0)\Name = DescrFileName()
		descr(0)\Key = Str(cp)
		;descr(0)\Text = ""
		descr_filename = descr(0)\Name
	EndIf
	If cp <> 0
		descr_codepage = cp
	Else
		descr_codepage = Val(descr(0)\Key)
	EndIf
	descr_attributes = GetFileAttributes(descr_filename)
	If descr_attributes = -1
		descr_attributes = 0
	Else
		; Если файл отсутствовал, кодовая страница по умолчанию
		descr_codepage = cp
		descr(0)\Key = Str(cp)
	EndIf
	Repeat
		descr_h = CreateFile(#PB_Any,descr_filename,#PB_File_SharedRead)
		If descr_h : Break : EndIf ; Успешно
		err = GetLastError_()
		CompilerIf #DESCRIPTIONS_LOG
			If err And errtext=""
				errtext = DescrErrorText(err,"SAVE",descr_filename)
			EndIf
		CompilerEndIf
		rpt+1
		If (err<>#ERROR_SHARING_VIOLATION And err<>#ERROR_LOCK_VIOLATION) Or rpt>=10
			; Цикл будет продолжен в том случае, если файл залочен и повторов было меньше заданного
			; Иначе - выход с ошибкой в errtext
			Break
		EndIf
		Delay(5)
	ForEver
	CompilerIf #DESCRIPTIONS_LOG
		DescrWriteLog(errtext)
	CompilerEndIf
	If descr_h
		WriteStringFormat(descr_h,descr_codepage)
		For i=1 To descr_size
			name = descr(i)\Name
			text = descr(i)\Text
			If name And text
				If FindString(name," ") > 0
					name = Chr(34) + name + Chr(34)
				EndIf
				WriteStringN(descr_h,name+" "+text,descr_codepage)
				descr_cnt+1
			EndIf
		Next
	EndIf
	CloseFile(descr_h)
	SetFileAttributes(descr_filename,descr_attributes|#PB_FileSystem_Hidden|#PB_FileSystem_Archive)
	If descr_cnt = 0 ; Ничего не записалось, файл пустой, удаляем
		DeleteFile(descr_filename,#PB_FileSystem_Force)
	EndIf
	descr(0)\Text = ""
EndProcedure

;========================================================================================================================
Procedure.s DescrGet(Array descr.Description(1),name.s)
	Protected i, descr_size = ArraySize(descr())
	Protected key.s = UCase(name)
	For i=1 To descr_size
		If descr(i)\Key = key
			ProcedureReturn descr(i)\Text
		EndIf
	Next
	ProcedureReturn ""
EndProcedure

;========================================================================================================================
; Удаляем name, в том числе и дубликаты.
; Возвращаем первое значение.
Procedure.s DescrDel(Array descr.Description(1),name.s)
	Protected i, descr_size = ArraySize(descr())
	Protected key.s = UCase(name)
	Protected prev.s = ""
	;PrintN("Del: "+Chr(34)+name+Chr(34))
	For i=descr_size To 1 Step -1
		If descr(i)\Key = key
			prev = descr(i)\Text
			descr(i)\Key = ""
			descr(i)\Name = ""
			descr(i)\Text = ""
			descr(0)\Text = "1"
		EndIf
	Next
	ProcedureReturn prev
EndProcedure

;========================================================================================================================
Procedure.s DescrSet(Array descr.Description(1),name.s,text.s)
	Protected i, descr_size = ArraySize(descr())
	Protected key.s = UCase(name)
	Protected prev.s
	descr(0)\Text = "1"
	For i=1 To descr_size
		If descr(i)\Key = key
			prev = descr(i)\Text
			descr(i)\Name = name ; на случай изменения регистра
			descr(i)\Text = text
			;PrintN("Set: "+Chr(34)+name+Chr(34)+" = "+Chr(34)+text+Chr(34))
			ProcedureReturn prev
		EndIf
	Next
	descr_size+1
	ReDim descr(descr_size)
	descr(descr_size)\Key = key
	descr(descr_size)\Name = name
	descr(descr_size)\Text = text
	;PrintN("New: "+Chr(34)+name+Chr(34)+" = "+Chr(34)+text+Chr(34))
	ProcedureReturn ""
EndProcedure

;========================================================================================================================
Procedure.s DescrAdd(Array descr.Description(1),name.s,text.s)
	Protected i, descr_size = ArraySize(descr())
	Protected key.s = UCase(name)
	Protected prev.s
	descr(0)\Text = "1"
	descr_size + 1
	ReDim descr(descr_size)
	descr(descr_size)\Key = key
	descr(descr_size)\Name = name
	descr(descr_size)\Text = text
	ProcedureReturn ""
EndProcedure

;========================================================================================================================
; При пустом name2 - удаление.
; Возвращается найденое описание для name1 (name2 не используем!).
Procedure.s DescrRen(Array descr.Description(1),name1.s,name2.s="")
	Protected text.s
	If name1
		;ADescrDel(descr(),name2) ; ???
		text = DescrDel(descr(),name1)
		If text
			DescrSet(descr(),name2,text)
		EndIf
	EndIf
	ProcedureReturn text
EndProcedure

;========================================================================================================================
; Управление флагом "изменено"
Procedure DescrChg(Array descr.Description(1),changed=#True)
	If changed
		descr(0)\Text = "1"
	Else
		descr(0)\Text = ""
	EndIf
EndProcedure

;========================================================================================================================

; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 126
; FirstLine = 102
; Folding = ---
; EnableXP
; DisableDebugger
; EnableExeConstant