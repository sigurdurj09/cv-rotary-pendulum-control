close all;
clear all;
clc;

logs = ["standard","slow","fast","veryfast", "lowGain", "highGain", "veryfastLowGain"];
speed = [100, 80, 125, 150, 100, 100, 150];

for i = 1:length(logs)

    log = logs(i);
    dir = strcat(pwd, '\logs\data230705', log, '.log');
    data = readtable(dir, 'Delimiter', ';');
    
    sampleAlphaQubeVar = var(data.alphaQube(data.camControl==1));
    sampleAlphaCamVar = var(data.alphaFiltered(data.camControl==1));
    sampleAlphaDotCamVar = var(data.alphaDotKalman(data.camControl==1));
    fprintf('%s - alphaQubevar: %f, alphaCamvar: %f, alphaDotCamvar: %f\n', log, sampleAlphaQubeVar, sampleAlphaCamVar, sampleAlphaDotCamVar);
    sampleMaxDeviation = max(abs(data.alphaQube(data.camControl==1)));
    fprintf('%s - maxDeviation: %f\n', log, sampleMaxDeviation*180/pi)
    
    figure(i);
    hold on
    plot((1:height(data))'/speed(i), data.alphaQube*180/pi);
    plot((1:height(data))'/speed(i), data.alphaFiltered*180/pi);
    plot((1:height(data))'/speed(i), data.camControl, 'LineWidth', 3);
    h = zoom;
    set(h,'Motion','horizontal','Enable','on');
    legend("Alpha Qube", "Alpha Cam Filtered", "Cam control", 'Location', 'SouthWest');
    title(log);
    axis([0 height(data)/speed(i) -10.0 10.0])
    grid on
    xlabel('Time [s]');
    ylabel('Alpha [°]');
    yyaxis right
    ylabel('Camera signal control on [Boolean]');
    yticks([])
    hold off  
    
end

