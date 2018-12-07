format PE GUI 4.0
entry start

include "C:\Users\1\FASM\INCLUDE\win32ax.inc" 

section '.text' code readable executable

  start:
        finit
        call calc
        
        invoke sprintf, output, formats, dword[S], dword[S+4]
        invoke  MessageBox, 0 , output, "Расчёт программы", MB_OK 
        invoke  ExitProcess,0
        
        proc print
            mov ecx, 6
            ro:
              fstp [res]
              invoke sprintf, output, formats, dword[res], dword[res+4]
              invoke MessageBox, 0, output, "Расчёт программы", MB_OK
            loop ro
            
            ret
        endp
        
        proc calc 
          iter:
              fld [X]
              fld [T]              
              call pow2
              
              fstp [XT]
              
              fld [T]
              call fact
              fstp [fT]
              
              fld1
              fchs
              fld[T]
             
              call pow2
              
              fstp [oneT]
              
              fld [oneT]
              fld [XT]
              fmulp st1, st0
                            
              fld [fT] 
                    
              fdivp st1, st0
              
              fld [S]
              ; S
              ; dX
              fadd st0, st1
              
              ; S + dX
              ; dX
              fld st1              
              fld st1
              
              ; S + dX
              ; dX
              ; S + dX
              ; dX
              fabs
              fxch
              fabs
              fxch
              
              ; |S + dX|
              ; |dX|
              ; S + dX
              ; dX
              fdivp st1, st0
              
              ; otn
              ; S + dX
              ; dX
              fld [error]
              fcomp st1
              
              ftst
              fstsw ax
              sahf
              
              ; otn
              ; S + dX
              ; dX
              fstp [res]
              fstp [S]
              fstp st0
              
              fld [T]
              fld1
              faddp st1, st0
              fstp [T]
              jg iter  
          ret
        endp
        
        
        proc pow2
          fld1
          fxch st2
          fxch st1
          
          ftst
          fstsw ax
          sahf
          jz endPow
          
          cyclePow:
            fxch st2
            fmul st0, st1
            fxch st2
            
            fld1
            fsubp st1, st0
            
            ftst
            fstsw ax
            sahf
            jnz cyclePow
            
          endPow:
            fstp st0
            fstp st0
            ret
        endp
        
        proc pow ; возвовдит st0 в степень st1 (использует 2 регистра fpu)
          fyl2x ;Стек FPU теперь содержит: ST(0)=y*log2(x)
          fld st0 ;Создаем еще одну копию z
          frndint   ;Округляем ST(0)=trunc(z)        | ST(1)=z
          fxch st1;ST(0)=z                             | ST(1)=trunc(z)
          fsub st0, st1  ;ST(0)=z-trunc(z)        | ST(1)=trunc(z)
          f2xm1  ;ST(0)=2**(z-trunc(z))-1            | ST(1)=trunc(z)
          fld1     ;ST(0)=1 ST(1)=2**(z-trunc(z))-1  | ST(2)=trunc(z)
          faddp st1,st0 ;ST(0)=2**(z-trunc(z))      | ST(1)=trunc(z)
          fscale ;ST(0)=(2**(z-trunc(z)))*(2**trunc(z))=2**(z)
          fxch st1
          fstp st0
          ret
        endp
        
        proc fact ; считает факториал st0, ответ в st0 (использует 3 регистра fpu)  
          fld st0
          fld1
          fsubp st1, st0
          ftst
          fstsw ax
          sahf
          jz theEnd
          cycle:
            fmul st1, st0
            fld1
            fsubp st1, st0
            ftst
            fstsw ax
            sahf
            jnz cycle
          theEnd:
            fstp st0
            ret
        endp

section '.data' data readable writeable

   formats2 db "%d", 0
   formats db "%1.10f", 0
   output db 256 dup(?) ; строка для вывода
   A dd ?
   res dq 0.0
   N dd 6.0
   X dd -0.8
   T dd 1.0
   S dq 1.0
   
   XT dd 0.0
   oneT dd 0.0
   fT dd 0.0
   
   num0 dd 0.0
   num1 dd 1.0
   num2 dd 2.0
   num3 dd 3.0
   num4 dd 4.0
   num5 dd 5.0
   num6 dd 6.0
   num7 dd 7.0
   
   num8m dd -8.0

   error dd 0.1

section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
    user,'USER32.DLL',\
    mscvrt,'msvcrt.DLL'

  import kernel,\
    ExitProcess,'ExitProcess'

  import user,\
    MessageBox,'MessageBoxA'

  import mscvrt,\
    sprintf,'sprintf' 