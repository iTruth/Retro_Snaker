extern _printf
extern _kbhit
extern _getch
extern _putchar
extern _malloc
extern _free
extern _time
extern _srand
extern _rand
extern _exit
extern _GetStdHandle@4
extern _SetConsoleCursorPosition@8
extern _SetConsoleCursorInfo@8
extern _MessageBoxA@16
extern _Sleep@4

segment .data
pszNewLine db 0x0D, 0x0A, 0
pszScore db "Score:  %d", 0
pszTarget db "Target: %d", 0
pszTitle db "Snake", 0
pszFailed db "You lost", 0
pszWon db "You win", 0

segment .bss
AreaX equ 70
AreaY equ 24
UP equ 0
DOWN equ 1
LEFT equ 2
RIGHT equ 3
Target equ 100
pszMapbuffer resb AreaX+1
pxySnakeHead resd 1
pxySnakeTail resd 1
nSnakeLenth resd 1
nxySnakeFoodX resd 1
nxySnakeFoodY resd 1
uniCurDir resw 1 ;0->上; 1->下; 2->左; 3->右

segment .text
global _main

;添加蛇头部
;参数: word x
;      word y
_add_snake_head@8:
push ebp
mov ebp, esp
sub esp, 4
mov dword [esp], 16
call _malloc
mov edx, [ebp+8]
mov dword [eax], edx ;x
mov edx, [ebp+12]
mov dword [eax+4], edx ;y
mov edx, [pxySnakeHead]
mov dword [edx+12], eax ;prev
mov dword [eax+8], edx ;next
mov dword [eax+12], eax ;prev->prev
mov dword [pxySnakeHead], eax ;更新蛇头位置
push '*'
push dword [eax+4]
push dword [eax]
call _printchar@12
leave
ret 8

;添加蛇尾部
;参数: dword x
;      dword y
_add_snake_tail@8:
push ebp
mov ebp, esp
sub esp, 4
mov dword [esp], 16
call _malloc
mov edx, [ebp+8]
mov dword [eax], edx ;x
mov edx, [ebp+12]
mov dword [eax+4], edx ;y
mov dword [eax+8], 0 ;next
mov ebx, [pxySnakeTail]
mov dword [eax+12], ebx ;prev
mov dword [ebx+8], eax ;prev->next = eax
mov dword [pxySnakeTail], eax
push '*'
push dword [eax+4]
push dword [eax]
call _printchar@12
leave
ret 8

;按情况去掉蛇尾
_remove_snake_tail@0:
push ebp
mov ebp, esp
;开始比较蛇尾和蛇尾的上一节的x和y是否相等
;这将决定是否在屏幕上擦除蛇尾
xor cx, cx
mov eax, [pxySnakeTail] ;蛇尾首地址
mov ebx, [eax+12] ;蛇尾上一节的首地址
mov edx, [ebx] ;edx = tail->x
cmp [eax], edx
setne cl
mov edx, [ebx+4]
cmp [eax+4], edx
setne ch
cmp bx, 0
jz LRemoveTail
push ' '
push dword [eax+4]
push dword [eax]
call _printchar@12
LRemoveTail:
mov eax, [pxySnakeTail] ;eax = tail
mov ebx, [eax+12] ;ebx = tail->prev
mov dword [pxySnakeTail], ebx ;tail = ebx
mov dword [ebx+8], 0 ;ebx->next=0
push eax
call _free
add esp, 4
leave
ret 0

;初始化蛇
_init_snake@0:
push ebp
mov ebp, esp
sub esp, 4
mov word [uniCurDir], RIGHT ;初始方向向右
mov dword [nSnakeLenth], 3 ;蛇长度初始为3
;开始初始化蛇头
mov dword [esp], 16
call _malloc
mov dword [pxySnakeHead], eax
mov dword [pxySnakeTail], eax
mov dword [eax], 5 ;x
mov dword [eax+4], 1 ;y
mov dword [eax+8], 0 ;next
mov dword [eax+12], eax ;prev
;打印蛇头
push '*'
push 1
push 5
call _printchar@12
;添加蛇身
mov ecx, [nSnakeLenth]
dec ecx
LInitPrintSnake:
push ecx
push 1
mov eax, ecx
add eax, 2
push eax
call _add_snake_tail@8
pop ecx
loop LInitPrintSnake
leave
ret 0

