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

.eqv    NAME_SIZE 256   # Размер буфера для имени файла
.eqv    TEXT_SIZE 512 # Размер чанка

.data
    in:           .space NAME_SIZE
    out:          .space NAME_SIZE
    strbuf:       .space TEXT_SIZE
    result:       .space TEXT_SIZE
    vowels:       .asciz "aeiouyAEIOUY"
    
.text
# Основная программа
process:
    push(ra)
    push(s0)
    push(s1)
    push(s2)
    push(s3)
    push(s4)
    push(s5)
    push(s6)
    
    # Открытие файла для чтения
    open(in, READ_ONLY)
    bltz a0, error_open
    mv s5, a0  # Сохранение дескриптора файла
     
    # Чтение файла
    read_file(s5, s0, s1)
    
    # Обработка строки
    processing(s0, s1, s2, s3)
    
    # Проверка вывода на консоль
    console_print(s2)
    
    # Открытие файла для записи
    open(out, WRITE_ONLY)
    bltz a0, error_open
    mv s6, a0
    
    # Запись в выходной файл
    write_file(s2, s3, s6)
    
    # Закрытие файлов
    close(s5)
    close(s6)
    
    pop(s6)
    pop(s5)
    pop(s4)
    pop(s3)
    pop(s2)
    pop(s1)
    pop(s0)
    pop(ra)
    ret
    
    
# Подпрограмма чтения входного файла
read_input:
    push(s0)
    push(s1)
    push(s2)
    push(s3)
    push(s4)
    push(s5)
    push(s6)
    
    mv s0, a0
    
    allocate(TEXT_SIZE)		# Результат хранится в a0
    mv s3, a0			# Сохранение адреса кучи в регистре
    mv s5, a0			# Сохранение изменяемого адреса кучи в регистре
    li s4, TEXT_SIZE	# Сохранение константы для обработки
    mv s6, zero		# Установка начальной длины прочитанного текста
read_loop:
    # Чтение информации из открытого файла
    read_addr_reg(s0, s5, TEXT_SIZE) # чтение для адреса блока из регистра
    # Проверка на корректное чтение
    bltz a0, error_read	# Ошибка чтения
    mv s2, a0       	# Сохранение длины текста
    add  s6, s6, s2		# Размер текста увеличивается на прочитанную порцию
    # При длине прочитанного текста меньшей, чем размер буфера,
    # необходимо завершить процесс.
    bne	s2,s4 end_read_loop
    # Иначе расширить буфер и повторить
    allocate(TEXT_SIZE)		# Результат здесь не нужен, но если нужно то...
    add		s5, s5, s2		# Адрес для чтения смещается на размер порции
    b read_loop				# Обработка следующей порции текста из файла
end_read_loop:
    
    mv t0, s3		# Адрес буфера в куче
    add t0, t0, s6	# Адрес последнего прочитанного символа
    addi t0, t0, 1	# Место для нуля
    sb zero, (t0)	# Запись нуля в конец текста
    
    mv a0, s3 # Возвращаем указатель на адреса кучи введенной строки
    mv a1, s6 # Возвращаем размер введенного текста
    
    pop(s6)
    pop(s5)
    pop(s4)
    pop(s3)
    pop(s2)
    pop(s1)
    pop(s0)
    ret
    
# Подпрограмма записи в выходной файл
write_output:
    push(s0)
    push(s1)
    
    # Запись обработанной строки в файл
    mv s0, a0
    mv s1, a1
    mv s2, a2
    
    # Запись в файл
    write_addr_reg(s2, s0, s1)
    
    
    pop(s1)
    pop(s0)
    ret
    
# Подпрограмма проверки вывода на консоль
check_console_output:
    push(s0)
    mv s0, a0    # Сохраняем указатель на строку в s0
    # Запрос на вывод в консоль
    print_str("Вывести результат в консоль?(Y/N): ")
    
    # Чтение ответа
    li a7, 12
    ecall
    
    # Проверка ответа
    li t0, 'Y'
    li t1, 'y'
    beq a0, t0, output_to_console
    beq a0, t1, output_to_console
    j skip_console_output
output_to_console:
    newline
    mv a0, s0    # Восстанавливаем указатель на строку в a0
    li a7, 4
    ecall
skip_console_output:
    newline
    pop(s0)
    ret

# Подпрограмма проверки, является ли символ гласным
is_vowel:
    push(ra)
    push(s0)
    push(s1)

    mv s0, a0       # Сохраняем проверяемый символ в s0
    la s1, vowels   # Загружаем адрес строки с гласными

