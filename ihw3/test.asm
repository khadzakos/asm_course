.include "macro_syscalls.asm"

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
    
.include "funcs.asm"