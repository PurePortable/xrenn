; System 1.03

;http://www.vsokovikov.narod.ru/New_MSDN_API/Menage_files/fn_io_flm.htm
;http://www.vsokovikov.narod.ru/New_MSDN_API/Menage_files/fn_setfilepointer.htm
;http://www.vsokovikov.narod.ru/New_MSDN_API/Menage_files/fn_setendoffile.htm
;http://www.vsokovikov.narod.ru/New_MSDN_API/Menage_files/fn_setfileattributes.htm
;http://www.vsokovikov.narod.ru/New_MSDN_API/Menage_files/fn_copyfileex.htm
;http://www.vsokovikov.narod.ru/New_MSDN_API/Menage_files/fn_movefile.htm
;EnableExplicit

; SetFileTime
; https://msdn.microsoft.com/en-us/library/windows/desktop/ms724933%28v=vs.85%29.aspx

; File Management Functions
; https://msdn.microsoft.com/en-us/library/windows/desktop/aa364232%28v=vs.85%29.aspx

;=======================================================================================================================

; DWORD WINAPI GetLongPathName(
; _In_  LPCTSTR lpszShortPath,
; _Out_ LPTSTR  lpszLongPath,
; _In_  DWORD   cchBuffer

;=======================================================================================================================
; https://msdn.microsoft.com/library/bb773727
; BOOL PathMatchSpecW( _In_ LPCSTR pszFile, _In_ LPCSTR pszSpec )
; BOOL WINAPI SymMatchString( _In_ PCTSTR string, _In_ PCTSTR expression, _In_ BOOL   fCase ) https://msdn.microsoft.com/library/ms681355
Procedure FileMatch(file.s,mask.s)
	ProcedureReturn PathMatchSpec_(file,mask)
EndProcedure
Procedure FileMatches(file.s,Array masks.s(1))
	Protected i, n = ArraySize(masks())
	For i=1 To n
		If PathMatchSpec_(file,masks(i))
			ProcedureReturn #True
		EndIf
	Next
	ProcedureReturn #False
EndProcedure
Procedure FileMatches2(file.s,Array masks.s(1),Array xmasks.s(1))
	Protected i, n
	n = ArraySize(xmasks())
	For i=1 To n
		If PathMatchSpec_(file,xmasks(i))
			ProcedureReturn #False
		EndIf
	Next
	n = ArraySize(masks())
	For i=1 To n
		If PathMatchSpec_(file,masks(i))
			ProcedureReturn #True
		EndIf
	Next
	ProcedureReturn #False
EndProcedure
;=======================================================================================================================
; https://msdn.microsoft.com/en-us/library/windows/desktop/aa364963%28v=vs.85%29.aspx
Procedure.s GetFullPathName( fn.s )
	Protected size.i = GetFullPathName_(@fn,0,#Null,#Null)
	Protected buf.s = Space(size)
	GetFullPathName_(fn,size,buf,#Null)
	;PrintN("LENBUF: "+Str(size))
	;PrintN("<"+buf+">")
	ProcedureReturn buf
EndProcedure
;=======================================================================================================================
CompilerIf Not Defined(AddBackSlash,#PB_Procedure)
	; Добавить один символ "\" в конец пути
	Procedure.s AddBackSlash(f.s)
		ProcedureReturn RTrim(f,"\")+"\"
	EndProcedure
CompilerEndIf

;=======================================================================================================================
CompilerIf Not Defined(DelBackSlash,#PB_Procedure)
	; Убрать символы "\" в конце пути
	Procedure.s DelBackSlash(f.s)
		ProcedureReturn RTrim(f,"\")
	EndProcedure
CompilerEndIf

;=======================================================================================================================
Enumeration
	#FILEOP_NONE      = 0
	#FILEOP_WINAPI    = $10000
	#FILEOP_SHFO      = $20000
	#FILEOP_NOTPB     = #FILEOP_WINAPI | #FILEOP_SHFO
	#FILEOP_UNCNAME   = $40000
	#FILEOP_OVERWRITE = #FOF_RENAMEONCOLLISION
	#FILEOP_RECYCLE   = #FOF_ALLOWUNDO
EndEnumeration

;=======================================================================================================================
; http://www.vsokovikov.narod.ru/New_MSDN_API/Menage_files/fn_getfileattributes.htm
; Сброс атрибутов FILE_ATTRIBUTE_HIDDEN, FILE_ATTRIBUTE_SYSTEM и FILE_ATTRIBUTE_READONLY
; TODO: автоматически добавлять \\?\
; TODO: если ошибка чтения атрибутов - выход (?)
#ATTRIBUTES_NORM = ~#FILE_ATTRIBUTE_HIDDEN | ~#FILE_ATTRIBUTE_SYSTEM | ~#FILE_ATTRIBUTE_READONLY
Procedure FileAttribNorm(src.s)
	Protected attr = GetFileAttributes_(src)
	attr & #ATTRIBUTES_NORM
	ProcedureReturn SetFileAttributes_(src,attr)
EndProcedure

;=======================================================================================================================
; TODO: автоматически добавлять \\?\
Procedure PathCreate(path.s)
	; CreateDirectory_(path,#Null)
EndProcedure

;=======================================================================================================================

Procedure.i FileCopy(src.s,dst.s,ovr=#False)
	Protected rt = #False
	If FileSize(dst)<0 Or ovr
		FileAttribNorm(dst)
		rt = CopyFile(src,dst)
	EndIf
	ProcedureReturn rt
EndProcedure

;=======================================================================================================================
Procedure.i FileMove(src.s,dst.s,ovr=#False)
	Protected rt = #False
	If FileSize(dst)<0 Or ovr
		FileAttribNorm(dst)
		rt = RenameFile(src,dst)
	EndIf
	ProcedureReturn rt
EndProcedure

;=======================================================================================================================
Procedure.i FileRename(src.s,dst.s,ovr=#False)
	Protected rt = #False
	If FileSize(dst)<0 Or ovr
		;FileAttribNorm(dst)
		rt = RenameFile(src,dst)
	EndIf
	ProcedureReturn rt
EndProcedure

;=======================================================================================================================
Procedure.i FileDelete(src.s)
	Protected rt = #False
	;FileAttribNorm(src)
	rt = DeleteFile(src)
	ProcedureReturn rt
EndProcedure

;=======================================================================================================================
Procedure.i FileRecycle(src.s)
	Protected rt = #False
	;FileAttribNorm(dst)
	rt = DeleteFile(src)
	ProcedureReturn rt
EndProcedure

;=======================================================================================================================
Procedure.i FileCase(src.s,cs.s="",delims.s="")
	Protected rt = #True
	Protected n.s = GetFilePart(src,#PB_FileSystem_NoExtension)
	Protected e.s = GetExtensionPart(src)
	Protected i, l, dst.s
	If cs="" : cs="LL" : EndIf
	If delims="" : delims=" _!-.,;#$" : EndIf
	Select Left(cs,1)
		Case "L","l" ; lower case
			n = LCase(n)
		Case "U","u" ; UPPER CASE
			n = UCase(n)
		Case "F","f" ; First capital
			n = UCase(Left(n,1))+LCase(Mid(n,2))
		Case "T","C","t","c" ; Title Case (Camel Case)
			dst = UCase(Left(n,1))
			l = Len(n)
			n = LCase(n)
			For i=2 To l
				If FindString(delims,Mid(n,i-1,1))
					dst+UCase(Mid(n,i,1))
				Else
					dst+Mid(n,i,1)
				EndIf
			Next
			n = dst
		;Case "N"     ; None
	EndSelect
	Select Mid(cs,2,1)
		Case "L","l" ; lower case
			e = LCase(e)
		Case "U","u" ; UPPER CASE
			e = UCase(e)
		Case "F","f" ; First capital
			e = UCase(Left(e,1))+LCase(Mid(e,2))
		Case "T","C","t","c" ; Title Case (Camel Case)
			dst = UCase(Left(e,1))
			l = Len(e)
			e = LCase(e)
			For i=2 To l
				If FindString(delims,Mid(e,i-1,1))
					dst+UCase(Mid(e,i,1))
				Else
					dst+Mid(e,i,1)
				EndIf
			Next
			e = dst
		;Case "N","n" ; None		
	EndSelect
	dst = GetPathPart(src)+n+"."+e
	If src<>dst
		rt = RenameFile(src,dst)
	EndIf
	ProcedureReturn rt
EndProcedure
;=======================================================================================================================
Procedure IsFolder(fold.s)
	ProcedureReturn Bool(FileSize(fold)<>-2)
EndProcedure
;=======================================================================================================================
Procedure DeleteFileToRecycleBin(file.s)
	;Protected result
	;Protected ptrFile = AllocateMemory(StringByteLength(file)+2)
	;PokeS(ptrFile,file)
	Protected SHFileOp.SHFILEOPSTRUCT
	;SHFileOp\pFrom = ptrFile
	SHFileOp\pFrom = @file
	SHFileOp\pTo = #Null
	SHFileOp\wFunc = #FO_DELETE
	SHFileOp\fFlags = #FOF_ALLOWUNDO | #FOF_NOCONFIRMATION | #FOF_SILENT
	;result = Bool(SHFileOperation_(@SHFileOp) = 0)
	;FreeMemory(ptrFile)
	ProcedureReturn Bool(SHFileOperation_(@SHFileOp)=0)
EndProcedure
;=======================================================================================================================
; http://w32api.narod.ru/functions/GetFullPathName.html
; http://msdn.microsoft.com/en-us/library/windows/desktop/aa364963%28v=vs.85%29.aspx
; http://msdn.microsoft.com/en-us/library/aa364232(v=VS.85).aspx
Procedure.s GetFullPath(fn.s)
	Protected len = GetFullPathName_(@fn,0,#Null,#Null)
	Protected buf = AllocateMemory(len*SizeOf(Character))
	GetFullPathName_(fn,len,buf,#Null)
	fn = PeekS(buf)
	FreeMemory(buf)
	ProcedureReturn fn
EndProcedure
;=======================================================================================================================
Procedure.s GetNamePart(f.s)
	Protected ext.s, file.s
	file = GetFilePart(f)
	ext = GetExtensionPart(file)
	If file = ext Or ext = "" ; Имя типа .xxxxx или без расширения
		ProcedureReturn file
	EndIf
	ProcedureReturn Left(file,Len(file)-Len(ext)-1)
EndProcedure
;=======================================================================================================================
Procedure.s GetExtPart(f.s)
	Protected ext.s, file.s
	file = GetFilePart(f)
	ext = GetExtensionPart(file)
	If file = ext Or ext = "" ; Имя типа .xxxxx или без расширения
		ProcedureReturn ""
	EndIf
	ProcedureReturn "."+ext
EndProcedure
;=======================================================================================================================
CompilerIf Not Defined(AddBackSlash,#PB_Procedure)
	; Добавить один символ "\" в конец пути
	Procedure.s AddBackSlash(f.s)
		ProcedureReturn RTrim(f,"\")+"\"
	EndProcedure
CompilerEndIf
;=======================================================================================================================
CompilerIf Not Defined(DelBackSlash,#PB_Procedure)
	; Убрать символы "\" в конце пути
	Procedure.s DelBackSlash(f.s)
		ProcedureReturn RTrim(f,"\")
	EndProcedure
CompilerEndIf
;=======================================================================================================================
Procedure.s AddPath(path.s,name.s)
	If path
		If name
			ProcedureReturn AddBackSlash(path)+AddBackSlash(name)
		EndIf
		ProcedureReturn AddBackSlash(path)
	EndIf
	ProcedureReturn AddBackSlash(name)
EndProcedure
;=======================================================================================================================
Procedure.s DelPath(path.s)
	If path
		ProcedureReturn GetPathPart(DelBackSlash(path)) ; ??? что даст в корне?
	EndIf
	ProcedureReturn ""
EndProcedure
;=======================================================================================================================

#KEY_WOW64_64KEY = $100
#KEY_WOW64_32KEY = $200

;;----------------------------------------------------------------------------------------------------------------------
; Функции для проверки разрядности Windows
;Prototype IsWow64Process(hProcess,*Wow64Process)
;Prototype Wow64DisableWow64FsRedirection(*OldValue)
;Prototype Wow64RevertWow64FsRedirection(*OldValue)
;Global kernel = OpenLibrary(#PB_Any,"Kernel32.dll")
;Global IsWow64Process_.IsWow64Process = GetFunction(kernel,"IsWow64Process")
;Global Wow64DisableWow64FsRedirection_.Wow64DisableWow64FsRedirection = GetFunction(kernel,"Wow64DisableWow64FsRedirection")
;;Global Wow64RevertWow64FsRedirection_.Wow64RevertWow64FsRedirection = GetFunction(kernel,"Wow64RevertWow64FsRedirection")
;;----------------------------------------------------------------------------------------------------------------------
;Procedure IsWindows64bit()
;	Protected IsWow64ProcessFlag, result = #False
;	If IsWow64Process_
;		IsWow64Process_(GetCurrentProcess_(),@IsWow64ProcessFlag)
;		result = Bool(IsWow64ProcessFlag <> 0)
;	EndIf
;	ProcedureReturn result
;EndProcedure
;Procedure DisableWow64()
;	; http://www.purebasic.fr/english/viewtopic.php?f=12&t=58681
;	Protected IsWow64ProcessFlag, Wow64OldValue
;	If IsWow64Process_ And Wow64DisableWow64FsRedirection_
;		IsWow64Process_(GetCurrentProcess_(),@IsWow64ProcessFlag)
;		If IsWow64ProcessFlag <> 0 ;And SizeOf(Integer) = 4
;			Wow64DisableWow64FsRedirection_(@Wow64OldValue)
;		EndIf
;	EndIf
;EndProcedure
;DisableWow64()
;=======================================================================================================================

; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 328
; FirstLine = 294
; Folding = ----
; EnableAsm
; EnableXP
; EnableExeConstant
; EnableUnicode