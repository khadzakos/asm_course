# ИДЗ №3
Автор: Николай Хадзакос, БПИ236
### Вариант №7
### Условие
Разработать программу, заменяющую все гласные буквы в заданной ASCII–строке их ASCII кодами в шестнадцатиричной системе счисления. Код каждого символа задавать в формате«0xDD», где D — шестнадцатиричная цифра от 0 до F.

### Пояснение
Приведены решения на 8 баллов и 10 баллов. Требования на 9 баллов учтены в решении на 10. На гитхабе лежат решения на 10 баллов.

## Решение на 8 баллов
### Концепция решения:
В main.asm происходит открытие файлов, их считывание по чанкам в 512 байт и вывод результата. В решении уже присутсвует опция вывода в консоль на основе выбора пользователя. Для замены гласной буквы на ее HEX код используется несколько функций: process_string, is_vowel, format_hex. Строки сохраняются в куче. 

Во тестовой программе пользователь вводит путь до папки, где у него лежит папка tests. Далее происходит формирование названий файлов и подставления пути к названию файлов. Подпрограммы, которые обрабатывают строку выхзываются как функции, соблюдая соглашения о вызовах. В отчете разделение двух программ для тестирования можно увидеть по разделительной полосе. 

Файл: **main.asm**
```
.include "macro_syscalls.asm"

.eqv    NAME_SIZE 256   # Размер буфера для имени файла
.eqv    TEXT_SIZE 512 # Размер чанка

.data
    in:           .space NAME_SIZE
    out:          .space NAME_SIZE
    strbuf:       .space TEXT_SIZE
    result:       .space TEXT_SIZE
    vowels:       .asciz "aeiouyAEIOUY"
    
.text
.globl main
# Основная программа
main:
    # Ввод имени входного файла
    print_str("Введите путь до файла со входными данными: ")
    str_get(in, NAME_SIZE)
    
    # Открытие файла для чтения
    open(in, READ_ONLY)
    bltz a0, error_open
    mv s5, a0  # Сохранение дескриптора файла
     
    # Чтение файла
    mv a0, s5
    jal read_input
    mv s0, a0
    mv s1, a1
    
    # Обработка строки
    mv a0, s0
    mv a1, s1
    jal process_string
    mv s2, a0
    mv s3, a1
    
    # Проверка вывода на консоль
    mv a0, s2
    jal check_console_output
    
    # Ввод имени выходного файла
    print_str("Введите путь до файла с выходными данными: ")
    str_get(out, NAME_SIZE)
    
    # Открытие файла для записи
    open(out, WRITE_ONLY)
    bltz a0, error_open
    mv s6, a0
    
    # Запись в выходной файл
    mv a0, s2
    mv a1, s3
    mv a2, s6
    jal write_output
    
    # Закрытие файлов
    close(s5)
    close(s6)
    
    exit
    
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
    
# Подпрограмма проверки вывода на консоль (из требований на 8 баллов)
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
```
### Запуск программы
<img width="1796" alt="Screenshot 2024-12-02 at 11 14 01" src="https://github.com/user-attachments/assets/581aeb70-ed07-4cff-b391-f2756a21ed8e">

### Тестирование 
Все тесты можно найти в папке **tests**.
#### Тест 1:
<img width="773" alt="Screenshot 2024-12-01 at 13 31 34" src="https://github.com/user-attachments/assets/f75f92d2-3c33-4225-bb37-24078aa0d41e">

#### Тест 2:
<img width="773" alt="Screenshot 2024-12-01 at 13 32 30" src="https://github.com/user-attachments/assets/4ada076a-9d73-4e0a-a253-25bdc4afebdd">

#### Тест 3:
<img width="773" alt="Screenshot 2024-12-01 at 13 33 51" src="https://github.com/user-attachments/assets/e5a8400d-f5be-4705-91c9-2e364e829ae6">

### Тест 4:
<img width="773" alt="Screenshot 2024-12-01 at 13 34 55" src="https://github.com/user-attachments/assets/d288578d-a9a4-4cbd-8360-d58031542933">

### Тест 5:
<img width="773" alt="Screenshot 2024-12-01 at 13 35 44" src="https://github.com/user-attachments/assets/2a0fd0c2-94b0-45b3-afdf-efb5ae541b42">

### Тест 6:
<img width="773" alt="Screenshot 2024-12-01 at 13 36 37" src="https://github.com/user-attachments/assets/37a6cb1f-c205-49f7-84f0-dee3d4a4fefd">

### Тест 7(7 кб):
Результат лежит в папке **tests** в файле **output.txt**

