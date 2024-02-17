;=======================================================================================================================

Structure FF
	file.s
	cmp.s		; в верхнем регистре для ускорения доступа, если sort будет <> ucase(file)
	sort.s
	num.l
EndStructure

Enumeration 1
	#SORTFF_NAME_ACC
	#SORTFF_NAME_DEC
	#SORTFF_NUM_ACC
	#SORTFF_NUM_DEC
EndEnumeration

;=======================================================================================================================
; Добавить исключая дубликаты
; Нулевой элемент массива не используется!
; Возвращает индекс
Procedure.i AddFF(Array ffa.FF(1), f.s, idx.i=0) ;, imax=0)
	Protected index, size=ArraySize(ffa())
	Protected snum.s
	Protected u.s = UCase(f)
	For index=1 To size
		If ffa(index)\cmp = u ; уже есть
			ProcedureReturn index
		EndIf
	Next
	index = size+1
	If idx=0
		ReDim ffa(index)
		ffa(index)\file = f
		ffa(index)\cmp = u
		ffa(index)\sort = ""
		ProcedureReturn index
	Else
		snum = GetNum(f,idx)
		If snum
			ReDim ffa(index)
			ffa(index)\file = f
			ffa(index)\cmp = u
			ffa(index)\num = Val(snum)
			ffa(index)\sort = Right("0000000000"+Str(ffa(index)\num),10) + "*" + u
			ProcedureReturn index
		EndIf
	EndIf
	ProcedureReturn -1
EndProcedure
;=======================================================================================================================
; Исключить
;Procedure.i DelFF(Array ffa.FF(1), f.s)
;	Protected index, size=ArraySize(ffa())
;	Protected u.s = UCase(f)
;	For index=1 To size
;		If ffa(index)\sort = u
;			ffa(index)\file = ""
;			ffa(index)\cmp = ""
;			ffa(index)\sort = ""
;			ProcedureReturn index
;		EndIf
;	Next
;	ProcedureReturn 0
;EndProcedure
;=======================================================================================================================
Procedure.i SortFF(Array ffa.FF(1), sort.i=#SORTFF_NAME_ACC)
	Protected size = ArraySize(ffa())
	If size > 0
		Select sort
			Case #SORTFF_NAME_ACC ; Сортировка по полному имени
				SortStructuredArray(ffa(),#PB_Sort_NoCase|#PB_Sort_Ascending,OffsetOf(FF\cmp),TypeOf(FF\cmp),1,ArraySize(ffa()))
			Case #SORTFF_NAME_DEC ; Обратная сортировка по полному имени
				SortStructuredArray(ffa(),#PB_Sort_NoCase|#PB_Sort_Descending,OffsetOf(FF\cmp),TypeOf(FF\cmp),1,ArraySize(ffa()))
			Case #SORTFF_NUM_ACC ; Сортировка по номеру
				SortStructuredArray(ffa(),#PB_Sort_NoCase|#PB_Sort_Ascending,OffsetOf(FF\sort),TypeOf(FF\sort),1,ArraySize(ffa()))
				;SortStructuredArray(ffa(),#PB_Sort_Ascending,OffsetOf(FF\num),#PB_Integer,1,ArraySize(ffa()))
				;CompilerIf #PB_Processor_x64
				;	SortStructuredArray(ffa(),#PB_Sort_Ascending,OffsetOf(FF\num),#PB_Quad,1,ArraySize(ffa()))
				;CompilerElse
				;	SortStructuredArray(ffa(),#PB_Sort_Ascending,OffsetOf(FF\num),#PB_Long,1,ArraySize(ffa()))
				;CompilerEndIf
			Case #SORTFF_NUM_DEC ; Обратная сортировка по номеру
				SortStructuredArray(ffa(),#PB_Sort_NoCase|#PB_Sort_Descending,OffsetOf(FF\sort),TypeOf(FF\sort),1,ArraySize(ffa()))
				;SortStructuredArray(ffa(),#PB_Sort_Descending,OffsetOf(FF\num),#PB_Integer,1,ArraySize(ffa()))
				;CompilerIf #PB_Processor_x64
				;	SortStructuredArray(ffa(),#PB_Sort_Descending,OffsetOf(FF\num),#PB_Quad,1,ArraySize(ffa()))
				;CompilerElse
				;	SortStructuredArray(ffa(),#PB_Sort_Descending,OffsetOf(FF\num),#PB_Long,1,ArraySize(ffa()))
				;CompilerEndIf
		EndSelect
	EndIf
EndProcedure
;=======================================================================================================================
; Значение для выравнивания при перенумерации/вставке
; n - стартовое значение
; s - шаг
Procedure.i SmartNum(Array ffa.FF(1),n=0,s=1)
	Protected index, size = ArraySize(ffa())
	Protected r = 1
	For index=1 To size
		If ffa(index)\file
			n+s
		EndIf
	Next
	If n
		r = Len(Str(n-s))
	EndIf
	ProcedureReturn r
EndProcedure
;=======================================================================================================================
; Значение для выравнивания при выравнивании
Procedure.i SmartAlign(Array ffa.FF(1))
	Protected index, size = ArraySize(ffa())
	Protected l, r = 1
	For index=1 To size
		l = Len(Str(ffa(index)\num))
		If l > r : r = l : EndIf
	Next
	ProcedureReturn r
EndProcedure
;=======================================================================================================================
; Значение для выравнивания при изменении
; a - приращение
Procedure.i SmartAdd(Array ffa.FF(1),a=0)
	Protected index, size = ArraySize(ffa())
	Protected n, r = 0
	If a > 0 ; увеличение чисел, массив должен быть уже отсортирован (в обратном порядке)
		For index=1 To size
			If ffa(index)\file
				n = ffa(index)\num
				Break
			EndIf
		Next
		If n
			r = Len(Str(n+a))
		EndIf
	ElseIf a < 0 ; уменьшение чисел, массив должен быть уже отсортирован
		For index=size To 1 Step -1
			If ffa(index)\file
				n = ffa(index)\num
				Break
			EndIf
		Next
		If n
			r = Len(Str(n-a)) ; ??? отрицательные числа?
		EndIf
	EndIf
	ProcedureReturn r
EndProcedure
;=======================================================================================================================

; IDE Options = PureBasic 5.51 (Windows - x86)
; CursorPosition = 83
; FirstLine = 54
; Folding = -
; EnableXP
; DisableDebugger
; EnableExeConstant