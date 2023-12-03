#define _USE_MATH_DEFINES
#include <cmath>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/opencv.hpp>
#include <deque>
#include "angleCalculation.h"
#include "timing.h"
#include "camControl.h"
#include "qubeControl.h"

//Calibration variables
bool getCalibrationDots = false;
bool calibrateDots = false;
bool calibratedDots = false;
bool calibratingDots = false;
std::vector<std::vector<cv::Vec3f>> calibrationCoordinates;
std::vector<cv::Point2f> dotPlacement;
std::vector<cv::Vec3f> foundDots;
std::vector<cv::Vec3f> filteredDots;
std::vector<cv::Point2f> foundCoordinates;

//Angle tracking
double alphaCam = 0.0;
double alphaCamLast = 0.0;
double alphaDotCam = 0.0;
double cameraAngle = 0.0;
bool twoDotCheck = false;

float findMode(std::vector<float> array) {
    //Finds mode of sorted double vector.
    int appearanceCounter = 1;
    int maxAppearance = 0;
    float mode;

    sort(array.begin(), array.end());

    for (size_t i = 1; i < array.size(); i++) {
        if (array[i] == array[i - 1]) {
            appearanceCounter++;
        }
        else {
            if (appearanceCounter > maxAppearance) {
                maxAppearance = appearanceCounter;
                mode = array[i - 1];
            }
        }
    }

    //If mode at end
    if (appearanceCounter > maxAppearance) {
        maxAppearance = appearanceCounter;
        mode = array[array.size() - 1];
    }
    return mode;
}

std::vector<cv::Point2f> dotCalibration() {

    calibratingDots = true;

    std::vector<cv::Point2f> dots;

    //Print all points for testing
    for (size_t i = 0; i < calibrationCoordinates.size(); i++) {
        for (size_t j = 0; j < calibrationCoordinates[i].size(); j++) {
            printf("X: %f Y: %f,", calibrationCoordinates[i][j][0], calibrationCoordinates[i][j][1]);
        }
        printf("\n");
    }

    //Mode tracking variables
    std::vector<float> X1Array;
    std::vector<float> Y1Array;
    std::vector<float> X2Array;
    std::vector<float> Y2Array;
    float X1Mode;
    float Y1Mode;
    float X2Mode;
    float Y2Mode;

    for (size_t i = 0; i < calibrationCoordinates.size(); i++) {
        //If there are 2 dots then consider them -> likely correct dot analysis
        if (calibrationCoordinates[i].size() == 2) {
            //Find mode of X and Y 1 and 2 by placing values in vector first
            X1Array.push_back(calibrationCoordinates[i][0][0]);
            Y1Array.push_back(calibrationCoordinates[i][0][1]);
            X2Array.push_back(calibrationCoordinates[i][1][0]);
            Y2Array.push_back(calibrationCoordinates[i][1][1]);
        }
    }

    if (X1Array.size() == 0) {
        //If no callibration dots found - stop calibration and program.
        printf("Could not calibrate dots - stopping program.\n");
        stop = 1;
        return dots;
    }

    //Find mode of coordinates
    X1Mode = findMode(X1Array);
    Y1Mode = findMode(Y1Array);
    X2Mode = findMode(X2Array);
    Y2Mode = findMode(Y2Array);
    
    //Place found dots in array to return
    dots.push_back(cv::Point2f(X1Mode, Y1Mode));
    dots.push_back(cv::Point2f(X2Mode, Y2Mode));

    printf("X1M: %f Y1M: %f X2M: %f Y2M: %f\n", X1Mode, Y1Mode, X2Mode, Y2Mode);

    dotPlacement = { cv::Point2f(X1Mode, Y1Mode), cv::Point2f(X2Mode, Y2Mode) };

    calibratingDots = false;

    return dots;
}


bool errorCheckDotsAndPlace() {
    twoDotCheck = false;

    int minDistIndex1 = -1;
    int minDistIndex2 = -1;
    double minDist1 = 20.0; //Must be within 20 pixels
    double minDist2 = 20.0;

    for (int i = 0; i < foundDots.size(); i++) {
        //For each dot found check distance to last calculated dots.
        double minDist1Calc = pow(pow(foundDots[i][0] - dotPlacement[0].x, 2) + pow(foundDots[i][1] - dotPlacement[0].y, 2), 0.5); //Euclidian distance
        double minDist2Calc = pow(pow(foundDots[i][0] - dotPlacement[1].x, 2) + pow(foundDots[i][1] - dotPlacement[1].y, 2), 0.5); //Euclidian distance

        //If Euclidian distance less than 20 and lowest found save index
        if (minDist1Calc < minDist1) {
            minDist1 = minDist1Calc;
            minDistIndex1 = i;
        }

        if (minDist2Calc < minDist2) {
            minDist2 = minDist2Calc;
            minDistIndex2 = i;
        }
    }

    //Only update angle on correct reading of 2 dots
    //Else we do not update filtered dots.
    if (minDistIndex1 != minDistIndex2 && minDistIndex1 != -1 && minDistIndex2 != -1) {
        dotPlacement = { cv::Point2f(foundDots[minDistIndex1][0], foundDots[minDistIndex1][1]), cv::Point2f(foundDots[minDistIndex2][0], foundDots[minDistIndex2][1]) };
        twoDotCheck = true;
    }

    return twoDotCheck;
}

void calculateAngle() {

    double A, B, C;
    double numerator =  ((double) dotPlacement[0].y - dotPlacement[1].y); //Y coordinates inverted
    double denominator = ((double) dotPlacement[1].x - dotPlacement[0].x);

    //Use Ax + By + C = 0 to define line.  
    if (denominator < pow(10, -6)) {
        A = 1.0;
        B = 0.0;
        C = dotPlacement[1].x;
    }
    else {
        A = numerator / denominator; //Y is inverted
        B = 1.0;
        C = (dotPlacement[1].y + A * dotPlacement[1].x);
    }

    //Calculate angle of line
    if (B != 0.0) {
        alphaCam = atan(A);
    }
    else {
        alphaCam = M_PI / 2;
    }

    cameraAngle = alphaCam / M_PI * 180;

    return;
}

void camUpdateLastValues() {
    //Update last count
    alphaCamLast = alphaCam;
}

void camDifferentiatePosition() {
    //Mean period gotten from timer module and converted from ms to seconds
    alphaDotCam = (double)(alphaCam - alphaCamLast) * framerate; 
}
