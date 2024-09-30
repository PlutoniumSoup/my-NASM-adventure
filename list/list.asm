section .data
    ; Сообщение для вывода
  end_line db 0xa, 0
  s dq '0', 0
  hello_msg db 'Hello, World!', 0   ; Нулевая терминация
  str1 db 'Tomato', 0
  str2 db 'Potato', 0
  str3 db 'Yamato', 0
  ad db ': ', 0

  len dq 8                ; размер выделяемой памяти (8 байт)
  prot dq 0x7                ; права доступа (0x7 = PROT_READ | PROT_WRITE | PROT_EXEC)
  flags dq 0x22              ; MAP_PRIVATE | MAP_ANONYMOUS
  fd dq -1                   ; файловый дескриптор не требуется
  offset dq 0                ; смещение 0

section .bss
  nameN resq 1
  LG resq 1
  strI resq 1

section .text
  global _start
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

_start:
  mov r15, nameN
  call create_nodeList
  mov r14, str1
  call addNode
  mov r15, nameN
  call addNode
  call addNode
  mov r14, str2
  call addNode

  mov r15, nameN
  mov r13, r15
  call int_to_str
  println strI

  mov r15, [nameN]
  mov r13, r15
  call int_to_str
  println strI

  mov r15, [nameN]
  mov r13, [r15]
  call int_to_str
  println strI

  mov r15, [nameN]
  mov r15, [r15]
  mov r13, [r15]
  call int_to_str
  println strI

  mov r15, [nameN]
  mov r15, [r15]
  mov r15, [r15]
  mov r13, [r15]
  call int_to_str
  println strI

  mov r15, [nameN]
  mov r15, [r15]
  mov r15, [r15]
  mov r15, [r15]
  mov r13, [r15]
  call int_to_str
  println strI

  mov r15, [nameN]
  mov r15, [r15]
  mov r15, [r15]
  mov r15, [r15]
  mov r15, [r15]
  mov r13, [r15+8]
  println r13
  call int_to_str
  println strI
  ; mov r15, LG
  ; call create_nodeList

  ; Освобождаем память
  ; mov rax, 11             ; syscall: munmap
  ; mov rdi, rdi            ; addr: адрес, возвращенный mmap (правильный адрес)
  ; mov rsi, 14             ; size: размер
  ; syscall

  ; Завершение программы
  ; er:
  end:
  mov rax, 60             ; syscall: exit
  xor rdi, rdi            ; статус выхода: 0
  syscall

create_nodeList:
  push rax
  push rdi
  push rsi
  push rdx
  push r10
  push r8
  push r9
  

  mov rax, 9              ; syscall: mmap
  xor rdi, rdi            ; addr: NULL (автоопределение адреса)
  mov rsi, [len]             ; размер памяти
  mov rdx, [prot]            ; права доступа
  mov r10, [flags]           ; флаги
  mov r8, [fd]               ; файловый дескриптор
  mov r9, [offset]           ; смещение
  syscall

  mov qword [r15], rax

  pop rax
  pop rdi
  pop rsi
  pop rdx
  pop r10
  pop r8
  pop r9
  ret

addNode:
  push r15
  push rax
  push rdi
  push rsi
  push rdx
  push r10
  push r8
  push r9

  mov rax, 9              ; syscall: mmap
  xor rdi, rdi            ; addr: NULL (автоопределение адреса)
  xor rsi, rsi
  add rsi, 8              ; 64 бит - адресс на след. узел
  add rsi, 8              ; 64 бит - ссылка на значение
  mov rdx, [prot]              ; prot: PROT_READ | PROT_WRITE
  mov r10, [flags]             ; flags: MAP_PRIVATE | MAP_ANONYMOUS
  mov r8, [fd]              ; fd: -1 (не используется)
  mov r9, [offset]             ; offset: 0
  syscall
  

  mov r15, [r15]
  find_tail:
    cmp qword [r15], 0
    je tail_found
    mov r15, [r15]
    jmp find_tail
  tail_found:
    
    mov qword [r15], rax
    mov qword [rax+8], r14


  pop r15
  pop rax
  pop rdi
  pop rsi
  pop rdx
  pop r10
  pop r8
  pop r9
  ret
  

int_to_str:
  push rax
  push rbx
  push rcx
  push rdx

  mov qword [strI], 0
  mov rax, r13
  mov rcx, 63
  mov rbx, 10
  cc:
    xor rdx, rdx
    cmp rax, 0
    je e
    div rbx
    add rdx, 48
    mov r12, 0
    add r12, 63
    sub r12, rcx
    mov [strI + r12], rdx
    loop cc
  e:
  pop rdx
  pop rcx
  pop rbx
  pop rax
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
  push rcx 

  xor rax, rax     ; обнуляем rax (длина строки)
  xor rcx, rcx     ; обнуляем счетчик
  count:
    cmp byte [rsi + rcx], 0x00 ; проверяем конец строки (нулевой байт)
    je done          ; если нашли конец строки, выходим
    inc rcx          ; увеличиваем счетчик
    jmp count        ; повторяем
  done:
    mov rax, rcx     ; длина строки в rax

  pop rcx
  ret