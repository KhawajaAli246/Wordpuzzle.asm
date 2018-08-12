.386
.model flat, stdcall
.stack 1024
GetTickCount PROTO ; get elapsed milliseconds
					; since computer turned on
ExitProcess PROTO,          ; exit program
    dwExitCode:DWORD        ; return code

GetStdHandle PROTO,         ; get standard handle
    nStdHandle:DWORD        ; type of console handle

CloseHandle PROTO,      ; close file handle
    handle:DWORD

ReadConsoleA PROTO,
    handle:DWORD,                     ; input handle
    lpBuffer:PTR BYTE,                ; pointer to buffer
    nNumberOfCharsToRead:DWORD,       ; number of chars to read
    lpNumberOfCharsRead:PTR DWORD,    ; number of chars read
    lpReserved:PTR DWORD              ; 0 (not used - reserved)

SetConsoleCursorPosition PROTO,
    nStdHandle:DWORD,    ; input mode handle
    coords:dword         ; screen X,Y coordinates

SetConsoleTextAttribute PROTO,
    nStdHandle:DWORD,   ; console output handle
    nColor:DWORD        ; color attribute

WriteConsoleA PROTO,                   ; write a buffer to the console
    handle:DWORD,; output handle
    lpBuffer:PTR BYTE,                ; pointer to buffer
    nNumberOfCharsToWrite:DWORD,      ; size of buffer
    lpNumberOfCharsWritten:PTR DWORD, ; number of chars written
    lpReserved:PTR DWORD              ; 0 (not used)

CreateFileA PROTO,           ; create new file
    pFilename:PTR BYTE,     ; ptr to filename
    accessMode:DWORD,       ; access mode
    shareMode:DWORD,        ; share mode
    lpSecurity:DWORD,       ; can be NULL
    howToCreate:DWORD,      ; how to create the file
    attributes:DWORD,       ; file attributes
    htemplate:DWORD         ; handle to template file

ReadFile PROTO,           ; read buffer from input file
    fileHandle:DWORD,     ; handle to file
    pBuffer:PTR BYTE,     ; ptr to buffer
    nBufsize:DWORD,       ; number bytes to read
    pBytesRead:PTR DWORD, ; bytes actually read
    pOverlapped:PTR DWORD ; ptr to asynchronous info

GetTimeFormatA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
.data
	title1 byte "|------ Welcome to The Word Puzzle Game ------|", 0
	description byte "To Solve This Game, You have 10 minutes to find the word. Your time had started at: ", 0
	attri byte "Words you have to find from following Puzzle are :                             Score : ", 0
	errormsg byte "Invalid input "
	worderror byte "Word Already Found"
	incorrect byte "Incorrect answer "
	failuremsg byte "Word not found try Again!"
	AllWords byte 10000 dup (?)
	selectedWords byte 90 dup (?)
	SearchedWords byte 90 dup (?)
	searchcounter dword  0
	wordTohide byte 12 dup (?)
	timeFormat byte "hh:mm:ss tt", 0
	sysTime byte 12 dup (?)
	success byte "Congrats! Word Found",0
		count dword ?
	newline1 byte ' ',0Dh,0Ah

filePath byte  "D:\uni\4th\COAL\words1.txt", 0
	space byte ?
	WordsHided word 0h
	alphabets byte "abcdefghijklmnopqrstuvwxyz", 0
	seed dword ?
st4 byte"Please enter the word,row no and column no, and direction no (e.g dummyword 1 2 0) where row and column are from 0 to 14:",0Dh,0Ah
	
	; Possible Directions with Selected Words variables
	dw1 byte "                                                           :::	Possible Directions :::", 0
	dw2 byte "                                                                     5    0     1", 0
	dw3 byte "                                                                      \   |   /", 0
	dw4 byte "                                                                       \  |  /", 0
	dw5 byte "                                                                 4 ------ o ------ 2", 0
	dw6 byte "                                                                          |", 0
	dw7 byte "                                                                          |", 0
	dw8 byte "                                                                          3", 0
Grid byte 225 dup (?)
buffer byte 50 dup (?)
lenword dword 0
row byte 5 dup (?),0
col byte 5 dup (?),0
pos byte 5 dup(?),0
convrow dword ?
convcol dword ?
givenword byte 10 dup (?),0
startposition dword ?
done dword ?

	score sdword 0
	convscore sbyte 10 dup (?),0 

.code

; Generate a random number in the range [0, n-1]
; Expect one parameter that is 'n' in EAX
; returns random number in EAX
; seed is a dword type variable global variable initialized with positive number
; (It’s not a good practice though to use global variables inside the procedure)

generaterandom proc uses ebx edx
	mov ebx, eax ; maximum value
	mov eax, 343FDh
	imul seed
	add eax, 269EC3h
	mov seed, eax ; save the seed for the next call
	ror eax,8 ; rotate out the lowest digit
	mov edx,0
	div ebx ; divide by max value
	mov eax, edx ; return the remainder
	ret
generaterandom endp

newlinemtd proc
invoke GetStdHandle, -11
invoke WriteConsoleA ,eax , offset newline1 ,lengthof newline1, offset count ,0

newlinemtd endp


	;; It gets row and col in 2 byte of each
	;; Find the right position accoding to row and col of grid 15 order
getPosition proc uses ebx ecx edx
	and ecx, 0
	and eax, 0
	mov ax, [esp + 16]					; al = row
	mov cx, [esp + 18]					; cl = col
		mov bx, 15
		mul bx						; RowP = (row - 1) * 15
		xor ebx, ebx
		or bx, dx
		shl ebx, 16
		or bx, ax
		mov eax, ebx
		add ecx, 1
		add eax, ecx					; Position = RowP + col
		ret
getPosition endp

	;;	It appends zero in the variable "wordTohide"
	;;	It is called before to get new word in 
clearWordToHide proc uses ebx ecx edx
	mov ecx, 12
	and ebx, 0
	l1:
	mov wordTohide[ebx], 0h
	inc ebx
	loop l1
	ret
