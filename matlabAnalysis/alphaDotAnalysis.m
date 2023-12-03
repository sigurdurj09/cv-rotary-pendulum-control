close all;
clear all;
clc;

log = 'data230703b.log'; %Benchmark
%log = 'data230626doublePhase.log';
dir = strcat(pwd, '\logs\', log);
data = readtable(dir, 'Delimiter', ';');

disp(log);

%Remove bias on data
data.alphaQube = data.alphaQube - 0.003068;

printAll = false;

covDotAlpha = cov(data.alphaDotQube(data.camControl==0), data.alphaDotCam(data.camControl==0));
corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), data.alphaDotCam(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), data.alphaDotCam(data.camControl==0), 5, 'normalized');
figure(1);
stem(lags, c);

fprintf('\n Two dots found in %f%% of frames before cam control\n', sum(data.twoDotCheck(data.camControl==0))/length(data.twoDotCheck(data.camControl==0)));
fprintf('\n Two dots found in %f%% of frames after cam control\n', sum(data.twoDotCheck(data.camControl==1))/length(data.twoDotCheck(data.camControl==1)));
fprintf('Unfiltered alphaDot data has CorCoef = %f and 0 lag = %f.\n' , corcoefAlphaDot(2,1), c(lags==0));

figure(2);
hold on
plot(data.alphaDotQube);
plot(data.alphaDotCam);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot Cam");
axis([0 height(data) -3 3])
grid on
hold off

%% Butterworth filters

fs = 100;

orArray = [1,2,3,4,5,6];
fcArray = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45];

bestCor = 0;
bestCorOr = 0;
bestCorFc = 0;

for loopOr = 1:length(orArray)
    for loopFc = 1:length(fcArray)

        fc = fcArray(loopFc);
        or = orArray(loopOr);
        [b,a] = butter(or, fc/(fs/2));

        %Test filter
        n = 0;
        samples = height(data);
        alphaDotButterworthFilter = zeros(samples, 1);

        x = zeros(1, or + 1);
        y = zeros(1, or + 1);

        for i = 1:samples

            for n = or+1:-1:2
                x(n) = x(n-1);
                y(n) = y(n-1);
            end

            x(1) = data.alphaDotCam(i);
            y(1) = 0;

            for n = or+1:-1:1
                if n ==1 
                    y(1) = y(1) + b(n) * x(n);     
                else
                    y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
                end        
            end

            alphaDotButterworthFilter(i) =  y(1);

        end

        [c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotButterworthFilter(data.camControl==0), 5, 'normalized');
        corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotButterworthFilter(data.camControl==0));
        
        maxCorr = -1;
        maxCorrInd = 0;
        
        zeroLagCCor = c(lags==0);
        
        for i = 1:length(c)
            if c(i) > maxCorr
                maxCorr = c(i);
                maxCorrInd = i;
            end            
        end
        
        if zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr > bestCor
            bestCor = zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr;
            bestCorOr = or;
            bestCorFc = fc;            
        end
        
        if printAll
            fprintf('Max butterworth alphaDot correlation for order %i CO %iHz is %f at lag %d. ' , or, fc, maxCorr, lags(maxCorrInd));
            fprintf('Cor Coef is %f.\n' , corcoefAlphaDot(2,1));
        end
    end
end

%Chosen filter
fc = bestCorFc;
or = bestCorOr;
[b,a] = butter(or, fc/(fs/2));

%Test filter
n = 0;
samples = height(data);
alphaDotButterworthFilter = zeros(samples, 1);

x = zeros(1, or + 1);
y = zeros(1, or + 1);

for i = 1:samples

    for n = or+1:-1:2
        x(n) = x(n-1);
        y(n) = y(n-1);
    end

    x(1) = data.alphaDotCam(i);
    y(1) = 0;

    for n = or+1:-1:1
        if n ==1 
            y(1) = y(1) + b(n) * x(n);     
        else
            y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
        end        
    end

    alphaDotButterworthFilter(i) =  y(1);

end

corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotButterworthFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotButterworthFilter(data.camControl==0), 5, 'normalized');
figure(3);
stem(lags, c);

fprintf('Best butterworth alphaDot has order %i cutoff %iHz with a sum of %f in relevant correlations.\n' , or, fc, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlphaDot(2,1), c(lags==0), max(c), lags(c==max(c)));
b
a

figure(4);
hold on
plot(data.alphaDotQube);
plot(alphaDotButterworthFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot Butterworth");
axis([0 height(data) -3 3])
grid on
hold off  

%% Custom filters
denomArray = [2,3,4,5];

bestCor = 0;
bestCorDenom = 0;

for loopdenom = 1:length(denomArray)
    
    denom = denomArray(loopdenom);
    
    b = [1/denom, 0];
    a = [1.0, -(denom-1)/denom];
    or = 1;

    %Test filter
    n = 0;
    samples = height(data);
    alphaDotCustomFilter = zeros(samples, 1);

    x = zeros(1, or + 1);
    y = zeros(1, or + 1);

    for i = 1:samples
        for n = or+1:-1:2
            x(n) = x(n-1);
            y(n) = y(n-1);
        end

        x(1) = data.alphaDotCam(i);
        y(1) = 0;

        for n = or+1:-1:1
            if n ==1 
                y(1) = y(1) + b(n) * x(n);     
            else
                y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
            end        
        end

        alphaDotCustomFilter(i) =  y(1);

    end

    [c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotCustomFilter(data.camControl==0), 5, 'normalized');
    corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotCustomFilter(data.camControl==0));
        
    maxCorr = -1;
    maxCorrInd = 0;
    
    zeroLagCCor = c(lags==0);

    for i = 1:length(c)
        if c(i) > maxCorr
            maxCorr = c(i);
            maxCorrInd = i;
        end    
    end
    
    if zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr > bestCor
        bestCor = zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr;
        bestCorDenom = denom;          
    end
    
    if printAll
        fprintf('Max custom alphaDot correlation for denom %i is %f at lag %d. ' , denom, maxCorr, lags(maxCorrInd));
        fprintf('Cor Coef is %f.\n' , corcoefAlphaDot(2,1));
    end
end


%Chosen filter
denom = bestCorDenom;
    
b = [1/denom, 0];
a = [1.0, -(denom-1)/denom];
or = 1;

%Test filter
n = 0;
samples = height(data);
alphaDotCustomFilter = zeros(samples, 1);

x = zeros(1, or + 1);
y = zeros(1, or + 1);

for i = 1:samples

    for n = or+1:-1:2
        x(n) = x(n-1);
        y(n) = y(n-1);
    end

    x(1) = data.alphaDotCam(i);
    y(1) = 0;

    for n = or+1:-1:1
        if n ==1 
            y(1) = y(1) + b(n) * x(n);     
        else
            y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
        end        
    end

    alphaDotCustomFilter(i) =  y(1);

end

corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotCustomFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotCustomFilter(data.camControl==0), 5, 'normalized');
figure(5);
stem(lags, c);

fprintf('Best custom alphaDot has denom %i with a sum of %f in relevant correlations.\n' , denom, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlphaDot(2,1), c(lags==0), max(c), lags(c==max(c)));
b
a

figure(6);
hold on
plot(data.alphaDotQube);
plot(alphaDotCustomFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot Custom");
axis([0 height(data) -3 3])
grid on
hold off  

%% Chebyshev T1 filters
fs = 100;

orArray = [1,2,3,4,5,6];
fcArray = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45];
rippleArray = [1, 2, 3, 5, 10];

bestCor = 0;
bestCorOr = 0;
bestCorFc = 0;
bestCorRipple = 0;

