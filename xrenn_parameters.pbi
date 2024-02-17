;========================================================================================================================
; Parameters 1.06.00
;========================================================================================================================
; DO:
; - PErrorMessage == CheckParamMessage
; - Check limit
; - Check date/time
; - CheckParamQuantity

;========================================================================================================================
; Проверка десятичных чисел
Enumeration IsDecimalSignEnum 0 ; какие знаки (+ и -) разрешены перед числом
	#ISDECSIGN_NONE
	#ISDECSIGN_BOTH
	#ISDECSIGN_PLUS
	#ISDECSIGN_MINUS
EndEnumeration

Global IsDecimalSignDefault.i = #ISDECSIGN_NONE

Procedure.i IsDecimal(s.s,sign.i=-1)
	Protected c.s = Left(s,1)
	Protected i.i, pos.i=1, n.i=Len(s)
	If sign < 0
		sign = IsDecimalSignDefault
	EndIf
	Select sign
		Case #ISDECSIGN_BOTH
			If c="-" Or c="+" ; разрешён любой знак
				pos=2
			EndIf
		Case #ISDECSIGN_PLUS
			If c="+" ; разрешён знак плюс
				pos=2
			EndIf
		Case #ISDECSIGN_MINUS
			If c="-" ; разрешён знак минус
				pos=2
			EndIf
	EndSelect
	If pos>n : ProcedureReturn #False : EndIf
	While pos<=n
		c = Mid(s,pos,1)
		If c<"0" Or c>"9"
			ProcedureReturn #False
		EndIf
		pos+1
	Wend
	ProcedureReturn #True
EndProcedure
;========================================================================================================================