clearWordToHide endp

	;;	It generates random word from 0-7 total 8
	;;	It finds the word according to random no from variable "selectedWords"
	;;	It copys the specific random word from "selectedWords" to "wordTohide"
	;;	It finds the length of word which has copied in "wordTohide"
RWordandLength proc uses ebx esi ebp ecx edi
						; Finding The Random Word and it's Length
mov eax, [esp + 24]
	and ebx, 0
	and edi, 0
	and esi, 0
	and ebp, 0
	cmp eax, 0
	je length1
	WordLength:
	cmp word ptr selectedWords[esi], 0a0dh
	je	wordFound
		inc esi
		jmp WordLength
	wordFound:
		inc esi
		inc esi
		inc ebx						; word found
		add edi, ebx
		cmp ebx, eax
		jne WordLength
			length1:
			cmp word ptr selectedWords[esi], 0a0dh
			je break
				mov cl, selectedWords[esi]
				inc esi
				mov wordTohide[ebp], cl
				inc ebp										; EBP = Word Length
				jmp length1
			break:
				mov eax, ebp
				ret
RWordandLength endp

			;;; Takes 3 Arguments, row , col and the word length which has to be hide  :::" FOR DIRECTION 0 "::::

D0overlapcheck proc uses ebx ecx edx esi edi ebp
	mov bx, [esp + 28]			; row
	mov dx, [esp + 30]			; Col
	mov ebp, [esp + 32]
	and ecx, 0
	and edi, 0
	push dx
	push bx
	call getposition
	add esp, 4
	mov esi, eax			; esi = position
	push bx
	add bx, 1
	sub ebx, ebp
		cmp bx, 0			;(row + 1 - word.length) >= 0
	pop bx
		jbe CannotPlace
		push ebx					; pushing original row no.
							add ebx, 1
							sub ebx, ebp
							cmp ebx, 225				; (Row+1 - word.length) >= 0
		pop ebx	
							jae CannotPlace
			CanPlace:
			cmp ebp, edi		; Word has completed or not
			je WordCompleted
				cmp Grid[esi], 0
					je	PreviousRow
						push bx
						mov bl, Grid[esi]
						cmp wordTohide[edi], bl
						pop bx
						jne CannotPlace
							PreviousRow:
							cmp bx, 0		; (row >= 0)
							jbe WordCompleted
								sub esi, 15
								mov eax, 1
								inc edi
								jmp CanPlace
	CannotPlace:
	mov eax, 0
	WordCompleted:
	ret
D0overlapCheck endp

D1overlapCheck proc	uses ebx ecx edx esi edi ebp
	mov bx, [esp + 28]			; row
	mov dx, [esp + 30]			; Col
	mov ebp, [esp + 32]
	and ecx, 0
	and edi, 0
	push dx
	push bx
		call getPosition
	mov esi, eax			; Position
	pop bx
	pop dx
	push ebx
		add bx, 1
		sub bx, bp
		cmp bx, 0				;(Row +1 - word.length) >= 0
	pop ebx
		jae CheckFurther1
			jmp CannotPlace1
			CheckFurther1:
				push ebx
					add bx, 1
					sub bx, bp
					cmp bx, 225	
				pop ebx
					jbe Condition1
						jmp CannotPlace1
					Condition1:
						push ebx
						push edx
							mov bx, 15
							sub bx, dx
							cmp bx, bp				; (15 - Col) >= word.length
						pop edx
						pop ebx
							jae CanPlace1
								jmp CannotPlace1
							CanPlace1:
								cmp ebp, edi
								je WordCompleted1
										cmp Grid[esi], 0
										je NextPosition
											push ebx
											push edx
												mov bl, wordTohide[edi]
												cmp Grid[esi], bl
											pop edx
											pop ebx
												jne CannotPlace1
										NextPosition:
											cmp bx, 0
											je WordCompleted1
											sub esi, 14
											inc edi
											mov eax, 1 
											jmp CanPlace1 
						WordCompleted1:
						mov eax, 1
						jmp CanOccr1
			CannotPlace1:
				mov eax, 0	
			CanOccr1:
				ret
D1overlapCheck endp

							;;; Takes 3 Arguments, row , col and the word length which has to be hide  :::" FOR DIRECTION 2 "::::
	
D2overlapCheck proc uses ebx ecx edx esi edi ebp
	mov bx, [esp + 28]			; row
	mov dx, [esp + 30]			; Col
	mov ebp, [esp + 32]
	and ecx, 0
	and edi, 0
	push dx
	push bx
		call getPosition
	mov esi, eax			; Position
	pop bx
	pop dx
	push edx
	push ebx
		mov bx, 15
		add dx, 1
		sub bx, dx
		cmp ebx, ebp
	pop ebx
	pop edx
		jae CanPlace2
				jmp CannotPlace2
			CanPlace2:
				cmp ebp, edi				; Word has completed or not
				je WordCompleted2
					cmp Grid[esi], 0
					je nextCol
						push dx
							mov dl, wordTohide[edi]
							cmp Grid[esi], dl
						pop dx
							jne CannotPlace2
								nextCol:
								cmp dx, 15						; (col < 15)
								ja WordCompleted2
								inc esi
								mov eax,1
								inc edi
								inc dx
								jmp CanPlace2
				WordCompleted2:
					mov eax, 1
					jmp CanOccur
		CannotPlace2:
			mov eax, 0
	CanOccur:
		ret
D2overlapCheck endp


D3overlapCheck proc uses ebx ecx edx esi edi ebp
	mov bx, [esp + 28]			; row
	mov dx, [esp + 30]			; Col
	mov ebp, [esp + 32]
	and ecx, 0
	and edi, 0
	push dx
	push bx
	call getposition
	add esp, 4
	mov esi, eax			; esi = position
	push ebx
	push edx
		mov dx, 15
		sub dx, bx
		cmp edx, ebp			;(row + 1 - word.length) >= 0
	pop edx
	pop ebx
		jae CanPlace3
			jmp CannotPlace3
			CanPlace3:
			cmp ebp, edi		; Word has completed or not
			je WordCompleted3
				cmp Grid[esi], 0
					je	NextRow3
						push bx
						mov bl, Grid[esi]
						cmp wordTohide[edi], bl
						pop bx
						jne CannotPlace3
							NextRow3:
							cmp bx, 14		; (row >= 14)
							jae WordCompleted3
								add esi, 15
								inc bx
								mov eax, 1
								inc edi
								jmp CanPlace3
					
	WordCompleted3:
	mov eax, 1
	jmp CanOccr	
	CannotPlace3:
	mov eax, 0
	CanOccr:
	ret
