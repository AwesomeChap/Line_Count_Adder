;					modified_textfile.asm
;					---------------------
;Source name:		modified_textfile.asm
;Executable name:	modified_textfile.asm
;Version:		1.0
;Created date:		22/06/2018
;Last Update:		22/06/2018
;Author:		Jatin Kumar
;Description:		text file I/O demo for linux, using NASM, What we do is pass a 
;			random input file containing some paragraphs. Our program then 
;			processes it and after every 64 charcters it breaks the para
;			into a new line with a incremented index. which you can see in
;			your output file ^_^
;
;Build Using these commands:
;	nasm -f elf -g -F stabs modified_textfile.asm
;	nasm -f elf -g -F stabs linelib.asm
;	gcc -m32 textfile.o linlib.o -o modified_textfile
;
;Note: this program requires several procedures in an external named LINLIB.ASM
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


[SECTION .data]				;section containing initialized data

StringFormat	dd  '%s',0
IntFormat	dd  '%d',0
WriteBase	db  '%d/ %s',10,0
DiskHelpNm	db  'Helptextfile.txt',0
WriteCode	db  'w',0
OpenCode	db  'r',0
ProcessMsg	db  '> Processing request...',10,0
Msg1		db  '> Input file processed...',10,0
Msg2		db  '> Output file processed...',10,0
Msg3		db  '>> Reading data <%s>  from %s....',10,0
Msg4		db  '<< Writing "%s" to %s....',10,0
DoneMsg		db  '> Your requested file has been processed with name "%s"',10,0
DefOutputFile	dd  'a.txt',0
Err1		db  'ERROR : It is compulsory to mention the name of input file.',10,0
Err2		db  'ERROR : Unable to read data from %s, PLease enter file name that exists.',10,0
Err3		db  'ERROR : Unable to open %s for writing',10,0
Err4		db  "ERROR : Can't Write to %s ",10,0
HelpMsg		db  'TEXTTEST:Generates a new test file with modified text. Arg(1)',10,0
HELPSIZE	EQU $-HelpMsg
		db  'should be name of text file to be read. Arg(2) should be name',10,0
		db  'of the output file with modified text or otherwise by default',10,0
		db  'a.tx name would be given to output file by default. This msg',10,0
		db  'appears only if the file HELPTEXTFILE.TXT cannot be opened.',10,0
HelpEnd		dd  0

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

[SECTION .bss]				;section containing un-initialized data

OutputFile:	resd  10
InputFile:	resd  10
HELPLEN:	EQU   72
HelpLine:	resd  HELPLEN
BUFSIZE:	EQU   64
Buff:		resb  BUFSIZE+5
inputFD		resd  1
outputFD	resd  1
argc		resd  1

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

[SECTION .text]				;section containing actual code ^_^

;from glibc

extern	fopen
extern 	fclose
extern	fgets
extern	fprintf
extern	printf
extern 	sscanf
extern	strlen

;from linlib

extern newline

global	main				;required so linker can find entry point

main:	push	ebp			;setup stack frame for debugger
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi

;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo	
;<--------------------| Every Thing Before This Is A Boiler-Plate |---------------------->
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo


	;First test is to see if there are command line arguments at all. If there are none. 
	;we show the help info as several lines. Don't forget that the first arg is always 
	;the program name / invocation text, so there's always atleast 1 cmd-line argument! 
	
	mov	eax,[ebp+8]	;Load argc from stack
	mov	[argc],eax
	cmp	eax,1		;comparing eax with 1; input file is mendatory to mention
	ja	chkarg2		;if eax > 1 i.e. if any cmd-line args passed jump to chkarg2
	mov	ebx,DiskHelpNm	;put the address of help file name in ebx
	call	diskhelp	;if only 1 arg, show help info...
	jmp	gohome		;...and exit the program

;Next we print Msg1 and extact name of input file

chkarg2:push	Msg1
	call	printf
	add	esp,4

	mov	ebx,[ebp+12]	;put pointer to argument table into ebx
	push	InputFile	;push address of InputFile variable for sscanf
	push	StringFormat	;push address of string format string
	push	dword[ebx+4]	;push pointer to arg(1) i.e. name of file to be read
	call	sscanf		;call sscanf to extract name of input file 
	add	esp,12		;clean up the stack
	cmp	eax,0		;return value of > 0 says we got something
	ja	chkarg3		;if we got a number, go on and check for Output file name; else abort
	
	mov	eax,Err1	;load EAX with address of Err msg
	call	showerr		;call err msg printing function
	jmp	gohome		;abort