for loopOr = 1:length(orArray)
    for loopFc = 1:length(fcArray)
        for loopRip = 1:length(rippleArray)

            fc = fcArray(loopFc);
            or = orArray(loopOr);
            rip = rippleArray(loopRip);
            [b,a] = cheby1(or, rip, fc/(fs/2), 'low');

            %Test filter
            n = 0;
            samples = height(data);
            alphaDotCheb1Filter = zeros(samples, 1);

            x = zeros(1, or + 1);
            y = zeros(1, or + 1);

            for i = 1:samples

                for n = or+1:-1:2
                    x(n) = x(n-1);
                    y(n) = y(n-1);
                end

                x(1) = data.alphaDotCam(i);
                y(1) = 0;

                for n = or+1:-1:1
                    if n ==1 
                        y(1) = y(1) + b(n) * x(n);     
                    else
                        y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
                    end        
                end

                alphaDotCheb1Filter(i) =  y(1);

            end

            [c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotCheb1Filter(data.camControl==0), 5, 'normalized');
            corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotCheb1Filter(data.camControl==0));

            maxCorr = -1;
            maxCorrInd = 1;
            
            zeroLagCCor = c(lags==0);

            for i = 1:length(c)
                if c(i) > maxCorr
                    maxCorr = c(i);
                    maxCorrInd = i;
                end    
            end
            
            if zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr > bestCor
                bestCor = zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr;
                bestCorOr = or;
                bestCorFc = fc;
                bestCorRipple = rip;
            end
            
            if printAll
                fprintf('Max Chebyshev1 alphaDot correlation for order %i, CO %iHz, ripple %i is %f at lag %d. ' , or, fc, rip, maxCorr, lags(maxCorrInd));
                fprintf('Cor Coef is %f.\n' , corcoefAlphaDot(2,1));
            end
        end
    end
end


%Chosen filter
fc = bestCorFc;
or = bestCorOr;
rip = bestCorRipple;
[b,a] = cheby1(or, rip, fc/(fs/2), 'low');

%Test filter
samples = height(data);
alphaDotCheb1Filter = zeros(samples, 1);

x = zeros(1, or + 1);
y = zeros(1, or + 1);

for i = 1:samples

    for n = or+1:-1:2
        x(n) = x(n-1);
        y(n) = y(n-1);
    end

    x(1) = data.alphaDotCam(i);
    y(1) = 0;

    for n = or+1:-1:1
        if n ==1 
            y(1) = y(1) + b(n) * x(n);     
        else
            y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
        end        
    end

    alphaDotCheb1Filter(i) =  y(1);

end

corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotCheb1Filter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotCheb1Filter(data.camControl==0), 5, 'normalized');
figure(7);
stem(lags, c);

fprintf('Best Cheby1 alphaDot has order %i, cutoff %iHz, rip %i with a sum of %f in relevant correlations.\n' , or, fc, rip, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlphaDot(2,1), c(lags==0), max(c), lags(c==max(c)));
b
a

figure(8);
hold on
plot(data.alphaDotQube);
plot(alphaDotCheb1Filter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot Cheb1");
axis([0 height(data) -3 3])
grid on
hold off  

%% Chebyshev T2 filters
fs = 100;

orArray = [1,2,3,4,5,6];
fcArray = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45];
attenArray = [1, 3, 10, 20, 40];

bestCor = 0;
bestCorOr = 0;
bestCorFc = 0;
bestCorAtten = 0;

for loopOr = 1:length(orArray)
    for loopFc = 1:length(fcArray)
        for loopAtten = 1:length(attenArray)

            fc = fcArray(loopFc);
            or = orArray(loopOr);
            atten = attenArray(loopAtten);
            [b,a] = cheby2(or, atten, fc/(fs/2), 'low');

            %Test filter
            n = 0;
            samples = height(data);
            alphaDotCheb2Filter = zeros(samples, 1);

            x = zeros(1, or + 1);
            y = zeros(1, or + 1);

            for i = 1:samples

                for n = or+1:-1:2
                    x(n) = x(n-1);
                    y(n) = y(n-1);
                end

                x(1) = data.alphaDotCam(i);
                y(1) = 0;

                for n = or+1:-1:1
                    if n ==1 
                        y(1) = y(1) + b(n) * x(n);     
                    else
                        y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
                    end        
                end

                alphaDotCheb2Filter(i) =  y(1);

            end

            [c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotCheb2Filter(data.camControl==0), 5, 'normalized');
            corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotCheb2Filter(data.camControl==0));

            maxCorr = -1;
            maxCorrInd = 1;
            
            zeroLagCCor = c(lags==0);

            for i = 1:length(c)
                if c(i) > maxCorr
                    maxCorr = c(i);
                    maxCorrInd = i;
                end    
            end
            
            if zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr > bestCor
                bestCor = zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr;
                bestCorOr = or;
                bestCorFc = fc;
                bestCorAtten = atten;
            end
            
            if printAll
                fprintf('Max Chebyshev2 alphaDot correlation for order %i, CO %iHz, atten %i is %f at lag %d. ' , or, fc, atten, maxCorr, lags(maxCorrInd));
                fprintf('Cor Coef is %f.\n' , corcoefAlphaDot(2,1));
            end
        end
    end
