*
* Remake in assembly language of "Cityscape", one of the short program of Lee Fastenau - thelbane.
* https://github.com/thelbane/Apple-II-Programs 
*
* For HGR, HPLOT etc. see "Inside the Apple IIe.pdf" p. 276
* for FP routines : 
* "micro_22_mar_1980.pdf" 
* "micro_33_feb_1981.pdf"
* "Assembly Lines Complete.pdf" ; 
* "Apple-Orchard-v1n1-1980-Mar-Apr.pdf"
* Poms 18
* Poms 20
* "Apple_Programmers_Handbook_1984.pdf"
* Inside the Apple IIe.pdf"
****

****** FP routines ******
float   equ $e2f2
PRINTFAC equ $ED2E
FIN equ $EC4A           ; FAC = expression pointee par TXTPTR
FNEG equ $EED0          ; FAC = - FAC
FABS equ $EBAF          ; FAC = ABS(FAC)
F2INT16 equ $E752       ; FAC to 16 bits int in A/Y and $50/51 (low/hi)
FADD    equ $E7BE       ; FAC = FAC + ARG 
FSUBT   equ $E7AA       ; FAC = FAC - ARG
FMULT   equ $E97F       ; Move the number pointed by Y,A into ARG and fall into FMULTT 
FMULTT  equ $E982       ; FAC = FAC x ARG
FDIVT   equ $EA69       ; FAC = FAC / ARG
RND     equ $EFAE       ; FAC = random number
FOUT    equ $ED34       ; Create a string at the start of the stack ($100−$110)
MOVAF   equ $EB63       ; Move FAC into ARG. On exit A=FACEXP and Z is set
CONINT  equ $E6FB        ; Convert FAC into a single byte number in X and FACLO
YTOFAC  equ $E301
MOVMF   equ $EB2B       ; Routine to pack FP number. Address of destination must be in Y
          ; (high) and X (low). Result is packed from FAC
QUINT   equ $EBF2       ; convert fac to 16bit INT at $A0 and $A1
STROUT  equ $DB3A       ; 

****** 
printhex equ $FDDA
******

TXTPTR equ $b8
CHARGET equ $b1
CHARGOT equ $b7

fac equ $9d
arg equ $a5

ptr equ $06
************************************************
    put const
    org $8000

debut

    lda #17     ; 40 col.
    jsr cout
    jsr home    ; clear screen

    ldy #>welcome   ; print welcome
    lda #<welcome
    jsr STROUT
    ldy #>choix     ; print choice string
    lda #<choix
    jsr STROUT
    jsr rdkey       ; read user choice
    pha
    jsr initrandom  ; init random with $4e/$4f
    jsr savfac      ; sav "random" fac
    pla
    cmp #"S"    ; slow ?
    beq slow
    cmp #"s"    ; slow ?
    beq slow    
    cmp #"F"    ; fast ?
    beq fast
    cmp #"f"    ; fast ?
    beq fast
    cmp #"E"    ; exit ?
    beq stop
    cmp #"e"    ; exit ?
    beq stop   
    bne debut   ; none of these 6 chars : restart
stop 
    jsr home    ; home
    rts         ; exit

slow 
    lda #35
    sta speed
    jmp debut2
fast 
    lda #01
    sta speed
    jmp debut2

debut2
    jsr fondbleu
    jsr initHGR

init
    lda #$00
    sta passe
    sta xend
    sta xstart
    jsr getfac      ; restrore "random" fac

bigloop
    lda #$00
    sta xstart

mloop
* J = I +  INT (RND (1) * 3) + 2
    lda $4e 
    jsr RND     ; fac = random number (> 0 et < 1)

**************
    ldy #>myfac
    ldx #<myfac
    jsr MOVMF   ; move fac => memory (packed) = RND
    ldy #3
    jsr YTOFAC  ; fac = 3 
    ldy #>myfac 
    lda #<myfac
    jsr FMULT   ; move number in memory (Y,A) to ARG and mult. result in fac.
    ;jsr prnfaq

**************
* alternative to previous code
    ;jsr MOVAF   ; arg = fac
    ;ldy #3
    ;jsr YTOFAC
    ;;jsr getsgn     ; alternative à jsr FABS cf. pom's 18
    ;jsr FMULTT      ; fac = fac * arg
    ;jsr FABS        ; cf. pom's 20 page 13 (alternative : jsr getsgn avant jsr FMULTT
    ;jsr prnfaq
**********

    jsr CONINT      ; x = fac
    txa
    clc
    adc #$02        ; add 2
    clc
    adc xstart
    sta xend        ; xend = xstart + rnd*3 +2 

*if J>39 then J = 39
    cmp #39         
    bcc ok39
    lda #39
    sta xend
ok39
    ;jsr prnstartend