;检测指定坐标是否在蛇身内
;参数: dword x
;      dword y
;      dword isCheckHead
_is_pos_in_snake@12:
push ebp
mov ebp, esp
mov eax, [pxySnakeHead]
cmp dword [ebp+16], 0 ;是否跳过头部检测
je LCheck
mov eax, [eax+8]
LCheck:
xor cx, cx
mov edx, dword [ebp+8]
cmp [eax], edx
setne cl
mov edx, dword [ebp+12]
cmp [eax+4], edx
setne ch
cmp cx, 0
je LInBody
cmp dword [eax+8], 0
je LNotInBody
mov eax, [eax+8]
jmp LCheck
LNotInBody:
mov eax, 0
jmp LIsPosInSnakeEnd
LInBody:
mov eax, 1
LIsPosInSnakeEnd:
leave
ret 12

;检测是否吃到了食物并决定是否增长蛇
_check_food@0:
push ebp
mov ebp, esp
xor dx, dx
mov eax, [pxySnakeHead]
mov bx, [eax]
cmp bx, [nxySnakeFoodX]
setne dl
mov bx, [eax+4]
cmp bx, [nxySnakeFoodY]
setne dh
cmp dx, 0
jne LCheckFoodEnd
inc dword [nSnakeLenth]
call _gen_food@0
mov eax, [pxySnakeTail]
push dword [eax+4]
push dword [eax]
call _add_snake_tail@8
LCheckFoodEnd:
leave
ret 0

;检测是否赢了
_check_won@0:
push ebp
mov ebp, esp
mov eax, dword [nSnakeLenth]
sub eax, 3
cmp eax, Target
jl LFailCheckEnd
call _free_all@0
push 0
push pszTitle
push pszWon
push 0
call _MessageBoxA@16
mov dword [esp], 0
call _exit
LCheckWonEnd:
leave
ret 0

;检测是否已经输了
_check_failed@0:
push ebp
mov ebp, esp
sub esp, 4
mov edx, [pxySnakeHead]
;检测蛇头是否碰到了蛇身
push 1 ;跳过头部检测
push dword [edx+4]
push dword [edx]
call _is_pos_in_snake@12
cmp eax, 0
je LCheckXZ
jmp LFailed
;下面检测是否碰壁
LCheckXZ:
mov edx, [pxySnakeHead]
cmp dword [edx], -1
jne LCheckYZ 
jmp LFailed
LCheckYZ:
cmp dword [edx+4], -1
jne LCheckXE 
jmp LFailed
LCheckXE:
cmp dword [edx], AreaX-2
jne LCheckYE 
jmp LFailed
LCheckYE:
cmp dword [edx+4], AreaY-2
jne LFailCheckEnd
jmp LFailed
;下面处理输了的情况
LFailed:
call _free_all@0
push 0
push pszTitle
push pszFailed
push 0
call _MessageBoxA@16
mov dword [esp], 0
call _exit
LFailCheckEnd:
leave
ret 0

;根据按键改变蛇的方向
_get_new_dir@0:
push ebp
mov ebp, esp
call _kbhit
cmp eax, 0
je LGetNewDirEnd
call _getch
cmp eax, 'w'
jne LK_A
cmp word [uniCurDir], DOWN
je LGetNewDirEnd ;防止蛇直接掉头
mov word [uniCurDir], UP
jmp LGetNewDirEnd
LK_A:
cmp eax, 'a'
jne LK_S
cmp word [uniCurDir], RIGHT
je LGetNewDirEnd
mov word [uniCurDir], LEFT
jmp LGetNewDirEnd
LK_S:
cmp eax, 's'
jne LK_D
cmp word [uniCurDir], UP
je LGetNewDirEnd
mov word [uniCurDir], DOWN
jmp LGetNewDirEnd
LK_D:
cmp eax, 'd'
jne LGetNewDirEnd
cmp word [uniCurDir], LEFT
je LGetNewDirEnd
mov word [uniCurDir], RIGHT
LGetNewDirEnd:
leave
ret 0

;使蛇移动一步
_move_snake@0:
push ebp
mov ebp, esp
sub esp, 8
;保存当前蛇头坐标
mov eax, [pxySnakeHead]
mov ebx, [eax]
mov dword [esp], ebx ;x
mov ebx, [eax+4]
mov dword [esp+4], ebx ;y
mov eax, [pxySnakeHead]
cmp word [uniCurDir], UP
je LUP
cmp word [uniCurDir], DOWN
je LDOWN
cmp word [uniCurDir], LEFT
je LLEFT
cmp word [uniCurDir], RIGHT
je LRIGHT
jmp LDIREND
LUP:
dec dword [esp+4]
jmp LDIREND
LDOWN:
inc dword [esp+4]
jmp LDIREND
LLEFT:
dec dword [esp]
jmp LDIREND
LRIGHT:
inc dword [esp]
LDIREND:
call _add_snake_head@8
call _remove_snake_tail@0
leave
ret 0

