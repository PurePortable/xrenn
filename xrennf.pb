;PP_SILENT
;RES_VERSION 5.21.0.0
;RES_COPYRIGHT (c) Smitis, 2010-2023
;RES_DESCRIPTION eXtended REName/reNum for folders
;RES_INTERNALNAME xrennf
;RES_ORIGINALFILENAME xrennf.exe
;RES_PRODUCTNAME Extended renamer/renumerator
;RES_PRODUCTVERSION 5.0.0.0
;RES_COMMENT PAM Project
;PP_FORMAT CONSOLE

;PP_X32_COPYAS "P:\PAM32\Cmd\xrennf.exe"
;PP_X64_COPYAS "P:\PAM\Cmd\xrennf.exe"

;PP_CLEAN 2

EnableExplicit
OpenConsole()

Define err.i, ret.i, x.i
Define exe.s = GetPathPart(ProgramFilename())+"xrenn.exe"
Define prm.s = PeekS(GetCommandLine_())
If Left(prm,1) = Chr(34)
	prm = Mid(prm,2)
	x = FindString(prm,Chr(34))
Else
	x = FindString(prm," ")
EndIf
If x
	prm = LTrim(Mid(prm,x+1))
Else
	prm = ""
EndIf

;PrintN(prm)

x = RunProgram(exe,"/f "+prm,"",#PB_Program_Open)
ret = WaitProgram(x)
ret = ProgramExitCode(x)
CloseProgram(x)
End ret

; IDE Options = PureBasic 6.04 LTS (Windows - x86)
; ExecutableFormat = Console
; Executable = xrennf.exe
; DisableDebugger
; EnableExeConstant
; IncludeVersionInfo
; VersionField0 = 5.21.0.0
; VersionField1 = 5.0.0.0
; VersionField3 = Extended renamer/renumerator
; VersionField4 = 5.0.0.0
; VersionField5 = 5.21.0.0
; VersionField6 = eXtended REName/reNum for folders
; VersionField7 = xrennf
; VersionField8 = xrennf.exe
; VersionField9 = (c) Smitis, 2010-2023
; VersionField18 = Comments
; VersionField21 = PAM Project
; EnableUnicode