* calcul de hauteur 
*T =  INT ( RND (1) * (4 - N) * 48) + N * 48

    jsr RND         ; fac = random number (> 0 et < 1)
    ldy #>myfac
    ldx #<myfac
    jsr MOVMF       ; move fac => memory (packed) = RND
    
    lda #4
    sec
    sbc passe       ; A = (4 - N)
    sta interligne  ; interligne is used as verticla space between black lines
    tay
    jsr YTOFAC      ; fac = (4 - N) 
    ldy #>myfac 
    lda #<myfac
    jsr FMULT       ; move mem. to ARG and mult fac*arg. fac =  RND * (4 - N) 
    ldy #>myfac
    ldx #<myfac
    jsr MOVMF       ; move fac to memory => memory = packed(RND * (4 - N))
    ldy #48
    jsr YTOFAC      ; fac = 48
    ldy #>myfac 
    lda #<myfac
    jsr FMULT       ; move mem. to ARG and mult fac*arg. fac =  RND * (4 - N) * 48      
    *jsr prnfaq

    jsr CONINT      ; x = int(fac). NB : fac <= 191
    stx hauteur     ; update hauteur

    ldy passe 
    jsr YTOFAC      ; fac = passe
    ldy #>myfac
    ldx #<myfac
    jsr MOVMF       ; move fac => memory (packed) = passe 
    ldy #48
    jsr YTOFAC      ; fac = 48
    ldy #>myfac 
    lda #<myfac
    jsr FMULT       ; move mem. to ARG and mult fac*arg. fac =  passe * 48 
    jsr CONINT      ; x = passe * 48
    txa
    clc
    adc hauteur     ; hauteur = INT(RND *(4-passe)* 48)+passe*48
    sta hauteur

    ;sta value
    ;jsr debug
;wk  jsr rdkey

* plot
    ldx hauteur     ; save initial values
    stx savhauteur  

nextligne
    ldx hauteur     ; set ptr to line
    lda lo,x 
    sta ptr
    lda hi,x 
    sta ptr+1
    ldy xstart      ; position horizontale => x reg.
    lda #$80        ; value to plot

    sta (ptr),y     ; plot !
    lda speed
    jsr wait
    lda hauteur     ; next black line to plot
    clc
    adc interligne  ; interligne was calculated before 
    sta hauteur     ; upadate heuteur
    cmp #191        ; bottom of screen ?
    bcc nextligne   ; no : plot next line
    beq nextligne
    ;jsr rdkey

    lda savhauteur  ; get original hauteur (hauteur of building)
    sta hauteur     ; ==> into var hauteur
    inc xstart      ; next horizontal position
    ldy xstart
    cpy xend        ; = building width ?
    bcc nextligne   ; no : plot another stack of lines
    beq nextligne


    lda xend        ; width of screen reached ?
    cmp #39
    beq nextpasse   ; yes
    lda xend        ; no : update xstart for next building
    clc
    adc #1
    sta xstart      ; xstart = xend + 1 
    jmp mloop

nextpasse
    ;jsr rdkey
    inc passe       ; another loop ?
    lda passe
    cmp #$04        ; 4 loops done ?
    beq end         ; yes : exit
    jmp bigloop     ; no : go again

end                 ; end of drawing code
readk  
    lda kbd         ; wait a keytroke
    bpl readk
    bit kbdstrb
    bit settext 
    jmp debut       ; restart 
    rts


*********** UTIL ****************

initrandom
* $EFAE (RND) : APPLESOFT FP - FORM A 'RANDOM' NUMBER IN fAC USING ORIGINAl VALUE IN FAC AS
* PARAMETER 'KEY' OR 'SEED'. MODifiES MANY fP LOCNS
* reference : "whats-where-in-the-apple-a-complete-guide-to-the-apple-computer.pdf" p.207
*
    lda $4e         ; init fac with pseudo random $4e/$4f
    ldy $4f         ; generated by rdkey routine 
    jsr float       ; convert $4e/$4f integer to fac
    ;jsr prnfaq
dornd           ; seed random generator with $4e value
    lsr $4e 
    jsr RND
    dec $4e 
    bne dornd
    ;jsr prnfaq
    rts



*** init HGR
initHGR
    lda page1       ; go HGR
    lda mixoff      ; no text
    lda graphics    ; graphic mode
    lda hires       ; hgr 
    rts
***

*** fond bleu
fondbleu
    ldx #$00
newline
    lda lo,x 
    sta ptr
    lda hi,x 
    sta ptr+1

    ldy #$00
doline
    lda #$d5 
    sta (ptr),y
    iny
    lda #$aa 
    sta (ptr),y
    iny
    cpy #$28            ; 40 bytes ?
    bne doline

    inx 
    cpx #$c0             ; 192 lines ?
    bne newline
    rts
***

*** debug routine
* print hauteur, x start, xend
debug
    lda hauteur
    sta value
    jsr prtbyt
    lda #" "
    jsr cout
    lda xstart
    sta value
    jsr prtbyt
    lda #" "
    jsr cout   
    lda xend
    sta value
    jsr prtbyt
    lda #$8d
    jsr cout 
    rts  
***

