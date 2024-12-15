#include <iostream>
#include <fstream>
#include <vector>

void write_data(const std::vector<int> data) {
    for (int i = 0; i < data.size(); i++) {
        std::cout << data[i] <<  " ";
    }
    std::cout << std::endl;

    while (true) {
        std::cout << "Введите имя выходного файла: ";
        std::string filename;
        std::cin >> filename;
        std::ofstream file(filename);
        if (!file.is_open()) {
            std::cout << "Ошибка открытия файла\n";
            continue;
        }
        for (int i = 0; i < data.size(); i++) {
            file << data[i] << " ";
        }
        file.close();
        std::cout << "Данные успешно записаны в файл\n";
        break;
    }
}