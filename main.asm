.data
prompt_size: .asciz "Введите размер массива: "
prompt_elem: .asciz "Введите элемент: "
result_msg: .asciz "Площади квадратов: "
array_size: .word 0
.align 2
array_A: .space 64 # Выделяем место для 16 элементов (16 * 4 байта)
array_B: .space 64 # Выделяем место для 16 элементов (16 * 4 байта)

.text
.global main

main:
    # Ввод размера массива
    la a0, prompt_size
    li a7, 4
    ecall
    li a7, 5
    ecall
    mv s0, a0  # s0 = размер массива
    sw s0, array_size, t0  # Сохраняем размер массива

    # Установка указателей на массивы A и B
    la s1, array_A  # s1 = указатель на массив A
    la s2, array_B  # s2 = указатель на массив B

    # Ввод элементов массива A
    mv t0, s1
    li t1, 0
input_loop:
    la a0, prompt_elem
    li a7, 4
    ecall
    li a7, 5
    ecall
    sw a0, (t0)
    addi t0, t0, 4
    addi t1, t1, 1
    blt t1, s0, input_loop

    # Вызов подпрограммы обработки массивов
    mv a0, s1  # адрес массива A
    mv a1, s2  # адрес массива B
    mv a2, s0  # размер массивов
    jal square_array

    # Вызов подпрограммы вывода массива
    mv a0, s2 # адрес массива B
    mv a1, s0 # размер массива
    jal print_array

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

# Подпрограмма вывода результата   
print_array:
    mv t0, a0 # указатель на B
    mv t1, a1 # размер массива
    # Вывод результатов
    la a0, result_msg
    li a7, 4
    ecall
    li t2, 0
output_loop:
    lw a0, (t0)
    li a7, 1
    ecall
    li a0, ' '
    li a7, 11
    ecall
    addi t0, t0, 4
    addi t2, t2, 1
    blt t2, t1, output_loop
    
    ret