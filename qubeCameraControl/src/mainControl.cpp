#include <iostream>
#include <fstream>
#include <hil.h>
#include <quanser_runtime.h>
#include <quanser_types.h>
#include <quanser_arguments.h>
#include <quanser_errors.h>
#include <stdio.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include "quanser_signal.h"
#include "quanser_messages.h"
#include "quanser_thread.h"
#include <cmath>
#include <chrono>
#include <thread>
#include <string>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/opencv.hpp>
#include "ueye.h"
#include "angleCalculation.h"
#include "timing.h"
#include "imageProcessing.h"
#include "camControl.h"
#include "qubeControl.h"
#include <windows.h>
#include <process.h>
#include <conio.h>
#include "logging.h"
#include "signalProcessing.h"

//Board variable for gracefull shutdown.
qsigaction_t action;
t_card board;
t_error result;
int stop = 0;
t_boolean enable = 1;

//Channel setup
const t_uint32 analogChannels[] = { 0 };
const t_uint32 encoderChannels[] = { 0, 1 };
const t_uint32 digitalChannels[] = { 0 };
t_int32   encoderCounts[ARRAY_LENGTH(encoderChannels)];
const t_int32 encoderChannelStart[] = { 0, 0 };
const t_int32 analogChannelCount = ARRAY_LENGTH(analogChannels);
const t_int32 encoderChannelCount = ARRAY_LENGTH(encoderChannels);
const t_int32 digitalChannelCount = ARRAY_LENGTH(digitalChannels);

//Task setup
int keyPress;

//Thread setup
unsigned int __stdcall CameraThread(void* data);
#define THREADCOUNT 1
HANDLE  cameraThreadHandle;
t_uint32 cameraThreadId;

int main() {

    std::cout << "\nStarting control loop" << std::endl;

    //Camera setup
    if (!setupCamera()) {
        stop = 1;
        printf("Could not set up camera\n");
    }

    //Log file setup
    startupLog();

    //Timing setup
    setupTimers();

    //Qube setup
    setupSignalHandler(action);
    result = setupBoard(&board);

    if (result == 0) {
        std::cout << "Opened the Qube Servo 2 with frequency " << std::to_string(frequency) << " Hz" << std::endl;

        //Increase our thread priority so we get better sample time performance
        //Create a task to read the encoder. The task will be used to time the control loop
        result = taskPreparation(&board);

        if (result == 0) //Initial value Setup
        {
            getEncoderValuesSimple(&board);
            calculateRadians();

            for (t_uint32 channel = 0; channel < ARRAY_LENGTH(encoderChannels); channel++)
                printf("Encoder %d status: %7d   ", encoderChannels[channel], encoderCounts[channel]);
            printf("\n");
        }
        else
        {
            std::cout << "Couldn't create task" << std::endl;
        }

        std::cout << "\nStarting loop" << std::endl;        
        
        result = hil_task_start(task, HARDWARE_CLOCK_0, frequency, samples);
        samples_read = hil_task_read_encoder(task, 1, &encoderCounts[0]); //To get loop started  
        cameraThreadHandle = (HANDLE)_beginthreadex(NULL, 0, &CameraThread, NULL, 0, &cameraThreadId);
        if (!SetThreadPriority(cameraThreadHandle, THREAD_PRIORITY_HIGHEST)) {
            printf("Could not boost camera thread priority");
        }
        
        while (stop == 0 && result == 0 && samples_read >= 0) {
            timerMap["QubeLoop"].start();
            //Update last count
            updateLastValues();
            //Extract count, read new values
            getEncoderValuesTask();
            //Calculate angle
            calculateRadians();
            //Differentiate for velocity
            differentiatePosition();
            //Calculate integral
            integrateError();
            if (!calibratedDots) {
                updateVoltage(&board); //Move voltage update to camera once calibrated to decrease delay.
            }
            timerMap["QubeSampleToCamVoltageSet"].start();

            if (samples_read == 0) { //Notify if a round of samples from Qube fails
                printf("Qube reading failed\n");
            }
                        
            //Calibration trigger and controls
            if (_kbhit()) {
                keyPress = _getch();
                if (keyPress == '1' && !calibratedDots) {
                    printf("Getting calibration dots\n");
                    getCalibrationDots = true;
                }
                if (keyPress == '2' && !calibratedDots) {
                    getCalibrationDots = false;
                    calibrateDots = true;
                }
                if (keyPress == 's' && !camControl) {
                    camControl = true;
                    printf("Starting Cam Control\n");
                }
                if (keyPress == 27) { //Stop program on escape
                    stop = 1;
                }                
            }
            timerMap["QubeLoop"].stop();
        }
        
        hil_task_stop(task); //Stop task after while loop
        hil_task_delete(task);
        printf("Qube thread shutting down.\n");

        //Clean up thread
        WaitForSingleObject(cameraThreadHandle, INFINITE);
        if (!SetThreadPriority(cameraThreadHandle, THREAD_PRIORITY_NORMAL)) {
            printf("Could not reset camera thread priority");
        }
        CloseHandle(cameraThreadHandle);

        printFinalState();
    }
    else {
        std::cout << "Couldn't open Qube Servo 2" << std::endl;
    }
    //Close the board
    result = shutdownBoard(&board);
    std::cout << "Shutting down" << std::endl;

    //Print timing statistics
    printTimers();
    //Shutdown Camera
    if (!shutdownCamera()) {
        stop = 1;
        printf("Could not shut down camera\n");
    }

    return 0;
}

