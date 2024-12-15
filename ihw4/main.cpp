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
        rnd.seed(std::chrono::system_clock::now().time_since_epoch().count());
        std::sort(data.begin(), data.end());

        pthread_mutex_init(&mutex, NULL);
        pthread_cond_init(&read_cond, NULL);
        pthread_cond_init(&write_cond, NULL);

        readers = 0;
        writers = 0;
    }

    Database(int size) {
        rnd.seed(std::chrono::system_clock::now().time_since_epoch().count());

        data.resize(size);
        for (int& i : data) {
            i = rnd() % 100;
        }
        std::sort(data.begin(), data.end());

        pthread_mutex_init(&mutex, NULL);
        pthread_cond_init(&read_cond, NULL);
        pthread_cond_init(&write_cond, NULL);

        readers = 0;
        writers = 0;
    }

    ~Database() {
        pthread_mutex_destroy(&mutex);
        pthread_cond_destroy(&read_cond);
        pthread_cond_destroy(&write_cond);
    }

    void read(int thread_id) {
        pthread_mutex_lock(&mutex);

        // Ждем, пока писатель закончит работу
        while (writers > 0) {
            pthread_cond_wait(&read_cond, &mutex);
        }
        readers++;
        pthread_mutex_unlock(&mutex);

        int index = rnd() % data.size();
        std::cout << "Читатель #" << thread_id
                  << " прочитал запись #" << index
                  << " со значением " << data[index] << std::endl;

        pthread_mutex_lock(&mutex);
        readers--;

        if (readers == 0) {
            pthread_cond_signal(&write_cond);
        }

        pthread_mutex_unlock(&mutex);

    }

    void write(int thread_id) {
        pthread_mutex_lock(&mutex);

        // Ждем, пока другие писатели или читатели закончат работу
        while (writers > 0 || readers > 0) {
            pthread_cond_wait(&write_cond, &mutex);
        }
        writers++;
        pthread_mutex_unlock(&mutex);

        int index = rnd() % data.size();
        int old_value = data[index];
        int new_value = rnd() % 100;
        data[index] = new_value;
        std::sort(data.begin(), data.end());

        std::cout << "Писатель #" << thread_id
                  << " изменил запись #" << index
                  << " со значения " << old_value
                  << " на " << new_value << std::endl;

        pthread_mutex_lock(&mutex);
        writers--;

        pthread_cond_signal(&write_cond);
        pthread_cond_broadcast(&read_cond);

        pthread_mutex_unlock(&mutex);
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
    read_data(data);

    Database db(data);

    std::vector<pthread_t> readers;
    std::vector<pthread_t> writers;
    for (int i = 0; i < 10; i++) {
        if (rand() % 2 == 0) {
            pthread_t thread;
            pthread_create(&thread, NULL, [](void* arg) -> void* {
                ThreadData* data = (ThreadData*) arg;
                data->db->read(data->thread_id);
                usleep(500000);
                return NULL;
            }, new ThreadData{&db, static_cast<int>(readers.size())});

            readers.push_back(thread);
        } else {
            pthread_t thread;
            pthread_create(&thread, NULL, [](void* arg) -> void* {
                ThreadData* data = (ThreadData*) arg;
                data->db->write(data->thread_id);
                usleep(500000);
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

    write_data(db.get_data());
    return 0;
}
