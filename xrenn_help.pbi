;=======================================================================================================================
ImportC ""
	pb_pcre_version(void);
EndImport

#HELP_END = Chr(3)

Procedure Help()
	Protected.s t
	Restore HelpData
	Read.s t
	While t <> #HELP_END
		PrintN(t)
		Read.s t
	Wend
	PrintN("PCRE version: "+PeekS(pb_pcre_version(0),-1,#PB_Ascii)) ; http://www.purebasic.fr/english/viewtopic.php?p=495331#p495331
	End 0
EndProcedure
DataSection
	HelpData:
	Data.s "XRENN V."+#XRENN_VERSION+" "+#XRENN_COPYRIGHT
	Data.s "Using:"
	Data.s "  xrenn [options] [mask] pattern replace"
	Data.s "  - rename files and/or folders"
	Data.s "or"
	Data.s "  xrenn [options] [mask] pattern [/PF:prefix|/SF:suffix]"
	Data.s "  - add text for name files and/or folders"
	Data.s "or"
	Data.s "  xrenn [options] [mask] pattern [/C:folder|/M:folder]"
	Data.s "  - copy (/C) or move (/M) files to folder"
	Data.s "or"
	Data.s "  xrenn [options] [mask] pattern /D|/DR"
	Data.s "  - delete files (/D) or delete to recycle bin (/DR)"
	Data.s "or"
	Data.s "  xrenn [options] [[mask] pattern] /N|/NN:# [/A:#]"
	Data.s "  - renum and align numbers in files and/or folders name"
	Data.s "or"
	Data.s "  xrenn [options] [[mask] pattern] /N|/NN:+#|/N:-# [/A:#]"
	Data.s "  - add/subtract value to numbers in files and/or folders name"
	Data.s "or"
	Data.s "  xrenn [options] [[mask] pattern] /A:#"
	Data.s "  - align numbers in files and/or folders name"
	Data.s "or"
	Data.s "  xrenn /U:undofilename|/UL"
	Data.s "  - undo rename (/UL - use last undo file for current folder)"
	Data.s "where:"
	Data.s "  #       - decimal value"
	Data.s "  mask    - file masks separated by ';' character"
	Data.s "            samples:"
	Data.s "              *.jpg"
	Data.s "              *.doc;*.docx;readme.*"
	Data.s "  list    - file contain files and/or folders list"
	Data.s "  pattern - regular expression pattern"
	Data.s "  replace - regular expression replace"
;	Data.s "output options:"
	Data.s "  /Q      - quiet (no output, no pause)"
	Data.s "  /Q1     - without pause"
	Data.s "  /Q2     - output only result info without pause"
;	Data.s "select objects for rename and renum (align):"
	Data.s "  /F      - rename folders only (ignore if use list)"
	Data.s "            or"
	Data.s "  /FF     - rename folder and files (ignore if use list)"
	Data.s "            otherwise rename files only"
	Data.s "  /H      - rename hidden and system files and folders"
	Data.s "  /mask   - alternative mask definition (need contain symbols *?) or list"
	Data.s "  /L:list - file contain list files"
;	Data.s "regex options:"
	Data.s "  / or /B - match from begin (^)"
	Data.s "  /CS     - case sensifity"
	;Data.s "  /1      - only one match (otherwise all matches)"
;	Data.s "rename options:"
	Data.s "  /PF:$   - add prefix to name"
	Data.s "  /SF:$   - add suffix to name"
;	Data.s "renum/align options:"
	Data.s "  /I:#     - index number (default -1)"
	Data.s "  /STEP:#  - step numeration (default 1)"
;	Data.s "common options:"
	Data.s "  /Z-     - not process descriptions"
	Data.s "  /T      - testing regular expression without real renum, rename, copy, move or delete"
	Data.s "  /U-     - not create undo file"
	Data.s "  /UCD    - create hidden undo file in current folder (otherwise in temp folder)"
	Data.s #HELP_END
EndDataSection
;=======================================================================================================================

; IDE Options = PureBasic 5.73 LTS (Windows - x86)
; CursorPosition = 20
; FirstLine = 14
; Folding = -
; EnableXP
; EnableExeConstant