unsigned int __stdcall CameraThread(void* data) {

    while (stop == 0) {
        timerMap["CameraLoop"].start();
        // Get a video frame     
        timerMap["GetFrame"].start();
        cv::Mat frame(areaOfInterest.s32Height, areaOfInterest.s32Width, CV_8UC1);
        if (!getFrame(areaOfInterest.s32Width, areaOfInterest.s32Height, frame)) {
            break;
        }
        timerMap["GetFrame"].stop();
        
        timerMap["ImageManipulation"].start();
        cv::rotate(frame, frame, cv::ROTATE_90_COUNTERCLOCKWISE);

        lightMasking(&frame);
        updateContrast(&frame);
        blurFrame(&frame, 5); //See if needed
        frame = blackFiltering(&frame);
        blurFrame(&frame, 3);

        foundDots = placeCircles(&frame, true, 20, 5);
        //foundDots = placeCircles(&frame, true, 20, 8);

        timerMap["ImageManipulation"].stop();
        
        if (getCalibrationDots) {
            calibrationCoordinates.push_back(foundDots);
        }
        if (calibratedDots) {
            timerMap["AngleCalculation"].start();
            //Update AlphaCamLast
            camUpdateLastValues();
            
            if (errorCheckDotsAndPlace()) {
                calculateAngle();
            }

            //Calculate AlphaDotCam
            camDifferentiatePosition();

            //Signal processing
            signalProcessingChain();

            //Update voltage
            updateVoltage(&board);
            timerMap["QubeSampleToCamVoltageSet"].stop();

            //Logging
            measurementLog();       

            //Paint colored circles on mask and angle text
            //Comment out for operation
            cv::circle(frame, dotPlacement[0], 1, cv::Scalar(0, 100, 100), 1, cv::LINE_AA);
            //cv::circle(frame, dotPlacement[0], 10, cv::Scalar(255, 0, 255), 3, cv::LINE_AA);
            cv::circle(frame, dotPlacement[1], 1, cv::Scalar(0, 100, 100), 1, cv::LINE_AA);
            //cv::circle(frame, dotPlacement[1], 10, cv::Scalar(255, 0, 255), 3, cv::LINE_AA);
            //cv::putText(frame, "Angle : " + std::to_string(cameraAngle / M_PI * 180), cv::Point(10, 25), cv::FONT_HERSHEY_SIMPLEX, 1, cv::Scalar(0, 0, 255), 3);
            timerMap["AngleCalculation"].stop();
        } 
               
        //Show frames
        timerMap["ImagePresentation"].start();
        //cv::imshow("Greyscale test", frame); //Comment out for operation
        //cv::waitKey(1); //Comment out for operation 
        timerMap["ImagePresentation"].stop();
        timerMap["CameraLoop"].stop();

        if (calibrateDots && !calibratedDots) {
            dotPlacement = dotCalibration();
            calibratedDots = true;
            printf("Dots Calibrated\n");
        }
    }
    cv::destroyAllWindows();
    printf("Camera Thread Shutting down\n");
    return 0;
}
