close all;
clear all;
clc;

log = 'vData230705stationary.log';
dir = strcat(pwd, '\logs\varianceLogs\', log);
data = readtable(dir, 'Delimiter', ';');

contrastedP1x = data.p1x(strcmp(data.source, 'contrasted'));
contrastedP1y = data.p1y(strcmp(data.source, 'contrasted'));
contrastedP1r = data.p1r(strcmp(data.source, 'contrasted'));
maskedP1x = data.p1x(strcmp(data.source, 'mask'));
maskedP1y = data.p1y(strcmp(data.source, 'mask'));
maskedP1r = data.p1r(strcmp(data.source, 'mask'));

contrastedP2x = data.p2x(strcmp(data.source, 'contrasted'));
contrastedP2y = data.p2y(strcmp(data.source, 'contrasted'));
contrastedP2r = data.p2r(strcmp(data.source, 'contrasted'));
maskedP2x = data.p2x(strcmp(data.source, 'mask'));
maskedP2y = data.p2y(strcmp(data.source, 'mask'));
maskedP2r = data.p2r(strcmp(data.source, 'mask'));

%% Fix wrong point analysis
samples = length(data.p1x(strcmp(data.source, 'mask')));

meanP1xContrasted = mean(contrastedP1x(contrastedP2x~=0.0));
meanP2xContrasted = mean(contrastedP2x(contrastedP2x~=0.0));
meanP1xMasked = mean(maskedP1x(contrastedP2x~=0.0));
meanP2xMasked = mean(maskedP2x(contrastedP2x~=0.0));

for i = 1:samples
    if abs(contrastedP1x(i) - meanP1xContrasted) > abs(contrastedP1x(i) - meanP2xContrasted) && contrastedP2x(i)==0.0
        contrastedP2x(i) = contrastedP1x(i);
        contrastedP2y(i) = contrastedP1y(i);
        contrastedP2r(i) = contrastedP1r(i);
        contrastedP1x(i) = 0.0;
        contrastedP1y(i) = 0.0;
        contrastedP1r(i) = 0.0;
    end
    
    if abs(maskedP1x(i) - meanP1xMasked) > abs(maskedP1x(i) - meanP2xMasked) && maskedP2x(i)==0.0
        maskedP2x(i) = maskedP1x(i);
        maskedP2y(i) = maskedP1y(i);
        maskedP2r(i) = maskedP1r(i);
        maskedP1x(i) = 0.0;
        maskedP1y(i) = 0.0;
        maskedP1r(i) = 0.0;
    end    
    
end

varContrastedp1x = var(contrastedP1x(contrastedP1x~=0.0));
varContrastedp1y = var(contrastedP1y(contrastedP1y~=0.0));
varContrastedp2x = var(contrastedP2x(contrastedP2x~=0.0));
varContrastedp2y = var(contrastedP2y(contrastedP2y~=0.0));
mostCommonR1Contrasted = mode(contrastedP1r);
mostCommonR2Contrasted = mode(contrastedP2r);

varMaskedp1x = var(maskedP1x(maskedP1x~=0.0));
varMaskedp1y = var(maskedP1y(maskedP1y~=0.0));
varMaskedp2x = var(maskedP2x(maskedP2x~=0.0));
varMaskedp2y = var(maskedP2y(maskedP2y~=0.0));
mostCommonR1Masked = mode(maskedP1r);
mostCommonR2Masked = mode(maskedP2r);

emptyP1xContrasted = sum(contrastedP1x == 0.0);
emptyP2xContrasted = sum(contrastedP2x == 0.0);
emptyP1xMasked = sum(maskedP1x == 0.0);
emptyP2xMasked = sum(maskedP2x == 0.0);
