#include <cmath>
#include "timing.h"

std::map<std::string, Timer>timerMap;

Timer::Timer() {
    nMeasurements = 0;
    meanPeriod = 0.0;
    meanFrequency = 0.0;
    startTime = std::chrono::high_resolution_clock::now();
}

void Timer::start() {
    startTime = std::chrono::high_resolution_clock::now();
}

void Timer::stop() {
    auto stopTime = std::chrono::high_resolution_clock::now();
    nMeasurements++;

    auto tElapsed = (stopTime - startTime);
    double period = tElapsed.count() / pow(10, 6); //nanoseconds divided by 10^6 ->milliseconds
    meanPeriod += (period - meanPeriod) / nMeasurements;
    meanFrequency = 1000 / meanPeriod;
}

double Timer::getMeanPeriod() {
    return meanPeriod;
}

double Timer::getMeanFrequency() {
    return meanFrequency;
}

void setupTimers() {

    Timer t1;
    Timer t2;
    Timer t3;
    Timer t4;
    Timer t5;
    Timer t6;
    Timer t7;

    timerMap["QubeLoop"] = t1;
    timerMap["CameraLoop"] = t2;
    timerMap["GetFrame"] = t3;    
    timerMap["ImageManipulation"] = t4;
    timerMap["AngleCalculation"] = t5;
    timerMap["ImagePresentation"] = t6;
    timerMap["QubeSampleToCamVoltageSet"] = t7;
}

void printTimers() {
    for (auto element :timerMap) {
        printf("Timer: %s - MeanPeriod %lf, MeanFrequency %lf\n", element.first.c_str(), element.second.getMeanPeriod(), element.second.getMeanFrequency());
    }
}

