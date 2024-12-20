.macro read_file(%x, %addr, %size) 
    push(ra)
    push(a0)
    mv a0, %x
    jal read_input
    mv %addr, a0
    mv %size, a1
    pop(a0)
    pop(ra)
.end_macro 

.macro processing(%addr, %size, %res_addr, %res_size)
    push(ra)
    push(a0)
    push(a1)
    mv a0, %addr
    mv a1, %size
    jal process_string
    mv %res_addr,a0
    mv %res_size, a1
    pop(a1)
    pop(a0)
    pop(ra)
.end_macro

.macro console_print(%addr) 
    push(ra)
    push(a0)
    mv a0, %addr
    jal check_console_output
    pop(a0)
    pop(ra)
.end_macro 

.macro write_file(%addr, %size, %file)
    push(ra)
    push(a0)
    push(a1)
    push(a2)
    mv a0, %addr
    mv a1, %size
    mv a2, %file
    jal write_output
    pop(a2)
    pop(a1)
    pop(a0)
    pop(ra)
.end_macro

.macro print_int (%x)
	li a7, 1
	mv a0, %x
	ecall
.end_macro

.macro print_imm_int (%x)
	li a7, 1
   	li a0, %x
   	ecall
.end_macro

.macro print_str (%x)
   .data
str:
   .asciz %x
   .align 2
   .text
   push (a0)
   li a7, 4
   la a0, str
   ecall
   pop	(a0)
.end_macro

.macro print_str_addr(%str)
    la a0, %str
    li a7, 4
    ecall
.end_macro

.macro print_str_reg(%reg)
    mv a0, %reg
    li a7, 4
    ecall
.end_macro

.macro print_char(%x)
   li a7, 11
   li a0, %x
   ecall
.end_macro

.macro newline
   print_char('\n')
.end_macro

.macro read_int(%x)
   push	(a0)
   li a7, 5
   ecall
   mv %x, a0
   pop	(a0)
.end_macro

.macro str_get(%strbuf, %size)
    la      a0 %strbuf
    li      a1 %size
    li      a7 8
    ecall
    push(s0)
    push(s1)
    push(s2)
    li	s0 '\n'
    la	s1	%strbuf
next:
    lb	s2  (s1)
    beq s0	s2	replace
    addi s1 s1 1
    b	next
replace:
    sb	zero (s1)
    pop(s2)
    pop(s1)
    pop(s0)
.end_macro

.eqv READ_ONLY	0	# Открыть для чтения
.eqv WRITE_ONLY	1	# Открыть для записи
.eqv APPEND	    9	# Открыть для добавления
.macro open(%file_name, %opt)
    li   	a7 1024     	# Системный вызов открытия файла
    la          a0 %file_name   # Имя открываемого файла
    li   	a1 %opt        	# Открыть для чтения (флаг = 0)
    ecall             		# Дескриптор файла в a0 или -1)
.end_macro


.macro read(%file_descriptor, %strbuf, %size)
    li   a7, 63       	# Системный вызов для чтения из файла
    mv   a0, %file_descriptor # Дескриптор файла
    la   a1, %strbuf   	# Адрес буфера для читаемого текста
    li   a2, %size      # Размер читаемой порции
    ecall             	# Чтение
.end_macro

.macro write(%file_descriptor, %strbuf, %size)
    li   a7, 64       	# Системный вызов для записи в файл
    mv   a0, %file_descriptor # Дескриптор файла
    la   a1, %strbuf   	# Адрес буфера для записываемого текста
    li   a2, %size      # Размер записываемой порции
    ecall             	# Запись
.end_macro

.macro read_addr_reg(%file_descriptor, %reg, %size)
    li   a7, 63       	# Системный вызов для чтения из файла
    mv   a0, %file_descriptor       # Дескриптор файла
    mv   a1, %reg   	# Адрес буфера для читаемого текста из регистра
    li   a2, %size 		# Размер читаемой порции
    ecall             	# Чтение
.end_macro

.macro write_addr_reg(%file_descriptor, %strbuf, %size)
    li   a7, 64       	# Системный вызов для записи в файл
    mv   a0, %file_descriptor # Дескриптор файла
    mv   a1, %strbuf   	# Адрес буфера для читаемого текста
    mv   a2, %size      # Размер выводимой порции
    ecall             	# Вывод
.end_macro


# Закрытие файла
.macro close(%file_descriptor)
    li   a7, 57       # Системный вызов закрытия файла
    mv   a0, %file_descriptor  # Дескриптор файла
    ecall             # Закрытие файла
.end_macro

# Выделение области динамической памяти заданного размера
.macro allocate(%size)
    li a7, 9
    li a0, %size	# Размер блока памяти
    ecall
.end_macro


# Выделение области динамической памяти заданного размера
.macro allocate_reg(%reg)
    li a7, 9
    mv a0, %reg	# Размер блока памяти
    ecall
.end_macro

# Завершение программы
.macro exit
    li a7, 10
    ecall
.end_macro

# Сохранение заданного регистра на стеке
.macro push(%x)
	addi	sp, sp, -4
	sw	%x, (sp)
.end_macro

# Выталкивание значения с вершины стека в регистр
.macro pop(%x)
	lw	%x, (sp)
	addi	sp, sp, 4
.end_macro