## Программа тестирования на 8 баллов
```
# tests.asm
.include "macro_syscalls.asm"
.include "funcs.asm"

.data
    folder_path:   .space 256 
    test_files:    .string "tests/test_1.txt\0tests/test_2.txt\0tests/test_3.txt\0tests/test_4.txt\0tests/test_5.txt\0tests/test_6.txt\0tests/test_7.txt\0"
    test_count:    .word 7
    test_out_suffix: .string "_out.txt\0"

.text
.globl main
main:
    # Ввод пути до папки
    print_str("Введите путь до папки: ")
    str_get(folder_path, NAME_SIZE)

    # Вызываем тестовую программу
    jal test_program
    
    # Завершаем программу
    exit

.globl test_program
test_program:
    push(ra)
    
    lw s0, test_count
    la s1, test_files
    
test_loop:
    beqz s0, test_done
    # Выводим имя тестируемого файла
    print_str("Тестирование файла: ")
    print_str_reg(s1)
    newline
    
    la a0, in
    la a1, folder_path
    mv a2, s1
    jal create_full_path
    
    # Отладочный вывод входного файла
    print_str("Входной файл: ")
    print_str_addr(in)
    newline
    
    # Создаем полный путь к выходному файлу
    la a0, out
    la a1, folder_path
    mv a2, s1
    jal create_output_name
    
    # Отладочный вывод выходного файла
    print_str("Выходной файл: ")
    print_str_addr(out)
    newline
    
    # Обрабатываем файлы
    jal process
    
    # Следующий тест
    addi s0, s0, -1
    find_next:
        lb s2, (s1)
        addi s1, s1, 1
        bnez s2, find_next
    
    j test_loop

test_done:
    pop(ra)
    ret

# Создание полного пути к файлу
create_full_path:
    push(ra)
    push(t0)
    push(t1)
    
    # Копируем путь к папке
    mv t0, a0        # destination
    mv t1, a1        # source
    
path_loop:
    lb t2, (t1)
    beqz t2, add_slash
    sb t2, (t0)
    addi t0, t0, 1
    addi t1, t1, 1
    j path_loop

add_slash:
    li t2, '/'
    sb t2, (t0)
    addi t0, t0, 1

    # Копируем имя файла
    mv t1, a2
file_loop:
    lb t2, (t1)
    sb t2, (t0)
    beqz t2, full_path_done
    addi t0, t0, 1
    addi t1, t1, 1
    j file_loop

full_path_done:
    pop(t1)
    pop(t0)
    pop(ra)
    ret

# Создание имени выходного файла (добавляем _out.txt)
create_output_name:
    push(ra)
    push(t0)
    push(t1)
    push(t2)
    
    # Создаем полный путь к файлу
    jal create_full_path
    
    # Убираем расширение и добавляем _out.txt
    addi t0, a0, 0
base_name_loop:
    lb t2, (t0)
    beqz t2, add_suffix
    li t3, '.'
    beq t2, t3, add_suffix
    addi t0, t0, 1
    j base_name_loop

add_suffix:
    # Добавляем _out.txt
    la t1, test_out_suffix
suffix_loop:
    lb t2, (t1)
    sb t2, (t0)
    beqz t2, create_name_done
    addi t0, t0, 1
    addi t1, t1, 1
    j suffix_loop
    
create_name_done:
    pop(t2)
    pop(t1)
    pop(t0)
    pop(ra)
    ret
############################################################################################################################################
# funcs.asm
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
    mv a0, s5
    jal read_input
    mv s0, a0
    mv s1, a1
    
    # Обработка строки
    mv a0, s0
    mv a1, s1
    jal process_string
    mv s2, a0
    mv s3, a1
    
    # Проверка вывода на консоль
    mv a0, s2
    jal check_console_output
    
    # Открытие файла для записи
    open(out, WRITE_ONLY)
    bltz a0, error_open
    mv s6, a0
    
    # Запись в выходной файл
    mv a0, s2
    mv a1, s3
    mv a2, s6
    jal write_output
    
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
```

### Запуск
Результаты запуска можно найти в папке **tests** в файлах **test_X_out.txt**, где X - число от 1 до 7.
<img width="1840" alt="Screenshot 2024-12-02 at 11 42 17" src="https://github.com/user-attachments/assets/5ec51948-32e2-4798-b75e-e26f1c54b427">

