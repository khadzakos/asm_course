# Макрос вывода строки
.macro print_str(%str)
    la a0, %str
    li a7, 4
    ecall
.end_macro

# Макрос чтения int
.macro read_int(%reg)
    li a7, 5
    ecall
    mv %reg, a0
.end_macro

# Макрос вывода int
.macro print_int(%reg)
    mv a0, %reg
    li a7, 1
    ecall
.end_macro


# Макрос вывода символа
.macro print_char(%char)
    li a0, %char
    li a7, 11
    ecall
.end_macro

# Ввод массива(буквально тот же код из первой программы, просто с макросами)
.macro input_array(%array, %size, %prompt)
    mv t0, %array
    li t1, 0
    loop1:
        print_str(%prompt)
        read_int(t2)
        sw t2, (t0)
        addi t0, t0, 4
        addi t1, t1, 1
        blt t1, %size, loop1
.end_macro

# Вывода массива(та же функция вывода, которую я обвесил макросами)
.macro print_array(%array, %size, %msg)
    print_str(%msg)
    mv t0, %array
    li t1, 0
    loop2:
        lw t2, (t0)
        print_int(t2)
        print_char(' ')
        addi t0, t0, 4
        addi t1, t1, 1
        blt t1, %size, loop2
    print_char('\n')
.end_macro

# Макрос генерации тестов
.macro generate_test_array(%array, %size)
    mv t0, %array
    li t1, 0
    li t2, 1000
    loop3:
        li a7, 41  # Системный вызов для получения случайного числа
        ecall
        bgez a0, mod # Для наглядности работал только с неотрицательными числами
        neg a0, a0
    mod:
        rem a0, a0, t2 # Беру модуль
        sw a0, (t0)
        addi t0, t0, 4
        addi t1, t1, 1
        blt t1, %size, loop3
.end_macro

.data
prompt_size: .asciz "Введите размер массива: "
prompt_elem: .asciz "Введите элемент: "
result_msg: .asciz "Площади квадратов: "
test_msg: .asciz "Тестовый массив: "
test_msg_res: .asciz "Площади тестового массива: "
array_size: .word 0
.align 2
array_A: .space 64 # Выделяем место для 16 элементов (16 * 4 байта)
array_B: .space 64 # Выделяем место для 16 элементов (16 * 4 байта)

.text
.global main

main:
    # Ввод размера массива
    print_str(prompt_size)
    read_int(s0)
    sw s0, array_size, t0  # Сохраняем размер массива

    # Установка указателей на массивы A и B
    la s1, array_A  # s1 = указатель на массив A
    la s2, array_B  # s2 = указатель на массив B

    # Ввод элементов массива A
    input_array(s1, s0, prompt_elem)

    # Вызов подпрограммы обработки массивов
    mv a0, s1  # адрес массива A
    mv a1, s2  # адрес массива B
    mv a2, s0  # размер массивов
    jal square_array

    # Вывод результата
    print_array(s2, s0, result_msg)

    # Генерация и вывод тестового массива
    generate_test_array(s1, s0)
    
    mv a0, s1  # адрес массива A
    mv a1, s2  # адрес массива B
    mv a2, s0  # размер массивов
    jal square_array
     
    print_array(s1, s0, test_msg)
    print_array(s2, s0, test_msg_res)

    # Выход из программы
    li a7, 10
    ecall

# Подпрограмма обработки массивов
square_array:
    addi sp, sp, -8
    sw s3, 0(sp) # сохраняем на стеке
    sw s4, 4(sp)  # сохраняем на стеке

    mv t0, a0  # указатель на A
    mv t1, a1  # указатель на B
    mv t2, a2  # счетчик элементов
    li t3, 0   # индекс текущего элемента

process_loop:
    lw t4, (t0)  # загрузка элемента из A
    mv t5, t4     # копия для умножения
    li t6, 0      # результат умножения
    li s3, 32     # счетчик битов

multiply:
    andi s4, t5, 1
    beqz s4, shift
    add t6, t6, t4
    bltu t6, t4, overflow
    bltz t6, overflow

shift:
    slli t4, t4, 1
    srli t5, t5, 1
    addi s3, s3, -1
    bnez s3, multiply

    sw t6, (t1)  # сохранение результата в B
    j next

overflow:
    sw zero, (t1)

next:
    addi t0, t0, 4
    addi t1, t1, 4
    addi t3, t3, 1
    blt t3, t2, process_loop

   # Восстанавливаем используемые значения
    lw s3, 0(sp)
    lw s4, 4(sp)
    addi sp, sp, 8
    ret