;Here we print Msg2 and check for the name of output file

chkarg3:push	Msg2
	call	printf
	add	esp,4

	cmp	dword[argc],2
	jz	putDef
	
	mov	ebx,[ebp+12]	;put pointer to argument table into ebx
	push	OutputFile	;push address of OutputFile variable for sscanf
	push	StringFormat	;push the string format
	push	dword[ebx+8]	;push the address of second arg from 0-based arg list 
	call	sscanf		;call sscanf
	add	esp,12		;clean stack
	cmp	eax,0		;see if everything happened successfully
	ja	openIF		;if parsed successfully jump to openIF to read input file
	
putDef:	mov	eax,dword[DefOutputFile];incase of no input from user work with def val a.txt
	mov	[OutputFile],eax;pass the a.txt in OutPutFile
	jmp	openIF		;jump to openIF label for furthur action

;here we open the input file specified by user in "read" mode and store file handle in [inputFD]

openIF:	push	OpenCode	;open code 'r'
	push	InputFile	;name of input file
	call	fopen		;fopen() to open the input file
	add	esp,8		;stack cleaned
	mov	[inputFD],eax	;mov file descriptor returned in EAX to EBX
	cmp	dword[inputFD],0 ;check if file exits or not?
	ja	openOF		;if exists : jump to openOF to open output file in read mode
	
	push	InputFile	;name of input file	
	push	Err2		;else abort the application by printing the err msg
	call	printf		;display err msg
	add	esp,8		;clean stack
	jmp	gohome		;end the program

;here we open the output file specified by user in "write" mode and store file handle in [outputFD]

openOF:	push	WriteCode	;write code 'w'
	push	OutputFile	;name of output file
	call	fopen		;fopen()
	add	esp,8		;cleaning stack
	mov	[outputFD],eax	;mov file handle from ESP to mem outputFD
	cmp	dword[outputFD],0 ;check if file exists or not
	ja	rwFile		;if true - jmp to function which would read from IF and write to OF
				
	push	OutputFile	;name of output file
	push	Err3		;push err msg to stack for printf
	call	printf		;call printf
	add	esp,8		;restore ESP
	jmp	gohome		;abort

;here we read from input file and write to output file with line numbers
	
rwFile:	xor	esi,esi		;zero ESI (Line Counter)
	inc	esi		;ESI=1

;here we read from input file and store the bytes read in Buff and remove line feed from end 
;if found

read:	push	dword[inputFD]	;push the file descriptor of input file
	push	BUFSIZE		;no of bytes to be read (64)
	push	Buff		;address of place to store read bytes
	call	fgets		;function call for fgets
	add	esp,12		;clean stack
	mov	edi,eax		;save value returned by fgets in EDI 
	
	push	Buff		;push address of Buff
	call	strlen		;call	strlen
	cmp	byte[Buff+eax-1],10	;check for \n at the end		
	jnz	display			;if not found proceed normally
	mov	byte[Buff+eax-1],0	;else remove linefeed 
	jmp	display			;then proceed

;It is the second half of read label where we display the name of file and data read
;and check for EOF, if found we terminate the process

display:push	InputFile	;push the addr of name of input file
	push	Buff		;push the addr of bytes read (Buff)
	push	Msg3		;push msg
	call	printf		;call printf
	add	esp,12		;clean stack
	
	cmp	edi,0		;check if value returned by fgets is != 0
	jz	doneWrite	;if = 0 terminate the program
	jnz	write		;else go on to write the buffer read
	
;here we close both the files

closeFiles:
	push	dword[inputFD]	;pass the FD for input file
	call	fclose		;call fclose
	add	esp,4		;clean stack

	push	dword[outputFD]	;pass the FD for output file
	call	fclose		;call fclose
	add	esp,4		;clean stack
	
	jmp	gohome		;abort

;here we write the bytes read from input file to output files and display the 
;msg beneficial for debugging purposes and if successfully written to file we
;mov on to read label to extract next chunk of 64 bytes from input file

write:	push	Buff		;address of buffer
	push	esi		;line number
	push	WriteBase	;base string
	push	dword[outputFD]	;file descriptor for output file
	call	fprintf		;fprintf call
	add	esp,16		;cleaning the stack
	mov	edi,eax		;save the value returned in EDI

	push	OutputFile	;here we display the the Msg4 having basic info
	push	Buff		;like name of file and data read...
	push	Msg4
	call	printf
	add	esp,12

	cmp	edi,0		;compare the value returned with 0
	jle	WrtErr		;if 0 we call WrtErr to display err msg
	inc	esi		;increase Line Count
	jmp	read		;jump to read to get next 64 bytes of data

