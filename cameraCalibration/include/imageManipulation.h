#ifndef IMAGE_MAN
#define IMAGE_MAN

#include <iostream>
#include <fstream>

extern std::string datafile;
extern std::ofstream file_out;

bool pointSort(const cv::Vec3f c1, const cv::Vec3f c2);
std::vector<cv::Vec3f> placeCircles(cv::Mat * frame, bool draw, int parm1, int parm2, std::string source);
void updateContrast(cv::Mat * frame);
cv::Mat blackFiltering(cv::Mat * frame);
void lightMasking(cv::Mat * frame);
void blurFrame(cv::Mat * frame, int aperature);

#endif