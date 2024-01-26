close all;
clear all;
clc;

log = 'vData230706stationaryAngle3.log';
dir = strcat(pwd, '\logs\varianceLogs\', log);
dataStationary = readtable(dir, 'Delimiter', ';');

log = 'vData230706liveAngle3.log';
dir = strcat(pwd, '\logs\varianceLogs\', log);
dataLive = readtable(dir, 'Delimiter', ';');

R = var(dataStationary.alphaDotCam);
totalVar = var(dataLive.alphaDotCam);