;生成食物
_gen_food@0:
push ebp
mov ebp, esp
cmp dword [nSnakeLenth], (AreaX-2)*(AreaY-2)
jge LGenFoodEnd
LGenFood:
push 0
xor edx, edx
call _rand
mov ebx, AreaY-3
div ebx
mov dword [nxySnakeFoodY], edx
push edx
xor edx, edx
call _rand
mov ebx, AreaX-3
div ebx
mov dword [nxySnakeFoodX], edx
push edx
call _is_pos_in_snake@12
cmp eax, 0
jne LGenFood
push '#'
push dword [nxySnakeFoodY]
push dword [nxySnakeFoodX]
call _printchar@12
call _print_score@0
LGenFoodEnd:
leave
ret 0

;基于窗口原点移动光标
;参数: byte x
;      byte y
_gotoxy@4:
push ebp
mov ebp, esp
push word [ebp+8]
push word [ebp+10]
push -11
call _GetStdHandle@4
push eax
call _SetConsoleCursorPosition@8
leave
ret 4

;基于地图原点移动光标
;参数: word x
;      word y
_map_gotoxy@8:
push ebp
mov ebp, esp
sub esp, 4
and dword [esp], 0
mov al, byte [ebp+8]
inc al
mov byte [esp], al
mov al, byte [ebp+12]
inc al
mov byte [esp+2], al
call _gotoxy@4
leave
ret 8

;基于地图原点打印一个字符
;参数: dword x
;      dword y
;      dword char
_printchar@12:
push ebp
mov ebp, esp
sub esp, 4
push dword [ebp+8]
push dword [ebp+12]
call _map_gotoxy@8
mov eax, [ebp+16]
mov [esp], eax
call _putchar
leave
ret 12

;打印地图
_printmap@0:
push ebp
mov ebp, esp
sub esp, 8
;定位光标到(0,0)处
push 0
call _gotoxy@4
mov ecx, AreaY
LLines:
push ecx
mov ecx, AreaX
;根据行的位置决定打印什么
cmp dword [esp], 1
je LHeaderLine
cmp dword [esp], AreaY
je LHeaderLine
mov byte [esp+4], '|'
mov byte [esp+5], ' '
jmp LPrintLine
LHeaderLine:
mov byte [esp+4], '+'
mov byte [esp+5], '-'
;构建一行
LPrintLine:
mov al, [esp+4]
mov byte [pszMapbuffer], al
mov ecx, AreaX-2
LCenter:
mov al, byte [esp+5]
mov byte [pszMapbuffer+ecx], al
loop LCenter
mov al, byte [esp+4]
mov byte [pszMapbuffer+AreaX-1], al
;打印构建好的行
push pszMapbuffer
call _printf
add esp, 4
;行末尾打印换行
LineEnd:
push pszNewLine
call _printf
add esp, 4
pop ecx
dec ecx
jnz LLines
leave
ret 0

;打印分数
_print_score@0:
push ebp
mov ebp, esp
sub esp, 8
push word AreaX-12
push word AreaY
call _gotoxy@4
mov eax, [nSnakeLenth]
sub eax, 3
mov dword [esp+4], eax
mov dword [esp], pszScore
call _printf
push word AreaX-12
push word AreaY+1
call _gotoxy@4
mov dword [esp+4], Target
mov dword [esp], pszTarget
call _printf
leave
ret 0

;释放整条蛇,用于游戏结束后的资源释放
_free_all@0:
push ebp
mov ebp, esp
sub esp, 4
mov ebx, [pxySnakeHead]
LFreeAll:
mov eax, ebx
mov ebx, [ebx+8]
mov dword [esp], eax
call _free
cmp ebx, 0
je LGenFoodEnd
jmp LFreeAll
LFreeAllEnd:
leave
ret 0

_main:
push ebp
mov ebp, esp
sub esp, 32
;隐藏光标
mov dword [esp], 1
mov dword [esp+4], 0
lea eax, [esp]
push eax
push -11
call _GetStdHandle@4
push eax
call _SetConsoleCursorInfo@8
;更新随机数种子
mov dword [esp], 0
call _time
mov dword [esp], eax
call _srand
;初始化
call _printmap@0
call _init_snake@0
call _gen_food@0
;游戏主循环
LGameMainLoop:
call _get_new_dir@0
call _move_snake@0
call _check_food@0
call _check_won@0
call _check_failed@0
push 100
call _Sleep@4
jmp LGameMainLoop
leave
ret