end


%Chosen filter
fc = bestCorFc;
or = bestCorOr;
atten = bestCorAtten;
[b,a] = cheby2(or, atten, fc/(fs/2), 'low');

%Test filter
samples = height(data);
alphaDotCheb2Filter = zeros(samples, 1);

x = zeros(1, or + 1);
y = zeros(1, or + 1);

for i = 1:samples

    for n = or+1:-1:2
        x(n) = x(n-1);
        y(n) = y(n-1);
    end

    x(1) = data.alphaDotCam(i);
    y(1) = 0;

    for n = or+1:-1:1
        if n ==1 
            y(1) = y(1) + b(n) * x(n);     
        else
            y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
        end        
    end

    alphaDotCheb2Filter(i) =  y(1);

end

corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotCheb2Filter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotCheb2Filter(data.camControl==0), 5, 'normalized');
figure(9);
stem(lags, c);

fprintf('Best Cheby2 alphaDot has order %i, cutoff %iHz, atten %i with a sum of %f in relevant correlations.\n' , or, fc, atten, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlphaDot(2,1), c(lags==0), max(c), lags(c==max(c)));
b
a

figure(10);
hold on
plot(data.alphaDotQube);
plot(alphaDotCheb2Filter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot Cheb2");
axis([0 height(data) -3 3])
grid on
hold off  

%% Elliptic filters
fs = 100;

orArray = [1,2,3,4,5,6];
fcArray = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45];
attenArray = [6, 10, 20, 40];
rippleArray = [1, 2, 3, 5];

bestCor = 0;
bestCorOr = 0;
bestCorFc = 0;
bestCorAtten = 0;
bestCorRipple = 0;

for loopOr = 1:length(orArray)
    for loopFc = 1:length(fcArray)
        for loopAtten = 1:length(attenArray)
            for loopRip = 1:length(rippleArray)

                fc = fcArray(loopFc);
                or = orArray(loopOr);
                atten = attenArray(loopAtten);
                rip = rippleArray(loopRip);
                [b,a] = ellip(or, rip, atten, fc/(fs/2), 'low');

                %Test filter
                n = 0;
                samples = height(data);
                alphaDotEllipFilter = zeros(samples, 1);

                x = zeros(1, or + 1);
                y = zeros(1, or + 1);

                for i = 1:samples

                    for n = or+1:-1:2
                        x(n) = x(n-1);
                        y(n) = y(n-1);
                    end

                    x(1) = data.alphaDotCam(i);
                    y(1) = 0;

                    for n = or+1:-1:1
                        if n ==1 
                            y(1) = y(1) + b(n) * x(n);     
                        else
                            y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
                        end        
                    end

                    alphaDotEllipFilter(i) =  y(1);

                end

                [c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotEllipFilter(data.camControl==0), 5, 'normalized');
                corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotEllipFilter(data.camControl==0));

                maxCorr = -1;
                maxCorrInd = 1;
                
                zeroLagCCor = c(lags==0);

                for i = 1:length(c)
                    if c(i) > maxCorr
                        maxCorr = c(i);
                        maxCorrInd = i;
                    end    
                end
                
                if zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr > bestCor
                    bestCor = zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr;
                    bestCorOr = or;
                    bestCorFc = fc;
                    bestCorAtten = atten;
                    bestCorRipple = rip;
                end
                
                if printAll
                    fprintf('Max Ellip alphaDot correlation for order %i, CO %iHz, atten %i, rip %i is %f at lag %d. ' , or, fc, atten, rip, maxCorr, lags(maxCorrInd));
                    fprintf('Cor Coef is %f.\n' , corcoefAlphaDot(2,1));
                end
            end
        end
    end
