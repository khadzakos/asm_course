#include <iostream>
#include <vector>
#include <chrono>
#include <random>
#include <pthread.h>
#include <print>

#include "data/input_data.cpp"
#include "data/output_data.cpp"

class Database {
public:
    Database(std::vector<int>& data) : data(data) {
        rnd.seed(std::chrono::system_clock::now().time_since_epoch().count()); // Инициализация генератора случайных чисел
        std::sort(data.begin(), data.end()); // Сортировка данных

        pthread_mutex_init(&mutex, NULL); // Инициализация мьютекса
        pthread_cond_init(&read_cond, NULL); // Инициализация условной переменной для читателей
        pthread_cond_init(&write_cond, NULL); // Инициализация условной переменной для писателей

        readers = 0; // Количество читателей
        writers = 0; // Количество писателей
    }

    // Деструктор
    ~Database() {
        pthread_mutex_destroy(&mutex);
        pthread_cond_destroy(&read_cond);
        pthread_cond_destroy(&write_cond);
    }

    void read(int thread_id) {
        pthread_mutex_lock(&mutex); // Блокируем мьютекс для изменения количества читателей

        // Ждем, пока писатель закончит работу
        while (writers > 0) {
            pthread_cond_wait(&read_cond, &mutex);
        }

        // Читаем случайную запись
        int index = rnd() % data.size();
        std::cout << "Читатель #" << thread_id
                  << " прочитал запись #" << index
                  << " со значением " << data[index] << std::endl;

        readers++;
        pthread_mutex_unlock(&mutex); // Разблокируем мьютекс

        pthread_mutex_lock(&mutex); // Блокируем мьютекс для изменения количества читателей
        readers--;

        if (readers == 0) {
            pthread_cond_signal(&write_cond); // Сигнализируем писателю, что все читатели закончили работу
        }

        pthread_mutex_unlock(&mutex); // Разблокируем мьютекс

    }

    void write(int thread_id) {
        pthread_mutex_lock(&mutex); // Блокируем мьютекс для изменения количества писателей

        // Ждем, пока другие писатели или читатели закончат работу
        while (writers > 0 || readers > 0) {
            pthread_cond_wait(&write_cond, &mutex);
        }

        // Изменяем случайную запись
        int index = rnd() % data.size();
        int old_value = data[index];
        int new_value = rnd() % 100;
        data[index] = new_value;
        std::sort(data.begin(), data.end());
        std::cout << "Писатель #" << thread_id
                  << " изменил запись #" << index
                  << " со значения " << old_value
                  << " на " << new_value << std::endl;
        std::cout << "Новые данные: ";
        for (int i = 0; i < data.size(); i++) {
            std::cout << data[i] << " ";
        }
        std::cout << std::endl;
        writers++;
        pthread_mutex_unlock(&mutex); // Разблокируем мьютекс


        pthread_mutex_lock(&mutex); // Блокируем мьютекс для изменения количества писателей
        writers--;

        pthread_cond_signal(&write_cond); // Сигнализируем другим писателям, что этот писатель закончил работу
        pthread_cond_broadcast(&read_cond); // Сигнализируем всем читателям, что писатель закончил работу

        pthread_mutex_unlock(&mutex); // Разблокируем мьютекс
    }

    std::vector<int> get_data() {
        return data;
    }

private:
    std::vector<int> data;
    pthread_mutex_t mutex;
    pthread_cond_t read_cond;
    pthread_cond_t write_cond;

    int readers;
    int writers;

    std::mt19937 rnd;
};

struct ThreadData {
    Database* db;
    int thread_id;
};

int main() {
    srand(time(0));

    std::vector<int> data;
    read_data(data); // Читаем данные из консоли/файла/генерированные данные

    Database db(data); // Создаем объект базы данных

    std::vector<pthread_t> readers; // Вектор потоков читателей
    std::vector<pthread_t> writers; // Вектор потоков писателей

    // Создаем потоки читателей и писателей
    for (int i = 0; i < 10; i++) {
        if (rand() % 2 == 0) {
            pthread_t thread;
            pthread_create(&thread, NULL, [](void* arg) -> void* {
                ThreadData* data = (ThreadData*) arg;
                data->db->read(data->thread_id);
//                usleep(500000);
                return NULL;
            }, new ThreadData{&db, static_cast<int>(readers.size())}); // Создаем поток читателя

            readers.push_back(thread); // Добавляем поток в вектор
        } else {
            // Тут все аналогично, только для писателей
            pthread_t thread;
            pthread_create(&thread, NULL, [](void* arg) -> void* {
                ThreadData* data = (ThreadData*) arg;
                data->db->write(data->thread_id);
//                usleep(500000);
                return NULL;
            }, new ThreadData{&db, static_cast<int>(writers.size())});

            writers.push_back(thread);
        }
    }

    // Ждем завершения всех потоков
    for (int i = 0; i < readers.size(); i++) {
        pthread_join(readers[i], NULL);
    }

    for (int i = 0; i < writers.size(); i++) {
        pthread_join(writers[i], NULL);
    }

    write_data(db.get_data()); // Записываем данные в консоль и файл
    return 0;
}