D3overlapCheck endp


D4overlapCheck proc uses ebx ecx edx esi edi ebp
	mov bx, [esp + 28]			; row
	mov dx, [esp + 30]			; Col
	mov ebp, [esp + 32]
	and ecx, 0
	and edi, 0
	push dx
	push bx
		call getPosition
	pop bx
	pop dx
	mov esi, eax			; Position
	push edx
		add dx, 1
		sub edx, ebp
		cmp edx, 0
	pop edx
		jbe CannotPlace4
			push edx
				add dx, 1
				sub dx, bp
				cmp dx, 225
			pop edx
			ja CannotPlace4
			CanPlace4:
				cmp ebp, edi
				je WordCompleted4
					cmp Grid[esi], 0
					je previousCol4
						push edx
							mov dl, wordTohide[edi]
							cmp Grid[esi], dl
						pop edx
							jne CannotPlace4
						previousCol4:
							dec esi
							mov eax, 1
							inc edi
							jmp CanPlace4
				WordCompleted4:
					mov eax, 1
					jmp CanOccr4
		CannotPlace4:
			mov eax, 0
	CanOccr4:
		ret
D4overlapCheck endp



D5overlapCheck proc	uses ebx ecx edx esi edi ebp
	mov bx, [esp + 28]			; row
	mov dx, [esp + 30]			; Col
	mov ebp, [esp + 32]
	and ecx, 0
	and edi, 0
	push dx
	push bx
		call getPosition
		mov esi, eax			; Position
	pop bx
	pop dx
	dec esi
	push ebx
		add bx, 1
		sub bx, bp
		cmp bx, 0				; Row + 1 - word.length >= 0
	pop ebx
		jae FirstCond
			jmp CannotPlace5
		firstCond:
		push ebx
			add bx, 1
			sub bx, bp
			cmp bx, 225
		pop ebx
			jb NextCond
				jmp CannotPlace5
			NextCond:
				push edx
					add dx, 1
					cmp dx, bp				; Col + 1 >= word.length
				pop edx
					jae CanPlace5
						jmp CannotPlace5
					CanPlace5:
						cmp edi, ebp
						je WordCompleted5
							cmp Grid[esi], 0
							je NextPosition5
							push ebx
								mov bl, wordTohide[edi]
								cmp Grid[esi], bl
							pop ebx
								jne CannotPlace5
							NextPosition5:
								inc edi
								sub esi, 16
								mov eax, 1
								jmp CanPlace5
				WordCompleted5:
					mov eax, 1
					jmp CanOccr5
			CannotPlace5:
				mov eax, 0
	CanOccr5:
	ret
D5overlapCheck endp


D5putWord proc	uses ebx ecx edx esi edi ebp
	mov bx, [esp + 28]			; row
	mov dx, [esp + 30]			; Col
	mov ebp, [esp + 32]
	and ecx, 0
	and edi, 0
	push dx
	push bx
		call getPosition
		mov esi, eax			; Position
	pop bx
	pop dx
	dec esi
	push ebx
		add bx, 1
		sub bx, bp
		cmp bx, 0				; Row + 1 - word.length >= 0
	pop ebx
		jae FirstCond
		jmp  CannotPlace5
		firstCond:
		push ebx
			add bx, 1
			sub bx, bp
			cmp bx, 225
		pop ebx
			jb NextCond
				jmp CannotPlace5
			NextCond:
				push edx
					add dx, 1
					cmp dx, bp				; Col + 1 >= word.length
				pop edx
					jae CanPlace5
						jmp CannotPlace5
					CanPlace5:
						cmp edi, ebp
						je WordCompleted5
							cmp Grid[esi], 0
							je NextPosition5
							push ebx
								mov bl, wordTohide[edi]
								cmp Grid[esi], bl
							pop ebx
								jne CannotPlace5
							NextPosition5:
								push ebx
									mov bl, wordTohide[edi]
									mov Grid[esi], bl
								pop ebx
								inc edi
								sub esi, 16
								mov eax, 1
								jmp CanPlace5
				WordCompleted5:
					mov eax, 1
					jmp CanOccr5
			CannotPlace5:
				mov eax, 0
	CanOccr5:
	ret	
D5putWord endp



D4putWord proc uses ebx ecx edx esi edi ebp
	mov bx, [esp + 28]			; row
	mov dx, [esp + 30]			; Col
	mov ebp, [esp + 32]
	and ecx, 0
	and edi, 0
	push dx
	push bx
		call getPosition
		mov esi, eax			; Position
	pop bx
	pop dx
	dec esi
	push edx
		add dx, 1
		sub edx, ebp
		cmp edx, 0
	pop edx
		jbe CannotPlace4
			push edx
				add dx, 1
				sub edx, ebp
				cmp edx, 225
			pop edx
			jae CannotPlace4
			CanPlace4:
				cmp ebp, edi
				je WordCompleted4
					cmp Grid[esi], 0
					je previousCol4
						push edx
							mov dl, wordTohide[edi]
							cmp Grid[esi], dl
						pop edx
							jne CannotPlace4
						previousCol4:
							push edx
								mov dl, wordTohide[edi]
								mov Grid[esi], dl
							pop edx
							dec esi
							mov eax, 1
							inc edi
							jmp CanPlace4
				WordCompleted4:
					mov eax, 1
					jmp CanOccr4
		CannotPlace4:
			mov eax, 0
	CanOccr4:
	ret
D4putWord endp


