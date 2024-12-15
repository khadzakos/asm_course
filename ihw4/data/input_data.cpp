#include <iostream>
#include <fstream>
#include <vector>

void read_data(std::vector<int>& data) {
    while (true) {
        std::cout << "Введите цифру: \n"
                  << "1. Ввод данных из консоли\n"
                  << "2. Ввод данных из файла\n"
                  << "3. Cлучайные данные\n"
                  << "4. Выйти\n";
        int choice;
        std::cin >> choice;
        if (choice == 1) {
            std::cout << "Введите количество чисел: ";
            int n;
            std::cin >> n;
            data.resize(n);
            std::cout << "Введите числа: ";
            for (int i = 0; i < n; i++) {
                std::cin >> data[i];
            }
            std::cout << "Данные успешно загружены\n";

            break;
        } else if (choice == 2) {
            std::string filename;
            std::cout << "Введите имя файла: ";
            std::cin >> filename;
            std::ifstream file(filename);
            if (!file.is_open()) {
                std::cout << "Ошибка открытия файла\n";
                continue;
            }

            while (!file.eof()) {
                int value;
                file >> value;
                data.push_back(value);
            }
            std::cout << "Данные успешно загружены\n";
            file.close();

            break;
        } else if (choice == 3) {
            std::cout << "Введите количество чисел: ";
            int n;
            std::cin >> n;
            data.resize(n);
            for (int i = 0; i < n; i++) {
                data[i] = rand() % 100;
            }

            std::cout << "Cгенерированные данные: ";
            for (int i = 0; i < n; i++) {
                std::cout << data[i] << " ";
            }
            std::cout << std::endl;

            std::cout << "Данные успешно загружены\n";
            break;
        } else if (choice == 4) {
            break;
        } else {
            std::cout << "Неверный ввод\n";
        }
    }
}