end

%Chosen filter
fc = bestCorFc;
or = bestCorOr;
atten = bestCorAtten;
rip = bestCorRipple;
[b,a] = ellip(or, rip, atten, fc/(fs/2), 'low');

%Test filter
samples = height(data);
alphaDotEllipFilter = zeros(samples, 1);

x = zeros(1, or + 1);
y = zeros(1, or + 1);

for i = 1:samples

    for n = or+1:-1:2
        x(n) = x(n-1);
        y(n) = y(n-1);
    end

    x(1) = data.alphaDotCam(i);
    y(1) = 0;

    for n = or+1:-1:1
        if n ==1 
            y(1) = y(1) + b(n) * x(n);     
        else
            y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
        end        
    end

    alphaDotEllipFilter(i) =  y(1);

end

corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotEllipFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotEllipFilter(data.camControl==0), 5, 'normalized');
figure(11);
stem(lags, c);

fprintf('Best Elliptical alphaDot has order %i, cutoff %iHz, rip %i, atten %i with a sum of %f in relevant correlations.\n' , or, fc, rip, atten, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlphaDot(2,1), c(lags==0), max(c), lags(c==max(c)));
b
a

figure(12);
hold on
plot(data.alphaDotQube);
plot(alphaDotEllipFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot Elliptical");
axis([0 height(data) -3 3])
grid on
hold off  

%% LS FIR filters
fs = 100;

orArray = [1,2,3,4,5,6,7,8,9,10,15,20];
fcArray = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45];

bestCor = 0;
bestCorOr = 0;
bestCorFc = 0;

for loopOr = 1:length(orArray)
    for loopFc = 1:length(fcArray)

        fc = fcArray(loopFc);
        or = orArray(loopOr);
        b = firls(or, [0, fc/(fs/2), (fc+5)/(fs/2),1] , [1, 1, 0, 0]);

        %Test filter
        n = 0;
        samples = height(data);
        alphaDotFIRLSFilter = zeros(samples, 1);

        x = zeros(1, or + 1);
        

        for i = 1:samples
            y = 0;
            
            for n = or+1:-1:2
                x(n) = x(n-1);
            end

            x(1) = data.alphaDotCam(i);

            for n = or+1:-1:1
                y = y + b(n) * x(n);     
            end

            alphaDotFIRLSFilter(i) =  y;

        end

        [c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotFIRLSFilter(data.camControl==0), 5, 'normalized');
        corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotFIRLSFilter(data.camControl==0));

        maxCorr = -1;
        maxCorrInd = 1;
        
        zeroLagCCor = c(lags==0);

        for i = 1:length(c)
            if c(i) > maxCorr
                maxCorr = c(i);
                maxCorrInd = i;
            end    
        end
        
        if zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr > bestCor
            bestCor = zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr;
            bestCorOr = or;
            bestCorFc = fc;            
        end
        
        if printAll
            fprintf('Max FIRLS alphaDot correlation for order %i, CO %iHz, is %f at lag %d. ' , or, fc, maxCorr, lags(maxCorrInd));
            fprintf('Cor Coef is %f.\n' , corcoefAlphaDot(2,1));
        end
    end
end


%Chosen filter
fc = bestCorFc;
or = bestCorOr;
b = firls(or, [0, fc/(fs/2), (fc+5)/(fs/2),1] , [1, 1, 0, 0]);

%Test filter
n = 0;
samples = height(data);
alphaDotFIRLSFilter = zeros(samples, 1);

x = zeros(1, or + 1);

