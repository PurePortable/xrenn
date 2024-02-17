;;======================================================================================================================
; XRENN (C) Smitis 2010-2023
;;======================================================================================================================
#XRENN_VERSION = "5.21" ; для хелпа
#XRENN_COPYRIGHT = "(c) Smitis, 2010-2023" ; для хелпа

;PP_SILENT
;RES_VERSION 5.21.0.0
;RES_COPYRIGHT (c) Smitis, 2010-2023
;RES_DESCRIPTION eXtended REName/reNum
;RES_INTERNALNAME xrenn
;RES_ORIGINALFILENAME xrenn.exe
;RES_PRODUCTNAME Extended renamer/renumerator
;RES_PRODUCTVERSION 5.0.0.0
;RES_COMMENT PAM Project
;PP_FORMAT CONSOLE

;PP_X32_COPYAS "P:\PAM32\Cmd\xrenn.exe"
;PP_X64_COPYAS "P:\PAM\Cmd\xrenn.exe"

;PP_CLEAN 2

;;======================================================================================================================
; http://www.cyberforum.ru/cmd-bat/thread1226601.html
; Библиотека PCRE: http://www.pcre.org/pcre.txt
;;======================================================================================================================

EnableExplicit
OpenConsole()

Macro PrintT(s)
	PrintN(s)
EndMacro