D2PutWord proc	uses ebx ecx edx esi edi ebp
	mov bx, [esp + 28]			; row
	mov dx, [esp + 30]			; Col
	mov ebp, [esp + 32]
	and ecx, 0
	and edi, 0
	push dx
	push bx
		call getPosition
	pop bx
	pop dx
	mov esi, eax			; Position
	push edx
	push ebx
		mov bx, 15
		add dx, 1
		sub bx, dx
		cmp ebx, ebp
	pop ebx
	pop edx
		jae CanCopy2
				jmp CannotPlace2		
			CanCopy2:	
				cmp ebp, edi				; Word has completed or not
				je WordCompleted2
					cmp Grid[esi], 0
					je nextCol
						push dx
							mov dl, wordTohide[edi]
							cmp Grid[esi], dl
						pop dx
							jne CannotPlace2
								nextCol:
								cmp dx, 15		;(Col > 15)
								ja WordCompleted2
								push edx
									mov dl, wordTohide[edi]
									mov Grid[esi], dl
								pop edx
								inc esi
								mov eax,1
								inc edi
								inc dx
								jmp CanCopy2
				WordCompleted2:
					mov eax, 1
					jmp CanOccur
		CannotPlace2:
			mov eax, 0
	CanOccur:
		ret
D2PutWord endp


D3PutWord proc uses ebx ecx edx esi edi ebp
	mov bx, [esp + 28]			; row
	mov dx, [esp + 30]			; Col
	mov ebp, [esp + 32]
	and ecx, 0
	and edi, 0
	push ebx
	push edx
		mov dx, 15
		sub dx, bx
		cmp edx, ebp			;(15-Row) >= 0
	pop edx
	pop ebx
		jae CanPlace3
			jmp CannotPlace3
			CanPlace3:
			cmp ebp, edi		; Word has completed or not
			je WordCompleted3
				cmp Grid[esi], 0
					je	NextRow3
						push bx
						mov bl, Grid[esi]
						cmp wordTohide[edi], bl
						pop bx
						jne CannotPlace3
							NextRow3:
							cmp bx, 15		; (row >= 14)
							ja WordCompleted3
								push bx
									mov bl, wordTohide[edi]
									mov Grid[esi], bl
								pop bx
								inc bx
								add esi, 15
								mov eax, 1
								inc edi
								jmp CanPlace3
		WordCompleted3:	
		mov eax, 1
		jmp Canoccr3			
	CannotPlace3:
	mov eax, 0
	Canoccr3:
	ret
D3PutWord endp

d0PutWord proc uses ebx ecx edx esi edi ebp
	mov bx, [esp + 28]			; row
	mov dx, [esp + 30]			; Col
	mov ebp, [esp + 32]
	and ecx, 0
	and edi, 0
	push dx
	push bx
	call getposition
	add esp, 4
	mov esi, eax			; esi = position
	push bx
	add bx, 1
	sub ebx, ebp
		cmp bx, 0			;(row + 1 - word.length) >= 0
	pop bx
		jbe CannotPlace
		push ebx					; pushing original row no.
							add ebx, 1
							sub ebx, ebp
							cmp ebx, 225				; (Row+1 - word.length) >= 0
		pop ebx	
							jae CannotPlace
			CanPlace:
			cmp ebp, edi		; Word has completed or not
			je WordCompleted
				cmp Grid[esi], 0
					je	PreviousRow
						push bx
						mov bl, Grid[esi]
						cmp wordTohide[edi], bl
						pop bx
						jne CannotPlace
							PreviousRow:
							cmp bx, 0		; (row >= 0)
							jbe WordCompleted
								push bx
									mov bl, wordTohide[edi]
									mov Grid[esi], bl
								pop bx
								dec bx
								sub esi, 15
								mov eax, 1
								inc edi
								jmp CanPlace
	CannotPlace:
	mov eax, 0
	WordCompleted:
	ret
d0PutWord endp


D1putWord proc	uses ebx ecx edx esi edi ebp
	mov bx, [esp + 28]			; row
	mov dx, [esp + 30]			; Col
	mov ebp, [esp + 32]
	and ecx, 0
	and edi, 0
	push dx
	push bx
		call getPosition
	mov esi, eax			; Position
	pop bx
	pop dx
	push ebx
		add bx, 1
		sub bx, bp
		cmp bx, 0				;(Row +1 - word.length) >= 0
	pop ebx
		jae CheckFurther1
			jmp CannotPlace1
			CheckFurther1:
				push ebx
					add bx, 1
					sub bx, bp
					cmp bx, 225	
				pop ebx
					jbe Condition1
						jmp CannotPlace1
					Condition1:
						push ebx
						push edx
							mov bx, 14
							sub bx, dx
							cmp bx, bp				; (15 - Col) >= word.length
						pop edx
						pop ebx
							jae CanPlace1
								jmp CannotPlace1
							CanPlace1:
								cmp ebp, edi
								je WordCompleted1
										cmp Grid[esi], 0
										je NextPosition
											push ebx
												mov bl, wordTohide[edi]
												mov Grid[esi], bl
											pop ebx
										NextPosition:
											push ebx
												mov bl, wordTohide[edi]
												mov Grid[esi], bl
											pop ebx
											sub esi, 14
											inc edi
											mov eax, 1
											jmp CanPlace1 
						WordCompleted1:
						mov eax, 1
						jmp CanOccr1
			CannotPlace1:
				mov eax, 0	
			CanOccr1:
				ret

D1putWord endp



scoredecide proc uses esi ecx ebx
	mov ebx, eax
	and esi, 0
	mov esi, offset score
	mov ecx, esi
	inc ecx
	push ecx
	call toInt
	pop ecx
	mov ecx, eax

	cmp ebx, 1
	jne checkedWordCheck
						; Here means that 10 should be added in score
		cmp ecx, 0
		ja StayonMinus
			
			add ecx, 10
			mov sbyte ptr score, cl
			jmp doneT

		StayonMinus:
			
			add ecx, 10
			mov sbyte ptr score, cl
			mov [score], '+'
			jmp doneT

	checkedWordCheck:
		cmp ebx, 2
		jne subScore
			jmp doneT

		subScore:
			cmp ecx, 0
			ja	minus
				sub ecx, 10
				mov sbyte ptr score, cl
				jmp doneT
			minus:
				sub ecx, 10
				mov sbyte ptr score, cl
				mov [score], '+'
				jmp doneT
		

	doneT:
