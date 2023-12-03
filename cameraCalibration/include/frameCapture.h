#ifndef FRAME_CAPTURE
#define FRAME_CAPTURE

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

bool setupCamera();
bool getFrame(int width, int height, cv::Mat& mat);
bool shutdownCamera();

#endif