vowel_loop:
    lb t0, (s1)     # Читаем текущий символ из строки с гласными
    beqz t0, not_vowel # Если символ = 0, дошли до конца строки
    beq t0, s0, is_vowel_end # Если символ совпадает, это гласная
    addi s1, s1, 1  # Идем к следующему символу
    j vowel_loop

not_vowel:
    li a0, 0        # Символ не является гласным
    j is_vowel_exit

is_vowel_end:
    li a0, 1        # Символ является гласным

is_vowel_exit:
    pop(s1)
    pop(s0)
    pop(ra)
    ret

# Подпрограмма для форматирования ASCII-кода в шестнадцатеричную строку
format_hex:
    push(ra)
    push(s0)
    push(s1)

    mv s0, a0       # Сохраняем ASCII-код символа в s0
    mv s1, a1       # Сохраняем указатель на строку результата в s1

    li t0, 0x30     # Код символа '0'
    li t1, 0x37
    
    li t2, '0'
    sb t2, (s1)    # Записываем символ '0'
    addi s1, s1, 1
    li t2, 'x'
    sb t2, (s1)    # Записываем символ 'x'
    addi s1, s1, 1

    # Вычисляем старший полубайт
    srli t2, s0, 4  # Сдвигаем ASCII-код на 4 бита вправо
    andi t2, t2, 0xF # Оставляем только младшие 4 бита
    li t3, 10
    blt t2, t3, hex_digit   # Если < 10, это цифра
    add t2, t2, t1          # Иначе добавляем 'A'
    j hex_write
hex_digit:
    add t2, t2, t0          # Если цифра, добавляем '0'
hex_write:
    sb t2, (s1)             # Записываем старший символ
    addi s1, s1, 1

    # Вычисляем младший полубайт
    andi t2, s0, 0xF        # Оставляем только младшие 4 бита
    li t3, 10
    blt t2, t3, hex_digit2
    add t2, t2, t1
    j hex_write2
hex_digit2:
    add t2, t2, t0
hex_write2:
    sb t2, (s1)             # Записываем младший символ
    addi s1, s1, 1

    sb zero, (s1)           # Завершаем строку нулем

    pop(s1)
    pop(s0)
    pop(ra)
    ret

# Основная функция обработки строки с динамическим выделением памяти
process_string:
    push(ra)
    push(s0)
    push(s1)
    push(s2)
    push(s3)
    push(s4)
    push(s5)

    mv s0, a0       # Указатель на входную строку
    mv s1, a1       # Длина входной строки

    allocate(TEXT_SIZE)    # Выделяем начальный буфер
    mv s2, a0              # Указатель на начало выходного буфера
    mv s3, a0              # Текущая позиция в выходном буфере
    li s4, TEXT_SIZE       # Начальный размер буфера
    mv s5, s4              # Оставшееся место в буфере

process_loop:
    lb t6, (s0)            # Считываем текущий символ
    beqz t6, process_end   # Если достигли конца строки, завершение

    mv a0, t6              # Передаем символ в is_vowel
    jal is_vowel
    beqz a0, copy_char     # Если это не гласная, копируем символ

    # Форматирование гласной в шестнадцатеричный код
    mv a0, t6              # Передаем ASCII-код символа
    mv a1, s3              # Указатель на текущую позицию в выходном буфере
    jal format_hex
    addi s3, s3, 4         # Смещаем указатель на длину "0xDD"
    addi s5, s5, -4        # Уменьшаем оставшееся место в буфере
    addi s0, s0, 1         # Переходим к следующему символу
    j process_loop

copy_char:

    sb t6, (s3)            # Копируем символ как есть
    addi s3, s3, 1         # Смещаем указатель
    addi s5, s5, -1          # Уменьшаем оставшееся место в буфере
    addi s0, s0, 1         # Переходим к следующему символу
    j process_loop

process_end:
    sb zero, (s3)          # Завершаем строку нулем
		
    mv a0, s2              # Указатель на выходную строку
    sub a1, s3, s2         # Длина выходной строки

    pop(s5)
    pop(s4)
    pop(s3)
    pop(s2)
    pop(s1)
    pop(s0)
    pop(ra)
    ret

# Обработка ошибок
error_open:
    print_str("Ошибка открытия файла\n")
    exit
error_read:
    print_str("Ошибка чтения файла\n")
    exit
error_size:
    print_str("Размер файла превышает 10 кб\n")
    exit