ret
scoredecide endp


				; Take offset of string and return to int in eax
toInt proc uses ebx ecx edx 
	mov esi, [esp + 16]
	and cl, 0
	and eax, 0
	and ebx, 0


	again:
	mov ch, [esi]

	cmp ch, 0
	jne iffcond
		jmp endiff

	iffcond:
		sub ch, '0'
		inc esi

		mov ebx, 10
		mul ebx
		movzx ecx, ch 
		add eax, ecx
		jmp again

	endiff:
	ret
toInt endp


toString proc uses ebx ecx edx 
	
;	movzx ebx, output ; Holds number to convert
;	mov esi, offset outputString	
;	mov edx,  sizeof outputString
;	add esi, edx
	dec esi

	ToString1:
		cmp ebx, 0
		je justjump
		push eax
		mov eax, ebx
		cdq
		mov ecx, 10
		div ecx
		mov ecx, edx
		mov ebx, eax
		pop eax
		add ecx, 48
		mov [esi], cl
		dec esi
		jmp ToString1
	justjump:
		ret
toString endp



subs proc uses ecx ebx esi edx ebp edi  
mov esi,[esp+28]

mov edx, 0
mov ebp,0
mov edi,lengthof selectedWords
mov ecx,0
l1:
mov eax,0

mov ebp,0
cmp eax,edi
dec edi
je endloop

cmp edx, lengthof selectedWords
jb l2


l2:

mov cl,[esi][edx]
mov ebx,offset givenword
mov bl,[ebx][ebp]
inc edx
inc ebp

cmp cl,bl
jne l1
cmp ebp,lengthof givenword
jb l3
jmp endloop

l3:
cmp cl,bl
jne l1
mov eax,1
mov ebx,offset givenword
mov bl,[ebx][ebp]
cmp bl,0
je endloop
cmp ecx,0
je endloop
jmp l2

endloop:

ret
subs endp
; this method will search for the word at the given cordinates 
;it will return 1 in eax if the answer is correct else 0
search proc

mov esi,0
and ebp,0
mov eax,0
; Agr code kuch masla kara to ya part ura dena :P
	mov esi,offset SearchedWords
	push esi	
			call subs
pop esi
cmp eax,0
je checkselected
jmp wordfounddone
;yahan tk ka 
checkselected:

	mov esi,offset selectedWords
	push esi	
			call subs
mov ebp,lenword
pop esi
cmp eax,1
je checkrow
jmp error
checkrow:
	cmp convrow,15

	jle checkcoloumn
	jmp error
checkcoloumn:
	cmp convcol,15
	jle calculations
	jmp error
calculations:
mov bx,word ptr convcol
mov ax,word ptr convrow
	push bx
	push ax
		call getposition
		add esp, 4
		
	mov startposition,eax
	dec startposition
	
	cmp pos,0
	jne position1

	push convrow
	sub convrow,ebp
	cmp convrow,0
pop convrow
	jnge error
	mov ecx,0
	
position0:
	cmp ecx,ebp
	jne l0
	inc done
mov eax,1
	jmp endloop
	
	l0:
	mov ebx,startposition
	mov dl,Grid[ebx]
	cmp givenword[ecx],dl
		
	je l00 
	jmp false
	l00:
	inc ecx
			sub startposition,15
	jmp position0


position1:
cmp pos,1
jne position2
push convrow
sub convrow,ebp
pop convrow
jnge error

mov eax,15
sub eax, convcol
jnge error

mov ecx,0
	
position1inn:
	cmp ecx,ebp
	jne l1
	inc done
	mov eax,1
	jmp endloop
	
	l1:
	mov ebx,startposition
	mov dl,Grid[ebx]
	cmp givenword[ecx],dl
		
	je l10 
	jmp false
	l10:
	inc ecx
			sub startposition,15
	inc startposition
	jmp position1inn






position2:
cmp pos,2
jne position3
push eax
mov eax,15
sub eax,convcol
cmp eax,ebp
pop eax
jnge error
	mov cl,0
	
position2inn:
	cmp ecx,ebp
	jne l2
	inc done
	mov eax,1
	jmp endloop
	l2:
	mov ebx,startposition
	mov dl,Grid[ebx]
	cmp givenword[ecx],dl
	je l20 
	jmp false
	l20:
		inc cl
inc startposition
	jmp position2inn



position3:
cmp pos,3
jne position4
push eax
mov eax,15
sub eax, convrow
add eax,1
cmp eax,ebp
pop eax
jnge error

	mov ecx,0
	
position3inn:
	cmp ecx,ebp
	jne l3 
	inc done
	mov eax,1
	jmp endloop
	l3:
	
	mov ebx,startposition
	mov dl,Grid[ebx]
	cmp givenword[ecx],dl
		
	je l30 
	jmp false
	l30:
	inc ecx
			add startposition,15
	jmp position3inn




position4:
cmp pos,4
jne position5
push convcol
sub convcol,ebp
cmp convcol, 0
pop convcol
jnge error
mov ecx,0
	
position4inn:
	cmp ecx,ebp
	jne l4
	inc done
	mov eax,1
	jmp endloop
	l4:
	mov al,15
	mov ebx,startposition
	mov dl,Grid[ebx]
	cmp givenword[ecx],dl
	je l40 
	jmp false
	l40:
		inc ecx
dec startposition
	jmp position4inn




pop convcol

position5:
cmp pos,5
jne error
push convrow
sub convrow,ebp
pop convrow
jnge error
cmp convcol,ebp
jnge error



mov ecx,0
	
position5inn:
	cmp ecx,ebp
	jne l5
inc done	
	mov eax,1
	jmp endloop
	l5:
	mov al,15
	mov ebx,startposition
	mov dl,Grid[ebx]
	cmp givenword[ecx],dl
		
	je l50 
	jmp false
	l50:
	inc ecx
			sub startposition,15
	dec startposition
	jmp position5inn




