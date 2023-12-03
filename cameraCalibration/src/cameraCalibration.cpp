#define _USE_MATH_DEFINES
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/opencv.hpp>
#include <iostream>
#include <fstream>
#include "ueye.h"
#include "angleCalculation.h"
#include "timing.h"
#include "imageManipulation.h"
#include "frameCapture.h"

std::string datafile("./data.log");
std::ofstream file_out;

std::string datafile2("./data2.log");
std::ofstream file_out2;
char buf2[26];

int main() {

    //Camera setup
    if (!setupCamera()) {
        printf("Could not set up camera\n");
    }

    //Log file setup
    auto systemTime = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());

    file_out.open(datafile, std::ios_base::app);
    file_out << "Starting new run: ";
    file_out << ctime(&systemTime) << std::endl;
    file_out << "source;p1x;p1y;p1r;p2x;p2y;p2r;p3x;p3y;p3r;p4x;p4y;p4r;p5x;p5y;p5r;systemTime" << std::endl;
    file_out.close(); 

    file_out2.open(datafile2, std::ios_base::app);
    file_out2 << "Starting new run: ";
    file_out2 << ctime(&systemTime) << std::endl;
    file_out2 << "alphaCam;alphaDotCam;systemTime" << std::endl;
    file_out2.close(); 


    //Timing setup
    setupTimers();
            
    while(true){
        timerMap["CameraLoop"].start();
	// Get a video frame        
        cv::Mat frame(areaOfInterest.s32Height, areaOfInterest.s32Width, CV_8UC1);
        getFrame(areaOfInterest.s32Width, areaOfInterest.s32Height, frame);

        cv::rotate(frame, frame, cv::ROTATE_90_COUNTERCLOCKWISE);
        cv::Mat contrasted, mask;

        contrasted = frame.clone();
        lightMasking(&contrasted);
        updateContrast(&contrasted);
        blurFrame(&contrasted, 5); //See if needed
        
        mask = blackFiltering(&contrasted);
        blurFrame(&mask,3);

        placeCircles(&frame, false, 50, 15, "basic");
        //placeCircles(&contrasted, true, 45, 13);
        foundDots = placeCircles(&contrasted, true, 20, 8, "contrasted");
        //foundDots = placeCircles(&mask, true, 20, 5);
        placeCircles(&mask, true, 20, 5, "mask");
        

        if(calibration) {
            calibrationCoordinates.push_back(foundDots);
        } else {
            
            camUpdateLastValues();

            if(errorCheckDotsAndPlace()) {
                calculateAngle();
            };

            camDifferentiatePosition();

            auto time2 = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
	        file_out2.open(datafile2, std::ios_base::app);
            file_out2 << std::to_string(alphaCam) << ";";
            file_out2 << std::to_string(alphaDotCam) << ";";
            ctime_s(buf2, sizeof(buf2), &time2);
            file_out2 << buf2;
            file_out2.close();
        }
        
        //Show frames
        cv::imshow("Greyscale test", frame);
        cv::imshow("Contrast update + threshold test", contrasted);
        cv::imshow("Black filter", mask);

        // Press  ESC on keyboard to exit
        //char c = (char)cv::waitKey(1000); //Slowdown to analyze
        //char c = (char)cv::waitKey(1000/fps);
        char c = (char)cv::waitKey(1); //Live

        timerMap["CameraLoop"].stop();

        if(c == 'c'){ 
            //Press c to start angle calculations
            calibration = false;
            dotPlacement = calibrateDots();
            std::cout << "System calibrated" << std::endl;
        }
        if(c == 27) {
            break;
        }
        if(c == 's') {
            cv::imwrite("rawFrame.jpg", frame);
            cv::imwrite("contrastedFrame.jpg", contrasted);
            cv::imwrite("maskedFrame.jpg", mask);
        }
    }   

    //Print timing statistics
    printTimers();

    //Shutdown Camera
    if (!shutdownCamera()) {
        printf("Could not shut down camera\n");
    }

    return 0;
}

