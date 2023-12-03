#ifndef ANGLE_CALC
#define ANGLE_CALC

#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/opencv.hpp>

//Calibration variables
extern bool getCalibrationDots;
extern bool calibrateDots;
extern bool calibratedDots;
extern bool calibratingDots;
extern std::vector<std::vector<cv::Vec3f>> calibrationCoordinates;
extern std::vector<cv::Point2f> dotPlacement;
extern std::vector<cv::Vec3f> foundDots;
extern std::vector<cv::Point2f> foundCoordinates;

//Angle tracking
extern double alphaCam;
extern double alphaCamLast;
extern double alphaDotCam;
extern double cameraAngle;
extern bool twoDotCheck;

float findMode(std::vector<double> array);
std::vector<cv::Point2f> dotCalibration();
void angleCalibration();
bool errorCheckDotsAndPlace();
void calculateAngle();
void camUpdateLastValues();
void camDifferentiatePosition();

#endif
