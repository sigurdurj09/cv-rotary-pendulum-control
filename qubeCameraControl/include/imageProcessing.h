#ifndef IMAGE_MAN
#define IMAGE_MAN

bool pointSort(const cv::Vec3f c1, const cv::Vec3f c2);
std::vector<cv::Vec3f> placeCircles(cv::Mat* frame, bool draw, int parm1, int parm2);
void updateContrast(cv::Mat* frame);
cv::Mat blackFiltering(cv::Mat* frame);
void lightMasking(cv::Mat* frame);
void blurFrame(cv::Mat* frame, int aperature);

#endif