format PE GUI 4.0
entry start

include "win32ax.inc" 

section '.text' code readable executable
  start:
        cinvoke GetCommandLine ; считывание командной строки в регистр eax
        mov [lpCommLine], eax ; перемещение ком строки в lpCommLine
        cinvoke sscanf, [lpCommLine], "%s %lf", output, X ; считывание значения введённого X
        
        finit; подготовка и очищение стека сопроцессора
        call calc ; выозов процедуры расчёта 1/e^x с точностью 0,1%
        
        ; рассчитаем 1/e^x с помощью встроенных средств fpu и полученную погрешность
        finit ; подготовка и очищение стека сопроцессора
        fld [X] 
        call exp ; st0 : e^x
        fld1 ; st0 : 1, st1 : e^x
        fxch  ; st0 : e^x, st1 : 1
        fdivp st1, st0 ; st0 : 1/e^x
        fst [realans] ; полученный ответ
        
        fld [S] ; st0 : S (ответ, полученный с помощью рядов), 1/e^x 
        fxch  ; st0 : 1/e^x, st1 : S
        fdivp st1, st0 ; st0 : S / (1 / e^x) = S * e^x
        fld1 ; st0 : 1 , st1 : S / (1 / e^x)
        fsubp st1, st0  ; st0 : S/ (1 / e^x) - 1
        fabs  ; st0 : |S/ (1 / e^x) - 1|
        fld [hundred] ; st0 : 100 , st1 : |S/ (1 / e^x) - 1| 
        fmulp st1, st0 ; st0 : |S/ (1 / e^x) - 1| * 100 (чтобы получить ошибку в процентах)
        fstp [realerr] ; полученная ошибка
        
        ; формирование строки с сообщением о результате вычислений   
        cinvoke sprintf, output, formats, dword[X], dword[X+4],\
                                          dword[S], dword[S+4],\
                                          dword[realans], dword[realans+4],\
                                          dword[realerr], dword[realerr+4] 
        cinvoke  MessageBox, 0 , output, "Расчёт программы", MB_OK  ; вывод строки с результатом    
        cinvoke  ExitProcess, 0 ; завершение программы
        
        proc exp ; вычисление e^x (x в st0)
            fldl2e ; st0 : log2e, st1 : x
            fmulp st1, st0 ; st0: x * log2e
            fld st0 ; st0 : x * log2e, st1 : x * log2e
            frndint ; st0 : round(x * log2e), st1 : x * log2e
            fsub st1, st0 ; st0 : round(x * log2e), st1 : x*log2e - round(x * log2e)
            fxch st1 ; st0 : x*log2e - round(x * log2e), st1 : round(x * log2e)
            f2xm1 ; st0 : 2 ^ (x*log2e - round(x * log2e)) - 1, st1 : round(x * log2e)
            fld1 ; st0 : 1, st1: 2 ^ (x*log2e - round(x * log2e)) - 1, st2 : round(x * log2e) 
            faddp st1, st0 ; st0: 2 ^ (x*log2e - round(x * log2e)), st1 : round(x * log2e) 
            FSCALE  ; st0: 2 ^ (x*log2e - round(x * log2e)) * 2 ^(round(x * log2e)) = 2 ^ (xlog2e) = e^x, st1 : round(x * log2e)
            FSTP st1 ; очищаем ненужное
            ;результат в st0
          ret
        endp
        
        proc calc ; расчёт 1/e^x с помощью степенных рядов Тейлора 
          iter:
              ; рассчитаем x ^ t
              fld [T] ; st0 : t            
              fld [X] ; st0 : x, st1 : t
              call pow ; st0 : x^t
              
              ; рассчитаем t!
              fld [T] ; st0: t, st1 : x^t
              call fact ; st0 : t!, st1 : x^t
              fxch ; st0 : x^t, st1 : t!
              
              ; рассчитаем (-1)^t
              fld[T] ; st0 : t, st1 : x^t, st2 : t! 
              fld1 ; st0 : 1, st1 : t, st2 : x^t, st3 : t!
              fchs ; st0 : -1, st1 : t, st2 : x^t, st3 : t!
              call pow; st0 : (-1)^t, st1 : x^t, st2 : t!
              
              ; рассчитаем (-1)^t * x^t
              fmulp st1, st0; st0 : (-1)^t * x^t, st1 : t!
                   
              ; рассчитаем (-1)^t * x^t / t!          
              fxch; st0 : t!, st1 : (-1)^t * x^t     
              fdivp st1, st0; st0 : (-1)^t * x^t / t!
              
              ; далее z = (-1)^t * x^t / t!
              
              ; рассчитаем s + z
              fld [S] ; st0 : s, st1 : z
              fadd st0, st1 ; st0 : s + z , st1 : z
              
              ; рассчитаем погрешность |z|/|s + z|
              fld st1 ; st0 : z, st1 : s + z, st2 : z     
              fld st1 ; st0 : s + z, st1 : z, st2 : s + z, st3 : z
              fabs ; st0 : |s + z|, st1 : z, st2 : s + z, st3 : z
              fxch ; st0 : z, st1 : |s + z|, st2 : s + z, st3 : z
              fabs ; st0 : |z|, st1 : |s + z|, st2 : s + z, st3 : z
              fxch ; st0 : |s + z|, st1 : |z|, st2 : s + z, st3 : z
              fdivp st1, st0 ; st0 : |z|/|s + z|, st1 : s + z, st2 : z
              
              ; далее d = |z|/|s + z|
              
              ; сравним текущую погрешность d с требуемой по условию error
              fld [error] ; st0 : error, st1 : d, st2 : s + z, st3 : z
              fcomp st1 ; st0 : d, st1 : s + z, st2 : z
              fstsw ax  ; сохранение значения регистра SR в ax
              fwait
              sahf ; запись флагов 
              jpe error_cmp ; если при сравнении вышла ошибка
              
              ; запишем текущее значение ряда
              fstp st0 ; st0 : s + z, st1 : z
              fstp [S] ; st0 : z
              fstp st0
              
              ; прибавим 1 к t - след шаг итерации
              fld [T]
              fld1
              faddp st1, st0
              fstp [T]
              jb iter ; если d > error, продолжить  
          ret 
          
            ;ошибка сравнения
            error_cmp:
              cinvoke  MessageBox, 0 , "Error", "Расчёт программы", MB_OK  ; вывод строки с результатом
            ret
                   
        endp
        
        proc pow ; процедура возведения в степень (x возводится в степень y, где y - целое число)
                 ; число x - в st0
                 ; число y - в st1
                 ; результат в st0
          
          ; в стеке 
          ; st0 : x
          ; st1 : y
          fld1
          fxch st2
          ; в стеке
          ; st0 : y
          ; st1 : x
          ; st2 : 1
            
          ; проверка на то, не является ли y - нулём
          ftst ; сравнение y с 0
          fstsw ax ; сохранение значения регистра SR в ax
          fwait
          sahf ; запись флагов
          jz endPow ; если y = 0, тогда x^y = 1 (st2)
          
          cyclePow: ; y != 0
            ; в стеке
            ; st0 : сколько раз осталось st2 умножить на x
            ; st1 : x
            ; st2 : промежуточный ответ
            
            ; умножаем st2 (промежуточный ответ) на st1 (x)
            fxch st2
            fmul st0, st1
            fxch st2
            ; в стеке
            ; st0 : сколько раз осталось st2 умножить на x
            ; st1 : x
            ; st2 : промежуточный ответ, умн на x
            
            ; уменьшаем st0 (y) на 1
            fld1
            fsubp st1, st0
            ; в стеке
            ; st0 : сколько раз осталось умн st2 на x уменьшенное на 1
            ; st1 : X
            ; st2 : промежуточный ответ, умн на x
            
            ; проверка на то, не является ли st0 (текущий y) нулём
            ftst ; сравнение y с 0
            fstsw ax ; сохранение значения регистра SR в ax
            fwait
            sahf ; запись флагов
            jnz cyclePow ; если y (текущий) = 0, тогда x^y = st2
            
          endPow:
            ; в стеке
            ; st0 : 0
            ; st1 : x
            ; st2 : x^y
          
            fstp st0 ; очищаем стек от значения в st0 (0)
            fstp st0 ; очищаем стек от значения в st0 (x)
            ; результат x^y в st0
            ret
        endp
                
        proc fact ; считает факториал x, ответ в st0 (x - целое число большее или равное 1)  
                  ; x - в st0
                  ; результат (x!) - в st0
                  
          ; в стеке
          ; st0 : x
          fld st0
          fld1
          fsubp st1, st0
          ; в стеке 
          ; st0 : x - 1
          ; st1 : x
          
          ; проверка на то, что st0 = 0
          ftst ; сравнение st0 с 0
          fstsw ax ; сохранение значения регистра SR в ax
          fwait
          sahf ; запись флагов
          jz theEnd ; если st0 = 0, то ответ в x! = st1 (x! = x = 1)
          
          cycle: ; итерирование до тех пор, пока st1 - 1 (st0) != 0
            ; в стеке
            ; st0 : x - 1
            ; st1 : промежуточный результат
            fmul st1, st0
            ; в стеке
            ; st0 : x - 1
            ; st1 : промежуточный результат * (x - 1)
            ; уменьшаем текущий x на 1
            fld1
            fsubp st1, st0
            ; в стеке
            ; st0 : x - 2
            ; st1 : x * (x - 1)
            ; проверка на то, что st0 = 0
            ftst ; сравнение st0 с 0
            fstsw ax ; сохранение значения регистра SR в ax
            fwait
            sahf ; запись флагов
            jnz cycle ; если st0 != 0 - продалжаем итерирование
          theEnd:
            ; в стеке
            ; st0 : 0
            ; st1 : x!
            fstp st0 ; очищаем стек от 0 (st0)
            ; результат в st0
            ret
        endp

section '.data' data readable writeable

   formats db "1/e^(%f) ~ %.15f", 10, "Значение, полученное с помощью вcтроенных средств FPU : %.15f", 10, "Ошибка : %.15f%%", 0 ; строка для вывода
   lpCommLine dd ? ; строка, в которой содержимое с консоли
   output db 256 dup(?) ; строка для вывода
   
   X dq 0.0 ; параметр выражения 1/e^(x)
   T dq 1.0 ; номер итерации вычислений с помощью степенных рядов
   S dq 1.0 ; ответ - сумма слагаемых ряда
      
   error dq 0.001 ; 0,1% - точность вычислений 
   
   hundred dq 100.0 ; чтобы получить погрешность
   
   realans dq 0.0 ; "точный" ответ
   realerr dq 0.0 ; полученная погрешность вычислений
section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
    user,'USER32.DLL',\
    mscvrt,'msvcrt.DLL'

  import kernel,\
    ExitProcess,'ExitProcess',\
    GetCommandLine,'GetCommandLineA' ; ANSI-функция

  import user,\
    MessageBox,'MessageBoxA'

  import mscvrt,\
    sprintf,'sprintf',\
    sscanf,  'sscanf'