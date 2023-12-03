#ifndef FRAME_CAPTURE
#define FRAME_CAPTURE

#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/opencv.hpp>
#include "ueye.h"

//Define Camera variables and settings
extern HIDS camID;
extern HWND camWindowPointer;
extern double actualFPS;
extern int cam;

//Camera size
extern int camWidth;
extern int camHeight;
extern int left;
extern IS_RECT areaOfInterest;
extern double framerate;

bool setupCamera();
bool getFrame(int width, int height, cv::Mat& mat);
bool shutdownCamera();

#endif