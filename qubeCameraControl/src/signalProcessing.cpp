#define _USE_MATH_DEFINES
#include <cmath>
#include "signalProcessing.h"
#include <deque>
#include "qubeControl.h"
#include "camControl.h"
#include "angleCalculation.h"
#include "timing.h"

//Signal processing variables
//Alpha
double b_alpha[] = { 0.2452, 0.2452 };
double a_alpha[] = { 1.0000, -0.5095 };
int alphaFilterOrder = 1;
std::deque<double> x_alpha(alphaFilterOrder + 1, 0.0);
std::deque<double> y_alpha(alphaFilterOrder, 0.0);
double alphaFiltered = 0.0;
//Alpha Dot
double b_alphaDot[] = { 0.4774,    0.9253,    1.3594,    0.9253,    0.4774 };
double a_alphaDot[] = { 1.0000,    0.9780,    1.6374,    0.6256,    0.4321 };
int alphaDotFilterOrder = 4;
std::deque<double> x_alphaDot(alphaDotFilterOrder + 1, 0.0);
std::deque<double> y_alphaDot(alphaDotFilterOrder, 0.0);
double alphaDotFiltered = 0.0;
//Gates
double alphaFilteredGated = 0.0;
double alphaFilteredGatedLast = 0.0;
double alphaGate = 0.004;
double alphaDotFilteredGated = 0.0;
double alphaDotGate = 0.18;
//Kalman Prediction
double alphaDotKalman = 0.0;
double alphaDotKalmanPrediction = 0.0;
double alphaDotRKalman = 0.08449; //Noise covariance - measured
double alphaDotQKalman = 0.01835; //Disturbance covariance - measured
double alphaDotKalmanWeight = alphaDotRKalman / (alphaDotRKalman + alphaDotQKalman); //Works out to alphaDot R Kalman with the combination above
//double alphaDotKalmanWeight = 0.82;
double alphaDotKKalman = 0.0; //Kalman Gain
double alphaDotPKalman = 0.06613; //Error covariance - measured
//double alphaDotPKalman = 0.0; //Error covariance - measured

double A_system[5][5] = {   {0.0, 1.0, 0.0, 0.0, 0.0},
                            {0.0, 0.0, 0.0, 1.0, 0.0},
                            {0.0, 0.0, 0.0, 0.0, 1.0},
                            {0.0, 0.0, 152.0057, -12.2542, -0.5005},
                            {0.0, 0.0, 264.3080, -12.1117, -0.8702}
                        };
double B_system[5][1] = {   {0.0},
                            {0.0}, 
                            {0.0}, 
                            {50.6372}, 
                            {50.0484} 
                        };
double alphaDotTransfromVector[5] = { (A_system[4][0] - B_system[4][0] * K[0][0]) / framerate, 
                                    (A_system[4][1] - B_system[4][0] * K[0][1]) / framerate,
                                    (A_system[4][2] - B_system[4][0] * K[0][2]) / framerate,
                                    (A_system[4][3] - B_system[4][0] * K[0][3]) / framerate,
                                    (A_system[4][4] - B_system[4][0] * K[0][4]) / framerate + 1
                                    };

void IIRFilter(int variable) {

	double * b;
	double * a;
    int * filterOrder;
    std::deque<double> * x;
    std::deque<double> * y;
    double * filteredVariable;
    double * rawVar;

    //Set pointers with regards to what to filter
	if (variable == PROCESSALPHA) {
        b = b_alpha;
        a = a_alpha;
        filterOrder = &alphaFilterOrder;
        x = &x_alpha;
        y = &y_alpha;
        filteredVariable = &alphaFiltered;
        rawVar = &alphaCam;
	}
	else if (variable == PROCESSALPHADOT) {
        b = b_alphaDot;
        a = a_alphaDot;
        filterOrder = &alphaDotFilterOrder;
        x = &x_alphaDot;
        y = &y_alphaDot;
        filteredVariable = &alphaDotFiltered;
        rawVar = &alphaDotCam;	}
	else {
		return;
	}
    //LP filtering
    x->push_front(*rawVar);
    x->pop_back();

    //IIR filter calculation
    *filteredVariable = 0.0;
    
    for (int i = 0; i <= *filterOrder; i++) {
        if (i == 0) {
            *filteredVariable += b[i] * x->at(i);
        }
        else {
            *filteredVariable += b[i] * x->at(i) - a[i] * y->at(i-1);
        }
    }

    y->push_front(*filteredVariable);
    y->pop_back();
    
}

void noiseGating(int variable) {
    //Gating
    double * rawVar;
    double * gatedVar;
    double * gate;

    //Set pointers with regards to what to filter
    if (variable == PROCESSALPHA) {
        rawVar = &alphaFiltered;
        gatedVar = &alphaFilteredGated;
        gate = &alphaGate;
    }
    else if (variable == PROCESSALPHADOT) {
        rawVar = &alphaDotFiltered;
        gatedVar = &alphaDotFilteredGated;
        gate = &alphaDotGate;
    }
    else {
        return;
    }

    if (abs(*rawVar) < *gate) {
        *gatedVar = 0.0;
    }
    else {
        *gatedVar = *rawVar;
    }
}

void kalmanFilter(int variable) {
    //Kalman filtering

    double * varKalman;
    double * varKalmanPrediction;
    double * varKalmanWeight;
    double * varTransfromVector;
    double * varRaw;
    double * varRKalman; 
    double * varQKalman;
    double * varKKalman;
    double * varPKalman;

    //Set pointers with regards to what to filter
    if (variable == PROCESSALPHADOT) {
        varKalman = &alphaDotKalman;
        varKalmanPrediction = &alphaDotKalmanPrediction;
        varKalmanWeight = &alphaDotKalmanWeight;
        varTransfromVector = alphaDotTransfromVector;
        varRaw = &alphaDotCam;
        varRKalman = &alphaDotRKalman;
        varQKalman = &alphaDotQKalman;
        varKKalman = &alphaDotKKalman;
        varPKalman = &alphaDotPKalman;
    } else {
        return;
    }

    //Filter process
    //Update
    *varKKalman = *varPKalman / (*varPKalman + *varRKalman);

    *varKalman = *varKalmanPrediction + *varKalmanWeight * (*varRaw - *varKalmanPrediction);
    //*varKalman = *varKalmanPrediction + *varKKalman * (*varRaw - *varKalmanPrediction);

    *varPKalman = (1 - *varKKalman) * *varPKalman + *varQKalman;

    //Predict
    *varKalmanPrediction = varTransfromVector[0] * thetaIntegral 
                        + varTransfromVector[1] * thetaQube 
                        + varTransfromVector[2] * alphaCam 
                        + varTransfromVector[3] * thetaDotQube
                        + varTransfromVector[4] * *varKalman;
}

void signalUpdateLastValues() {
    //Update last count
    alphaFilteredGatedLast = alphaFilteredGated;
}

void signalDifferentiatePosition() { 
    alphaDotFilteredGated = (double)(alphaFilteredGated - alphaFilteredGatedLast) * framerate;
}

void signalProcessingChain() {
    //API entrance to signal processing update chain
    signalUpdateLastValues();
    IIRFilter(PROCESSALPHA);
    IIRFilter(PROCESSALPHADOT);
    noiseGating(PROCESSALPHA);    
    signalDifferentiatePosition();
    kalmanFilter(PROCESSALPHADOT);
}