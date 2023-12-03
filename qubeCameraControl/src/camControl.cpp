#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/opencv.hpp>
#include "ueye.h"
#include "camControl.h"
#include "timing.h"
#include <vector>

#define EXPOSURE 5.0 //Main lab testing -> 5.0
#define BUFFERNUM 10
#define PIXELCLOCK 35 //MHz
#define HWGAIN 90

double framerate = 150.0; //Measured from the program

//Define Camera variables and settings
HIDS camID;
HWND camWindowPointer;
double actualFPS;
UINT pixelClockValue;
UINT pixelClockSetting = PIXELCLOCK;
int cam;

//int gainSetting = is_SetHardwareGain(camID, 90, 0, 0, 0);
double exposure; //tested at 20.0 -> need 12.5 or lower for 80Hz
int exposureSet;

//Camera size
int camWidth = 752; //Template program: 768, camera max: 752, my testing: 228
int camHeight = 480; //Template program: 576, camera max: 480, my testing 480.
int left = 220;
IS_RECT areaOfInterest;

//Memory variables
char* activeMemPointer = NULL;
int activeMemID = 0;
std::vector<char*> memPointerVector;
std::vector<int> memIdVector;
int activeMemBuffers;

//Event variables
IS_INIT_EVENT usedEvents[] = {
    {IS_SET_EVENT_FRAME, TRUE, FALSE} };
UINT enabledEvents[] = { IS_SET_EVENT_FRAME };
IS_WAIT_EVENTS waitFrame = {enabledEvents, sizeof(enabledEvents) / sizeof(int), FALSE, 2000, 0, 0 };

bool allocateMemory() {
    for (int i = 0; i < BUFFERNUM; i++) {
        int allocRet = is_AllocImageMem(camID, areaOfInterest.s32Width, areaOfInterest.s32Height, 8, &activeMemPointer, &activeMemID);
        if (allocRet != IS_SUCCESS) {
            printf("Image memory could not be allocated. Error %i\n", allocRet);
            break;
        }

        if (is_AddToSequence(camID, activeMemPointer, activeMemID) != IS_SUCCESS) {
            printf("Image memory could not be added to sequence.\n");
            if (is_FreeImageMem(camID, activeMemPointer, activeMemID) != IS_SUCCESS) {
                printf("Image memory could not be freed after sequence addition failure.\n");
            }
            break;
        }
        memPointerVector.push_back(activeMemPointer);
        memIdVector.push_back(activeMemID);
    }

    activeMemBuffers = (int) memIdVector.size();

    if (activeMemBuffers == BUFFERNUM) {
        return true;
    }
    else {
        return false;
    }
}

bool setupEvents() {
    bool success = true;

    do {
        if (is_Event(camID, IS_EVENT_CMD_INIT, usedEvents, sizeof(usedEvents)) != IS_SUCCESS) {
            success = false;
            printf("Event initialization failed.\n");
            break;
        };
        if (is_Event(camID, IS_EVENT_CMD_ENABLE, enabledEvents, sizeof(enabledEvents)) != IS_SUCCESS) {
            success = false;
            printf("Event enabling failed.\n");
            break;
        };

    } while (false); //Do once

    return success;
};

