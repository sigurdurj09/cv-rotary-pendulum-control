close all;
clear all;
clc;

logsA = ["a3min", "b6min", "c10min","d10min", "e10min"];
logsB = ["f7minUnplugged","g10minUnplugged"];
logsC = ["h8minQube","i10minQube"];
speed = 150;

alphaQubes = {};
alphaCamRaws = {};
alphaCamFiltereds = {};
alphaDotQubes = {};
alphaDotCamRaws = {};
alphaDotCamFiltereds = {};

for i = 1:length(logsA)

    log = logsA(i);
    dir = strcat(pwd, '\logs\data230706', log, '.log');
    data = readtable(dir, 'Delimiter', ';');
    
    %Data
    alphaQube = data.alphaQube(data.camControl==1);
    alphaCamRaw = data.alphaCam(data.camControl==1);
    alphaCamFiltered = data.alphaFiltered(data.camControl==1);
    alphaDotQube = data.alphaDotQube(data.camControl==1);
    alphaDotCamRaw = data.alphaDotCam(data.camControl==1);
    alphaDotCamFiltered = data.alphaDotFiltered(data.camControl==1);
    voltageQube = data.Kx(data.camControl==1);
    voltageCam = data.KxCam(data.camControl==1);
    
    %Add data to cells for later
    alphaQubes{end + 1} = alphaQube;
    alphaCamRaws{end + 1} = alphaCamRaw;
    alphaCamFiltereds{end + 1} = alphaCamFiltered;
    alphaDotQubes{end + 1} = alphaDotQube;
    alphaDotCamRaws{end + 1} = alphaDotCamRaw;
    alphaDotCamFiltereds{end + 1} = alphaDotCamFiltered;    
    
    %Sensor Quality
    twoDotPercBefore = sum(data.twoDotCheck(data.camControl==0))/length(data.twoDotCheck(data.camControl==0));
    twoDotPercAfter = sum(data.twoDotCheck(data.camControl==1&abs(data.alphaFiltered)<(pi/180*5)))/length(data.twoDotCheck(data.camControl==1&abs(data.alphaFiltered)<(pi/180*5)));
    twoDotPercOverall = sum(data.twoDotCheck(abs(data.alphaFiltered)<(pi/180*5)))/length(data.twoDotCheck(abs(data.alphaFiltered)<(pi/180*5))); 
    
    %Max deviation
    sampleMaxDeviation = max(abs(alphaQube))*180/pi; %Degrees
    
    %Variances
    varAlphaQube = var(alphaQube);
    varAlphaCamRaw = var(alphaCamRaw);
    varAlphaCamFiltered = var(alphaCamFiltered);
    varAlphaDotQube = var(alphaDotQube);
    varAlphaDotCamRaw = var(alphaDotCamRaw);
    varAlphaDotCamFiltered = var(alphaDotCamFiltered);
    varVoltageQube = var(voltageQube);
    varVoltageCam = var(voltageCam);    
    
    %Correlation coefficients
    corcoefAlphaQCamRaw = corrcoef(alphaQube, alphaCamRaw);
    corcoefAlphaQCamFiltered = corrcoef(alphaQube, alphaCamFiltered);
    corcoefAlphaDotQCamRaw = corrcoef(alphaDotQube, alphaDotCamRaw);
    corcoefAlphaDotQCamFiltered = corrcoef(alphaDotQube, alphaDotCamFiltered);
    corcoefVoltage = corrcoef(voltageQube, voltageCam);
 
    %Cross correlation
    [c1,lags1] = xcorr(alphaQube, alphaCamRaw, 5, 'normalized');
    [c2,lags2] = xcorr(alphaQube, alphaCamFiltered, 5, 'normalized');
    [c3,lags3] = xcorr(alphaDotQube, alphaDotCamRaw, 5, 'normalized');
    [c4,lags4] = xcorr(alphaDotQube, alphaDotCamFiltered, 5, 'normalized');    
        
    %Printing
    fprintf('     %s\n', log);
    fprintf('maxDeviation: %f\n', sampleMaxDeviation)
    fprintf('time: %f\n', length(alphaQube)'/speed);
    fprintf('varAlphaQube & varAlphaCamRaw & varAlphaCamFiltered & varAlphaDotQube & varAlphaDotCamRaw & varAlphaDotCamFiltered & varVoltageQube & varVoltageCam //\n');
    fprintf('%.6f & %.6f & %.6f & %.6f & %.6f & %.6f & %.6f & %.6f//\n', varAlphaQube, varAlphaCamRaw, varAlphaCamFiltered, varAlphaDotQube, varAlphaDotCamRaw, varAlphaDotCamFiltered, varVoltageQube, varVoltageCam);
    fprintf('corcoefAlphaQCamRaw & corcoefAlphaQCamFiltered & corcoefAlphaDotQCamRaw & corcoefAlphaDotQCamFiltered & corcoefVoltage //\n');
    fprintf('%.2f & %.2f & %.2f & %.2f & %.2f//\n', corcoefAlphaQCamRaw(2,1), corcoefAlphaQCamFiltered(2,1), corcoefAlphaDotQCamRaw(2,1), corcoefAlphaDotQCamFiltered(2,1), corcoefVoltage(2,1));
    fprintf('twoDotPercBefore & twoDotPercAfter & twoDotPercOverall //\n');
    fprintf('%.2f & %.2f & %.2f//\n', twoDotPercBefore, twoDotPercAfter, twoDotPercOverall);    
    
    %Figures
    figure(i);
    hold on
    plot((1:length(alphaQube))'/speed, alphaQube*180/pi);
    plot((1:length(alphaQube))'/speed, alphaCamRaw*180/pi);
    plot((1:length(alphaQube))'/speed, alphaCamFiltered*180/pi, 'k');
    h = zoom;
    set(h,'Motion','horizontal','Enable','on');
    legend("Alpha Qube", "Alpha Cam Raw", "Alpha Cam Filtered", 'Location', 'SouthWest', 'FontSize', 20);
    title(log, 'FontSize', 20);
    axis([0 3 -3.0 3.0])
    grid on
    xlabel('Time [s]', 'FontSize', 20);
    ylabel('$\alpha [^{\circ}]$', 'Interpreter','latex', 'FontSize', 20);
    hold off  
    
    figure(i+length(logsA));
    hold on
    plot((1:length(alphaDotQube))'/speed, alphaDotQube*180/pi);
    plot((1:length(alphaDotQube))'/speed, alphaDotCamRaw*180/pi);
    plot((1:length(alphaDotQube))'/speed, alphaDotCamFiltered*180/pi, 'k');
    h = zoom;
    set(h,'Motion','horizontal','Enable','on');
    legend("AlphaDot Qube", "AlphaDot Cam Raw", "AlphaDot Cam Filtered", 'Location', 'SouthWest', 'FontSize', 20);
    title(log, 'FontSize', 20);
    axis([0 3 -200.0 200.0])
    grid on
    xlabel('Time [s]', 'FontSize', 20);
    ylabel('$\dot{\alpha} [^{\circ}/s]$', 'Interpreter','latex', 'FontSize', 20);
    hold off  
    
    figure(i+2*length(logsA)); 
    stem(lags1, c1); hold on; grid on; title(log + ' - Cross-Correlation $\alpha_{Qube}$/$\alpha_{Cam}$', 'Interpreter','latex'); xlabel('Sample Lag');ylabel('Cross Correlation'); hold off;
    
    figure(i+3*length(logsA));
    stem(lags2, c2); hold on; grid on; title(log + ' - Cross-Correlation $\alpha_{Qube}$/$\alpha_{CamIIR}$', 'Interpreter','latex'); xlabel('Sample Lag');ylabel('Cross Correlation'); hold off;
    
    figure(i+4*length(logsA));
    stem(lags3, c3); hold on; grid on; title(log + ' - Cross-Correlation $\dot{\alpha}_{Qube}$/$\dot{\alpha}_{Cam}$', 'Interpreter','latex'); xlabel('Sample Lag');ylabel('Cross Correlation'); hold off;
    
    figure(i+5*length(logsA));
    stem(lags4, c4); hold on; grid on; title(log + ' - Cross-Correlation $\dot{\alpha}_{Qube}$/$\dot{\alpha}_{CamOF}$', 'Interpreter','latex'); xlabel('Sample Lag');ylabel('Cross Correlation'); hold off;
    
end
%%
for i = 1:length(logsB)

    log = logsB(i);
    dir = strcat(pwd, '\logs\data230706', log, '.log');
    data = readtable(dir, 'Delimiter', ';');
    
    %Data
    alphaCamRaw = data.alphaCam(data.camControl==1);
    alphaCamFiltered = data.alphaFiltered(data.camControl==1);
    alphaDotCamRaw = data.alphaDotCam(data.camControl==1);
    alphaDotCamFiltered = data.alphaDotFiltered(data.camControl==1);
    voltageCam = data.KxCam(data.camControl==1);
    
    %Add data to cells for later
    alphaQubes{end + 1} = zeros(5,1);
    alphaCamRaws{end + 1} = alphaCamRaw;
    alphaCamFiltereds{end + 1} = alphaCamFiltered;
    alphaDotQubes{end + 1} = zeros(5,1);
    alphaDotCamRaws{end + 1} = alphaDotCamRaw;
    alphaDotCamFiltereds{end + 1} = alphaDotCamFiltered; 
    
    %Sensor Quality
    twoDotPercBefore = sum(data.twoDotCheck(data.camControl==0))/length(data.twoDotCheck(data.camControl==0));
    twoDotPercAfter = sum(data.twoDotCheck(data.camControl==1&abs(data.alphaFiltered)<(pi/180*5)))/length(data.twoDotCheck(data.camControl==1&abs(data.alphaFiltered)<(pi/180*5)));
    twoDotPercOverall = sum(data.twoDotCheck(abs(data.alphaFiltered)<(pi/180*5)))/length(data.twoDotCheck(abs(data.alphaFiltered)<(pi/180*5)));
    
    %Max deviation
    sampleMaxDeviation = max(abs(alphaCamFiltered))*180/pi; %Degrees
    
    %Variances
    varAlphaCamRaw = var(alphaCamRaw);
    varAlphaCamFiltered = var(alphaCamFiltered);
    varAlphaDotCamRaw = var(alphaDotCamRaw);
    varAlphaDotCamFiltered = var(alphaDotCamFiltered);
    varVoltageCam = var(voltageCam);    
            
    %Printing
    fprintf('     %s\n', log);
    fprintf('maxDeviation: %f\n', sampleMaxDeviation)
    fprintf('time: %f\n', length(alphaCamRaw)'/speed);
    fprintf('varAlphaQube & varAlphaCamRaw & varAlphaCamFiltered & varAlphaDotQube & varAlphaDotCamRaw & varAlphaDotCamFiltered & varVoltageQube & varVoltageCam //\n');
    fprintf('%.6f & %.6f & %.6f & %.6f & %.6f & %.6f & %.6f & %.6f//\n', 0, varAlphaCamRaw, varAlphaCamFiltered, 0, varAlphaDotCamRaw, varAlphaDotCamFiltered, 0, varVoltageCam);
    fprintf('twoDotPercBefore & twoDotPercAfter & twoDotPercOverall //\n');
    fprintf('%.2f & %.2f & %.2f//\n', twoDotPercBefore, twoDotPercAfter, twoDotPercOverall);  
    
    %Figures
    figure(6*length(logsA) + i);
    hold on
    plot((1:length(alphaCamRaw))'/speed, alphaCamRaw*180/pi);
    plot((1:length(alphaCamRaw))'/speed, alphaCamFiltered*180/pi, 'k');
    h = zoom;
    set(h,'Motion','horizontal','Enable','on');
    legend("Alpha Cam Raw", "Alpha Cam Filtered", 'Location', 'SouthWest', 'FontSize', 20);
    title(log, 'FontSize', 20);
    axis([0 3 -3.0 3.0])
    grid on
    xlabel('Time [s]', 'FontSize', 20);
    ylabel('Alpha [°]', 'FontSize', 20);
    hold off  
    
    figure(6*length(logsA) + i + length(logsB));
    hold on
    plot((1:length(alphaDotCamRaw))'/speed, alphaDotCamRaw*180/pi);
    plot((1:length(alphaDotCamRaw))'/speed, alphaDotCamFiltered*180/pi, 'k');
    h = zoom;
    set(h,'Motion','horizontal','Enable','on');
    legend("AlphaDot Cam Raw", "AlphaDot Cam Filtered", 'Location', 'SouthWest', 'FontSize', 20);
    title(log, 'FontSize', 20);
    axis([0 3 -200.0 200.0])
    grid on
    xlabel('Time [s]', 'FontSize', 20);
    ylabel('AlphaDot [°/s]', 'FontSize', 20);
    hold off  
    
end
%%
for i = 1:length(logsC)

    log = logsC(i);
    dir = strcat(pwd, '\logs\data230706', log, '.log');
    data = readtable(dir, 'Delimiter', ';');
    
    %Data
    alphaQube = data.alphaQube(data.camControl==0);
    alphaCamRaw = data.alphaCam(data.camControl==0);
    alphaCamFiltered = data.alphaFiltered(data.camControl==0);
    alphaDotQube = data.alphaDotQube(data.camControl==0);
    alphaDotCamRaw = data.alphaDotCam(data.camControl==0);
    alphaDotCamFiltered = data.alphaDotFiltered(data.camControl==0);
    voltageQube = data.Kx(data.camControl==0);
    voltageCam = data.KxCam(data.camControl==0);
    
    %Add data to cells for later
    alphaQubes{end + 1} = alphaQube;
    alphaCamRaws{end + 1} = alphaCamRaw;
    alphaCamFiltereds{end + 1} = alphaCamFiltered;
    alphaDotQubes{end + 1} = alphaDotQube;
    alphaDotCamRaws{end + 1} = alphaDotCamRaw;
    alphaDotCamFiltereds{end + 1} = alphaDotCamFiltered;
    
    %Sensor Quality
    twoDotPercBefore = sum(data.twoDotCheck(data.camControl==0))/length(data.twoDotCheck(data.camControl==0));
    twoDotPercAfter = sum(data.twoDotCheck(data.camControl==1&abs(data.alphaFiltered)<(pi/180*5)))/length(data.twoDotCheck(data.camControl==1&abs(data.alphaFiltered)<(pi/180*5)));
    twoDotPercOverall = sum(data.twoDotCheck(abs(data.alphaFiltered)<(pi/180*5)))/length(data.twoDotCheck(abs(data.alphaFiltered)<(pi/180*5))); 
    
    %Max deviation
    sampleMaxDeviation = max(abs(alphaQube))*180/pi; %Degrees
    
    %Variances
    varAlphaQube = var(alphaQube);
    varAlphaCamRaw = var(alphaCamRaw);
    varAlphaCamFiltered = var(alphaCamFiltered);
    varAlphaDotQube = var(alphaDotQube);
    varAlphaDotCamRaw = var(alphaDotCamRaw);
    varAlphaDotCamFiltered = var(alphaDotCamFiltered);
    varVoltageQube = var(voltageQube);
    varVoltageCam = var(voltageCam);    
    
    %Correlation coefficients
    corcoefAlphaQCamRaw = corrcoef(alphaQube, alphaCamRaw);
    corcoefAlphaQCamFiltered = corrcoef(alphaQube, alphaCamFiltered);
    corcoefAlphaDotQCamRaw = corrcoef(alphaDotQube, alphaDotCamRaw);
    corcoefAlphaDotQCamFiltered = corrcoef(alphaDotQube, alphaDotCamFiltered);
    corcoefVoltage = corrcoef(voltageQube, voltageCam);
 
    %Cross correlation
    [c1,lags1] = xcorr(alphaQube, alphaCamRaw, 5, 'normalized');
    [c2,lags2] = xcorr(alphaQube, alphaCamFiltered, 5, 'normalized');
    [c3,lags3] = xcorr(alphaDotQube, alphaDotCamRaw, 5, 'normalized');
    [c4,lags4] = xcorr(alphaDotQube, alphaDotCamFiltered, 5, 'normalized');    
        
    %Printing
    fprintf('     %s\n', log);
    fprintf('maxDeviation: %f\n', sampleMaxDeviation)
    fprintf('time: %f\n', length(alphaQube)'/speed);
    fprintf('varAlphaQube & varAlphaCamRaw & varAlphaCamFiltered & varAlphaDotQube & varAlphaDotCamRaw & varAlphaDotCamFiltered & varVoltageQube & varVoltageCam //\n');
    fprintf('%.6f & %.6f & %.6f & %.6f & %.6f & %.6f & %.6f & %.6f//\n', varAlphaQube, varAlphaCamRaw, varAlphaCamFiltered, varAlphaDotQube, varAlphaDotCamRaw, varAlphaDotCamFiltered, varVoltageQube, varVoltageCam);
    fprintf('corcoefAlphaQCamRaw & corcoefAlphaQCamFiltered & corcoefAlphaDotQCamRaw & corcoefAlphaDotQCamFiltered & corcoefVoltage //\n');
    fprintf('%.2f & %.2f & %.2f & %.2f & %.2f//\n', corcoefAlphaQCamRaw(2,1), corcoefAlphaQCamFiltered(2,1), corcoefAlphaDotQCamRaw(2,1), corcoefAlphaDotQCamFiltered(2,1), corcoefVoltage(2,1));
    fprintf('twoDotPercBefore & twoDotPercAfter & twoDotPercOverall //\n');
    fprintf('%.2f & %.2f & %.2f//\n', twoDotPercBefore, twoDotPercAfter, twoDotPercOverall);    
    
    %Figures
    figure(6*length(logsA) + 2*length(logsB) + i);
    hold on
    plot((1:length(alphaQube))'/speed, alphaQube*180/pi);
    plot((1:length(alphaQube))'/speed, alphaCamRaw*180/pi);
    plot((1:length(alphaQube))'/speed, alphaCamFiltered*180/pi, 'k');
    h = zoom;
    set(h,'Motion','horizontal','Enable','on');
    legend("Alpha Qube", "Alpha Cam Raw", "Alpha Cam Filtered", 'Location', 'SouthWest', 'FontSize', 20);
    title(log, 'FontSize', 20);
    axis([0 3 -3.0 3.0])
    grid on
    xlabel('Time [s]', 'FontSize', 20);
    ylabel('$\alpha [^{\circ}]$', 'Interpreter','latex', 'FontSize', 20);
    hold off  
    
    figure(6*length(logsA) + 2*length(logsB) + i + length(logsC));
    hold on
    plot((1:length(alphaDotQube))'/speed, alphaDotQube*180/pi);
    plot((1:length(alphaDotQube))'/speed, alphaDotCamRaw*180/pi);
    plot((1:length(alphaDotQube))'/speed, alphaDotCamFiltered*180/pi, 'k');
    h = zoom;
    set(h,'Motion','horizontal','Enable','on');
    legend("AlphaDot Qube", "AlphaDot Cam Raw", "AlphaDot Cam Filtered", 'Location', 'SouthWest', 'FontSize', 20);
    title(log, 'FontSize', 20);
    axis([0 3 -200.0 200.0])
    grid on
    xlabel('Time [s]', 'FontSize', 20);
    ylabel('$\dot{\alpha} [^{\circ}/s]$', 'Interpreter','latex', 'FontSize', 20);
    hold off  
    
    figure(6*length(logsA) + 2*length(logsB) + i + 2*length(logsC));
    stem(lags1, c1); hold on; grid on; title(log + ' - Cross-Correlation $\alpha_{Qube}$/$\alpha_{Cam}$', 'Interpreter','latex'); xlabel('Sample Lag');ylabel('Cross Correlation'); hold off;
    
    figure(6*length(logsA) + 2*length(logsB) + i + 3*length(logsC));
    stem(lags2, c2); hold on; grid on; title(log + ' - Cross-Correlation $\alpha_{Qube}$/$\alpha_{CamIIR}$', 'Interpreter','latex'); xlabel('Sample Lag');ylabel('Cross Correlation'); hold off;
        
    figure(6*length(logsA) + 2*length(logsB) + i + 4*length(logsC));
    stem(lags3, c3); hold on; grid on; title(log + ' - Cross-Correlation $\dot{\alpha}_{Qube}$/$\dot{\alpha}_{Cam}$', 'Interpreter','latex'); xlabel('Sample Lag');ylabel('Cross Correlation'); hold off;
        
    figure(6*length(logsA) + 2*length(logsB) + i + 5*length(logsC));
    stem(lags4, c4); hold on; grid on; title(log + ' - Cross-Correlation $\dot{\alpha}_{Qube}$/$\dot{\alpha}_{CamOF}$', 'Interpreter','latex'); xlabel('Sample Lag');ylabel('Cross Correlation'); hold off;
       
end

%%

logs = [logsA logsB logsC];
normalityMatHAd = zeros(length(logs), 6);
normalityMatPAd = zeros(length(logs), 6);
normalityMatHJb = zeros(length(logs), 6);
normalityMatPJb = zeros(length(logs), 6);
normalityMatHLi = zeros(length(logs), 6);
normalityMatPLi = zeros(length(logs), 6);

for i = 1:length(logs)
    [h1,p1] = adtest(alphaQubes{i});
    [h2,p2] = adtest(alphaCamRaws{i});
    [h3,p3] = adtest(alphaCamFiltereds{i});
    [h4,p4] = adtest(alphaDotQubes{i});
    [h5,p5] = adtest(alphaDotCamRaws{i});
    [h6,p6] = adtest(alphaDotCamFiltereds{i});  
    normalityMatHAd(i,:) = [h1, h2, h3, h4, h5, h6];
    normalityMatPAd(i,:) = [p1, p2, p3, p4, p5, p6];   
    
    [h1,p1] = jbtest(alphaQubes{i});
    [h2,p2] = jbtest(alphaCamRaws{i});
    [h3,p3] = jbtest(alphaCamFiltereds{i});
    [h4,p4] = jbtest(alphaDotQubes{i});
    [h5,p5] = jbtest(alphaDotCamRaws{i});
    [h6,p6] = jbtest(alphaDotCamFiltereds{i});  
    normalityMatHJb(i,:) = [h1, h2, h3, h4, h5, h6];
    normalityMatPJb(i,:) = [p1, p2, p3, p4, p5, p6];  
    
    [h1,p1] = lillietest(alphaQubes{i});
    [h2,p2] = lillietest(alphaCamRaws{i});
    [h3,p3] = lillietest(alphaCamFiltereds{i});
    [h4,p4] = lillietest(alphaDotQubes{i});
    [h5,p5] = lillietest(alphaDotCamRaws{i});
    [h6,p6] = lillietest(alphaDotCamFiltereds{i});  
    normalityMatHLi(i,:) = [h1, h2, h3, h4, h5, h6];
    normalityMatPLi(i,:) = [p1, p2, p3, p4, p5, p6];      
    
end

%close all;

figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 1)
histogram(alphaQubes{5})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 2)
histogram(alphaCamFiltereds{5})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 3)
histogram(alphaDotQubes{5})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 4)
histogram(alphaDotCamFiltereds{5})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 5)
histogram(alphaQubes{9})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 6)
histogram(alphaCamFiltereds{9})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 7)
histogram(alphaDotQubes{9})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 8)
histogram(alphaDotCamFiltereds{9})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 9)
probplot(alphaQubes{5})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 10)
probplot(alphaCamFiltereds{5})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 11)
probplot(alphaDotQubes{5})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 12)
probplot(alphaDotCamFiltereds{5})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 13)
probplot(alphaQubes{9})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 14)
probplot(alphaCamFiltereds{9})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 15)
probplot(alphaDotQubes{9})
figure(6*length(logsA) + 2*length(logsB) + 6*length(logsC) + 16)
probplot(alphaDotCamFiltereds{9})

%% F test

[h1,p1,ci1,stats1] = vartest2(alphaCamFiltereds{5}, alphaCamFiltereds{7});
[h2,p2,ci2,stats2] = vartest2(alphaCamFiltereds{5}, alphaCamFiltereds{9});
[h3,p3,ci3,stats3] = vartest2(alphaDotCamFiltereds{5}, alphaDotCamFiltereds{7});
[h4,p4,ci4,stats4] = vartest2(alphaDotCamFiltereds{5}, alphaDotCamFiltereds{9});

fHs = [h1 h2 h3 h4];
fPs = [p1 p2 p3 p4];
fci1 = [ci1(1) ci2(1) ci3(1) ci4(1)];
fci2 = [ci1(2) ci2(2) ci3(2) ci4(2)];
fFs = [stats1.fstat stats2.fstat stats3.fstat stats4.fstat];
fdf1 = [stats1.df1 stats2.df1 stats3.df1 stats4.df1];
fdf2 = [stats1.df2 stats2.df2 stats3.df2 stats4.df2];

%% Levenes Test
[p5,stats5] = vartestn([alphaCamFiltereds{5};alphaCamFiltereds{7}], [zeros(length(alphaCamFiltereds{5}),1);ones(length(alphaCamFiltereds{7}),1)],'TestType','LeveneAbsolute');
[p6,stats6] = vartestn([alphaCamFiltereds{5};alphaCamFiltereds{9}], [zeros(length(alphaCamFiltereds{5}),1);ones(length(alphaCamFiltereds{9}),1)],'TestType','LeveneAbsolute');
[p7,stats7] = vartestn([alphaDotCamFiltereds{5};alphaDotCamFiltereds{7}], [zeros(length(alphaDotCamFiltereds{5}),1);ones(length(alphaDotCamFiltereds{7}),1)],'TestType','LeveneAbsolute');
[p8,stats8] = vartestn([alphaDotCamFiltereds{5};alphaDotCamFiltereds{9}], [zeros(length(alphaDotCamFiltereds{5}),1);ones(length(alphaDotCamFiltereds{9}),1)],'TestType','LeveneAbsolute');

LPs1 = [p5 p6 p7 p8];

%% NonParametric Levenes Test
[p9,stats9] = vartestn(tiedrank([alphaCamFiltereds{5};alphaCamFiltereds{7}]), [zeros(length(alphaCamFiltereds{5}),1);ones(length(alphaCamFiltereds{7}),1)],'TestType','LeveneAbsolute');
[p10,stats10] = vartestn(tiedrank([alphaCamFiltereds{5};alphaCamFiltereds{9}]), [zeros(length(alphaCamFiltereds{5}),1);ones(length(alphaCamFiltereds{9}),1)],'TestType','LeveneAbsolute');
[p11,stats11] = vartestn(tiedrank([alphaDotCamFiltereds{5};alphaDotCamFiltereds{7}]), [zeros(length(alphaDotCamFiltereds{5}),1);ones(length(alphaDotCamFiltereds{7}),1)],'TestType','LeveneAbsolute');
[p12,stats12] = vartestn(tiedrank([alphaDotCamFiltereds{5};alphaDotCamFiltereds{9}]), [zeros(length(alphaDotCamFiltereds{5}),1);ones(length(alphaDotCamFiltereds{9}),1)],'TestType','LeveneAbsolute');

LPs2 = [p9 p10 p11 p12];

