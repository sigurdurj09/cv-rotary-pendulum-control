#include "logging.h"

//Log file setup
std::string datafile("./data.log");
std::ofstream file_out;
time_t systemTime;
char buf[26];

void startupLog() {
	//Log file setup
	auto systemTime = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
	file_out.open(datafile, std::ios_base::app);
	file_out << "Starting new run: ";	
	file_out << " K= " << std::to_string(K[0][0]) << ", " << std::to_string(K[0][1]) << ", " << std::to_string(K[0][2]) << ", " << std::to_string(K[0][3]) << ", " << std::to_string(K[0][4]) << " - ";
	ctime_s(buf, sizeof(buf), &systemTime);
	file_out << buf;
	file_out << "Qube Frequency: " << std::to_string(frequency) << ", Cam framerate: " << std::to_string(framerate) << std::endl;
	file_out << "AlphaDotTransformVector: " << std::to_string(alphaDotTransfromVector[0]) << ", " << std::to_string(alphaDotTransfromVector[1]) << ", " << std::to_string(alphaDotTransfromVector[2]) << ", " << std::to_string(alphaDotTransfromVector[3]) << ", " << std::to_string(alphaDotTransfromVector[4]) << std::endl;
	file_out << "alphaQube;alphaDotQube;thetaQube;thetaDotQube;z;thetaTarget;p1x;p1y;p2x;p2y;alphaCam;alphaDotCam;cameraAngle;twoDotCheck;Kx;KxCam;alphaFiltered;alphaDotFiltered;alphaFilteredGated;alphaDotFilteredGated;alphaDotKalman;alphaDotKKalman;camControl;systemTime" << std::endl;
	file_out.close();
}

void measurementLog() {
	systemTime = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
	file_out.open(datafile, std::ios_base::app);
	file_out << std::to_string(alphaQube) << ";";
	file_out << std::to_string(alphaDotQube) << ";";
	file_out << std::to_string(thetaQube) << ";";
	file_out << std::to_string(thetaDotQube) << ";";
	file_out << std::to_string(thetaIntegral) << ";";
	file_out << std::to_string(thetaTarget) << ";";
	file_out << std::to_string(dotPlacement[0].x) << ";";
	file_out << std::to_string(dotPlacement[0].y) << ";";
	file_out << std::to_string(dotPlacement[1].x) << ";";
	file_out << std::to_string(dotPlacement[1].y) << ";";
	file_out << std::to_string(alphaCam) << ";";
	file_out << std::to_string(alphaDotCam) << ";";
	file_out << std::to_string(cameraAngle) << ";";
	file_out << std::to_string(twoDotCheck) << ";";
	file_out << std::to_string(Kx) << ";";
	file_out << std::to_string(KxCam) << ";";
	file_out << std::to_string(alphaFiltered) << ";";
	file_out << std::to_string(alphaDotFiltered) << ";";
	file_out << std::to_string(alphaFilteredGated) << ";";
	file_out << std::to_string(alphaDotFilteredGated) << ";";
	file_out << std::to_string(alphaDotKalman) << ";";
	file_out << std::to_string(alphaDotKKalman) << ";";
	file_out << std::to_string(camControl) << ";";
	ctime_s(buf, sizeof(buf), &systemTime);
	file_out << buf;
	file_out.close();
}