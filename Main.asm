format PE GUI 4.0
entry start

include "win32ax.inc" 

section '.text' code readable executable
  start:
        cinvoke GetCommandLine ; ���������� ��������� ������ � ������� eax
        mov [lpCommLine], eax ; ����������� ��� ������ � lpCommLine
        cinvoke sscanf, [lpCommLine], "%s %lf", output, X ; ���������� �������� ��������� X
        
        finit; ���������� � �������� ����� ������������
        call calc ; ������ ��������� ������� 1/e^x � ��������� 0,1%
        
        ; ���������� 1/e^x � ������� ���������� ������� fpu � ���������� �����������
        finit ; ���������� � �������� ����� ������������
        fld [X] 
        call exp ; st0 : e^x
        fld1 ; st0 : 1, st1 : e^x
        fxch  ; st0 : e^x, st1 : 1
        fdivp st1, st0 ; st0 : 1/e^x
        fst [realans] ; ���������� �����
        
        fld [S] ; st0 : S (�����, ���������� � ������� �����), 1/e^x 
        fxch  ; st0 : 1/e^x, st1 : S
        fdivp st1, st0 ; st0 : S / (1 / e^x) = S * e^x
        fld1 ; st0 : 1 , st1 : S / (1 / e^x)
        fsubp st1, st0  ; st0 : S/ (1 / e^x) - 1
        fabs  ; st0 : |S/ (1 / e^x) - 1|
        fld [hundred] ; st0 : 100 , st1 : |S/ (1 / e^x) - 1| 
        fmulp st1, st0 ; st0 : |S/ (1 / e^x) - 1| * 100 (����� �������� ������ � ���������)
        fstp [realerr] ; ���������� ������
        
        ; ������������ ������ � ���������� � ���������� ����������   
        cinvoke sprintf, output, formats, dword[X], dword[X+4],\
                                          dword[S], dword[S+4],\
                                          dword[realans], dword[realans+4],\
                                          dword[realerr], dword[realerr+4] 
        cinvoke  MessageBox, 0 , output, "������ ���������", MB_OK  ; ����� ������ � �����������    
        cinvoke  ExitProcess, 0 ; ���������� ���������
        
        proc exp ; ���������� e^x (x � st0)
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
            FSTP st1 ; ������� ��������
            ;��������� � st0
          ret
        endp
        
        proc calc ; ������ 1/e^x � ������� ��������� ����� ������� 
          iter:
              ; ���������� x ^ t
              fld [T] ; st0 : t            
              fld [X] ; st0 : x, st1 : t
              call pow ; st0 : x^t
              
              ; ���������� t!
              fld [T] ; st0: t, st1 : x^t
              call fact ; st0 : t!, st1 : x^t
              fxch ; st0 : x^t, st1 : t!
              
              ; ���������� (-1)^t
              fld[T] ; st0 : t, st1 : x^t, st2 : t! 
              fld1 ; st0 : 1, st1 : t, st2 : x^t, st3 : t!
              fchs ; st0 : -1, st1 : t, st2 : x^t, st3 : t!
              call pow; st0 : (-1)^t, st1 : x^t, st2 : t!
              
              ; ���������� (-1)^t * x^t
              fmulp st1, st0; st0 : (-1)^t * x^t, st1 : t!
                   
              ; ���������� (-1)^t * x^t / t!          
              fxch; st0 : t!, st1 : (-1)^t * x^t     
              fdivp st1, st0; st0 : (-1)^t * x^t / t!
              
              ; ����� z = (-1)^t * x^t / t!
              
              ; ���������� s + z
              fld [S] ; st0 : s, st1 : z
              fadd st0, st1 ; st0 : s + z , st1 : z
              
              ; ���������� ����������� |z|/|s + z|
              fld st1 ; st0 : z, st1 : s + z, st2 : z     
              fld st1 ; st0 : s + z, st1 : z, st2 : s + z, st3 : z
              fabs ; st0 : |s + z|, st1 : z, st2 : s + z, st3 : z
              fxch ; st0 : z, st1 : |s + z|, st2 : s + z, st3 : z
              fabs ; st0 : |z|, st1 : |s + z|, st2 : s + z, st3 : z
              fxch ; st0 : |s + z|, st1 : |z|, st2 : s + z, st3 : z
              fdivp st1, st0 ; st0 : |z|/|s + z|, st1 : s + z, st2 : z
              
              ; ����� d = |z|/|s + z|
              
              ; ������� ������� ����������� d � ��������� �� ������� error
              fld [error] ; st0 : error, st1 : d, st2 : s + z, st3 : z
              fcomp st1 ; st0 : d, st1 : s + z, st2 : z
              fstsw ax  ; ���������� �������� �������� SR � ax
              fwait
              sahf ; ������ ������ 
              jpe error_cmp ; ���� ��� ��������� ����� ������
              
              ; ������� ������� �������� ����
              fstp st0 ; st0 : s + z, st1 : z
              fstp [S] ; st0 : z
              fstp st0
              
              ; �������� 1 � t - ���� ��� ��������
              fld [T]
              fld1
              faddp st1, st0
              fstp [T]
              jb iter ; ���� d > error, ����������  
          ret 
          
            ;������ ���������
            error_cmp:
              cinvoke  MessageBox, 0 , "Error", "������ ���������", MB_OK  ; ����� ������ � �����������
            ret
                   
        endp
        
        proc pow ; ��������� ���������� � ������� (x ���������� � ������� y, ��� y - ����� �����)
                 ; ����� x - � st0
                 ; ����� y - � st1
                 ; ��������� � st0
          
          ; � ����� 
          ; st0 : x
          ; st1 : y
          fld1
          fxch st2
          ; � �����
          ; st0 : y
          ; st1 : x
          ; st2 : 1
            
          ; �������� �� ��, �� �������� �� y - ����
          ftst ; ��������� y � 0
          fstsw ax ; ���������� �������� �������� SR � ax
          fwait
          sahf ; ������ ������
          jz endPow ; ���� y = 0, ����� x^y = 1 (st2)
          
          cyclePow: ; y != 0
            ; � �����
            ; st0 : ������� ��� �������� st2 �������� �� x
            ; st1 : x
            ; st2 : ������������� �����
            
            ; �������� st2 (������������� �����) �� st1 (x)
            fxch st2
            fmul st0, st1
            fxch st2
            ; � �����
            ; st0 : ������� ��� �������� st2 �������� �� x
            ; st1 : x
            ; st2 : ������������� �����, ��� �� x
            
            ; ��������� st0 (y) �� 1
            fld1
            fsubp st1, st0
            ; � �����
            ; st0 : ������� ��� �������� ��� st2 �� x ����������� �� 1
            ; st1 : X
            ; st2 : ������������� �����, ��� �� x
            
            ; �������� �� ��, �� �������� �� st0 (������� y) ����
            ftst ; ��������� y � 0
            fstsw ax ; ���������� �������� �������� SR � ax
            fwait
            sahf ; ������ ������
            jnz cyclePow ; ���� y (�������) = 0, ����� x^y = st2
            
          endPow:
            ; � �����
            ; st0 : 0
            ; st1 : x
            ; st2 : x^y
          
            fstp st0 ; ������� ���� �� �������� � st0 (0)
            fstp st0 ; ������� ���� �� �������� � st0 (x)
            ; ��������� x^y � st0
            ret
        endp
                
        proc fact ; ������� ��������� x, ����� � st0 (x - ����� ����� ������� ��� ������ 1)  
                  ; x - � st0
                  ; ��������� (x!) - � st0
                  
          ; � �����
          ; st0 : x
          fld st0
          fld1
          fsubp st1, st0
          ; � ����� 
          ; st0 : x - 1
          ; st1 : x
          
          ; �������� �� ��, ��� st0 = 0
          ftst ; ��������� st0 � 0
          fstsw ax ; ���������� �������� �������� SR � ax
          fwait
          sahf ; ������ ������
          jz theEnd ; ���� st0 = 0, �� ����� � x! = st1 (x! = x = 1)
          
          cycle: ; ������������ �� ��� ���, ���� st1 - 1 (st0) != 0
            ; � �����
            ; st0 : x - 1
            ; st1 : ������������� ���������
            fmul st1, st0
            ; � �����
            ; st0 : x - 1
            ; st1 : ������������� ��������� * (x - 1)
            ; ��������� ������� x �� 1
            fld1
            fsubp st1, st0
            ; � �����
            ; st0 : x - 2
            ; st1 : x * (x - 1)
            ; �������� �� ��, ��� st0 = 0
            ftst ; ��������� st0 � 0
            fstsw ax ; ���������� �������� �������� SR � ax
            fwait
            sahf ; ������ ������
            jnz cycle ; ���� st0 != 0 - ���������� ������������
          theEnd:
            ; � �����
            ; st0 : 0
            ; st1 : x!
            fstp st0 ; ������� ���� �� 0 (st0)
            ; ��������� � st0
            ret
        endp

section '.data' data readable writeable

   formats db "1/e^(%f) ~ %.15f", 10, "��������, ���������� � ������� �c�������� ������� FPU : %.15f", 10, "������ : %.15f%%", 0 ; ������ ��� ������
   lpCommLine dd ? ; ������, � ������� ���������� � �������
   output db 256 dup(?) ; ������ ��� ������
   
   X dq 0.0 ; �������� ��������� 1/e^(x)
   T dq 1.0 ; ����� �������� ���������� � ������� ��������� �����
   S dq 1.0 ; ����� - ����� ��������� ����
      
   error dq 0.001 ; 0,1% - �������� ���������� 
   
   hundred dq 100.0 ; ����� �������� �����������
   
   realans dq 0.0 ; "������" �����
   realerr dq 0.0 ; ���������� ����������� ����������
section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
    user,'USER32.DLL',\
    mscvrt,'msvcrt.DLL'

  import kernel,\
    ExitProcess,'ExitProcess',\
    GetCommandLine,'GetCommandLineA' ; ANSI-�������

  import user,\
    MessageBox,'MessageBoxA'

  import mscvrt,\
    sprintf,'sprintf',\
    sscanf,  'sscanf'