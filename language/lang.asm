%macro println 1
  push rsi
  mov rsi, %1
  print %1
  print end_line
  pop rsi
%endmacro
%macro print 1
  push rsi
  mov rsi, %1
  call _print
  pop rsi
%endmacro
%macro str_var 1
  %define var_name %1
  var_name resb 128
%endmacro
%macro wfile 1
  push rsi
  mov rsi, %1
  call _wfile
  pop rsi
%endmacro

section .data
  filename db 'output.txt', 0
  source db 'let x = 10;', 0xa, 0
  prompt db 'Enter a string: ', 0
  end_line db 0xa, 0
  let db 'let', 0
  end db 'call end_program', 0xa, 0
  section_data db 'section .data', 0xa, 0
  section_bss db 'section .bss', 0xa, 0
  section_text db "section .text", 0xa, '  global _start', 0xa, 0
  main db '_start: ', 0xa, 0
  callEnd db 'end_program:', 0xa, '  mov rax, 60', 0xa, '  xor rdi, rdi', 0xa, '  syscall', 0xa, 0

section .bss
  buffer resb 128

section .text
  global _start

_start:
  ; mov byte [source + 1], 0xa
  ; println source
  mov rax, 1
  mov rdi, 1
  mov edx, 1
  syscall

  wfile section_data
    ; create data
    xor rdi, rdi
    xor rsi, rsi
    xor rbx, rbx
      readToken_cycle:
        cmp byte [source + rdi], ' '
        je ws_done
        mov cl, [source + rdi]
        mov byte [buffer + rsi], cl
        inc rdi
        inc rsi
        jmp readToken_cycle
      ws_done:
        xor rsi, rsi
        cycle1:

        mov byte [buffer + rsi], 0xa
        println buffer

  wfile section_bss
    ; create bss
  wfile section_text
    wfile main

  wfile end

  wfile callEnd
  ; Завершаем программу
  call end_program

file_error:
  ; Обработка ошибки (например, вывод сообщения об ошибке)
  print end_line
  ; Завершаем программу с ошибкой
  mov rax, 60                 ; syscall: exit
  mov rdi, 1                  ; код выхода 1 (ошибка)
  syscall

_wfile:
  push rax
  push rdi
  push rsi
  push rdx

  mov r15, rsi
  ; sys_open
  mov rax, 2
  mov rdi, filename
  mov rsi, 0x441
  mov rdx, 0o666
  syscall

  test rax, rax               ; проверка на ошибки
  js file_error               ; если rax < 0, ошибка

  mov rdi, rax
  
  ; sys_write
  ; pop rsi
  mov rsi, r15

  call strlen
  mov rdx, rax
  mov rax, 1
  syscall


  ; sys_close
  mov rax, 3
  syscall
  
  pop rsi
  pop rax
  pop rdi
  pop rdx
  ret

read:
  push rax
  push rbx
  push rdx
  push rdi
  mov rax, 0       ; системный вызов read
  mov rdi, 0       ; стандартный ввод (stdin)
  mov rsi, buffer  ; буфер для ввода
  mov rdx, 128     ; максимальное количество байт для чтения
  syscall
  pop rax
  pop rbx
  pop rdx
  pop rdi
  ret


_print:
  push rax
  push rbx
  push rdx
  push rdi
  push rsi

  call strlen      ; rsi указывает на строку
  mov rdx, rax     ; rdx теперь содержит длину строки
  mov rax, 1       ; системный вызов sys_write
  mov rdi, 1       ; вывод в stdout
  syscall          ; вызов ядра

  pop rax
  pop rbx
  pop rdx
  pop rdi
  pop rsi
  ret

strlen:
  xor rax, rax     ; обнуляем rax (длина строки)
  xor rcx, rcx     ; обнуляем счетчик
  count:
    cmp byte [rsi + rcx], 0x00 ; проверяем конец строки (нулевой байт)
    je done          ; если нашли конец строки, выходим
    inc rcx          ; увеличиваем счетчик
    jmp count        ; повторяем
  done:
    mov rax, rcx     ; длина строки в rax
    ret

end_program:
  mov rax, 60      ; системный вызов exit
  xor rdi, rdi     ; код выхода 0
  syscall
