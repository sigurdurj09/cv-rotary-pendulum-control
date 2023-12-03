#ifndef TIMING
#define TIMING
#include <chrono>
#include <stdint.h>
#include <map>
#include <string>

class Timer {
public:
    Timer();
    void start();
    void stop();
    double getMeanPeriod();
    double getMeanFrequency();

private:
    uint32_t nMeasurements;
    double meanPeriod; //milliseconds
    double meanFrequency; 
    std::chrono::high_resolution_clock::time_point startTime;
};

extern std::map<std::string, Timer>timerMap;
void setupTimers();
void printTimers();

#endif