## Решение на 10 баллов
Файл: **main.asm**
```
.include "macro_syscalls.asm"

.eqv    NAME_SIZE 256   # Размер буфера для имени файла
.eqv    TEXT_SIZE 512 # Размер чанка

.data
    in:           .space NAME_SIZE
    out:          .space NAME_SIZE
    strbuf:       .space TEXT_SIZE
    result:       .space TEXT_SIZE
    vowels:       .asciz "aeiouyAEIOUY"
    
.text
.globl main
# Основная программа
main:
    # Ввод имени входного файла
    print_str("Введите путь до файла со входными данными: ")
    str_get(in, NAME_SIZE)
     
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
    
    # Ввод имени выходного файла
    print_str("Введите путь до файла с выходными данными: ")
    str_get(out, NAME_SIZE)
    
    # Открытие файла для записи
    open(out, WRITE_ONLY)
    bltz a0, error_open
    mv s6, a0
    
    # Запись в выходной файл
    write_file(s2, s3, s6)
    
    # Закрытие файлов
    close(s5)
    close(s6)
    
    exit
    
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
```
Файл: **macro_syscall.asm**
```
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
```
Файл: **funcs.asm**
```
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
```
Файл: **test.asm**
```
.include "macro_syscalls.asm"
.include "funcs.asm"

.data
    folder_path:   .space 256 
    test_files:    .string "tests/test_1.txt\0tests/test_2.txt\0tests/test_3.txt\0tests/test_4.txt\0tests/test_5.txt\0tests/test_6.txt\0tests/test_7.txt\0"
    test_count:    .word 7
    test_out_suffix: .string "_out.txt\0"

.text
.globl main
main:
    # Ввод пути до папки
    print_str("Введите путь до папки: ")
    str_get(folder_path, NAME_SIZE)

    # Вызываем тестовую программу
    jal test_program
    
    # Завершаем программу
    exit

.globl test_program
test_program:
    push(ra)
    
    lw s0, test_count
    la s1, test_files
    
test_loop:
    beqz s0, test_done
    # Выводим имя тестируемого файла
    print_str("Тестирование файла: ")
    print_str_reg(s1)
    newline
    
    la a0, in
    la a1, folder_path
    mv a2, s1
    jal create_full_path
    
    # Отладочный вывод входного файла
    print_str("Входной файл: ")
    print_str_addr(in)
    newline
    
    # Создаем полный путь к выходному файлу
    la a0, out
    la a1, folder_path
    mv a2, s1
    jal create_output_name
    
    # Отладочный вывод выходного файла
    print_str("Выходной файл: ")
    print_str_addr(out)
    newline
    
    # Обрабатываем файлы
    jal process
    
    # Следующий тест
    addi s0, s0, -1
    find_next:
        lb s2, (s1)
        addi s1, s1, 1
        bnez s2, find_next
    
    j test_loop

test_done:
    pop(ra)
    ret

# Создание полного пути к файлу
create_full_path:
    push(ra)
    push(t0)
    push(t1)
    
    # Копируем путь к папке
    mv t0, a0        # destination
    mv t1, a1        # source
    
path_loop:
    lb t2, (t1)
    beqz t2, add_slash
    sb t2, (t0)
    addi t0, t0, 1
    addi t1, t1, 1
    j path_loop

add_slash:
    li t2, '/'
    sb t2, (t0)
    addi t0, t0, 1

    # Копируем имя файла
    mv t1, a2
file_loop:
    lb t2, (t1)
    sb t2, (t0)
    beqz t2, full_path_done
    addi t0, t0, 1
    addi t1, t1, 1
    j file_loop

full_path_done:
    pop(t1)
    pop(t0)
    pop(ra)
    ret

# Создание имени выходного файла (добавляем _out.txt)
create_output_name:
    push(ra)
    push(t0)
    push(t1)
    push(t2)
    
    # Создаем полный путь к файлу
    jal create_full_path
    
    # Убираем расширение и добавляем _out.txt
    addi t0, a0, 0
base_name_loop:
    lb t2, (t0)
    beqz t2, add_suffix
    li t3, '.'
    beq t2, t3, add_suffix
    addi t0, t0, 1
    j base_name_loop

add_suffix:
    # Добавляем _out.txt
    la t1, test_out_suffix
suffix_loop:
    lb t2, (t1)
    sb t2, (t0)
    beqz t2, create_name_done
    addi t0, t0, 1
    addi t1, t1, 1
    j suffix_loop
    
create_name_done:
    pop(t2)
    pop(t1)
    pop(t0)
    pop(ra)
    ret

```

### Результат запуска
Для main.asm
<img width="1840" alt="Screenshot 2024-12-02 at 15 01 13" src="https://github.com/user-attachments/assets/6dcb3e9d-ff32-475c-b11f-d24e0c1ba307">

Для tests.asm
<img width="1840" alt="Screenshot 2024-12-02 at 15 02 46" src="https://github.com/user-attachments/assets/108faa7d-e5ee-40d6-ba69-bf06376cceb9">

### Изменения 
В макросы добавленны функции read_file, write_file, processing, console_print.
В основную программу и в программу с функциями(funcs) заменены обычные вызовы на макросы.
Изменений в файле test.asm нет, ибо вся логика вызовов обрабатывающих файлы и строки функции находятся в funcs.asm 
Сделана многофайловая сборка программы(в main.asm вызывается библиотека макросов), в test.asm вызывается и модуль funcs, и модуль макросов.
