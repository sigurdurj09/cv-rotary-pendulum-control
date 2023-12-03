# Using Computer Vision for Control of a Rotary Inverted Pendulum System - Code Repository
A repo of thesis material for Sigurður Jakobsson

## CAD
Autodesk Inventor files for device covers and thesis diagrams.

## cameraCalibration
Code that is similar to the camera portion of the main control code.  Can be used to train the camera on the pendulum while it is controlled by a different application.
This is useful for tuning camera parameters that can then be copied to the main code.

## matlabAnalysis
Contains various materials used for controller gain calculations, signal analysis, and model analysis.  The most important and useful scripts are mentioned in the thesis.
The testing scripts for chapters 5.2 and 5.3 are labeled as such.  A few test scripts that did not make the thesis are included in case they may be of interest to someone.

## qubeCameraControl
The main application code.  Consult the thesis for a detailed description of functionality and Appendix C for setup help.

## UML
Contains UML code used to generate diagrams in the thesis.