*** another debug routine
prnstartend
    lda #$8d
    jsr cout
    lda #"$"
    jsr cout
    lda xstart 
    jsr printhex
    lda #" "
    jsr cout 
    jsr cout
    lda #"$"
    jsr cout
    lda xend 
    jsr printhex
    rts     
***

*** another debug routine
* print fac in hex and in decimal
prnfaq
    jsr savfac
    lda #$8d
    jsr cout
    ldx #$00
print2
    lda fac,x
    jsr printhex
    lda #" "
    jsr cout
    inx
    cpx #$6
    bne print2
    lda #" "
    jsr cout
    ldy #>fleche
    lda #<fleche
    jsr STROUT
    jsr getfac
    jsr PRINTFAC        ; kills FAC
    jsr getfac
    rts
***

*** save FAC content to mem.
savfac
    ldx #$05
lsav
    lda fac,x
    sta myfac,x
    dex
    bpl lsav
    rts
***

*** restaore FAC content from mem.
getfac
    ldx #$05
lgf
    lda myfac,x
    sta fac,x
    dex
    bpl lgf
    rts  

getsgn              ; cf. pom's 18
    lda $aa         ; signe de fac
    eor $a2         ; signe de arg
    sta $ab         ; signe resultat dans $ab ??? 
    lda $9d         ; necessaire pour FMULT
    rts
***

*** print byte in memory (at value) in decimal
* ref. : "Using 6502 Assembly Language" by Randy Hyde
* source converted to Merlin syntax
prtbyt  
    pha             ;save registers
    txa
    pha
          ;
    ldx #$2         ;max of 3 digits (0-255)
    stx lead0       ;init lead0 to non-neg value
prtb1   
    lda #"0"        ;initialize digit counter
    sta digit
          ;
prtb2   sec
    lda value       ;get value to be output
    sbc tbl10,x     ;compare with powers of 10
    blt prtb3       ;if less than, output digit
          ;
    sta value       ;decrement value
    inc digit       ;increment digit couoter
    jmp prtb2       ;and try again
          ;
prtb3   lda digit       ;get character to output
    cpx #$0         ;check to see if the last digit
    beq prtb5       ;is being output
    cmp #"0"        ;test for leading zeros
    beq prtb4
    sta lead0       ;force lead0 neg if non-zero
          ;
prtb4   
    bit lead0       ;if all leading zeros, don't
    bpl prtb6       ;output this one
prtb5   
    jsr cout        ;output digit
prtb6   
    dex             ;move to next digit
    bpl prtb1       ;quit if three digits have
    pla             ;been handled
    txa
    pla
    rts

*** data fot prtbyt routine
tbl10   
    hex 01
    hex 0a
    hex 64
          
lead0   hex 00
digit   hex 00
value   hex 00

                
********** data **********
passe   hex 00
xstart  hex 00
xend    hex 00
hauteur hex 00
savhauteur  hex 00
interligne  hex 00
speed   hex 00

trois   hex 0300
myfac hex ffffffffffffff
fleche asc "===> "
        hex 00

welcome asc "          Welcome to CityScape !"
    hex 8d8d8d00

choix asc "   Choose : <S>low    <F>ast   <E>xit "
    hex 8d8d
    asc "                   "
    hex 00

* HGR line addresses
*
hi      hex 2024282C3034383C    ; high byte of HGR memory address
        hex 2024282C3034383C
        hex 2125292D3135393D
        hex 2125292D3135393D
        hex 22262A2E32363A3E
        hex 22262A2E32363A3E
        hex 23272B2F33373B3F
        hex 23272B2F33373B3F
        hex 2024282C3034383C
        hex 2024282C3034383C
        hex 2125292D3135393D
        hex 2125292D3135393D
        hex 22262A2E32363A3E
        hex 22262A2E32363A3E
        hex 23272B2F33373B3F
        hex 23272B2F33373B3F
        hex 2024282C3034383C
        hex 2024282C3034383C
        hex 2125292D3135393D
        hex 2125292D3135393D
        hex 22262A2E32363A3E
        hex 22262A2E32363A3E
        hex 23272B2F33373B3F
        hex 23272B2F33373B3F
lo      hex 0000000000000000        ; low byte of HGR memory address
        hex 8080808080808080
        hex 0000000000000000
        hex 8080808080808080
        hex 0000000000000000
        hex 8080808080808080
        hex 0000000000000000
        hex 8080808080808080
        hex 2828282828282828
        hex A8A8A8A8A8A8A8A8
        hex 2828282828282828
        hex A8A8A8A8A8A8A8A8
        hex 2828282828282828
        hex A8A8A8A8A8A8A8A8
        hex 2828282828282828
        hex A8A8A8A8A8A8A8A8
        hex 5050505050505050
        hex D0D0D0D0D0D0D0D0
        hex 5050505050505050
        hex D0D0D0D0D0D0D0D0
        hex 5050505050505050
        hex D0D0D0D0D0D0D0D0
        hex 5050505050505050
        hex D0D0D0D0D0D0D0D0
*