;it is label which is invoked when we do not have any more data to be writen
;so we terminate the process by displaying a success msg and calling gohome label
	
doneWrite:
	push	OutputFile
	push	DoneMsg
	call	printf
	add	esp,8
	
	jmp 	closeFiles

;it is simple lable employed to display any err msgs if any

WrtErr:	push	dword[OutputFile]
	push	Err4
	call	printf
	add	esp,8
	jmp	gohome		
	

;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
;<----------------------| Every Thing After This Is A Boiler-Plate |--------------------->
;ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo

gohome:	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret

;SUBROUTINES ============================================================================>

;----------------------------------------------------------------------------------------
; Disk-base mini-help subroutines == last update 22/06/2018				|
;											|
; This routine reads text from a text file, the name of which is passed by  way of a 	|
; pointer to the name string in EBX, The routine opnes the textfile.			|
; 											|
; reads the text from it, and displays it to standard output. if the file cannot be	|
; opened, a very short memory-based message is displayed instead			|
;----------------------------------------------------------------------------------------

diskhelp:
	push  	OpenCode	;push pointer to open-for-read cose 'r'
	push  	ebx		;pointer to name of help file is passed in ebx
	call  	fopen		;attempt to open the file reading
	add 	esp,8		;clean up the stack
	cmp	eax,0		;fopen returns null if attempted open failed
	jne	.disk		;rea help info from disk, else from memory
	call	memhelp
	ret
.disk:	mov	ebx,eax		;save the handle of the operand file in ebx
.rdln:	push	ebx		;push file handle on the stack 
	push	dword HELPLEN	;limit line length of text read
	push	HelpLine	;push address of help text line buffer
	call	fgets		;read a line of text from the file
	add	esp,12		;clean stack
	cmp	eax,0		;a returned null idicates error or EOF
	jle	.done		;if we get 0 in eax, close up and return
	push	HelpLine	;push address of help line on the stack
	call	printf		;call printf to display help line
	add	esp,4		;clean up the stack
	jmp	.rdln

.done:	push	ebx		;push the handle of the file to be closed
	call	fclose		;closes the file whose handle is on stack
	add	esp,4		;cleam up stack
	ret			;return to caller

memhelp:mov	eax,1		
	call	newline
	mov	ebx,HelpMsg	;load the addr of help text in EAX
.chkln:	cmp	dword[ebx],0	;does help msg pointer point to a null?
	jne	.show		;if not, show the help lines
	mov 	eax,1		;load EAX with number of newlines to output
	call	newline		;output the newlines
	ret			;if yes, go home
.show:	push	ebx		;push addr of help line on the stack
	call	printf		;display the line
	add	esp,4		;clean up the stack
	add	ebx,HELPSIZE	;increment addr by length of help line
	jmp	.chkln		;loop back and check to see if we done yet

showerr:push	eax		;on entry, EAX contains addr of err msg
	call	printf		;show err msg
	add	esp,4		;clean up the stack
	ret			;return to caller

												 
;		   -------------------------------------------------------------
;		   | Breif explaination of inner working of common C functions |
;		   -------------------------------------------------------------

;************************************************************************************************
; In Unix everything is file based. Nothing is floating in air freely. Every damn thing is	|
; stored in file statically which may be changed dynamically.					|
;												|
; In scanf function our input text is first stored in STDIN file whose file descriptor is 0	|
; and then some number of bytes (depends on the size of the variable) from file are transfered	|
; to the variable (remember that no. of bytes that are being transferred can be <= total bytes 	|
; present in file.										|
;												|
; In printf function the text is first loaded from the source variabe to STDOUT file whose	|
; file descriptor is 1 which is then correspondingly displayed in console			|
;												|
; fscanf is a more of a general sort of function as compared to scanf where file descriptor 	|
; can have any arbitrary value other than only 0 as in case of scanf. We can say that scanf	|
; function is more or less a special case of fscanf which can be used for intuitive taskes 	|
; comparatively											|
;												|
; Similarly fprintf is another function who is similar to printf function which could be used	|
; with any arbitrary file descriptor other than only 1						|
;												|
; NOTE: fgets is another function which is employed for same puroposes for which fscanf is.	|
;       One major diff b/w the two is that fgets accepts whitespace characters where as in 	|
;       case of fscanf execution is stopped immediately as it encounters a white space 		|
;       character like space, linefeed, tab,etc (0-32 ascii codes)				|
;************************************************************************************************