bool setupCamera() {
    camID = 0;
    camWindowPointer = NULL;

    areaOfInterest.s32Width = 200; //228 initial
    areaOfInterest.s32Height = 274; //300 initial
    areaOfInterest.s32X = 272;  //244 initial
    areaOfInterest.s32Y = 206; //180 initial    

    if (is_InitCamera(&camID, camWindowPointer) != IS_SUCCESS) {
        printf("Could not open camera. is_InitCamera failed.\n");
        return false;
    }
    if (is_AOI(camID, IS_AOI_IMAGE_SET_AOI, (void*)&areaOfInterest, sizeof(areaOfInterest)) != IS_SUCCESS) {
        printf("is_AOI failed.\n");
        return false;
    }
    if (is_SetColorMode(camID, IS_CM_MONO8) != IS_SUCCESS) {
        printf("is_SetColorMode failed.\n");
        return false;
    }
    if (is_SetDisplayMode(camID, IS_SET_DM_DIB) != IS_SUCCESS) {//Save picture to memory so its possible to work with it
        printf("is_SetDisplayMode failed.\n");
        return false;
    }
    if (is_PixelClock(camID, IS_PIXELCLOCK_CMD_SET, (void*)&pixelClockSetting, sizeof(pixelClockSetting)) != IS_SUCCESS) {
        printf("is_PixelClock set failed.\n");
        return false;
    }
    if (is_PixelClock(camID, IS_PIXELCLOCK_CMD_GET, (void*)&pixelClockValue, sizeof(pixelClockValue)) != IS_SUCCESS) {
        printf("is_PixelClock get failed.\n");
        return false;
    }
    if (is_SetExternalTrigger(camID, IS_SET_TRIGGER_OFF) != IS_SUCCESS) { //Free run not triggering
        printf("is_SetExternalTrigger failed.\n");
        return false;
    }
    if (is_SetGainBoost(camID, IS_SET_GAINBOOST_ON) != IS_SUCCESS) { //Free run not triggering
        printf("is_SetGainBoost failed.\n");
        return false;
    }
    if (is_SetHardwareGain(camID, HWGAIN, IS_IGNORE_PARAMETER, IS_IGNORE_PARAMETER, IS_IGNORE_PARAMETER) != IS_SUCCESS){ //Free run not triggering
        printf("is_SetHardwareGain failed.\n");
        return false;
    }  
    exposure = EXPOSURE; //tested at 20.0 -> need 12.5 or lower for 80Hz
    if (is_Exposure(camID, IS_EXPOSURE_CMD_SET_EXPOSURE, &exposure, sizeof(exposure)) != IS_SUCCESS) { //Free run not triggering
        printf("is_SetHardwareGain failed.\n");
        return false;
    }
    if (is_SetFrameRate(camID, framerate, &actualFPS) != IS_SUCCESS) {
        printf("is_SetFrameRate failed.\n");
        return false;
    }
    if (!allocateMemory()) {
        return false;
    }
    if (is_CaptureVideo(camID, IS_WAIT) != IS_SUCCESS) { //Wait for the first frame to return from function
        printf("Could not start capture.\n");
        return false;
    };
    if (!setupEvents()) { //Event setup after capture in example
        return false;
    }

    printf("Camera has been set up with pixel clock %i MHz and FPS %f\n", pixelClockValue, actualFPS);

    return true;
}

bool getFrame(int width, int height, cv::Mat& mat) {
    //Initialize variables
    void* memPointer_b;
    
    bool success = true;

    do {

        int ret = is_Event(camID, IS_EVENT_CMD_WAIT, &waitFrame, sizeof(waitFrame));

        if ((ret == IS_SUCCESS) && (waitFrame.nSignaled == IS_SET_EVENT_FRAME)) {

            //Get image memory by getting a pointer to the active memory
            if (is_GetImageMem(camID, &memPointer_b) != IS_SUCCESS) {
                printf("Image data could not be read from memory.\n");
                success = false;
                break;
            }

            memcpy(mat.ptr(), memPointer_b, mat.cols * mat.rows);

            //is_GetFramesPerSecond (camID, &actualFPS);            
            //printf("Got frame.  Running at %f\n", actualFPS);

            is_Event(camID, IS_EVENT_CMD_RESET, &enabledEvents[0], sizeof(UINT));
        }
        else {
            printf("Frame capture failure, likely timeout. Error %i\n", ret);
        }

        /*
        IS_NO_SUCCESS = -1
        IS_SUCCESS = 0
        IS_TIMED_OUT = 122
        IS_ACCESS_VIOLATION = 129
        IS_OUT_OF_MEMORY = 127
        IS_INVALID_PARAMETER = 125
         */

    } while (false); //Only once    

    return success;
}

bool freeSequenceMemories() {
    bool success = true;

    for (int i = 0; i < activeMemBuffers; i++) {
        if (is_FreeImageMem(camID, memPointerVector[i], memIdVector[i]) != IS_SUCCESS) {
            printf("Image data could not be freed\n");
            success = false;
        }
    }

    return success;
}

bool teardownEvents() {
    bool success = true;

    if (is_Event(camID, IS_EVENT_CMD_DISABLE, enabledEvents, sizeof(enabledEvents)) != IS_SUCCESS) {
        success = false;
    };

    if (is_Event(camID, IS_EVENT_CMD_EXIT, enabledEvents, sizeof(enabledEvents)) != IS_SUCCESS) {
        success = false;
    };

    return success;
}

bool shutdownCamera() {
    bool success = true;

    if (is_StopLiveVideo(camID, IS_FORCE_VIDEO_STOP) != IS_SUCCESS) {
        printf("Could not stop video\n");
        success = false;
    }

    if (!teardownEvents()) {
        printf("Could not turn of event handler\n");
        success = false;
    }

    if (is_ClearSequence(camID) != IS_SUCCESS) {
        printf("Could not clear sequence\n");
        success = false;
    }

    if (!freeSequenceMemories()) {
        printf("Could not free sequence memories\n");
        success = false;
    }

    if (is_ExitCamera(camID) != IS_SUCCESS) {
        printf("Could not exit camera\n");
        success = false;
    }

    return success;
}