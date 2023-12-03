#define _USE_MATH_DEFINES
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/opencv.hpp>
#include <cmath>
#include "imageManipulation.h"
#include "angleCalculation.h"
#include <string>

//Image macros
#define ALPHA 8.0 //Contrast // Blinds -> 10.0 / Daylight -> 8.0 / Main lab testing -> 8.0
#define BETA -100 //Brightness / Main lab testing -> -100
#define BRIGHTTHRESHOLD 30  //Blinds -> 22 / Daylight -> 180 / Main lab testing -> 30
#define BLACKTHRESHOLD 60 //Threshold for black mask //Blinds -> 50 / Daylight -> 200 / Main lab testing -> 60
//Hough Macros
#define HOUGHMINRAD 4 // Main lab testing -> 4
#define HOUGHMAXRAD 7 // Main lab testing -> 7

char buf[26];

//Sorting operator. Compare x position
bool pointSort(const cv::Vec3f c1, const cv::Vec3f c2) {return c1[0] < c2[0];}

//Takes a frame pointer and applies Haugh processing for circles to it.  Return circles for further analysis
std::vector<cv::Vec3f> placeCircles(cv::Mat * frame, bool draw, int parm1, int parm2, std::string source) {
    std::vector<cv::Vec3f> circles;
    cv::HoughCircles(*frame, circles, cv::HOUGH_GRADIENT, 1, frame->rows/5, parm1, parm2, HOUGHMINRAD, HOUGHMAXRAD);

    //Convert color back to BGR to be able to paint on frame after analysis
    cv::cvtColor(*frame, *frame, cv::COLOR_GRAY2BGR);

    //Draw circles with center
    for (size_t i = 0; i < circles.size(); i++) {
        cv::Vec3i c = circles[i];
        cv::Point center = cv::Point(c[0], c[1]);
        int radius = c[2];
        if(draw) {
            cv::circle(*frame, center, 1, cv::Scalar(0,0,255), 1, cv::LINE_AA);          
            cv::circle(*frame, center, radius, cv::Scalar(255,0,255), 1, cv::LINE_AA);
        }
    }

    //Return points sorted by x coordinate
    std::sort(circles.begin(), circles.end(), pointSort);

    //Once calibrated log the data.
    if (!calibration && draw) {
        auto time = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
	    file_out.open(datafile, std::ios_base::app);

        file_out << source << ";";

        for (size_t i = 0; i < 5; i++) {
            if (i < circles.size()) {
                cv::Vec3i c = circles[i];
                file_out << std::to_string(c[0]) << ";";
                file_out << std::to_string(c[1]) << ";";
                file_out << std::to_string(c[2]) << ";";  
            } else {
                file_out << std::to_string(0.0) << ";";
                file_out << std::to_string(0.0) << ";";
                file_out << std::to_string(0.0) << ";"; 
            }            
        }
    
        ctime_s(buf, sizeof(buf), &time);
        file_out << buf;
        file_out.close();
    }

    //Convert color back to BGR to be able to paint on frame after analysis
    //cv::cvtColor(*frame, *frame, cv::COLOR_GRAY2BGR);

    return circles;
}

//Takes a frame pointer and updates contrast
void updateContrast(cv::Mat * frame) {
    //Change contrast and brightness
    for (int y = 0; y < frame->rows; y++) {
        for (int x = 0; x < frame->cols; x++) {
            frame->at<uchar>(y,x) = cv::saturate_cast<uchar>(ALPHA*frame->at<uchar>(y,x) + BETA);
        }
    }
}

cv::Mat blackFiltering(cv::Mat * frame) {
    //Takes a frame pointer and filters on black to try to find dots.
    cv::Mat mask;
    cv::inRange(*frame, cv::Scalar(0), cv::Scalar(BLACKTHRESHOLD), mask);
    return mask;
}

void lightMasking(cv::Mat * frame) {
    //Filter out all above half intensity
    cv::Mat mask;
    cv::threshold(*frame, *frame, BRIGHTTHRESHOLD, 255, cv::THRESH_TRUNC);
}

void blurFrame(cv::Mat * frame, int aperature) {
    //Aperature size must be 3, 5, or 7
    cv::medianBlur(*frame, *frame, aperature);
}