for i = 1:samples
    
    y = 0;
    
    for n = or+1:-1:2
        x(n) = x(n-1);
    end

    x(1) = data.alphaDotCam(i);

    for n = or+1:-1:1
        y = y + b(n) * x(n);     
    end

    alphaDotFIRLSFilter(i) =  y;

end

corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotFIRLSFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotFIRLSFilter(data.camControl==0), 5, 'normalized');
figure(13);
stem(lags, c);

fprintf('Best FIR LS alphaDot has order %i cutoff %iHz with a sum of %f in relevant correlations.\n' , or, fc, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlphaDot(2,1), c(lags==0), max(c), lags(c==max(c)));
b

figure(14);
hold on
plot(data.alphaDotQube);
plot(alphaDotFIRLSFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot FIR LS");
axis([0 height(data) -3 3])
grid on
hold off  

%% PM FIR filters
fs = 100;

orArray = [3,4,5,6,7,8,9,10,15,20];
fcArray = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45];

bestCor = 0;
bestCorOr = 0;
bestCorFc = 0;

for loopOr = 1:length(orArray)
    for loopFc = 1:length(fcArray)

        fc = fcArray(loopFc);
        or = orArray(loopOr);
        b = firpm(or, [0, fc/(fs/2), (fc+5)/(fs/2),1] , [1, 1, 0, 0]);

        %Test filter
        n = 0;
        samples = height(data);
        alphaDotFIRPMFilter = zeros(samples, 1);

        x = zeros(1, or + 1);
        

        for i = 1:samples
            y = 0;
            
            for n = or+1:-1:2
                x(n) = x(n-1);
            end

            x(1) = data.alphaDotCam(i);

            for n = or+1:-1:1
                y = y + b(n) * x(n);     
            end

            alphaDotFIRPMFilter(i) =  y;

        end

        [c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotFIRPMFilter(data.camControl==0), 5, 'normalized');
        corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotFIRPMFilter(data.camControl==0));

        maxCorr = -1;
        maxCorrInd = 1;
        
        zeroLagCCor = c(lags==0);

        for i = 1:length(c)
            if c(i) > maxCorr
                maxCorr = c(i);
                maxCorrInd = i;
            end    
        end
        
        if zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr > bestCor
            bestCor = zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr;
            bestCorOr = or;
            bestCorFc = fc;            
        end
        
        if printAll
            fprintf('Max FIRPM alphaDot correlation for order %i, CO %iHz, is %f at lag %d. ' , or, fc, maxCorr, lags(maxCorrInd));
            fprintf('Cor Coef is %f.\n' , corcoefAlphaDot(2,1));
        end
    end
end


%Chosen filter
fc = bestCorFc;
or = bestCorOr;
b = firpm(or, [0, fc/(fs/2), (fc+5)/(fs/2),1] , [1, 1, 0, 0]);

%Test filter
n = 0;
samples = height(data);
alphaDotFIRPMFilter = zeros(samples, 1);

x = zeros(1, or + 1);


for i = 1:samples
    
    y = 0;
    
    for n = or+1:-1:2
        x(n) = x(n-1);
    end

    x(1) = data.alphaDotCam(i);

    for n = or+1:-1:1
        y = y + b(n) * x(n);     
    end

    alphaDotFIRPMFilter(i) =  y;

end

corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotFIRPMFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotFIRPMFilter(data.camControl==0), 5, 'normalized');
figure(15);
stem(lags, c);

fprintf('Best FIR PM alphaDot has order %i cutoff %iHz with a sum of %f in relevant correlations.\n' , or, fc, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlphaDot(2,1), c(lags==0), max(c), lags(c==max(c)));
b

