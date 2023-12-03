#ifndef ANGLE_CALC
#define ANGLE_CALC

//Calibration variables
extern bool calibration;
extern std::vector<std::vector<cv::Vec3f>> calibrationCoordinates;
extern std::vector<cv::Point2f> dotPlacement;
extern std::vector<cv::Vec3f> foundDots;
extern std::vector<cv::Point2f> foundCoordinates;

//Angle tracking
//Angle tracking
extern double alphaCam;
extern double alphaCamLast;
extern double alphaDotCam;
extern double cameraAngle;
extern bool twoDotCheck;

double findMode(std::vector<double> array);
std::vector<cv::Point2f> calibrateDots();
bool errorCheckDotsAndPlace();
void calculateAngle();
void camUpdateLastValues();
void camDifferentiatePosition();

#endif