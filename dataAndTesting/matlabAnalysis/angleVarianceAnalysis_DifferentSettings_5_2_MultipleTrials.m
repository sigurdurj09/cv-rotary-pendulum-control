close all;
clear all;
clc;

logs = ["standardGain","lowGain"];

meanAlphaQubeVars = {};
sDevAlphaQubeVars = {};
ns = {};

for i = 1:length(logs)
    
    n = 0;
    trialAlphaQubeVariances = [];
    trialAlphaMaxDeviations = [];
    trialAlphaMaxDeviation = 0;
    
    for serialNumber = 1:15
        log = logs(i);
        logName = strcat('20240121-', log, '-150FPS-30secSession-', string(serialNumber));
        dir = strcat(pwd, '\AdditionalTestLogs\', logName, '.log');
        data = readtable(dir, 'Delimiter', ';');

        sampleAlphaQubeVar = var(data.alphaQube(data.camControl==1));
        sampleAlphaCamVar = var(data.alphaFiltered(data.camControl==1));
        sampleAlphaDotCamVar = var(data.alphaDotKalman(data.camControl==1));
        fprintf('%s - alphaQubevar: %f, alphaCamvar: %f, alphaDotCamvar: %f\n', logName, sampleAlphaQubeVar, sampleAlphaCamVar, sampleAlphaDotCamVar);
        sampleMaxDeviation = max(abs(data.alphaQube(data.camControl==1)));
        fprintf('%s - maxDeviation: %f\n', logName, sampleMaxDeviation*180/pi)

        if sampleMaxDeviation*180/pi < 12
            n=n+1;
            trialAlphaQubeVariances(end+1) = sampleAlphaQubeVar;
            trialAlphaMaxDeviations(end+1) = sampleMaxDeviation*180/pi;
            if trialAlphaMaxDeviation < sampleMaxDeviation*180/pi
                trialAlphaMaxDeviation = sampleMaxDeviation*180/pi;
            end
        end        
    end
    
    meanAlphaQubeVars{end+1} = mean(trialAlphaQubeVariances)
    sDevAlphaQubeVars{end+1} = std(trialAlphaQubeVariances)
    meanAlphaQubeMaxDev = mean(trialAlphaMaxDeviations)
    trialAlphaMaxDeviation
    ns{end+1} = n
    
    tval = tinv(0.975, n-1)
    lower95 = meanAlphaQubeVars{end} - tval*sDevAlphaQubeVars{end}/sqrt(n)
    upper95 = meanAlphaQubeVars{end} + tval*sDevAlphaQubeVars{end}/sqrt(n)
    
    fprintf('Test Description & Mean Variance $alpha_{text{QUBE}}$ & Standard Deviation $alpha_{text{QUBE}}$ & Trials & 95 Confidence Interval & Mean max. deviation of sessions & Absolute max. deviation of sessions  \n')
    fprintf('%s & %f & %f & %d & $begin{bmatrix} %f, %f end{bmatrix}$ & %f & %f \n', logName, meanAlphaQubeVars{end}, sDevAlphaQubeVars{end}, ns{end}, lower95, upper95, meanAlphaQubeMaxDev, trialAlphaMaxDeviation);
    
end

n = 0;
trialAlphaQubeVariances = [];
trialAlphaMaxDeviations = [];
trialAlphaMaxDeviation = 0;

for serialNumber = 1:15
    log = "onlyEncoders-lowGain";
    logName = strcat('20240121-', log, '-150FPS-30secSession-', string(serialNumber));
    dir = strcat(pwd, '\AdditionalTestLogs\', logName, '.log');
    data = readtable(dir, 'Delimiter', ';');

    sampleAlphaQubeVar = var(data.alphaQube(data.camControl==0));
    sampleAlphaCamVar = var(data.alphaFiltered(data.camControl==0));
    sampleAlphaDotCamVar = var(data.alphaDotKalman(data.camControl==0));
    fprintf('%s - alphaQubevar: %f, alphaCamvar: %f, alphaDotCamvar: %f\n', logName, sampleAlphaQubeVar, sampleAlphaCamVar, sampleAlphaDotCamVar);
    sampleMaxDeviation = max(abs(data.alphaQube(data.camControl==0)));
    fprintf('%s - maxDeviation: %f\n', logName, sampleMaxDeviation*180/pi)
    
    if sampleMaxDeviation*180/pi < 10
        n=n+1;
        trialAlphaQubeVariances(end+1) = sampleAlphaQubeVar;
        trialAlphaMaxDeviations(end+1) = sampleMaxDeviation*180/pi;
        if trialAlphaMaxDeviation < sampleMaxDeviation*180/pi
            trialAlphaMaxDeviation = sampleMaxDeviation*180/pi;
        end
    end 
end

meanAlphaQubeVars{end+1} = mean(trialAlphaQubeVariances)
sDevAlphaQubeVars{end+1} = std(trialAlphaQubeVariances)
meanAlphaQubeMaxDev = mean(trialAlphaMaxDeviations)
trialAlphaMaxDeviation
ns{end+1} = n
  
tval = tinv(0.975, n-1)
lower95 = meanAlphaQubeVars{end} - tval*sDevAlphaQubeVars{end}/sqrt(n)
upper95 = meanAlphaQubeVars{end} + tval*sDevAlphaQubeVars{end}/sqrt(n)

fprintf('Test Description & Mean Variance $alpha_{text{QUBE}}$ & Standard Deviation $alpha_{text{QUBE}}$ & Trials & 95 Confidence Interval & Mean max. deviation of sessions & Absolute max. deviation of sessions  \n')
fprintf('%s & %f & %f & %d & $begin{bmatrix} %f, %f end{bmatrix}$ & %f & %f \n', logName, meanAlphaQubeVars{end}, sDevAlphaQubeVars{end}, ns{end}, lower95, upper95, meanAlphaQubeMaxDev, trialAlphaMaxDeviation);
    

%% T tests

t1 = (meanAlphaQubeVars{1} - meanAlphaQubeVars{2} - 0) / sqrt((sDevAlphaQubeVars{1}^2)/ns{1} + (sDevAlphaQubeVars{2}^2)/ns{2});
v1 = ((sDevAlphaQubeVars{1}^2)/ns{1} + (sDevAlphaQubeVars{2}^2)/ns{2})^2 / ((sDevAlphaQubeVars{1}^2/ns{1})^2/(ns{1}-1) + (sDevAlphaQubeVars{2}^2/ns{2})^2/(ns{2}-1));
t2 = (meanAlphaQubeVars{2} - meanAlphaQubeVars{3} - 0) / sqrt((sDevAlphaQubeVars{2}^2)/ns{2} + (sDevAlphaQubeVars{3}^2)/ns{3});
v2 = ((sDevAlphaQubeVars{2}^2)/ns{2} + (sDevAlphaQubeVars{3}^2)/ns{3})^2 / ((sDevAlphaQubeVars{2}^2/ns{2})^2/(ns{2}-1) + (sDevAlphaQubeVars{3}^2/ns{3})^2/(ns{3}-1));

tval95onetail1 = tinv(0.95,round(v1));
tval95onetail2 = tinv(0.95,round(v2));

tpval1 = 1 - tcdf(t1, v1);
tpval2 = 1 - tcdf(t2, v2);

% Check math with example from Navidi book
tBookCheck = (44.1 - 32.3 - 0) / sqrt((10.09^2)/10 + (8.56^2)/10);
vBookCheck = ((10.09^2)/10 + (8.56^2)/10)^2 / ((10.09^2/10)^2/(10-1) + (8.56^2/10)^2/(10-1));