; Конфигурация
CompilerIf Not Defined(PARAMS_DATETIME,#PB_Constant)
	#PARAMS_DATETIME = 0 ; Компилировать процедуры проверки даты/времени
CompilerEndIf
CompilerIf Not Defined(PARAMS_CODEPAGE,#PB_Constant)
	#PARAMS_CODEPAGE = 0 ; Компилировать процедуры проверки кодовой страницы
CompilerEndIf
CompilerIf Not Defined(PARAMS_SLASH,#PB_Constant)
	#PARAMS_SLASH = 1 ; Считать символ "/" разделителем параметров или нет.
CompilerEndIf
CompilerIf Not Defined(PARAMS_SPLIT,#PB_Constant)
	#PARAMS_SPLIT = 1 ; Компилировать SplitParam
CompilerEndIf
CompilerIf Not Defined(PARAMS_CHECK,#PB_Constant)
	#PARAMS_CHECK = 1 ; Компилировать процедуры проверки параметров и сообщения
CompilerEndIf
CompilerIf Not Defined(PARAMS_RANGE,#PB_Constant)
	#PARAMS_RANGE = 1 ; Для проверки диапазонов ##:##
CompilerEndIf

Structure ParamType
	raw.s ; как прочиталось
	key.s
	ukey.s
	value.s
	num.i
	limit.i ; второе число
	delim.i	; есть разделитель ":" или "=", значение в value
	decimal.i ; value содержит правильное десятичное число, значение в num
	range.i ; значение имеет вид число:число, значения в num и limit
EndStructure

;========================================================================================================================
; Получение командной строки, переданной программе при запуске
Procedure.s GetCmdLine(slash=#PARAMS_SLASH)
	Protected c.s, n.i, i.i
	Protected cmdline.s = PeekS(GetCommandLine_())
	; В начале всегда имя исполняемого файла, возможно, в кавычках
	; Отделяем программу от параметров
	If Left(cmdline,1) = Chr(34) ; программа в кавычках
		i = FindString(cmdline,Chr(34),2)
		If i ; полностью в кавычках
			cmdline = Mid(cmdline,i+1)
		Else ; не закрытые кавычки
			cmdline = ""
		EndIf
	Else ; программа отделена пробелом, табуляцией или "/"
		n = Len(cmdline)
		i = 1
		While i <= n
			c = Mid(cmdline,i,1)
			If c = #TAB$ Or c = " " Or (slash And c = "/")
				Break
			EndIf
			i+1
		Wend
		cmdline = Mid(cmdline,i) ; если разделитель не был найден, строка будет пустая
	EndIf
	; Отбрасываем начальные пробелы и табуляции
	n = Len(cmdline)
	i = 1
	While i <= n
		c = Mid(cmdline,i,1)
		If c <> " " And c <> #TAB$
			Break
		EndIf
		i+1
	Wend
	cmdline = Mid(cmdline,i) ; всё от первого непробельного символа или пустая строка
	ProcedureReturn cmdline
EndProcedure

;========================================================================================================================
; Получение следующего параметра из командной строки и его разбор.
; Возвращается остаток строки с очередного непробельного символа после параметра.
Procedure.s NextParam(cmdline.s, *par.ParamType, slash=#PARAMS_SLASH)
	Protected c.s, i.i
	Protected len.i = Len(cmdline)
	Protected pos.i = 1 ; обрабатываемая позиция
	Protected sval.s = "", spar.s = ""
	Protected ProcessQuote = #False ; обработка кавычек

	While pos <= len ; пропустить до первого непробельного символа
		c = Mid(cmdline,pos,1)
		If c <> " " And c <> #TAB$
			Break
		EndIf
		pos+1
	Wend
	If slash ; возможно несколько символов / в начале параметра
		While pos <= len
			c = Mid(cmdline,pos,1)
			If c <> "/"
				Break
			EndIf
			spar + c
			pos + 1
		Wend
	EndIf
	; остальная часть параметра
	While pos <= len
		c = Mid(cmdline,pos,1)
		If c = Chr(34) ; кавычки
			ProcessQuote = Bool(Not ProcessQuote)
		ElseIf ProcessQuote ; любой символ в кавычках
			spar + c
		ElseIf c = " " Or c = #TAB$ Or (slash And c = "/") ; пробельный символ не в кавычках - конец параметра
			Break
		Else ; добавить символ к параметру
			spar + c
		EndIf
		pos + 1
	Wend
	; пропустить до первого непробельного символа
	While pos <= len
		c = Mid(cmdline,pos,1)
		If c <> " " And c <> #TAB$
			Break
		EndIf
		pos + 1
	Wend
	cmdline = Mid(cmdline,pos) ; остаток строки

	; разбор параметра
	*par\raw = spar
	*par\range = 0
	If Left(spar,1)="/" ; /ключ:значение
		len = Len(spar)
		pos = 0
		For i=1 To len ; ищем разделитель /ключ:значение
			c = Mid(spar,i,1)
			If c=":" Or c="="
				pos = i
				Break
			EndIf
		Next
		*par\delim = pos
		If pos
			*par\key = Left(spar,pos-1)
			sval = Mid(spar,pos+1)
		Else
			*par\key = spar
		EndIf
	Else ; только значение
		*par\delim = 0
		*par\key = ""
		sval = spar
	EndIf
	*par\value = sval
	*par\ukey = UCase(*par\key)
	*par\decimal = IsDecimal(*par\value)
	If *par\decimal
		*par\num = Val(sval)
	Else ; проверка на диапазон значений
		pos = FindString(sval,":")
		If pos And IsDecimal(Left(sval,pos-1)) And IsDecimal(Mid(sval,pos+1))
			*par\range = 1
			*par\num = Val(Left(sval,pos-1))
			*par\limit = Val(Mid(sval,pos+1))
		EndIf
	EndIf
	ProcedureReturn cmdline
EndProcedure

;========================================================================================================================
; Получение следующего параметра как value для параметров вида "/O значение"
;Procedure.s NextValue(cmdline.s, *par.ParamType)
;
;EndProcedure
;========================================================================================================================
; Разбор значения как диапазона ##:##
;Procedure SplitRange(*par.ParamType)
;	Protected x = FindString(*par\value,
;EndProcedure
;========================================================================================================================

CompilerIf #PARAMS_SPLIT

	; Для разделения параметров вида /STEP1 как если бы он был /STEP:1 (len = Len("/STEP"))
	Procedure SplitParam(*par.ParamType,len)
		If len
			*par\key = Left(*par\raw,len)
			*par\value = Mid(*par\raw,len+1)
		Else
			*par\key = *par\raw
			*par\value = ""
		EndIf
		*par\delim = Bool(*par\value<>"")
		*par\ukey = UCase(*par\key)
		*par\decimal = IsDecimal(*par\value)
		If *par\decimal
			*par\num = Val(*par\value)
		EndIf
	EndProcedure

CompilerEndIf ; #PARAMS_SPLIT

;========================================================================================================================
CompilerIf #PARAMS_CHECK ; Процедуры проверки параметров
;========================================================================================================================
	; Кода возврата по умолчанию
	#PERRCODE_PARAM = 1
	#PERRCODE_DECIMAL = 1
	#PERRCODE_RANGE = 1
	#PERRCODE_LIMIT = 1
	#PERRCODE_DATETIME = 1
	#PERRCODE_CODEPAGE = 1

	; Сообщения
	Enumeration CheckParamMessageNum 0
		#CHKPRMMSG_WRONG_PARAM
		#CHKPRMMSG_WRONG_VALUE
		#CHKPRMMSG_WRONG_DECIMAL
		#CHKPRMMSG_WRONG_RANGE
		#CHKPRMMSG_WRONG_LIMIT
		CompilerIf #PARAMS_DATETIME
			#CHKPRMMSG_WRONG_DATE
			#CHKPRMMSG_WRONG_TIME
			#CHKPRMMSG_WRONG_DATETIME
		CompilerEndIf
		CompilerIf #PARAMS_CODEPAGE
			#CHKPRMMSG_WRONG_CODEPAGE
		CompilerEndIf
		#CHKPRMMSG_PARAM_CONFLICT
		#CHKPRMMSG_PARAM_CONFLICT2
		#CHKPRMMSG_FILENOTEXIST
		#CHKPRMMSG_WRONG_FILENAME
		#_CHKPRMMSG_MAX
	EndEnumeration
	Global Dim CheckParamMessages.s(#_CHKPRMMSG_MAX) ; Массив сообщений
	CheckParamMessages(#CHKPRMMSG_WRONG_PARAM)     = "!!! Wrong parameter: <☺>"
	CheckParamMessages(#CHKPRMMSG_WRONG_VALUE)     = "!!! Wrong parameter value: <☺>"
	CheckParamMessages(#CHKPRMMSG_WRONG_DECIMAL)   = "!!! Wrong decimal value: <☺>"
	CheckParamMessages(#CHKPRMMSG_WRONG_RANGE)     = "!!! Wrong decimal range: <☺>"
	CheckParamMessages(#CHKPRMMSG_WRONG_LIMIT)     = "!!! Wrong decimal limit: <☺>"
	CompilerIf #PARAMS_DATETIME
		CheckParamMessages(#CHKPRMMSG_WRONG_DATE)      = "!!! Wrong date: <☺>"
		CheckParamMessages(#CHKPRMMSG_WRONG_TIME)      = "!!! Wrong time: <☺>"
		CheckParamMessages(#CHKPRMMSG_WRONG_DATETIME)  = "!!! Wrong date/time: <☺>"
	CompilerEndIf
	CompilerIf #PARAMS_CODEPAGE
		CheckParamMessages(#CHKPRMMSG_WRONG_CODEPAGE)  = "!!! Wrong codepage code: <☺>"
	CompilerEndIf
	CheckParamMessages(#CHKPRMMSG_PARAM_CONFLICT)  = "!!! Parameter conflict: <☺>"
	CheckParamMessages(#CHKPRMMSG_PARAM_CONFLICT2) = "!!! Parameter conflict: <☺> <☻>"
	CheckParamMessages(#CHKPRMMSG_FILENOTEXIST)    = "!!! File not exist: <☺>"
	CheckParamMessages(#CHKPRMMSG_WRONG_FILENAME)  = "!!! Wrong filename: <☺>"

	Global PErrCode = #PERRCODE_PARAM ; Код возврата
	Global PErrCodeDecimal = #PERRCODE_DECIMAL ; Код возврата при ошибке в CheckDecimal

	Enumeration DecimalType 0
		#DECTYPE_ANY
		#DECTYPE_NZ		; <= 0
		#DECTYPE_N		; < 0
		#DECTYPE_PZ		; >= 0
		#DECTYPE_P		; > 0
		#DECTYPE_T		; <> 0
		#DECTYPE_NP = #DECTYPE_T
		#DECTYPE_PN = #DECTYPE_T
	EndEnumeration

	Global PErrCodeRange = #PERRCODE_RANGE
	Global PErrCodeLimit = #PERRCODE_LIMIT
	Enumeration RangeType 1
		#RANGETYPE_RISING ; возрастающий
	EndEnumeration

	Procedure CheckParamMessage(*par.ParamType,msg=#CHKPRMMSG_WRONG_PARAM,errcode=0,conflict.s="")
		PrintN(ReplaceString(ReplaceString(CheckParamMessages(msg),"☺",*par\raw),"☻",conflict))
		If errcode<>0 : End errcode : EndIf
		End PErrCode
	EndProcedure

	;====================================================================================================================
	; Не должно быть никакого значения в именованном параметре (/Q)
	Procedure CheckNoValue(*par.ParamType)
		If *par\delim
			CheckParamMessage(*par,#CHKPRMMSG_WRONG_VALUE)
		EndIf
	EndProcedure
	;====================================================================================================================
	; Должно быть непустое значение в именованном параметре ( /N:1 но не /N: и не /N:"" )
	Procedure.s CheckValue(*par.ParamType)
		If Not *par\delim Or *par\value=""
			CheckParamMessage(*par,#CHKPRMMSG_WRONG_VALUE)
		EndIf
		ProcedureReturn *par\value
	EndProcedure

	;====================================================================================================================
	; Проверка правильности числа
	; Должно быть непустое десятичное значение в именованном параметре ( /N:1 но не /N: и не /N:"" )
	Procedure.i CheckDecimal(*par.ParamType,dectype=#DECTYPE_ANY)
		Protected n = *par\num
		If Not *par\decimal Or
			   (dectype=#DECTYPE_N And n>=0) Or
			   (dectype=#DECTYPE_NZ And n>0) Or
			   (dectype=#DECTYPE_P And n<=0) Or
			   (dectype=#DECTYPE_PZ And n<0) Or
			   (dectype=#DECTYPE_T And n=0)
			CheckParamMessage(*par,#CHKPRMMSG_WRONG_DECIMAL,PErrCodeDecimal)
		EndIf
		ProcedureReturn n
	EndProcedure

	;====================================================================================================================
	; Проверка правильности дипазона чисел
	Procedure.i CheckRange(*par.ParamType,dectype1=#DECTYPE_ANY,dectype2=#DECTYPE_ANY,rangetype=#RANGETYPE_RISING)
		Protected n1 = *par\num
		Protected n2 = *par\limit
		If Not *par\range Or
			   (dectype1=#DECTYPE_N And n1>=0) Or
			   (dectype1=#DECTYPE_NZ And n1>0) Or
			   (dectype1=#DECTYPE_P And n1<=0) Or
			   (dectype1=#DECTYPE_PZ And n1<0) Or
			   (dectype1=#DECTYPE_T And n1=0) Or
			   (dectype2=#DECTYPE_N And n2>=0) Or
			   (dectype2=#DECTYPE_NZ And n2>0) Or
			   (dectype2=#DECTYPE_P And n2<=0) Or
			   (dectype2=#DECTYPE_PZ And n2<0) Or
			   (dectype2=#DECTYPE_T And n2=0) Or
			   (rangetype=#RANGETYPE_RISING And n2<n1)
			CheckParamMessage(*par,#CHKPRMMSG_WRONG_LIMIT,PErrCodeRange)
		EndIf
		ProcedureReturn n1
	EndProcedure

	;====================================================================================================================
	; Должно быть непустое десятичное значение в именованном параметре ( /N:1 но не /N: и не /N:"" )
	; Если значения нет, возвращаем число по умолчанию
	Procedure.i CheckDecimalDef(*par.ParamType,dectype,def)
		If *par\decimal
			ProcedureReturn CheckDecimal(*par,dectype)
		EndIf
		CheckNoValue(*par) ; значение должно быть числом или значения не должно быть
		*par\decimal = #True
		*par\num = def
		ProcedureReturn def
	EndProcedure

;========================================================================================================================
CompilerEndIf ; #PARAMS_CHECK
;========================================================================================================================

; TODO
CompilerIf #PARAMS_DATETIME

	;#DATE_DELIMS = "[.,;_:/\- ]"
	;#DATE_PATTERN1 = "(\d\d\d\d)(\d\d)(\d\d)"
	;#DATE_PATTERN2 = "(\d\d)(\d\d)(\d\d)"
	;#DATE_PATTERN3 = "(\d\d\d\d)"+#DATE_DELIMS+"(\d\d)"+#DATE_DELIMS+"(\d\d)"
	;#DATE_PATTERN4 = "(\d\d)"+#DATE_DELIMS+"(\d\d)"+#DATE_DELIMS+"(\d\d)"

	;Procedure.q CheckDate(*par.ParamType)
	;	Protected d.s = *par\value
	;	If XTest(d,#DATE_PATTERN1)
	;		d = XReplace(d,#DATE_PATTERN1,"\1-\2-\3")
	;	ElseIf XTest(d,#DATE_PATTERN2)
	;		d = XReplace(d,#DATE_PATTERN2,"\1-\2-\3")
	;	ElseIf XTest(d,#DATE_PATTERN3)
	;		d = XReplace(d,#DATE_PATTERN3,"\1-\2-\3")
	;	ElseIf XTest(d,#DATE_PATTERN4)
	;		d = XReplace(d,#DATE_PATTERN4,"20\1-\2-\3")
	;	EndIf
	;	ProcedureReturn ParseDate("%yyyy-%mm-%dd",d)
	;EndProcedure

CompilerEndIf ; #PARAMS_DATETIME
;========================================================================================================================

; IDE Options = PureBasic 5.73 LTS (Windows - x86)
; ExecutableFormat = Console
; CursorPosition = 1
; Folding = --
; Executable = ParseCmdLine.exe
; DisableDebugger
; EnableExeConstant
; EnableUnicode