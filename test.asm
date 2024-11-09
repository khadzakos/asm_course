.data
test_array_1: .word 2, 3, 5, 7, 9 # Тест 1
test_array_2: .word 1000000, 11, 29, 35, 12 # Тест 2
test_array_3: .word 33, 14, 2000000, -20, 0 # Тест 3
test_array_4: .word 0, 1, 4, 6, 8 # Тест 4
test_array_5: .word 111, 222, 333, 444, 993 # Тест 5
test_array_6: .word 1, 2, 3, 4, 5, 6, 7, 8, 9 # Тест 6(экстра)
result_array: .word 0, 0, 0, 0, 0 # Массив результата
result_array_extra: .word 0, 0, 0, 0, 0, 0, 0, 0, 0 # Массив результата(для другого размера)
array_size: .word 5
array_size_extra: .word 9
test_msg: .asciz "Тест "
result_msg: .asciz "Площади квадратов: "
endl: .asciz "\n"

.text
.global test_main


test_main:
    la s0, array_size
    lw s0, (s0)

    # Тест 1
    la a0, test_msg
    li a7, 4
    ecall
    li a0, 1
    li a7, 1
    ecall
    la a0, endl
    li a7, 4
    ecall
    
    la a0, test_array_1
    la a1, result_array
    mv a2, s0
    jal square_array
    
    la a0, result_array
    mv a1, s0
    jal print_array
    
    # Тест 2
    la a0, test_msg
    li a7, 4
    ecall
    li a0, 2
    li a7, 1
    ecall
    la a0, endl
    li a7, 4
    ecall
    
    la a0, test_array_2
    la a1, result_array
    mv a2, s0
    jal square_array
    
    la a0, result_array
    mv a1, s0
    jal print_array
    
    # Тест 3
    la a0, test_msg
    li a7, 4
    ecall
    li a0, 3
    li a7, 1
    ecall
    la a0, endl
    li a7, 4
    ecall
    
    la a0, test_array_3
    la a1, result_array
    mv a2, s0
    jal square_array
    
    la a0, result_array
    mv a1, s0
    jal print_array
    
    # Тест 4
    la a0, test_msg
    li a7, 4
    ecall
    li a0, 4
    li a7, 1
    ecall
    la a0, endl
    li a7, 4
    ecall
    
    la a0, test_array_4
    la a1, result_array
    mv a2, s0
    jal square_array
    
    la a0, result_array
    mv a1, s0
    jal print_array
    
    # Тест 5
    la a0, test_msg
    li a7, 4
    ecall
    li a0, 5
    li a7, 1
    ecall
    la a0, endl
    li a7, 4
    ecall
    
    la a0, test_array_5
    la a1, result_array
    mv a2, s0
    jal square_array
    
    la a0, result_array
    mv a1, s0
    jal print_array
    
    # Тест 6
    la a0, test_msg
    li a7, 4
    ecall
    li a0, 6
    li a7, 1
    ecall
    la a0, endl
    li a7, 4
    ecall
    
    la s0, array_size_extra
    lw s0, (s0)
    
    la a0, test_array_6
    la a1, result_array_extra
    mv a2, s0
    jal square_array
    
    la a0, result_array_extra
    mv a1, s0
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
    
    la a0, endl
    li a7, 4
    ecall
    ret