false:
mov eax,0
error:
invoke GetStdHandle, -11
invoke WriteConsoleA ,eax , offset failuremsg,lengthof failuremsg,offset count,0
call newlinemtd
mov eax,0

jmp endloop
wordfounddone:

invoke GetStdHandle, -11
invoke WriteConsoleA ,eax , offset worderror,lengthof worderror,offset count,0
call newlinemtd
mov eax,2
endloop:

ret
search endp

answer proc


cmp eax,1

jne incorrectans 
mov ebp,lenword

mov bx,word ptr convcol
mov dx,word ptr convrow
	push bx
	push dx
		call getposition
	add esp,4
	mov startposition,eax
	dec startposition

cmp pos,0
jne position1


	mov ecx,0
	
position0:
	cmp ecx,ebp
	jne l0
pop convrow

	jmp endloop
	
	l0:
	mov al,15
	mov ebx,startposition
mov edi,searchcounter
	mov dl,Grid[ebx]
	mov SearchedWords[edi],dl
	inc searchcounter
	inc ecx
			sub startposition,15
	jmp position0


position1:
cmp pos,1
jne position2


mov ecx,0
	
position1inn:
	cmp ecx,ebp
	jne l1
pop convrow

	jmp endloop
	
	l1:
	mov al,15
	mov ebx,startposition
mov edi,searchcounter
	mov dl,Grid[ebx]
	mov SearchedWords[edi],dl
	inc searchcounter
			inc ecx
			sub startposition,15
	inc startposition
	jmp position1inn





position2:
cmp pos,2
jne position3

	mov cl,0
	
position2inn:
	cmp ecx,ebp
	jne l2

	jmp endloop
	
	l2:
	mov al,15
	mov ebx,startposition
mov edi,searchcounter
	mov dl,Grid[ebx]
	mov SearchedWords[edi],dl
	inc ecx
		inc searchcounter
inc startposition
	jmp position2inn



position3:
cmp pos,3
jne position4

mov ecx,0
	
position3inn:
	cmp ecx,ebp
	jne l3 


	jmp endloop
	
	l3:
	mov al,15
	mov ebx,startposition
mov edi,searchcounter
	mov dl,Grid[ebx]
	mov SearchedWords[edi],dl
		inc ecx
		inc searchcounter
			add startposition,15
	jmp position3inn


position4:
cmp pos,4
jne position5

mov ecx,0
	
position4inn:
	cmp ecx,ebp
	jne l4

	jmp endloop
	
	l4:
	mov al,15
	mov ebx,startposition
mov edi,searchcounter
	mov dl,Grid[ebx]
	mov SearchedWords[edi],dl
	inc ecx
		inc searchcounter
dec startposition
	jmp position4inn



position5:

mov ecx,0
	
position5inn:
	cmp ecx,ebp
	jne l5

jmp endloop
	
	l5:
	mov al,15
	mov ebx,startposition
mov edi,searchcounter
	mov dl,Grid[ebx]
	mov SearchedWords[edi],dl
		inc ecx
		inc searchcounter
			sub startposition,15
	dec startposition
	jmp position5inn


incorrectans:

invoke GetStdHandle, -11
invoke WriteConsoleA ,eax , offset incorrect,lengthof incorrect,offset count,0

endloop:

ret
answer endp



;breaks  input into seperate variables
inputbreak proc
mov eax,0
mov count,0
mov ebx,offset buffer
mov edx,0
mov ecx,0
givenwordst:
mov al,[ebx+edx]
cmp al, 0
je error
	cmp eax,020h
	jne moveletters
	inc edx

givenrowst:
mov al,[ebx+edx]
cmp al, 0
je error
	cmp eax,020h
	jne movrow
	
	push offset row
push count
push offset convrow
call convertascii
add esp,12
mov count,0	
cmp convrow,14
jnle error
	inc edx
mov ecx,0

givencolst:

mov al,[ebx+edx]
	cmp al,0
	je error
	
	cmp eax,020h
	jne movcol
	push offset col
push count
push offset convcol
call convertascii
	add esp,12
	cmp convcol,14
	jnle error
	inc edx
	mov al,[ebx+edx]
	cmp al,0
	je error
	cmp al,'-'
	je error
	mov pos,al

	sub pos,48
	cmp pos,5
	jnle error
	jmp endloop

moveletters:

mov al,[ebx+edx]
	inc lenword
	mov givenword[edx],al
	inc edx
	jmp givenwordst

movrow:
mov al,[ebx+edx]
mov row[ecx],al
inc ecx
inc count
	inc edx
	jmp givenrowst

movcol:
mov al,[ebx+edx]
mov col[ecx],al
inc ecx
inc count
	inc edx
	jmp givencolst
	error:
	invoke GetStdHandle, -11
invoke WriteConsoleA ,eax , offset errormsg,lengthof errormsg,offset count,0
call newlinemtd
jmp finalend
endloop:

continue0 :
push offset givenword
call strlength
mov ecx,edi
push offset row
call strlength
mov ebx,edi
push offset col
call strlength
mov edx,edi
add ecx,ebx
add ecx,edx
push offset pos
call strlength
mov ebx,edi
add ecx,ebx
add ecx,3
push offset buffer
call strlength
mov esi,edi
sub esi,2
	continue:

cmp ecx,esi
jne error

finalend:
add esp,20
ret
inputbreak endp
strlength proc 
mov esi,[esp+4]
mov edi,0
bufferLength:
mov al,[esi+edi]
	cmp  al, 0
	je	endloop
		inc edi
		jmp bufferLength
		endloop:
		
		ret
strlength endp
convertascii proc uses ebp ecx ebx eax edx edi esi	;converts back to decimal
;push offset num2
;push lengthtem
;push offset convertnum2

mov ebp,[esp+32]; conv num
mov ecx,[esp+36]  ;length
	push ecx
mov eax,1
mov ebx,10
l1:
mul ebx
dec ecx
cmp ecx,0
jne l1
pop ecx
mov ebx,0
mov edi,10
mov esi,[esp+40]; num
l2:
mov bl,[esi]
sub bl,48
cdq
div edi
push eax
movzx ebx,bl
mul ebx
mov ebx,eax
add ebx,[ebp]
mov [ebp],ebx
mov ebx,0
pop eax
inc esi
dec ecx
cmp ecx,0
jne l2
jmp endloop 

