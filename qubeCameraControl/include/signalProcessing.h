#ifndef SIGNAL_PROC
#define SIGNAL_PROC

#include <deque>

#define PROCESSALPHA 1
#define PROCESSALPHADOT 2

//Signal processing variables
extern double alphaDotFiltered;
extern std::deque<double> x_alphaDot;
extern std::deque<double> y_alphaDot;
extern double alphaFiltered;
extern std::deque<double> x_alpha;
extern std::deque<double> y_alpha;
extern double alphaFilteredGated;
extern double alphaDotFilteredGated;
extern double alphaDotKalman;
extern double alphaDotKKalman;

extern double alphaDotTransfromVector[5];

void signalProcessingChain();

#endif