CompilerIf Not Defined(QUOTE$,#PB_Constant)
	#QUOTE$ = Chr(34)
CompilerEndIf
CompilerIf Not Defined(Q,#PB_Constant)
	#Q = Chr(34)
CompilerEndIf
CompilerIf Not Defined(SPACE$,#PB_Constant)
	#SPACE$ = Chr(32)
CompilerEndIf
CompilerIf Not Defined(S,#PB_Constant)
	#S = Chr(32)
CompilerEndIf

;IncludePath #PB_Compiler_Home

;IncludePath #PB_Compiler_FilePath+"\include"
XIncludeFile "xrenn_help.pbi"
#DESCRIPTIONS_APP = "XRENN.EXE"
#DESCRIPTIONS_LOG = 0
XIncludeFile "xrenn_descriptions.pbi"
;XIncludeFile "SplitString.pbi"

;;----------------------------------------------------------------------------------------------------------------------
#REGEX_TEST     = 1 ; Компилировать процедуру RegexTest
#REGEX_MATCHES  = 0 ; Компилировать процедуру RegexMatches
#REGEX_XREPLACE = 0 ; Компилировать процедуру XReplace
#REGEX_XTEST    = 0 ; Компилировать процедуру XTest
XIncludeFile "xrenn_regexp2.pbi"
;;----------------------------------------------------------------------------------------------------------------------

XIncludeFile "xrenn_findnum.pbi"
XIncludeFile "xrenn_ff.pbi"
XIncludeFile "xrenn_system.pbi"
CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
	Prototype IsWow64Process(hProcess,*Wow64Process)
	Prototype Wow64DisableWow64FsRedirection(*OldValue)
	Prototype Wow64RevertWow64FsRedirection(*OldValue)
	Global kernel = OpenLibrary(#PB_Any,"kernel32.dll")
	Global IsWow64Process_.IsWow64Process = GetFunction(kernel,"IsWow64Process")
	Global Wow64DisableWow64FsRedirection_.Wow64DisableWow64FsRedirection = GetFunction(kernel,"Wow64DisableWow64FsRedirection")
	;Global Wow64RevertWow64FsRedirection_.Wow64RevertWow64FsRedirection = GetFunction(kernel,"Wow64RevertWow64FsRedirection")
	Define IsWow64ProcessFlag, Wow64OldValue
	If IsWow64Process_ And Wow64DisableWow64FsRedirection_
		IsWow64Process_(GetCurrentProcess_(),@IsWow64ProcessFlag)
		If IsWow64ProcessFlag <> 0
			;PrintT("Disable WOW")
			Wow64DisableWow64FsRedirection_(@Wow64OldValue)
		EndIf
	EndIf
CompilerEndIf

Define rex
Define i, j, n, m, err, ret, x
Define s.s, t.s, c.s, v.s
Global Dim dd.Description(0)
Global dd_changed = #False
Define Dim masks.s(0), Dim xmasks.s(0)
Define imask, nmask, iff, nff ; для циклов по маскам, файлам, папкам

;;----------------------------------------------------------------------------------------------------------------------
Declare PrintQ(text.s="")
Declare EndProgram(ret.i=0)
XIncludeFile "xrenn_subs.pbi"

;;----------------------------------------------------------------------------------------------------------------------
#PARAMS_DATETIME = 0 ; Компилировать процедуры проверки даты/времени
#PARAMS_CODEPAGE = 0 ; Компилировать процедуры проверки кодовой страницы
#PARAMS_SLASH    = 1 ; Считать символ "/" разделителем параметров или нет
#PARAMS_SPLIT    = 1 ; Procedure SplitParam
#PARAMS_CHECK    = 1 ; Процедуры проверки параметров и сообщения
#PARAMS_RANGE    = 1 ; Для проверки диапазонов ##:##
XIncludeFile "xrenn_parameters.pbi"
IsDecimalSignDefault = #ISDECSIGN_BOTH
;;----------------------------------------------------------------------------------------------------------------------

Global CntFound=0, CntRename=0, CntError=0, CntDescr=0, CntDone=0 ; счётчики
Global RetCode=0
Global RetCode_invert=1

Structure ParametersBool
	pause.i ; Делать паузу после окончания работы
	test.i ; Тест, без реального переименования, включается /T
	files.i ; Обрабатывать файлы
	folders.i ; Обрабатывать папки
	hidden.i  ; Обрабатывать скрытые и системные файлы
	regexp.i ; Использовать регулярные выражения
	nocase.i ; Нечувствительность к регистру, выключается параметром /CS (case sensitive)
	beginpat.i ; Сравнение с начала имени, символ ^ в начало шаблона добавится автоматически
	glob.i ; Глобальная замена, отменяется параметром /1 (TODO)
	filelist.i ; Список
	descr.i ; Обрабатывать описания из descript.ion
	ext.i ; Учитывать расширения файлов при переименовании
	smart.i ; Интелектуальное выравнивание
	no_smart.i ; no smart align
	no_nsmart.i ; no smart align
	ni.i ; Вставка числа
	na.i
	numsort.i ; Числовая сортировка (/NN)
	;order.i ; Сортировка
EndStructure
Global b.ParametersBool
b\pause = #False
b\test = #False
b\files = #True
b\folders = #False
b\hidden = #False
b\regexp = #True
b\nocase = #True
b\beginpat = #False
b\glob = #True
b\filelist = #False
b\descr = #True
b\ext = #False
b\smart = #True
b\no_smart = #False
b\no_nsmart = #False
b\ni = #False
b\na = #False
b\numsort = #False
Structure Parameters
	quiet.i ; Управление выводом информации
	q.i	; К-во неименованных параметров
	pat.s ; Что ищем
	cmppat.s ; Что сравниваем
	lenpat.i ; Длина того, что ищем
	casefind.i; Параметр для FindString
	repl.s; На что меняем
	filelist.s ; Список файлов (CP1251 или UTF8)
	prefix.s
	suffix.s
	dest.s ; Папка назначения для copy/move
	width.i ; Ширина поля выравнивания при перенумерации
	start.i ; Стартовое значение при перенумерации
	stp.i ; Шаг нумерации
	align.i ; Выравнивание, если <0 - вместо выравнивания - усечение
	index.i	; Какое число ищем (1 - первое, -1 - последнее, 0 - не задано, по умолчанию будет -1)
	add.i ; Приращение числа
	nstart.i ; Стартовое значение при вставке
	nwidth.i
	nalign.i
	overwrite.i ; /Y - перезаписывать при /C и /M
	;order.i ; Тип сортировки
EndStructure
Global p.Parameters
p\width = 0
p\start = 1
p\stp = 1
p\align = 1
p\index = 0
p\add = 0
p\nstart = 1
p\nwidth = 0
p\nalign = 0

Global operation_text.s			; Текущая операция COPY/MOVE для сообщений
Global operation_error.s		; Текст сообщения об ошибке для текущей операции

; ElapsedMilliseconds не работает!
;Global ElapsedTime.q = ElapsedMilliseconds()
Global ElapsedSystemTime.SYSTEMTIME
GetSystemTime_(@ElapsedSystemTime)
;GetLocalTime_(@ElapsedSystemTime)
Global ElapsedTime.FILETIME
SystemTimeToFileTime_(@ElapsedSystemTime,@ElapsedTime)
;PrintT(StrU(PeekQ(@ElapsedTime),#PB_Quad))

Enumeration FilenumEnum 1
	#FN_UNDO
	#FN_REST
	#FN_LIST
	#FN_LOGF
EndEnumeration

Global undo_use = #True			; Создавать файл отката
Global undo_cd = #False			; Создавать файл отката в текущей папке + hidden
Global logf_use = #False		; Если требуется запись лога
Define undo_file.s = FormatDate("%yyyy-%mm-%dd--%hh-%ii-%ss"+"--"+Right("00000000000000000000"+StrU(PeekQ(@ElapsedTime),#PB_Quad),20),Date())
Define logf_file.s = AddBackSlash(GetEnvironmentVariable("TEMP")) + "xrenn-" + undo_file + ".log"
Global Dim undo_cmd.s(0)

Enumeration RetCode
	#RETCODE_PARAM = 1
	#RETCODE_REGEXP = 2
	#RETCODE_UNDO = 3 ; ошибка открытия/переименования undo-файла
	#RETCODE_DIR = 4  ; ошибка изменения/создания директории
	#RETCODE_RENAME = 5 ; ошибка переименования/копирования/перемещения
EndEnumeration

Enumeration OrderEnum 0
	#ORDER_NONE
	#ORDER_NAME_ACC
	#ORDER_NAME_DEC
	#ORDER_NUM_ACC
	#ORDER_NUM_DEC
	#_ORDER_MAX
EndEnumeration
;b\order = #False
;p\order = #ORDER_NAME_ACC

; Значения #O_ARENUM и #O_AADD нужны для исключения повторов ключа /A через проверку ConflictOther
; и после обработки параметров должны быть заменены на #O_RENUM и #O_ADD соответственно.
; Пример: XRENN /N /A2 /A3 - первый ключ установит значение op = #O_RENUM, второй #O_ARENUM, третий выдаст ошибку.
; Пример: XRENN /A2 /N /A3 - первый ключ установит значение op = #O_ALIGN, второй #O_ARENUM, третий выдаст ошибку.
Enumeration OperationsEnum 0
	#O_UNDEF
	#O_RENAME
	#O_PREFIX
	#O_SUFFIX
	#O_RENUM
	#O_ADD
	#O_ALIGN
	;#O_ARENUM			; RENUM после ALIGN
	;#O_AADD			; ADD после ALIGN
	#O_COPY
	#O_MOVE
	#O_DELETE
	#O_RECYCLE
	#O_UNDO
	#O_UNDOLAST
	#_O_MAX				; количество элементов для массивов и проверок + 1
EndEnumeration
Define op = #O_UNDEF	; Выполняемая операция
Define Dim ops.s(#_O_MAX) ; Ключи для каждой операции (+1 на всякий случай)

Declare ConflictOther(*par.ParamType,op.i,Array ops.s(1),nop1.i=#O_UNDEF,nop2.i=#O_UNDEF,nop3.i=#O_UNDEF,nop4.i=#O_UNDEF)
Declare ConflictSame(*par.ParamType,op.i,Array ops.s(1))
Declare CheckParamQuantity(q.i,n1.i,n2.i)

;;----------------------------------------------------------------------------------------------------------------------
;{ Разбор параметров командной строки
Define Dim ParamsUnnamed.s(0)
Define cmdline.s = GetCmdLine()
Define allparams.s = cmdline
Define param.ParamType
If cmdline = ""
	Help()
EndIf
While cmdline
	cmdline = NextParam(cmdline,param)
	;AddArray(Params(),param\raw)
	If param\delim
		CheckValue(param) ; не должно быть пустых значений вида /N:
	EndIf
	; Резерв:
	; /X - маски исключения
	; /S - recurse subfolders
	; /P - position
	; /V - verbose

	If param\ukey="/?"
		CheckNoValue(param)
		Help()
	ElseIf param\ukey="/" Or param\ukey="/B" ;Or param\ukey="/BEGIN"
		; Пустой ключ /. Обрабатывать с начала имени (символ ^ в начале шаблона)
		; (для сокращения, чтобы не заключать щаблон в кавычки).
		CheckNoValue(param)
		b\beginpat = #True
	ElseIf Left(param\raw,1)="/" And (FindString(Mid(param\raw,2),"*")>0 Or FindString(Mid(param\raw,2),"?")>0)
		CheckNoValue(param)
		SplitMask2(Mid(param\raw,2),masks(),xmasks())
	ElseIf param\ukey="/Q" ; Самый тихий режим - вообще ничего не выводим
		CheckNoValue(param)
		p\quiet = 3
		b\pause = #False
	ElseIf param\ukey="/Q1" ; Всё выводим без паузы
		CheckNoValue(param)
		p\quiet = 1
		b\pause = #False
	ElseIf param\ukey="/Q2" ; Вывести только результирующую информацию без паузы
		CheckNoValue(param)
		p\quiet = 2
		b\pause = #False
	ElseIf param\ukey="/T" Or param\ukey="/TEST" ; Тестирование (вывод результатов без реального переименования)
		CheckNoValue(param)
		b\test = #True
	ElseIf param\ukey="/EXT" ; Учитывать при переименовании расширения
		CheckNoValue(param)
		b\ext = #True
	ElseIf param\ukey="/Z-" Or param\ukey="/NZ" ; Не обрабатывать файл описаний descript.ion
		CheckNoValue(param)
		b\descr = #False
	ElseIf param\ukey="/CS" ; Сase sensitive
		CheckNoValue(param)
		b\nocase = #False
	;ElseIf param\ukey="/1" ; Только одну замену в имени (not global)
	;	CheckNoValue(param)
	;	b_glob = #False
	ElseIf param\ukey="/F" ; Обрабатывать только папки
		CheckNoValue(param)
		b\files = #False
		b\folders = #True
	ElseIf param\ukey="/FF" ; ' Обрабатывать и файлы и папки
		CheckNoValue(param)
		b\files = #True
		b\folders = #True
	ElseIf param\ukey="/H" ; Обрабатывать невидимые и системные файлы
		CheckNoValue(param)
		b\hidden = #True
	ElseIf param\ukey="/M" Or param\ukey="/MOVE" ; MOVE - переместить в папку
		p\dest = CheckValue(param)
		ConflictOther(param,op,ops())
		op = #O_MOVE
		ops(op) = param\raw
		operation_text = "MOVE: "
		operation_error = "!!! Can't move file to "
	ElseIf param\ukey="/C" Or param\ukey="/COPY" ; COPY - копировать в папку
		p\dest = CheckValue(param)
		ConflictOther(param,op,ops())
		op = #O_COPY
		ops(op) = param\raw
		operation_text = "COPY: "
		operation_error = "!!! Can't copy file to "
	ElseIf param\ukey="/D" Or param\ukey="/DELETE"
		CheckNoValue(param)
		ConflictOther(param,op,ops())
		op = #O_DELETE
		ops(op) = param\raw
	ElseIf param\ukey="/Y"
		p\overwrite = #True
	ElseIf param\ukey="/DR" Or param\ukey="/RECYCLE"
		CheckNoValue(param)
		ConflictOther(param,op,ops())
		op = #O_RECYCLE
		ops(op) = param\raw
	ElseIf param\ukey="/LOG" ; Создавать лог-файл
		logf_use = #True
	ElseIf param\ukey="/UCD" Or param\ukey="/UNDOCD" ; Создавать файл отката в текущей папке
		CheckNoValue(param)
		undo_cd = #True
		undo_use = #True
	ElseIf param\ukey="/U-" Or param\ukey="/UNDO-" Or param\ukey="/NOUNDO" ; Не создавать файл отката
		CheckNoValue(param)
		undo_use = #False
	ElseIf param\ukey="/UL" Or param\ukey="/UNDOLAST"
		CheckNoValue(param)
		ConflictOther(param,op,ops())
		op = #O_UNDOLAST
		ops(op) = param\raw
	ElseIf param\ukey="/U" Or param\ukey="/UNDO" ; Restoration, Undo, rollback, Откат
		If param\delim ; задано имя файла отката
			undo_file = CheckValue(param)
			;CheckNoValue(param)
			ConflictOther(param,op,ops())
			op = #O_UNDO
		Else ; не задано имя, используем как /UNDOLAST
			op = #O_UNDOLAST
		EndIf
		ops(op) = param\raw
	ElseIf param\ukey="/RE-" Or param\ukey="/NORE" Or param\ukey="/NOREGEXP"
		CheckNoValue(param)
		b\regexp = #False
	ElseIf param\ukey="/NI" ; Вставка номера
		p\nstart = CheckDecimalDef(param,0,#DECTYPE_PZ)
		;ConflictOther(#O_RENAME) ; реально O_RENAME выставляется только после обработки всех ключей, а других режимов быть не должно
		If b\na ; если был параметр /NA, используем его
			p\nwidth = Abs(p\nalign)
			;no_smart = #True ; отключен в /NA
		Else
			p\nwidth = Len(param\value)
			If Len(param\value)>1 And Left(param\value,1)="0"
				b\no_smart = #True
			EndIf
		EndIf
		b\ni = #True
	ElseIf Left(param\ukey,3)="/NI" ; Вставка номера
		CheckNoValue(param)
		SplitParam(param,3)
		p\nstart = CheckDecimal(param,#DECTYPE_PZ)
		;ConflictOther(#O_RENAME)
		If b\na ; если был параметр /NA, используем его
			p\nwidth = Abs(p\nalign)
			;no_smart = #True ; отключен в /NA
		Else
			p\nwidth = Len(Mid(v,4))
			If Len(v)>1 And Left(v,1)="0"
				b\no_smart = #True
			EndIf
		EndIf
		b\ni = #True
	ElseIf param\ukey="/AI" ; Выравнивание при вставке номера
		p\nalign = CheckDecimalDef(param,#DECTYPE_ANY,0)
		p\nwidth = Abs(p\nalign)
		;ConflictOther(#O_RENAME)
		b\no_nsmart = Bool(p\nalign<>0)
		b\na = #True
	ElseIf Left(param\ukey,3)="/AI" ; Выравнивание при вставке номера
		CheckNoValue(param)
		SplitParam(param,3)
		p\nalign = CheckDecimal(param,#DECTYPE_ANY)
		p\nwidth = Abs(p\nalign)
		;ConflictOther(#O_RENAME)
		b\no_nsmart = Bool(p\nalign<>0)
		b\na = #True
	ElseIf param\ukey="/N" Or param\ukey="/RENUM" Or param\ukey="/NN" Or param\ukey="/NRENUM" ; Перенумерация
		b\numsort = Bool(param\ukey="/NN" Or param\ukey="/NRENUM")
		;ConflictSame(param,#O_RENUM,ops())
		ConflictOther(param,op,ops(),#O_ALIGN)
		v = param\value
		If Left(v,1) = "-" Or Left(v,1) = "+"
			p\add = CheckDecimal(param,#DECTYPE_T)
			If op=#O_ALIGN ; если был параметр /A, используем его
				p\width = Abs(p\align)
			Else
				p\width = Len(v)-1 ; без учёта знака
				If Len(v)>2 And Mid(v,2,1)="0"
					b\no_smart = #True
				EndIf
			EndIf
			op = #O_ADD
		Else
			p\start = CheckDecimalDef(param,#DECTYPE_PZ,1)
			If op=#O_ALIGN ; если был параметр /A, используем его
				p\width = Abs(p\align)
			Else
				p\width = Len(v)
				If Len(v)>1 And Left(v,1)="0"
					b\no_smart = #True
				EndIf
			EndIf
			op = #O_RENUM
		EndIf
		ops(op) = param\raw
	ElseIf Left(param\ukey,2)="/N" Or Left(param\ukey,3)="/NN" ; Перенумерация
		CheckNoValue(param)
		;ConflictSame(param,#O_RENUM,ops())
		ConflictOther(param,op,ops(),#O_ALIGN)
		If Left(param\ukey,3)="/NN"
			b\numsort = #True
			SplitParam(param,3)
		Else
			b\numsort = #False
			SplitParam(param,2)
		EndIf
		v = param\value
		If Left(v,1) = "-" Or Left(v,1) = "+"
			p\add = CheckDecimal(param,#DECTYPE_T)
			If op=#O_ALIGN ; если был параметр /A, используем его
				p\width = Abs(p\align)
			Else
				p\width = Len(v)-1 ; без учёта знака
				If Len(v)>2 And Mid(v,2,1)="0"
					b\no_smart = #True
				EndIf
			EndIf
			op = #O_ADD
		Else
			p\start = CheckDecimalDef(param,#DECTYPE_PZ,1)
			If op=#O_ALIGN ; если был параметр /A, используем его
				p\width = Abs(p\align)
			Else
				p\width = Len(v)
				If Len(v)>1 And Left(v,1)="0"
					b\no_smart = #True
				EndIf
			EndIf
			op = #O_RENUM
		EndIf
		ops(op) = param\raw
	ElseIf param\ukey="/PAUSE"
		b\pause = #True
	ElseIf param\ukey="/STEP"
		p\stp = CheckDecimal(param,#DECTYPE_T)
	ElseIf Left(param\ukey,5)="/STEP"
		CheckNoValue(param)
		SplitParam(param,5)
		p\stp = CheckDecimal(param,#DECTYPE_T)
	ElseIf param\ukey="/A" Or param\ukey="/ALIGN" ; Выравнивание без перенумерации или ширина выравнивания при перенумерации /justification
		ConflictSame(param,#O_ALIGN,ops())
		ConflictOther(param,op,ops(),#O_RENUM,#O_ADD)
		p\align = CheckDecimalDef(param,#DECTYPE_ANY,0)
		If op=#O_RENUM Or op=#O_ADD ; если были параметры /N или /A, значит задаётся выравнивание для них
			p\width = p\align
		Else
			op = #O_ALIGN
		EndIf
		b\no_smart = Bool(p\align<>0)
		ops(#O_ALIGN) = param\raw
	ElseIf Left(param\ukey,2)="/A" ; Выравнивание
		CheckNoValue(param)
		ConflictSame(param,#O_ALIGN,ops())
		ConflictOther(param,op,ops(),#O_RENUM,#O_ADD)
		SplitParam(param,2)
		p\align = CheckDecimalDef(param,#DECTYPE_ANY,0)
		If op=#O_RENUM Or op=#O_ADD ; если был параметр /N, значит задаётся выравнивание для него
			p\width = p\align
		Else
			op = #O_ALIGN
		EndIf
		b\no_smart = Bool(p\align<>0)
		ops(#O_ALIGN) = param\raw
	ElseIf param\ukey="/I" Or param\ukey="/INDEX" ; индекс (порядковый номер) числа в имени
		p\index = CheckDecimalDef(param,#DECTYPE_T,1)
		;ConflictOther(#O_RENUM,#O_ALIGN,#O_ADD)
	ElseIf Left(param\ukey,2)="/I" ; индекс (порядковый номер) числа в имени
		CheckNoValue(param)
		;ConflictOther(#O_RENUM,#O_ALIGN,#O_ADD)
		SplitParam(param,2)
		p\index = CheckDecimal(param,#DECTYPE_T)
	ElseIf Left(param\ukey,6)="/INDEX" ; индекс (порядковый номер) числа в имени
		CheckNoValue(param)
		;ConflictOther(#O_RENUM,#O_ALIGN,#O_ADD)
		SplitParam(param,6)
		p\index = CheckDecimal(param,#DECTYPE_T)
	;ElseIf param\ukey="/O" Or param\ukey="/ORDER"
	;	b\order = #True
	;ElseIf Left(param\ukey,2)="/O"
	;	CheckDecimal(Mid(par,3),#DECIMAL_T)
	;	b\order = #True
	ElseIf param\ukey="/PF" Or param\ukey="PREFIX" ; Префикс - добавить произвольный текст в начало имени
		p\prefix = CheckValue(param)
		ConflictOther(param,op,ops())
		op = #O_PREFIX
		ops(op) = param\raw
	ElseIf param\ukey="/SF" Or param\ukey="SUFFIX" ; Суффикс - добавить произвольный текст в конец имени
		p\suffix = CheckValue(param)
		ConflictOther(param,op,ops())
		op = #O_SUFFIX
		ops(op) = param\raw
	ElseIf param\ukey="/L" Or param\ukey="/LIST"
		p\filelist = CheckValue(param)
		b\filelist = #True
	ElseIf Left(param\ukey,1)="/"
		CheckParamMessage(param)
	Else ; Неименованный параметр
		ReDim ParamsUnnamed(ArraySize(ParamsUnnamed())+1)
		ParamsUnnamed(ArraySize(ParamsUnnamed())) = param\value
	EndIf
Wend
If op = #O_UNDEF : op = #O_RENAME : EndIf

; Неименованные (позиционные) параметры (т.е., тех, которые без "/")
p\q = ArraySize(ParamsUnnamed())

; Назначение неименованных параметров, кроме переименования
If op <> #O_RENAME
	If p\q = 1 ; только шаблон
		p\pat = ParamsUnnamed(1)
	ElseIf p\q = 2
		; Маска и шаблон
		SplitMask2(ParamsUnnamed(1),masks(),xmasks())
		p\pat = ParamsUnnamed(2)
	ElseIf p\q >= 3
		CheckParamQuantity(p\q,1,0)
	EndIf
EndIf

; Проверка количества неименованных (позиционных) параметров и пр.
Select op
	Case #O_RENAME
		CheckParamQuantity(p\q,2,3) ; шаблон+замена, маска+шаблон+замена
		If p\q = 2 ; шаблон+замена
			p\pat = ParamsUnnamed(1)
			p\repl = ParamsUnnamed(2)
		ElseIf p\q = 3 ; маска+шаблон+замена
			SplitMask2(ParamsUnnamed(1),masks(),xmasks())
			p\pat = ParamsUnnamed(2)
			p\repl = ParamsUnnamed(3)
		EndIf
		If b\no_nsmart : b\smart = #False : EndIf
		p\index = 0 ; для AddFF
	Case #O_PREFIX, #O_SUFFIX
		If p\q = 0 ; ищем всё
			p\pat = "."
			p\q = 1
			b\beginpat = #False ; не нужен
		EndIf
		If b\no_nsmart : b\smart = #False : EndIf
		CheckParamQuantity(p\q,1,2) ; шаблон, маска+шаблон
		p\index = 0 ; для AddFF
	Case #O_RENUM, #O_ALIGN, #O_ADD
		If p\index = 0 : p\index = -1 : EndIf ; по умолчанию
		If p\q = 0 ; ищем имена с цифрами
			p\pat = "\d"
			p\q = 1
			b\beginpat = #False ; не нужен
		EndIf
		If b\no_smart : b\smart = #False : EndIf
		CheckParamQuantity(p\q,1,2) ; шаблон, маска+шаблон
	Case #O_COPY, #O_MOVE
		CheckParamQuantity(p\q,1,2) ; шаблон, маска+шаблон
		b\files = #True : b\folders = #False ; Обрабатывать только файлы
		p\index = 0 ; для AddFF
		undo_use = #False
	Case #O_DELETE, #O_RECYCLE
		CheckParamQuantity(p\q,1,2) ; шаблон, маска+шаблон
		b\files = #True : b\folders = #False ; Обрабатывать только файлы
		p\index = 0 ; для AddFF
		undo_use = #False
	Case #O_UNDO, #O_UNDOLAST
		CheckParamQuantity(p\q,0,0) ; при восстановлении параметров быть не должно
		undo_use = #False
	Default
		CheckParamQuantity(p\q,1,0) ; Ошибка задания режима! TODO
EndSelect
;}

; Создаём лог файл
If logf_use
	CreateFile(#FN_LOGF,logf_file)	
EndIf

If Not op=#O_UNDO And Not op=#O_UNDOLAST And b\regexp
	If p\pat = ""
		If b\regexp
			PrintQ("!!! Regular Expression ie empty")
			EndProgram(#RETCODE_REGEXP)
		Else
			PrintQ("!!! Searching string ie empty")
			EndProgram(#RETCODE_REGEXP)
		EndIf
	EndIf
	If b\regexp
		If b\beginpat And Not Left(p\pat,1)="^"
			; Символ ^ в начало патерна
			p\pat = "^"+p\pat
		EndIf
		rex = RegexCreate(p\pat,b\nocase)
		If Not rex ; Неправильное регулярное выражение
			PrintQ(~"!!! Regular Expression Error \""+p\pat+~"\" : "+RegularExpressionError())
			EndProgram(#RETCODE_REGEXP)
		EndIf
	ElseIf b\nocase
		p\casefind = #PB_String_NoCase
		p\cmppat = UCase(p\pat)
		p\lenpat = Len(p\pat)
	Else
		p\casefind = #PB_String_CaseSensitive
		p\cmppat = p\pat
		p\lenpat = Len(p\pat)
	EndIf
EndIf

If p\repl = "\" ; пустая строка замены
	p\repl = ""
EndIf

Define name0.s, name1.s, name2.s, ext.s, path.s, descr.s, ff.s, ff1.s, ff2.s
Define Dim ddcm.Description(0) ; descriptions for /C or /M
Define ddcm_changed = #False
Define directory, hidden, cp
Define dirname.s, entry.s, entchk.s
Define mask.s = "*.*"
Define curdir.s = GetCurrentDirectory()
Define Dim files.FF(0), Dim folders.FF(0), Dim undos.s(0)

Define hfind, ffd.WIN32_FIND_DATA

If op=#O_UNDOLAST ; Ищем последний файл отката, если найдём, выполним с ним #O_UNDO
	dirname = curdir
	If UndoList(undos(),dirname)=0 ; Или ищем во временной папке
		dirname = AddBackSlash(GetEnvironmentVariable("TEMP"))
		UndoList(undos(),dirname)
		If ArraySize(undos())>0
			For i=1 To ArraySize(undos())
				ReadFile(#FN_UNDO,dirname+undos(i))
				While Eof(#FN_UNDO) = 0
					s = ReadString(#FN_UNDO,#PB_UTF8)
					x = CheckChdir(s)
					If x > 0
						s = AddBackSlash(QTrim(Mid(s,x)))
						If UCase(s)=UCase(curdir)
							undo_file = dirname+undos(i)
							op = #O_UNDO ; Выполнить undo с найденным файлом
							CloseFile(#FN_UNDO)
							Break 2 ; Последний файл найден
						EndIf
						Break
					EndIf
				Wend
				CloseFile(#FN_UNDO)
			Next
		EndIf
		undo_cd = #False
	Else ; Найдены файлы в текущей папке
		undo_file = dirname+undos(ArraySize(undos()))
		op = #O_UNDO ; Выполнить undo с найденным файлом
		undo_cd = #True
	EndIf
	If Not op = #O_UNDO ; Последний файл не найден
		PrintQ("!!! Can't find last undo file !!!")
		EndProgram(#RETCODE_UNDO)
	EndIf
EndIf
If op=#O_UNDO ; Обрабатываем файл отката
	If FindString(undo_file,"\") = 0
		; Если нет пути, значит файл в текущей директории (кроме маловероятного случая, когда c:file - TODO).
		; Полный путь нужен будет для переименования.
		undo_file = GetFullPath(undo_file)
	EndIf
	If ReadFile(#FN_UNDO,undo_file)
		;cp = ReadStringFormat(#FN_UNDO)
		cp = #PB_UTF8
		While Eof(#FN_UNDO) = 0
			s = ReadString(#FN_UNDO,cp)
			If UCase(Left(s,7)) = "@PUSHD "
				If b\descr And dd_changed
					DescrSave(dd())
					dd_changed = #False
				EndIf
				s = QTrim(Mid(s,8))
				If SetCurrentDirectory(s) = 0
					PrintQ(~"!!! Error change directory \""+s+~"\"")
					EndProgram(#RETCODE_DIR)
				EndIf
				If b\descr
					DescrLoad(dd())
				EndIf
			ElseIf UCase(Left(s,8)) = "@RENAME "
				CntFound+1
				s = BTrim(Mid(s,9))
				If Left(s,1) = #DQUOTE$ ; первое имя в кавычках
					x = FindString(s,#DQUOTE$,2)
					If x=0 : Continue : EndIf
					ff1 = QTrim(Mid(s,1,x))
				Else ; первое имя без кавычек
					x = FindString(s," ")
					If x=0 : Continue : EndIf
					ff1 = Left(s,x-1)
				EndIf
				ff2 = QTrim(Mid(s,x+1))
				If ff1="" Or ff2="" Or ff1=ff2 : Continue : EndIf
				PrintQ(ff1)
				PrintQ("-> "+ff2)
				If Not b\test
					err = RenameFile(ff1,ff2)
					If err = 0
						CntError+1
						PrintQ("!!! Rename Error !!!")
						RetCode = #RETCODE_UNDO
					Else
						CntDone+1
						If b\descr And DescrRen(dd(),ff1,ff2)
							CntDescr+1
							dd_changed = #True
						EndIf
					EndIf
				EndIf
			EndIf
		Wend
	Else
		PrintQ(~"!!! Can't open undo file \""+GetFilePart(undo_file)+~"\"")
		EndProgram(#RETCODE_UNDO)
	EndIf
	CloseFile(#FN_UNDO)
	SetCurrentDirectory(curdir)
	If RenameFile(undo_file,undo_file+"-bak") = 0
		PrintQ(~"!!! Error rename undo file: \""+GetFilePart(undo_file)+~"\"")
		EndProgram(#RETCODE_UNDO)
	EndIf
ElseIf b\filelist And p\filelist <> "" ; Обрабатываем сформированный ФАРом список папок и файлов
	If ReadFile(#FN_LIST,p\filelist)
		cp = ReadStringFormat(#FN_LIST)
		While Eof(#FN_LIST) = 0
			entry = ReadString(#FN_LIST,cp) ; TODO: QTrim (?)
			x = FileSize(entry)
			If x = -2 ; folder
				AddFF(folders(),entry,p\index)
			ElseIf x >= 0 ; file
				AddFF(files(),entry,p\index)
			Else ; not exist (TODO)

			EndIf
		Wend
	Else
		PrintQ(~"!!! Can't open list file \""+p\filelist+~"\"")
		EndProgram(#RETCODE_UNDO)
	EndIf
	CloseFile(#FN_LIST)
Else ; Строим списки папок и файлов
	If ArraySize(masks()) = 0
		AddArray(masks(),"*.*")
	EndIf
	nmask = ArraySize(masks())
	hfind = FindFirstFile_(@mask,ffd)
	If hfind <> #INVALID_HANDLE_VALUE
		Repeat
			entry = PeekS(@ffd\cFileName)
			hidden = Bool(ffd\dwFileAttributes & (#FILE_ATTRIBUTE_HIDDEN|#FILE_ATTRIBUTE_SYSTEM) <> 0)
			directory = Bool(ffd\dwFileAttributes & #FILE_ATTRIBUTE_DIRECTORY <> 0)
			;PrintT("ENTRY: "+entry)
			If Not directory And b\files And (b\hidden Or Not hidden)
				If b\descr And entry="descript.ion" : Continue : EndIf
				For imask=1 To nmask
					If PathMatchSpec_(entry,masks(imask))
						If b\ext
							entchk = entry
						Else
							entchk = GetNamePart(entry)
						EndIf
						If b\regexp
							If RegexTest(rex,entchk)
								AddFF(files(),entry,p\index)
							EndIf
						ElseIf b\beginpat And b\nocase
							If UCase(Left(entchk,p\lenpat)) = p\cmppat
								AddFF(files(),entry,p\index)
							EndIf
						ElseIf b\beginpat And Not b\nocase
							If Left(entchk,p\lenpat) = p\cmppat
								AddFF(files(),entry,p\index)
							EndIf
						Else
							If FindString(entchk,p\pat,1,p\casefind)
								AddFF(files(),entry,p\index)
							EndIf
						EndIf
						Break ; imask
					EndIf
				Next
			ElseIf directory And b\folders And entry<>"." And entry<>".." And (b\hidden Or Not hidden)
				For imask=1 To nmask
					If PathMatchSpec_(entry,masks(imask))
						If b\regexp
							If RegexTest(rex,entry)
								AddFF(folders(),entry,p\index)
							EndIf
						ElseIf b\beginpat And b\nocase
							If UCase(Left(entry,p\lenpat)) = p\cmppat
								AddFF(folders(),entry,p\index)
							EndIf
						ElseIf b\beginpat And Not b\nocase
							If Left(entry,p\lenpat) = p\cmppat
								AddFF(folders(),entry,p\index)
							EndIf
						Else
							If FindString(entry,p\pat,1,p\casefind)
								AddFF(folders(),entry,p\index)
							EndIf
						EndIf
						Break ; imask
					EndIf
				Next
			EndIf
		Until FindNextFile_(hfind,ffd) = 0
		FindClose_(hfind)
	EndIf
	If ArraySize(folders())
		If (op=#O_RENUM Or op=#O_ALIGN Or op=#O_ADD) And b\numsort
			If p\add > 0 ; для O_RENUM и O_ALIGN всегда 0
				SortFF(folders(),#SORTFF_NUM_DEC)
			Else
				SortFF(folders(),#SORTFF_NUM_ACC)
			EndIf
		Else
			SortFF(folders(),#SORTFF_NAME_ACC)
		EndIf
	EndIf
	If ArraySize(files())
		If (op=#O_RENUM Or op=#O_ALIGN Or op=#O_ADD) And b\numsort
			If p\add > 0 ; для O_RENUM и O_ALIGN всегда 0
				SortFF(files(),#SORTFF_NUM_DEC)
			Else
				SortFF(files(),#SORTFF_NUM_ACC)
			EndIf
		Else
			SortFF(files(),#SORTFF_NAME_ACC)
		EndIf
	EndIf
EndIf
nmask = ArraySize(xmasks())
If nmask ; исключения
	; TODO: Проверить, надо ли фильтровать пустые маски
	; TODO: Пропускать маски без символов-джокеров ???
	nff = ArraySize(folders())
	For iff=1 To nff
		entry = folders(iff)\file
		For imask=1 To nmask
			If xmasks(imask)
				If PathMatchSpec_(entry,xmasks(imask))
					; исключаем
					folders(iff)\file = ""
					folders(iff)\cmp = ""
					folders(iff)\sort = ""
					Break
				EndIf
			EndIf
		Next
	Next
	nff = ArraySize(files())
	For iff=1 To nff
		entry = files(iff)\file
		For imask=1 To nmask
			If xmasks(imask)
				If PathMatchSpec_(entry,xmasks(imask))
					; исключаем
					files(iff)\file = ""
					files(iff)\cmp = ""
					files(iff)\sort = ""
					Break
				EndIf
			EndIf
		Next
	Next
EndIf
;;----------------------------------------------------------------------------------------------------------------------

; (!) Нулевой элемент массива в цикле формирования списка получается всегда пустой, поэтому циклы начинаются с 1
Define num.i, oldnum.s, newnum.s, newnum1.s, newnum2.s, Dim posnum.i(1)
Declare.s InsNum(text.s,*num.Integer)
Declare ReName(ff1.s,name2.s,ext2.s)
Select op
	Case #O_COPY, #O_MOVE
		; TODO: Проверять правильность имени папки
		p\dest = AddBackSlash(GetFullPath(p\dest))
		If FileSize(p\dest)<>-2 And SHCreateDirectory_(#Null,p\dest)
			; не удалось создать папку назначения
			If Not b\test
				PrintQ(~"!!! Can't create folder \""+p\dest+~"\"")
				EndProgram(#RETCODE_DIR)
			EndIf
		EndIf
		If b\descr
			DescrLoad(dd())
			DescrLoad(ddcm(),p\dest)
		EndIf
		nff = ArraySize(files())
		For iff=1 To nff
			ff1 = files(iff)\file
			If ff1
				CntFound+1
				ff2 = p\dest+"\"+ff1
				PrintQ(operation_text+ff1)
				If Not b\test
					If op=#O_COPY
						err = CopyFile(ff1,ff2)
					Else
						err = RenameFile(ff1,ff2)
					EndIf
					If err = 0
						CntError+1
						PrintQ(operation_error+#DQUOTE$+ff2+#DQUOTE$)
					Else
						CntDone+1
						PrintQ("-> "+ff2)
						If b\descr
							descr = DescrGet(dd(),ff1)
							If descr
								CntDescr+1
								DescrSet(ddcm(),ff1,descr)
								ddcm_changed = #True
								If op=#O_MOVE
									DescrDel(dd(),ff1)
									dd_changed = #True
								EndIf
							EndIf
						EndIf
					EndIf
				Else
					PrintQ("-> "+ff2)
				EndIf
			EndIf
		Next
		If ddcm_changed
			DescrSave(ddcm())
		EndIf
	Case #O_DELETE, #O_RECYCLE
		If b\descr : DescrLoad(dd()) : EndIf
		nff = ArraySize(files())
		For iff=1 To nff
			ff1 = files(iff)\file
			If ff1
				CntFound+1
				PrintQ("DELETE: "+ff1)
				If Not b\test
					If op=#O_RECYCLE
						err = DeleteFileToRecycleBin(ff1)
					Else
						err = DeleteFile(ff1,#PB_FileSystem_Force)
					EndIf
					If err = 0
						CntError+1
						PrintQ("!!! Error delete file")
					Else
						CntDone+1
						If b\descr And DescrGet(dd(),ff1)
							CntDescr+1
							DescrDel(dd(),ff1)
							dd_changed = #True
						EndIf
					EndIf
				EndIf
			EndIf
		Next
	Case #O_RENUM
		operation_text = "RENUM: "
		If b\descr : DescrLoad(dd()) : EndIf
		num = p\start
		If b\smart : p\width = SmartNum(folders(),p\start,p\stp) : EndIf
		nff = ArraySize(folders())
		For iff=1 To nff
			ff1 = folders(iff)\file
			If ff1
				name1 = ff1
				CntFound+1
				oldnum = FindNum(posnum(),name1,p\index)
				If posnum(0)
					newnum = Str(Abs(num))
					newnum2 = newnum
					If p\width > 0 ; выравнивание без потери значащих цифр
						newnum = Right(RSet("",p\width,"0")+newnum,p\width)
						If Len(newnum)<Len(newnum2) : newnum=newnum2 : EndIf
					ElseIf p\width < 0
						newnum = Right(RSet("",-p\width,"0")+newnum,-p\width)
					EndIf
					ReName(ff1,Left(name1,posnum(0)-1)+newnum+Mid(name1,posnum(1)),"")
					num+p\stp
				EndIf
			EndIf
		Next
		num = p\start
		If b\smart : p\width = SmartNum(files(),p\start,p\stp) : EndIf
		nff = ArraySize(files())
		For iff=1 To nff
			ff1 = files(iff)\file
			If ff1
				ext = GetExtPart(ff1)
				name1 = GetNamePart(ff1)
				CntFound+1
				oldnum = FindNum(posnum(),name1,p\index)
				If posnum(0)
					newnum = Str(Abs(num))
					newnum2 = newnum
					If p\width > 0 ; выравнивание без потери значащих цифр
						newnum = Right(RSet("",p\width,"0")+newnum,p\width)
						If Len(newnum)<Len(newnum2) : newnum=newnum2 : EndIf
					ElseIf p\width < 0
						newnum = Right(RSet("",-p\width,"0")+newnum,-p\width)
					EndIf
					ReName(ff1,Left(name1,posnum(0)-1)+newnum+Mid(name1,posnum(1)),ext)
					num+p\stp
				EndIf
			EndIf
		Next
	Case #O_ADD
		If b\descr : DescrLoad(dd()) : EndIf
		If b\smart : p\width = SmartAdd(folders(),p\add) : EndIf
		nff = ArraySize(folders())
		For iff=1 To nff
			ff1 = folders(iff)\file
			If ff1
				name1 = ff1
				CntFound+1
				oldnum = FindNum(posnum(),name1,p\index)
				If posnum(0)
					newnum = Str(Abs(Val(oldnum)+p\add))
					newnum2 = newnum
					If p\width > 0 ; выравнивание без потери значащих цифр
						newnum = Right(RSet("",p\width,"0")+newnum,p\width)
						If Len(newnum)<Len(newnum2) : newnum=newnum2 : EndIf
					ElseIf p\width < 0
						newnum = Right(RSet("",-p\width,"0")+newnum,-p\width)
					EndIf
					ReName(ff1,Left(name1,posnum(0)-1)+newnum+Mid(name1,posnum(1)),"")
				EndIf
			EndIf
		Next
		If b\smart : p\width = SmartAdd(files(),p\add) : EndIf
		nff = ArraySize(files())
		For iff=1 To nff
			ff1 = files(iff)\file
			If ff1
				ext = GetExtPart(ff1)
				name1 = GetNamePart(ff1)
				CntFound+1
				oldnum = FindNum(posnum(),name1,p\index)
				If posnum(0)
					newnum = Str(Abs(Val(oldnum)+p\add))
					newnum2 = newnum
					If p\width > 0 ; выравнивание без потери значащих цифр
						newnum = Right(RSet("",p\width,"0")+newnum,p\width)
						If Len(newnum)<Len(newnum2) : newnum=newnum2 : EndIf
					ElseIf p\width < 0
						newnum = Right(RSet("",-p\width,"0")+newnum,-p\width)
					EndIf
					ReName(ff1,Left(name1,posnum(0)-1)+newnum+Mid(name1,posnum(1)),ext)
				EndIf
			EndIf
		Next
	Case #O_ALIGN
		If b\descr : DescrLoad(dd()) : EndIf
		If b\smart : p\align = SmartAlign(folders()) : EndIf
		nff = ArraySize(folders())
		For iff=1 To nff
			ff1 = folders(iff)\file
			If ff1
				name1 = ff1
				CntFound+1
				oldnum = FindNum(posnum(),name1,p\index)
				If posnum(0)
					If p\align = 0 ; убрать ведущие нули
						newnum = Str(Val(oldnum))
					ElseIf p\align > 0 ; выравнивание без потери значащих цифр
						newnum = Right(RSet("",p\align,"0")+oldnum,p\align)
						newnum2 = Str(Val(oldnum))
						If Len(newnum)<Len(newnum2) : newnum=newnum2 : EndIf
					Else ; p_align < 0
						newnum = Right(RSet("",-p\align,"0")+oldnum,-p\align)
					EndIf
					ReName(ff1,Left(name1,posnum(0)-1)+newnum+Mid(name1,posnum(1)),"")
				EndIf
			EndIf
		Next
		If b\smart : p\align = SmartAlign(files()) : EndIf
		nff = ArraySize(files())
		For iff=1 To nff
			ff1 = files(iff)\file
			If ff1
				ext = GetExtPart(ff1)
				name1 = GetNamePart(ff1)
				CntFound+1
				oldnum = FindNum(posnum(),name1,p\index)
				If posnum(0)
					If p\align = 0 ; убрать ведущие нули
						newnum = Str(Val(oldnum))
					ElseIf p\align > 0 ; выравнивание без потери значащих цифр
						newnum = Right(RSet("",p\align,"0")+oldnum,p\align)
						newnum2 = Str(Val(oldnum))
						If Len(newnum)<Len(newnum2) : newnum=newnum2 : EndIf
					Else ; p_align < 0
						newnum = Right(RSet("",-p\align,"0")+oldnum,-p\align)
					EndIf
					ReName(ff1,Left(name1,posnum(0)-1)+newnum+Mid(name1,posnum(1)),ext)
				EndIf
			EndIf
		Next
	Case #O_RENAME
		operation_text = "RENAME: "
		If b\descr : DescrLoad(dd()) : EndIf
		num = p\nstart
		If b\smart : p\nwidth = SmartNum(folders(),p\nstart,p\stp) : EndIf
		nff = ArraySize(folders())
		For iff=1 To nff
			;path = GetPathPart(folders(iff)\file) ; TODO
			ff1 = GetFilePart(folders(iff)\file)
			If ff1
				ext = ""
				name1 = ff1
				name2 = name1
				CntFound+1
				If p\q > 1
					If b\regexp
						name2 = RegexReplace(rex,name1,p\repl)
					ElseIf b\beginpat
						name2 = p\repl+Mid(name1,p\lenpat+1)
					Else
						name2 = ReplaceString(name1,p\pat,p\repl,p\casefind)
					EndIf
				EndIf
				name2 = FTrim(name2)
				If name2 <> ""
					ReName(ff1,InsNum(name2,@num),ext)
				EndIf
			EndIf
		Next
		num = p\nstart
		If b\smart : p\nwidth = SmartNum(files(),p\nstart,p\stp) : EndIf
		nff = ArraySize(files())
		For iff=1 To nff
			;path = GetPathPart(files(iff)\file) ; TODO
			ff1 = GetFilePart(files(iff)\file)
			If ff1
				If b\ext
					ext = ""
					name1 = ff1
				Else
					ext = GetExtPart(ff1)
					name1 = GetNamePart(ff1)
				EndIf
				name2 = name1
				CntFound+1
				If p\q > 1
					If b\regexp
						name2 = RegexReplace(rex,name1,p\repl)
					ElseIf b\beginpat
						name2 = p\repl+Mid(name1,p\lenpat+1)
					Else
						name2 = ReplaceString(name1,p\pat,p\repl,p\casefind)
					EndIf
				EndIf
				name2 = FTrim(name2)
				If name2 <> ""
					ReName(ff1,InsNum(name2,@num),ext)
				EndIf
			EndIf
		Next
	Case #O_PREFIX, #O_SUFFIX
		If op=#O_PREFIX
			operation_text = "PREFIX: "
		Else
			operation_text = "SUFFIX: "
		EndIf
		If b\descr : DescrLoad(dd()) : EndIf
		num = p\nstart
		If b\smart : p\nwidth = SmartNum(folders(),p\nstart,p\stp) : EndIf
		nff = ArraySize(folders())
		For iff=1 To nff
			;path = GetPathPart(folders(iff)\file) ; TODO
			ff1 = GetFilePart(folders(iff)\file)
			If ff1
				CntFound+1
				ReName(ff1,InsNum(p\prefix+ff1+p\suffix,@num),"")
			EndIf
		Next
		num = p\nstart
		If b\smart : p\nwidth = SmartNum(files(),p\nstart,p\stp) : EndIf
		nff = ArraySize(files())
		For iff=1 To nff
			;path = GetPathPart(files(iff)\file) ; TODO
			ff1 = GetFilePart(files(iff)\file)
			If ff1
				If b\ext
					ext = ""
					name1 = ff1
				Else
					ext = GetExtPart(ff1)
					name1 = GetNamePart(ff1)
				EndIf
				CntFound+1
				ReName(ff1,InsNum(p\prefix+name1+p\suffix,@num),ext)
			EndIf
		Next
EndSelect

If b\descr And dd_changed : DescrSave(dd()) : EndIf

If undo_use ;And ArraySize(undo_cmd())>0 And CntDone>0
	; для #O_RENAME, #O_PREFIX, #O_SUFFIX, #O_RENUM, #O_ALIGN, #O_ADD если не было /UNDO-
	If undo_cd
		undo_file + ".xrenn"
	Else
		undo_file = AddBackSlash(GetEnvironmentVariable("TEMP")) + undo_file + ".xrenn"
	EndIf
	If CreateFile(#FN_UNDO,undo_file)
		WriteStringN(#FN_UNDO,":: XRENN UNDO FILE")
		WriteStringN(#FN_UNDO,":: COMMAND LINE: XRENN "+allparams,#PB_UTF8)
		WriteStringN(#FN_UNDO,~"@FOR /F \"USEBACKQ TOKENS=1,* DELIMS=:\" %%I IN (`CHCP`) DO @SET CODEPAGE=%%J")
		WriteStringN(#FN_UNDO,"@CHCP 65001 >NUL")
		WriteStringN(#FN_UNDO,~":@XRENN.EXE /Q2 /UNDO:\"%~f0\" & @GOTO CODEPAGE",#PB_UTF8)
		WriteStringN(#FN_UNDO,"@PUSHD "+#DQUOTE$+GetCurrentDirectory()+#DQUOTE$,#PB_UTF8)
	EndIf
	m = ArraySize(undo_cmd())
	; Переименование будет идти в обратном порядке
	For i=m To 1 Step -1
		WriteStringN(#FN_UNDO,undo_cmd(i),#PB_UTF8)
	Next
	WriteStringN(#FN_UNDO,"@POPD")
	WriteStringN(#FN_UNDO,":CODEPAGE")
	WriteStringN(#FN_UNDO,"@CHCP %CODEPAGE% >NUL")
	CloseFile(#FN_UNDO)
	If undo_cd
		SetFileAttributes(undo_file,#PB_FileSystem_Hidden)
	EndIf
EndIf

; Статистика выполнения
;PrintT("!!!!!")
;ElapsedTime = ElapsedMilliseconds()-ElapsedTime
GetSystemTime_(@ElapsedSystemTime)
;GetLocalTime_(@ElapsedSystemTime)
Global ElapsedTime2.FILETIME
SystemTimeToFileTime_(@ElapsedSystemTime,@ElapsedTime2)
;PrintT(StrU(PeekQ(@ElapsedTime),#PB_Quad))
; Здесь возникает исключение
;ElapsedTime = ElapsedTime2-ElapsedTime
;PrintT(StrU(PeekQ(@ElapsedTime),#PB_Quad))

If p\quiet <= 2
	PrintQ("")
	ConsoleColor(15,1) : Print("* FOUND: "+Str(CntFound)+" ") : ConsoleColor(7,0) : PrintN("")
	ConsoleColor(15,1) : Print("* DONE: "+Str(CntDone)+" ") : ConsoleColor(7,0) : PrintN("")
	ConsoleColor(15,1) : Print("* ERRORS:")
	If CntError : ConsoleColor(15,4) : EndIf
	Print(" "+Str(CntError)+" ") : ConsoleColor(7,0) : PrintN("")
	If b\descr
		ConsoleColor(15,1) : Print("* DESCRIPTIONS: "+Str(CntDescr)+" ") : ConsoleColor(7,0) : PrintN("")
	EndIf
	;PrintN("TIME: "+StrD(ElapsedTime/1000)+" s") ; ???
EndIf
If b\pause
	;ConsoleColor(15,1)
	Print("Press any key to continue...")
	;ConsoleColor(7,0)
	Repeat : Inkey() : Until RawKey()
	PrintN("")
EndIf
If CntError : RetCode=#RETCODE_RENAME : EndIf
EndProgram(RetCode)
End

;;----------------------------------------------------------------------------------------------------------------------

Procedure.s InsNum(text.s,*num.Integer)
	If FindString(text,"\N",1,#PB_String_NoCase)
		Protected newnum2.s
		Protected newnum.s = Str(Abs(*num\i))
		If p\nwidth > 0 ; выравнивание без потери значащих цифр
			newnum2 = newnum
			newnum = Right(RSet("",p\nwidth,"0")+newnum,p\nwidth)
			If Len(newnum)<Len(newnum2) : newnum=newnum2 : EndIf
		ElseIf p\nwidth < 0
			newnum = Right(RSet("",-p\nwidth,"0")+newnum,-p\nwidth)
		EndIf
		text = ReplaceString(text,"\N",newnum,#PB_String_NoCase)
		*num\i+p\stp
	EndIf
	ProcedureReturn text
EndProcedure

Procedure ReName(ff1.s,name2.s,ext2.s)
	Protected ff2.s = name2+ext2
	If ff1 <> ff2
		PrintQ(operation_text+ff1)
		PrintQ("-> "+ff2)
		If Not CheckFilename(ff2) Or name2="" Or ff2=""
			PrintQ("!!! Bad filename !!!")
			CntError+1
		ElseIf b\descr And ff2="descript.ion"
			PrintQ("!!! Skip rename !!!")
			;CntError+1
		ElseIf Not b\test
			Protected err = RenameFile(ff1,ff2)
			If err = 0
				PrintQ("!!! Rename Error !!!")
				CntError+1
				If undo_use
					AddArray(undo_cmd(),~":ERROR \""+ff2+~"\" \""+ff1+~"\"")
				EndIf
			Else
				CntDone+1
				If b\descr And DescrRen(dd(),ff1,ff2)
					CntDescr+1
					dd_changed = #True
				EndIf
				If undo_use
					AddArray(undo_cmd(),~"@RENAME \""+ff2+~"\" \""+ff1+~"\"")
				EndIf
			EndIf
		EndIf
	EndIf
EndProcedure

;;======================================================================================================================
Procedure PrintQ(text.s="")
	If p\quiet <= 1
		PrintN(text)
	EndIf
EndProcedure
;;======================================================================================================================
;#O_UNDEF = 0
; nop1, nop2, nop3, nop4 - с чем НЕ конфликтует
Procedure ConflictOther(*par.ParamType,op.i,Array ops.s(1),nop1.i=#O_UNDEF,nop2.i=#O_UNDEF,nop3.i=#O_UNDEF,nop4.i=#O_UNDEF)
	If op<>#O_UNDEF And op<>nop1 And op<>nop2 And op<>nop3 And op<>nop4
		;PrintN("!!! Parameter conflict <"+*par\raw+">")
		PrintN("!!! Parameter conflict <"+*par\raw+"> with <"+ops(op)+">")
		End -1
	EndIf
EndProcedure
;;======================================================================================================================
; Конфликт с таким же параметром (для /N и /A)
Procedure ConflictSame(*par.ParamType,op.i,Array ops.s(1))
	If ops(op) ; если такой параметр уже был, строка будет не пустая
		PrintN("!!! Parameter conflict <"+*par\raw+"> with <"+ops(op)+">")
	EndIf
EndProcedure
;;======================================================================================================================
; Проверка количества параметров
Procedure CheckParamQuantity(q.i,n1.i,n2.i)
	If q < n1
		PrintN("!!! No enough unnamed parameters !!!")
		End -1
	ElseIf q > n2
		PrintN("!!! Many unnamed parameters !!!")
		End -1
	EndIf
EndProcedure
;;======================================================================================================================
Procedure EndProgram(ret.i=0)
	End ret*RetCode_invert
EndProcedure
;;======================================================================================================================

; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; ExecutableFormat = Console
; CursorPosition = 679
; FirstLine = 676
; Folding = v-
; Optimizer
; Executable = xrenn.exe
; DisableDebugger
; CommandLine = /i1 /n-1 /sa
; EnablePurifier
; DisableBuildCount = 175
; EnableExeConstant
; IncludeVersionInfo
; VersionField0 = 5.21.0.0
; VersionField1 = 5.0.0.0
; VersionField3 = Extended renamer/renumerator
; VersionField4 = 5.0.0.0
; VersionField5 = 5.21.0.0
; VersionField6 = eXtended REName/reNum
; VersionField7 = xrenn
; VersionField8 = xrenn.exe
; VersionField9 = (c) Smitis, 2010-2023
; VersionField18 = Comments
; VersionField21 = PAM Project
; EnableUnicode