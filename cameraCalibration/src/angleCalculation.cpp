#define _USE_MATH_DEFINES
#include <cmath>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/opencv.hpp>
#include "angleCalculation.h"
#include "timing.h"

//Calibration variables
bool calibration = true;
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

double findMode(std::vector<double> array) {
    //Finds mode of sorted double vector.
    int appearanceCounter = 1;
    int maxAppearance = 0;
    double mode;

    sort(array.begin(), array.end());

    for (size_t i = 1; i < array.size(); i++) {
        if (array[i] == array[i-1]) {
            appearanceCounter++;
        } else {
            if (appearanceCounter > maxAppearance) {
                maxAppearance = appearanceCounter;
                mode = array[i-1];
            }
        }
    }

    //If mode at end
    if (appearanceCounter > maxAppearance) {
        maxAppearance = appearanceCounter;
        mode = array[array.size()-1];
    }
    return mode;
}

std::vector<cv::Point2f> calibrateDots() {
    
    std::vector<cv::Point2f> dots;
    
    //Print all points for testing
    for (size_t i = 0; i < calibrationCoordinates.size(); i++) {
        for (size_t j = 0; j < calibrationCoordinates[i].size(); j++) {
            std::cout << "X: " << std::to_string(calibrationCoordinates[i][j][0]) << " Y: " << std::to_string(calibrationCoordinates[i][j][1]) << ", ";
        }
        std::cout << std::endl;
    }

    //Mode tracking variables
    std::vector<double> X1Array;
    std::vector<double> Y1Array;
    std::vector<double> X2Array;
    std::vector<double> Y2Array;
    double X1Mode;
    double Y1Mode;
    double X2Mode;
    double Y2Mode;

    for (size_t i = 0; i < calibrationCoordinates.size(); i++) {
        //If there are 2 dots then consider them -> likely correct dot analysis
        if(calibrationCoordinates[i].size() == 2) {
            //Find mode of X and Y 1 and 2 by placing values in vector first
            X1Array.push_back(calibrationCoordinates[i][0][0]);
            Y1Array.push_back(calibrationCoordinates[i][0][1]);
            X2Array.push_back(calibrationCoordinates[i][1][0]);
            Y2Array.push_back(calibrationCoordinates[i][1][1]);
        } /*else if (calibrationCoordinates[i].size() == 1) {
            X1Array.push_back(calibrationCoordinates[i][0][0]);
            Y1Array.push_back(calibrationCoordinates[i][0][1]);
        }   */
    }

    //Find mode of coordinates
    X1Mode = findMode(X1Array);
    Y1Mode = findMode(Y1Array);

    if (X2Array.size() > 0) {
        X2Mode = findMode(X2Array);
        Y2Mode = findMode(Y2Array);
    } else {
        X2Mode = 0.0;
        Y2Mode = 0.0;
    }    

    //Place found dots in array to return
    dots.push_back(cv::Point2f(X1Mode, Y1Mode));
    dots.push_back(cv::Point2f(X2Mode, Y2Mode));

    std::cout << "X1M: " << std::to_string(X1Mode) << " Y1M: " << std::to_string(Y1Mode);
    std::cout << " X2M: " << std::to_string(X2Mode) << " Y2M: " << std::to_string(Y2Mode) << std::endl;

    dotPlacement = {cv::Point2f(X1Mode, Y1Mode), cv::Point2f(X2Mode, Y2Mode)};

    return dots;
}

bool errorCheckDotsAndPlace() {
    bool check = false;

    int minDistIndex1 = -1;
    int minDistIndex2 = -1;
    double minDist1 = 20.0; //Must be within 20 pixels
    double minDist2 = 20.0;

    for(int i = 0; i < foundDots.size(); i++) {
        double minDist1Calc = pow(pow(foundDots[i][0] - dotPlacement[0].x, 2) + pow(foundDots[i][1] - dotPlacement[0].y, 2), 0.5); //Euclidian distance
        double minDist2Calc = pow(pow(foundDots[i][0] - dotPlacement[1].x, 2) + pow(foundDots[i][1] - dotPlacement[1].y, 2), 0.5); //Euclidian distance

        if(minDist1Calc < minDist1) {
            minDist1 = minDist1Calc;
            minDistIndex1 = i;
        }

        if(minDist2Calc < minDist2) {
            minDist2 = minDist2Calc;
            minDistIndex2 = i;
        }
    }

    //Only update angle on correct reading of 2 dots
    //Else we do not update filtered dots.
    if (minDistIndex1 != minDistIndex2 && minDistIndex1 != -1 && minDistIndex2 != -1) {
        dotPlacement = {cv::Point2f(foundDots[minDistIndex1][0], foundDots[minDistIndex1][1]), cv::Point2f(foundDots[minDistIndex2][0], foundDots[minDistIndex2][1])};
        twoDotCheck = true;
    }

    return twoDotCheck;
}

void calculateAngle() {
    
    double A, B, C;
    double numerator = dotPlacement[0].y - dotPlacement[1].y; //Y coordinates inverted
    double denominator = dotPlacement[1].x - dotPlacement[0].x;

    //Use Ax + By + C = 0 to define line.  
    if (denominator < pow(10, -6)) {
        A = 1.0;
        B = 0.0;
        C = dotPlacement[1].x;
    } else {
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
    alphaDotCam = (double)(alphaCam - alphaCamLast) * timerMap["CameraLoop"].getMeanFrequency(); 
}