figure(16);
hold on
plot(data.alphaDotQube);
plot(alphaDotFIRPMFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot FIR PM");
axis([0 height(data) -3 3])
grid on
hold off  

%% Alpha Filter first

%Chosen Elliptical filter
fc = 30;
or = 3;
atten = 6;
rip = 2;
[b,a] = ellip(or, rip, atten, fc/(fs/2), 'low');

%Test filter
samples = height(data);
alphaEllipFilter = zeros(samples, 1);

x = zeros(1, or + 1);
y = zeros(1, or + 1);

for i = 1:samples

    for n = or+1:-1:2
        x(n) = x(n-1);
        y(n) = y(n-1);
    end

    x(1) = data.alphaCam(i);
    y(1) = 0;

    for n = or+1:-1:1
        if n ==1 
            y(1) = y(1) + b(n) * x(n);     
        else
            y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
        end        
    end

    alphaEllipFilter(i) =  y(1);

end

frequency = 150;

alphaDotPreFilter = zeros(samples, 1);

for i = 2:samples
    alphaDotPreFilter(i) = (alphaEllipFilter(i) - alphaEllipFilter(i-1)) * frequency; 
end

corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotPreFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotPreFilter(data.camControl==0), 5, 'normalized');
figure(17);
stem(lags, c);

