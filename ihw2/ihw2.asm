.data
null: .float 0.0
one: .float 1.0
pow: .float -0.5
epsilon: .float 0.0005
.align 2
prompt: .asciz "Данная программа ищет корень 1 + x, используя степенной ряд\n"
prompt_elem: .asciz "Введите элемент(неотрицательное число): "
result_msg: .asciz "Результат sqrt(1 + x) c точностью ошибки 0.0005%: "
warning_ltz: .asciz "Число должно быть неотрицательным!\n"
endl: .asciz "\n"

.text
.globl main
main:
    la a0, prompt
    li a7, 4
    ecall
    la t1, null
    flw f0, 0(t1)
   
enter_number: # Ввод числа до момента корректного ввода
    la a0, prompt_elem
    li a7, 4
    ecall
		
    li a7, 6 
    ecall
    fmv.s fs0, fa0 # fs0 = x
    flt.s t1, fs0, f0
    beqz t1, end_enter_number
	
    la a0, warning_ltz # Вывод ошибки 
    li a7, 4
    ecall
    j enter_number
end_enter_number:

    fmv.s fa0, fs0 # В функцию передается только один параметр x
    jal sqrt_x
    # Результат лежит в fa0, сразу выводим
    la a0, result_msg # Вывод сообщения
    li a7, 4
    ecall		
    li a7, 2 # Вывод ответа
    ecall

    li a7, 10
    ecall
	
sqrt_x:
    addi sp, sp, -16
    fsw fs0, 8(sp)    # Сохраняем float регистры
    fsw fs1, 4(sp)
    fsw fs2, 0(sp)
    
    flw f0, one, t1
    flt.s t5, fa0, f0 # Проверка, что число меньше или больше либо равно 1, чтобы установить значение fs0 = x или fs0 = 1/x соответственно
    beqz t5, x_greater
x_less:
    fmv.s fs0, fa0 # fs0 = x
    j x_next
x_greater:
    # Вычисляем fs0 = 1/x
    flw f0, one, t1
    fdiv.s fs0, f0, fa0 # fs0 = 1/x
    j x_next
x_next:

    flw fs1, one, t1  # fs1 = 1 - назовем его term
    flw fs2, one, t1  # fs2 = 1 - назовем его result
    li t0, 1 # счетчик - назовем n

loop:
    # Вычисляем (2*n - 3) работает корректно до o(x^6)(этого достаточно для нащей точности)
    add t1, t0, t0  # t1 = 2*n
    addi t1, t1, -3 # t1 = 2*n - 3
    fcvt.s.w f1, t1 # Конвертируем в float
    
    # Умножаем на -0.5
    flw f2, pow, t1
    fmul.s f1, f1, f2
    
    # Умножаем на (1/x), если x >= 1 или на x, если x < 1
    fmul.s f1, f1, fs0
    
    # Делим на n
    fcvt.s.w f2, t0  # Конвертируем n в float
    fdiv.s f1, f1, f2
    
    # Умножаем текущий term
    fmul.s fs1, fs1, f1 # Новый term

    # Добавляем к result
    fadd.s fs2, fs2, fs1


    # Проверяем условие выхода |term| > epsilon * result(проверяем, текущий член изменяет сильнее, чем на 0.005%)
    fabs.s f1, fs1 # |term|
    flw f2, epsilon, t1 # загружаем epsilon
    fmul.s f3, f2, fs2 # epsilon * result
    fle.s t1, f3, f1 # if |term| >= epsilon * result
    
    # Увеличиваем n
    addi t0, t0, 1
    
    bnez t1, loop 

    beqz t5, result_greater # Проверка, что число меньше или больше либо равно 1(t5 мы не меняли, в нем лежит результат прошлой проверки flt.s t5, fa0, f0)
result_less:
    fmv.s fa0, fs2
    j result_next
result_greater:
    # Умножаем на sqrt(x) - этого требует степенная форма, где x >= 1
    fsqrt.s f0, fa0
    fmul.s fa0, f0, fs2
    j result_next
result_next:
    # Эпилог
    j done

done:
    # Восстанавливаем сохраненные регистры
    flw fs0, 8(sp)
    flw fs1, 4(sp)
    flw fs2, 0(sp)
    addi sp, sp, 16
    ret