endloop :

ret
convertascii endp		


wordschose proc

and ebp, 0
and ecx, 0

or ecx, 8

Ran:

and esi, 0			; index
and edx, 0			; edx will count AllWords by enter key asci
push ecx
mov eax,500
call generaterandom


checkAllWords:

cmp word ptr AllWords[esi], 0a0dh
jne Select8Words
	
	inc esi
	inc edx
	push eax
	dec eax
	cmp edx, eax 			; comparing enter key assci code with random no (eax)

	pop eax
	jne checkAllWords
		MovSelectWord:
			inc esi
			mov cl, AllWords[esi]
			mov selectedWords[bp], cl
			inc bp
			cmp  AllWords[esi], 0ah				; Enter key automaitcally added here, No need to add separately add after selected word
			jne MovSelectWord
				jmp endSelection
	Select8Words:
		inc esi
		jmp checkAllWords
	endSelection:
	pop ecx
loop Ran	

ret
wordschose endp
wordstomatrix proc

mov ecx,8
l1:
mov eax,255
call generaterandom

l2:
cmp Grid[eax],0Ah
mov Grid[ebx],al
inc ebx
loop l1 

ret
wordstomatrix endp
settemp proc
and edx, 0			; Checks which word no is on current position
or edx, 1

and esi, 0
and ecx, 0
and bp, 0

checkWords:
cmp word ptr selectedWords[esi], 0a0dh
jne copywords
	inc esi
	inc esi
	inc edx
	and bp, 0
	jmp checkwords

copywords:
	
	cmp edx, 1
	jne indw2

		mov cl, selectedWords[esi]
		mov dw1[bp], cl
		inc bp
		inc esi
		jmp checkwords

	indw2:
		cmp edx, 2
		jne indw3
			mov cl, selectedWords[esi]
			mov dw2[bp], cl
			inc bp
			inc esi
			jmp checkwords

	indw3:
		cmp edx, 3
			jne indw4
				mov cl, selectedWords[esi]
				mov dw3[bp], cl
				inc bp
				inc esi
				jmp checkwords

	indw4:
		cmp edx, 4
			jne indw5
				mov cl, selectedWords[esi]
				mov dw4[bp], cl
				inc bp
				inc esi
				jmp checkwords

	indw5:
		cmp edx, 5
			jne indw6
				mov cl, selectedWords[esi]
				mov dw5[bp], cl
				inc bp
				inc esi
				jmp checkwords

	indw6:
		cmp edx, 6
			jne indw7
				mov cl, selectedWords[esi]
				mov dw6[bp], cl
				inc bp
				inc esi
				jmp checkwords

	indw7:
		cmp edx, 7
			jne indw8
				mov cl, selectedWords[esi]
				mov dw7[bp], cl
				inc bp
				inc esi
				jmp checkwords

	indw8:
		cmp edx, 8
			jne endCheckWords
				mov cl, selectedWords[esi]
				mov dw8[bp], cl
				inc bp
				inc esi
				jmp checkwords
endCheckWords:
ret
settemp endp

main proc

mov seed, eax
invoke GetTickCount
push eax
						;; Displays Title
invoke GetStdHandle, -11
invoke SetConsoleCursorPosition, eax, 30

invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset title1, lengthof title1, offset count, 0

call newlinemtd

invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset description, lengthof description, offset count, 0

invoke GetTimeFormatA, 0000h, 0, 0, offset timeformat, offset sysTime, lengthof sysTime

invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset sysTime, lengthof sysTime, offset count, 0

call newlinemtd

invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset attri, lengthof attri, offset count, 0				;; Till "Score:"


invoke GetStdHandle,-11
 
invoke CreateFileA, offset filepath, 1, 0, 0, 3, 128, 0
	;handle will be in eax
push eax
invoke ReadFile, eax, offset AllWords, lengthof AllWords, offset count, 0
mov ebx, count
pop eax
invoke CloseHandle, eax
			

call wordschose
 
call settemp

call newlinemtd


invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset dw1, lengthof dw1, offset count, 0

call newlinemtd
invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset dw2, lengthof dw2, offset count, 0

call newlinemtd
invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset dw3, lengthof dw3, offset count, 0

call newlinemtd
invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset dw4, lengthof dw4, offset count, 0

call newlinemtd
invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset dw5, lengthof dw5, offset count, 0

call newlinemtd
invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset dw6, lengthof dw6, offset count, 0

call newlinemtd

invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset dw7, lengthof dw7, offset count, 0

call newlinemtd

invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset dw8, lengthof dw8, offset count, 0

call newlinemtd
call newlinemtd



									;;; Finding The Random Column, Row and their Relevent Position
PickAnotherPosition:

and eax, 0
and ebx, 0
mov eax, 15
call generaterandom
mov ebx, eax				; bx = row (0-14)

and eax, 0
and edx, 0
mov eax, 15
call generaterandom
mov edx, eax				; dx = col (0-14)

push dx
push bx
call getPosition
pop esi
mov esi, eax			; position that has to be added in the offset of grid to start to hide the word 

PickAnotherWord:

