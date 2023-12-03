#ifndef LOGGING
#define LOGGING

#include <chrono>
#include <iostream>
#include <fstream>
#include <string>
#include "angleCalculation.h"
#include "qubeControl.h"
#include "signalProcessing.h"
#include "camControl.h"
#include <vector>

extern std::string datafile;
extern std::ofstream file_out;
extern time_t systemTime;
extern char buf[26];

void startupLog();
void measurementLog();

#endif