fprintf('PreFilter: CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlphaDot(2,1), c(lags==0), max(c), lags(c==max(c)));

figure(18);
hold on
plot(data.alphaDotQube);
plot(alphaDotPreFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot PreFilter");
axis([0 height(data) -3 3])
grid on
hold off 

%% Noise gate

alphaDotEllipGateFilter = alphaDotEllipFilter;

for i = 1:samples
    if abs(alphaDotEllipGateFilter(i)) < 0.17
        alphaDotEllipGateFilter(i) = 0;
    end
end

corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotEllipGateFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotEllipGateFilter(data.camControl==0), 5, 'normalized');
figure(19);
stem(lags, c);

fprintf('GateEllipsoid: CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlphaDot(2,1), c(lags==0), max(c), lags(c==max(c)));

figure(20);
hold on
plot(data.alphaDotQube);
plot(alphaDotEllipGateFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot GatedEllipsoid");
axis([0 height(data) -3 3])
grid on
hold off 

%% Gated Alpha then Ellipsoid

alphaEllipGateFilter = alphaEllipFilter;
noiseGate = 0.001;

for i = 1:samples
    if abs(alphaEllipGateFilter(i)) < noiseGate
        alphaEllipGateFilter(i) = 0;
    end
end

alphaDotElipGateFilter = zeros(samples, 1);

for i = 2:samples
    alphaDotElipGateFilter(i) = (alphaEllipGateFilter(i) - alphaEllipGateFilter(i-1)) * frequency; 
end

corcoefAlpha = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotElipGateFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotElipGateFilter(data.camControl==0), 5, 'normalized');
figure(21);
stem(lags, c);

fprintf('Alpha2xEllipsoidGate: CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlpha(2,1), c(lags==0), max(c), lags(c==max(c)));

figure(22);
hold on
plot(data.alphaDotQube);
plot(alphaDotEllipGateFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot PreGatedEllipsoid");
axis([0 height(data) -3 3])
grid on
hold off 

%% GateFilter Elliptical

%Chosen filter
fc = 20;
or = 2;
atten = 20;
rip = 1;
[b,a] = ellip(or, rip, atten, fc/(fs/2), 'low');

%Test filter
samples = height(data);
alphaDotEllipGateFilter = zeros(samples, 1);

x = zeros(1, or + 1);
y = zeros(1, or + 1);

for i = 1:samples

    for n = or+1:-1:2
        x(n) = x(n-1);
        y(n) = y(n-1);
    end

    x(1) = data.alphaDotCam(i);
    y(1) = 0;

    for n = or+1:-1:1
        if n ==1 
            y(1) = y(1) + b(n) * x(n);     
        else
            y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
        end        
    end
    
    if abs(y(1)) < 0.17
        y(1) = 0;
    end

    alphaDotEllipGateFilter(i) =  y(1);

end

corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotEllipGateFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotEllipGateFilter(data.camControl==0), 5, 'normalized');
figure(23);
stem(lags, c);

fprintf('AlphaDot Elliptical Dynamic filter CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlphaDot(2,1), c(lags==0), max(c), lags(c==max(c)));

figure(24);
hold on
plot(data.alphaDotQube);
plot(alphaDotEllipGateFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot EllipticalDynamicGate");
axis([0 height(data) -3 3])
grid on
hold off  

%% Elliptic filters w. gate
fs = 100;

orArray = [1,2,3,4,5,6];
fcArray = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45];
attenArray = [6, 10, 20, 40];
rippleArray = [1, 2, 3, 5];

bestCor = 0;
bestCorOr = 0;
bestCorFc = 0;
bestCorAtten = 0;
bestCorRipple = 0;

for loopOr = 1:length(orArray)
    for loopFc = 1:length(fcArray)
        for loopAtten = 1:length(attenArray)
            for loopRip = 1:length(rippleArray)

                fc = fcArray(loopFc);
                or = orArray(loopOr);
                atten = attenArray(loopAtten);
                rip = rippleArray(loopRip);
                [b,a] = ellip(or, rip, atten, fc/(fs/2), 'low');

                %Test filter
                n = 0;
                samples = height(data);
                alphaDotEllipGateFilter = zeros(samples, 1);

                x = zeros(1, or + 1);
                y = zeros(1, or + 1);

                for i = 1:samples

                    for n = or+1:-1:2
                        x(n) = x(n-1);
                        y(n) = y(n-1);
                    end

                    x(1) = data.alphaDotCam(i);
                    y(1) = 0;

                    for n = or+1:-1:1
                        if n ==1 
                            y(1) = y(1) + b(n) * x(n);     
                        else
                            y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
                        end        
                    end
                    
                    if abs(y(1)) < 0.17
                        y(1) = 0;
                    end

                    alphaDotEllipGateFilter(i) =  y(1);

                end

                [c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotEllipGateFilter(data.camControl==0), 5, 'normalized');
                corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotEllipGateFilter(data.camControl==0));

                maxCorr = -1;
                maxCorrInd = 1;
                
                zeroLagCCor = c(lags==0);

                for i = 1:length(c)
                    if c(i) > maxCorr
                        maxCorr = c(i);
                        maxCorrInd = i;
                    end    
                end
                
                if zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr > bestCor
                    bestCor = zeroLagCCor + corcoefAlphaDot(2,1) + maxCorr;
                    bestCorOr = or;
                    bestCorFc = fc;
                    bestCorAtten = atten;
                    bestCorRipple = rip;
                end
                
                if printAll
                    fprintf('Max EllipGate alphaDot correlation for order %i, CO %iHz, atten %i, rip %i is %f at lag %d. ' , or, fc, atten, rip, maxCorr, lags(maxCorrInd));
                    fprintf('Cor Coef is %f.\n' , corcoefAlphaDot(2,1));
                end
            end
        end
    end
end

%Chosen filter
fc = bestCorFc;
or = bestCorOr;
atten = bestCorAtten;
rip = bestCorRipple;
[b,a] = ellip(or, rip, atten, fc/(fs/2), 'low');

%Test filter
samples = height(data);
alphaDotEllipGateFilter = zeros(samples, 1);

x = zeros(1, or + 1);
y = zeros(1, or + 1);

for i = 1:samples

    for n = or+1:-1:2
        x(n) = x(n-1);
        y(n) = y(n-1);
    end

    x(1) = data.alphaDotCam(i);
    y(1) = 0;

    for n = or+1:-1:1
        if n ==1 
            y(1) = y(1) + b(n) * x(n);     
        else
            y(1) = y(1) + b(n) * x(n) - a(n) * y(n); 
        end        
    end

    alphaDotEllipGateFilter(i) =  y(1);

end

corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotEllipGateFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotEllipGateFilter(data.camControl==0), 5, 'normalized');
figure(25);
stem(lags, c);

fprintf('Best Elliptical alphaDot has order %i, cutoff %iHz, rip %i, atten %i with a sum of %f in relevant correlations.\n' , or, fc, rip, atten, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlphaDot(2,1), c(lags==0), max(c), lags(c==max(c)));
b
a

figure(26);
hold on
plot(data.alphaDotQube);
plot(alphaDotEllipGateFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("AlphaDot Qube", "AlphaDot EllipticalGated");
axis([0 height(data) -3 3])
grid on
hold off  