call clearWordToHide
movzx eax, WordsHided
push eax
call RWordandLength						; Retruns eax = word.Length,	wordTohide has the random word now
mov ebp, eax						; ebp =  wordtoHide word length

	getDirectionAgain:
		mov eax, 6
		call generaterandom
		mov edi, eax			; random direction
	
	direction0:
	cmp edi, 0
	jne direction1
			push ebx					; pushing original row no.
				add ebx, 1
				sub ebx, ebp
				cmp ebx, 0				; (Row+1 - word.length) >= 0
			pop ebx						; getting back the original row no.
				jae CheckFurther0 
					jmp PickAnotherPosition
					CheckFurther0:
									; Now check overlapping
						push ebx					; pushing original row no.
							add ebx, 1
							sub ebx, ebp
							cmp ebx, 225				; (Row+1 - word.length) >= 0
						pop ebx	
							ja PickAnotherWord
						push ebx		; row
						push edx		; col
						push edi		; direction
						push esi		; position
							and edi, 0
							check0:
							push ebp		; word.length
							push dx			; col
							push bx			; row
							call D0overlapCheck
							add esp, 8
						pop esi
						pop edi
						pop edx
						pop ebx
							cmp eax, 1
							jne PickAnotherPosition		
								push ebp
								push dx
								push bx
								call d0PutWord
								add esp, 8
				add WordsHided, 1
				cmp WordsHided, 7
				ja AllHided
					jmp PickAnotherPosition

	direction1:
	cmp edi, 1
	jne direction2
			push ebp				; word.length
			push dx					; col
			push bx					; row
			call D1overlapCheck		; Checks Overlap of Direction 1 for the random word selected
			add esp, 8
			cmp eax, 1
			jne PickAnotherPosition
				push ebp				; word.length
				push dx					; col
				push bx					; row
				call D1PutWord			; Coping the word in Grid in the direction of 1
				add esp, 8
				add WordsHided, 1
				cmp WordsHided, 7
				ja AllHided
					jmp PickAnotherPosition

	direction2:
	cmp edi, 2
	jne direction3
	
			push ebp				; word.length
			push dx					; col
			push bx					; row
			call D2overlapCheck		; Checks Overlap of Direction 3 for the random word selected
			add esp, 8
			cmp eax, 1
			jne PickAnotherPosition
				push ebp				; word.length
				push dx					; col
				push bx					; row
				call D2PutWord			; Coping the word in Grid in the direction of 2
				add esp, 8
				add WordsHided, 1
				cmp WordsHided, 7
				ja AllHided
					jmp PickAnotherPosition

	direction3:
	cmp edi, 3
	jne direction4
			push ebp				; word.length
			push dx					; col
			push bx					; row
			call D3overlapCheck
			add esp,8
			cmp eax, 1
			jne PickAnotherPosition
				push ebp				; word.length
				push dx					; col
				push bx					; row
				call D3PutWord			; Coping the word in Grid in the direction of 3
				add esp, 8
				add WordsHided, 1
				cmp WordsHided, 7
				ja AllHided
					jmp PickAnotherPosition
	
	direction4:
	cmp edi, 4
	jne direction5
			push ebp				; word.length
			push dx					; col
			push bx					; row
			call D4overlapCheck
			add esp, 8
			cmp eax,1
			jne PickAnotherPosition
				push ebp				; word.length
				push dx					; col
				push bx					; row
				call D4PutWord			; Coping the word in Grid in the direction of 4
				add esp, 8
				add WordsHided, 1
				cmp WordsHided, 7
				ja AllHided
					jmp PickAnotherPosition

	direction5:
	cmp edi, 5
	jne AllHided
		push ebp				; word.length
			push dx					; col
			push bx					; row
			call D5overlapCheck
			add esp, 8
			cmp eax,1
			jne PickAnotherPosition
				push ebp				; word.length
				push dx					; col
				push bx					; row
				call D5PutWord			; Coping the word in Grid in the direction of 5
				add esp, 8
				add WordsHided, 1
				cmp WordsHided, 7
				ja AllHided
					jmp PickAnotherPosition



AllHided:
							;;; This inserts '-' in the Grid.
							;;; For 2nd part we can use this for our easy approach and searching them.

mov esi, 0
mov ecx, 15
Outer:
push ecx
mov ecx, 15
Inner:
cmp Grid[esi], 0
je PutRandom
	jmp Leaveit
PutRandom:
	mov Grid[esi], '-'
	inc esi
	jmp Endthis
	Leaveit:
	inc esi
	Endthis:
loop Inner
pop ecx
loop Outer

								;;; This Inserts the random alphabet in the Grid, leaving hided words position

;and esi, 0
;mov ecx, 15
;Outer1:
;;push ecx
;	mov ecx, 15
;;Inner1:
;			mov eax, 26
;			call generaterandom
;;			cmp Grid[esi], 0
;			je putAlpha
;				jmp bS1
;			putAlpha:
;				mov bl, alphabets[eax]
;				mov Grid[esi], bl
;			inc esi
;;				jmp BS
	;				bS1:
				inc esi
	;		BS:
;loop Inner1
;pop ecx
;loop Outer1

						;;; This Prints The Grid regardless of WHatever is in it.


;this part will be used as a loop for continuing the game highligthing ka kaam idher dalna and is loop ko apna hisab sa set krlo 
;isma jo 3 function call hua hai input break user ki given input ko 4 parts ma torta hai
;search wala search krta hai and answer wala jo searchedanswers hai usko aik array ma store krta hai 

continuegame:

mov ecx, 15
mov esi, offset Grid
colPrint:
	push ecx
	mov ecx, 15
	rowPrint:
		push ecx
		invoke GetStdHandle, -11
		invoke WriteConsoleA, eax, esi, 1, offset count, 0
		inc esi
		invoke GetStdHandle, -11
		invoke WriteConsoleA, eax, offset space, 1, offset count, 0
		pop ecx
	loop rowPrint
call newlinemtd
	pop ecx
loop colPrint
call newlinemtd
pop ebx					; Contains Time which has saved on the starting of pragram
invoke  GetTickCount
sub eax, ebx

mov ecx,8
cmp ecx,done
je endloopfinal

printon:
invoke GetStdHandle, -11
invoke WriteConsoleA, eax, offset st4, lengthof st4, offset count, 0

invoke GetStdHandle, -10
invoke ReadConsoleA ,eax , offset buffer, lengthof buffer, offset count ,0



call inputbreak

call search

push eax
cmp eax,1
jne scoreonwards
invoke GetStdHandle, -11
invoke WriteConsoleA ,eax , offset success,lengthof success,offset count,0

call newlinemtd

scoreonwards:
pop eax
;push eax
call scoredecide
;pop eax
call answer
invoke GetStdHandle,-11
 

call newlinemtd
jmp continuegame
endloopfinal:
	invoke ExitProcess, 0
main endp 
end main