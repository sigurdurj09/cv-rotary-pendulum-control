all: cameraCalibration

cameraCalibration: cameraCalibration.o angleCalculation.o timing.o imageManipulation.o frameCapture.o
	g++ -o cameraCalibration cameraCalibration.o angleCalculation.o timing.o imageManipulation.o frameCapture.o -I"C:\opencv\build\include" -I"C:\Program Files\IDS\uEye\develop\include" -I".\include" -L "C:\opencv\build\lib" -L "C:\Program Files\IDS\uEye\develop\lib" -lopencv_core455 -lopencv_imgproc455 -lopencv_imgcodecs455 -lopencv_highgui455 -lopencv_videoio455 -lueye_api_64

cameraCalibration.o: src/cameraCalibration.cpp
	g++ -o cameraCalibration.o -c src/cameraCalibration.cpp -I"C:\opencv\build\include" -I"C:\Program Files\IDS\uEye\develop\include" -I".\include" -L "C:\opencv\build\lib" -L "C:\Program Files\IDS\uEye\develop\lib" -lopencv_core455 -lopencv_imgproc455 -lopencv_imgcodecs455 -lopencv_highgui455 -lopencv_videoio455 -lueye_api_64

angleCalculation.o: src/angleCalculation.cpp
	g++ -o angleCalculation.o -c src/angleCalculation.cpp -I"C:\opencv\build\include" -I".\include" -L "C:\opencv\build\lib" -lopencv_core455 -lopencv_imgproc455 -lopencv_imgcodecs455 -lopencv_highgui455 -lopencv_videoio455

timing.o: src/timing.cpp
	g++ -o timing.o -c src/timing.cpp -I".\include"

imageManipulation.o: src/imageManipulation.cpp
	g++ -o imageManipulation.o -c src/imageManipulation.cpp -I"C:\opencv\build\include" -I".\include" -L "C:\opencv\build\lib" -lopencv_core455 -lopencv_imgproc455 -lopencv_imgcodecs455 -lopencv_highgui455 -lopencv_videoio455

frameCapture.o: src/frameCapture.cpp
	g++ -o frameCapture.o -c src/frameCapture.cpp -I"C:\opencv\build\include" -I"C:\Program Files\IDS\uEye\develop\include" -I".\include" -L "C:\opencv\build\lib" -L "C:\Program Files\IDS\uEye\develop\lib" -lopencv_core455 -lopencv_imgproc455 -lopencv_imgcodecs455 -lopencv_highgui455 -lopencv_videoio455 -lueye_api_64