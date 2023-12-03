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

covAlpha = cov(data.alphaQube(data.camControl==0), data.alphaCam(data.camControl==0));
corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), data.alphaCam(data.camControl==0));
[c,lags] = xcorr(data.alphaQube(data.camControl==0), data.alphaCam(data.camControl==0), 5, 'normalized');
figure(1);
stem(lags, c);

fprintf('\n Two dots found in %f%% of frames before cam control\n', sum(data.twoDotCheck(data.camControl==0))/length(data.twoDotCheck(data.camControl==0)));
fprintf('\n Two dots found in %f%% of frames after cam control\n', sum(data.twoDotCheck(data.camControl==1))/length(data.twoDotCheck(data.camControl==1)));
fprintf('Unfiltered data has CorCoef = %f and 0 lag = %f.\n' , corcoefAlpha(2,1), c(lags==0));

figure(2);
hold on
plot(data.alphaQube);
plot(data.alphaCam);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("Alpha Qube", "Alpha Cam");
axis([0 height(data) -0.03 0.03])
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
        alphaButterworthFilter = zeros(samples, 1);

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

            alphaButterworthFilter(i) =  y(1);

        end

        [c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaButterworthFilter(data.camControl==0), 5, 'normalized');
        corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaButterworthFilter(data.camControl==0));
        
        maxCorr = -1;
        maxCorrInd = 0;
        
        zeroLagCCor = c(lags==0);
        
        for i = 1:length(c)
            if c(i) > maxCorr
                maxCorr = c(i);
                maxCorrInd = i;
            end            
        end
        
        if zeroLagCCor + corcoefAlpha(2,1) + maxCorr > bestCor
            bestCor = zeroLagCCor + corcoefAlpha(2,1) + maxCorr;
            bestCorOr = or;
            bestCorFc = fc;            
        end
        
        if printAll
            fprintf('Max butterworth alpha correlation for order %i CO %iHz is %f at lag %d. ' , or, fc, maxCorr, lags(maxCorrInd));
            fprintf('Cor Coef is %f.\n' , corcoefAlpha(2,1));
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
alphaButterworthFilter = zeros(samples, 1);

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

    alphaButterworthFilter(i) =  y(1);

end

corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaButterworthFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaButterworthFilter(data.camControl==0), 5, 'normalized');
figure(3);
stem(lags, c);

fprintf('Best butterworth alpha has order %i cutoff %iHz with a sum of %f in relevant correlations.\n' , or, fc, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlpha(2,1), c(lags==0), max(c), lags(c==max(c)));
b
a

figure(4);
hold on
plot(data.alphaQube);
plot(alphaButterworthFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("Alpha Qube", "Alpha Butterworth");
axis([0 height(data) -0.03 0.03])
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
    alphaCustomFilter = zeros(samples, 1);

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

        alphaCustomFilter(i) =  y(1);

    end

    [c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaCustomFilter(data.camControl==0), 5, 'normalized');
    corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaCustomFilter(data.camControl==0));
        
    maxCorr = -1;
    maxCorrInd = 0;
    
    zeroLagCCor = c(lags==0);

    for i = 1:length(c)
        if c(i) > maxCorr
            maxCorr = c(i);
            maxCorrInd = i;
        end    
    end
    
    if zeroLagCCor + corcoefAlpha(2,1) + maxCorr > bestCor
        bestCor = zeroLagCCor + corcoefAlpha(2,1) + maxCorr;
        bestCorDenom = denom;          
    end
    
    if printAll
        fprintf('Max custom alpha correlation for denom %i is %f at lag %d. ' , denom, maxCorr, lags(maxCorrInd));
        fprintf('Cor Coef is %f.\n' , corcoefAlpha(2,1));
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
alphaCustomFilter = zeros(samples, 1);

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

    alphaCustomFilter(i) =  y(1);

end

corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaCustomFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaCustomFilter(data.camControl==0), 5, 'normalized');
figure(5);
stem(lags, c);

fprintf('Best custom alpha has denom %i with a sum of %f in relevant correlations.\n' , denom, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlpha(2,1), c(lags==0), max(c), lags(c==max(c)));
b
a

figure(6);
hold on
plot(data.alphaQube);
plot(alphaCustomFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("Alpha Qube", "Alpha Custom");
axis([0 height(data) -0.03 0.03])
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
            alphaCheb1Filter = zeros(samples, 1);

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

                alphaCheb1Filter(i) =  y(1);

            end

            [c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaCheb1Filter(data.camControl==0), 5, 'normalized');
            corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaCheb1Filter(data.camControl==0));

            maxCorr = -1;
            maxCorrInd = 1;
            
            zeroLagCCor = c(lags==0);

            for i = 1:length(c)
                if c(i) > maxCorr
                    maxCorr = c(i);
                    maxCorrInd = i;
                end    
            end
            
            if zeroLagCCor + corcoefAlpha(2,1) + maxCorr > bestCor
                bestCor = zeroLagCCor + corcoefAlpha(2,1) + maxCorr;
                bestCorOr = or;
                bestCorFc = fc;
                bestCorRipple = rip;
            end
            
            if printAll
                fprintf('Max Chebyshev1 alpha correlation for order %i, CO %iHz, ripple %i is %f at lag %d. ' , or, fc, rip, maxCorr, lags(maxCorrInd));
                fprintf('Cor Coef is %f.\n' , corcoefAlpha(2,1));
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
alphaCheb1Filter = zeros(samples, 1);

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

    alphaCheb1Filter(i) =  y(1);

end

corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaCheb1Filter(data.camControl==0));
[c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaCheb1Filter(data.camControl==0), 5, 'normalized');
figure(7);
stem(lags, c);

fprintf('Best Cheby1 alpha has order %i, cutoff %iHz, rip %i with a sum of %f in relevant correlations.\n' , or, fc, rip, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlpha(2,1), c(lags==0), max(c), lags(c==max(c)));
b
a

figure(8);
hold on
plot(data.alphaQube);
plot(alphaCheb1Filter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("Alpha Qube", "Alpha Cheb1");
axis([0 height(data) -0.03 0.03])
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
            alphaCheb2Filter = zeros(samples, 1);

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

                alphaCheb2Filter(i) =  y(1);

            end

            [c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaCheb2Filter(data.camControl==0), 5, 'normalized');
            corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaCheb2Filter(data.camControl==0));

            maxCorr = -1;
            maxCorrInd = 1;
            
            zeroLagCCor = c(lags==0);

            for i = 1:length(c)
                if c(i) > maxCorr
                    maxCorr = c(i);
                    maxCorrInd = i;
                end    
            end
            
            if zeroLagCCor + corcoefAlpha(2,1) + maxCorr > bestCor
                bestCor = zeroLagCCor + corcoefAlpha(2,1) + maxCorr;
                bestCorOr = or;
                bestCorFc = fc;
                bestCorAtten = atten;
            end
            
            if printAll
                fprintf('Max Chebyshev2 alpha correlation for order %i, CO %iHz, atten %i is %f at lag %d. ' , or, fc, atten, maxCorr, lags(maxCorrInd));
                fprintf('Cor Coef is %f.\n' , corcoefAlpha(2,1));
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
alphaCheb2Filter = zeros(samples, 1);

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

    alphaCheb2Filter(i) =  y(1);

end

corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaCheb2Filter(data.camControl==0));
[c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaCheb2Filter(data.camControl==0), 5, 'normalized');
figure(9);
stem(lags, c);

fprintf('Best Cheby2 alpha has order %i, cutoff %iHz, atten %i with a sum of %f in relevant correlations.\n' , or, fc, atten, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlpha(2,1), c(lags==0), max(c), lags(c==max(c)));
b
a

figure(10);
hold on
plot(data.alphaQube);
plot(alphaCheb2Filter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("Alpha Qube", "Alpha Cheb2");
axis([0 height(data) -0.03 0.03])
grid on
hold off  

%% Elliptic filters
fs = 100;

orArray = [2,3,4,5,6];
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

                [c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaEllipFilter(data.camControl==0), 5, 'normalized');
                corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaEllipFilter(data.camControl==0));

                maxCorr = -1;
                maxCorrInd = 1;
                
                zeroLagCCor = c(lags==0);

                for i = 1:length(c)
                    if c(i) > maxCorr
                        maxCorr = c(i);
                        maxCorrInd = i;
                    end    
                end
                
                if zeroLagCCor + corcoefAlpha(2,1) + maxCorr > bestCor
                    bestCor = zeroLagCCor + corcoefAlpha(2,1) + maxCorr;
                    bestCorOr = or;
                    bestCorFc = fc;
                    bestCorAtten = atten;
                    bestCorRipple = rip;
                end
                
                if printAll
                    fprintf('Max Ellip alpha correlation for order %i, CO %iHz, atten %i, rip %i is %f at lag %d. ' , or, fc, atten, rip, maxCorr, lags(maxCorrInd));
                    fprintf('Cor Coef is %f.\n' , corcoefAlpha(2,1));
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

corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaEllipFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaEllipFilter(data.camControl==0), 5, 'normalized');
figure(11);
stem(lags, c);

fprintf('Best Elliptical alpha has order %i, cutoff %iHz, rip %i, atten %i with a sum of %f in relevant correlations.\n' , or, fc, rip, atten, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlpha(2,1), c(lags==0), max(c), lags(c==max(c)));
b
a

figure(12);
hold on
plot(data.alphaQube);
plot(alphaEllipFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("Alpha Qube", "Alpha Elliptical");
axis([0 height(data) -0.03 0.03])
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
        alphaFIRLSFilter = zeros(samples, 1);

        x = zeros(1, or + 1);
        

        for i = 1:samples
            y = 0;
            
            for n = or+1:-1:2
                x(n) = x(n-1);
            end

            x(1) = data.alphaCam(i);

            for n = or+1:-1:1
                y = y + b(n) * x(n);     
            end

            alphaFIRLSFilter(i) =  y;

        end

        [c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaFIRLSFilter(data.camControl==0), 5, 'normalized');
        corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaFIRLSFilter(data.camControl==0));

        maxCorr = -1;
        maxCorrInd = 1;
        
        zeroLagCCor = c(lags==0);

        for i = 1:length(c)
            if c(i) > maxCorr
                maxCorr = c(i);
                maxCorrInd = i;
            end    
        end
        
        if zeroLagCCor + corcoefAlpha(2,1) + maxCorr > bestCor
            bestCor = zeroLagCCor + corcoefAlpha(2,1) + maxCorr;
            bestCorOr = or;
            bestCorFc = fc;            
        end
        
        if printAll
            fprintf('Max FIRLS alpha correlation for order %i, CO %iHz, is %f at lag %d. ' , or, fc, maxCorr, lags(maxCorrInd));
            fprintf('Cor Coef is %f.\n' , corcoefAlpha(2,1));
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
alphaFIRLSFilter = zeros(samples, 1);

x = zeros(1, or + 1);

for i = 1:samples
    
    y = 0;
    
    for n = or+1:-1:2
        x(n) = x(n-1);
    end

    x(1) = data.alphaCam(i);

    for n = or+1:-1:1
        y = y + b(n) * x(n);     
    end

    alphaFIRLSFilter(i) =  y;

end

corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaFIRLSFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaFIRLSFilter(data.camControl==0), 5, 'normalized');
figure(13);
stem(lags, c);

fprintf('Best FIR LS alpha has order %i cutoff %iHz with a sum of %f in relevant correlations.\n' , or, fc, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlpha(2,1), c(lags==0), max(c), lags(c==max(c)));
b

figure(14);
hold on
plot(data.alphaQube);
plot(alphaFIRLSFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("Alpha Qube", "Alpha FIR LS");
axis([0 height(data) -0.03 0.03])
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
        alphaFIRPMFilter = zeros(samples, 1);

        x = zeros(1, or + 1);
        

        for i = 1:samples
            y = 0;
            
            for n = or+1:-1:2
                x(n) = x(n-1);
            end

            x(1) = data.alphaCam(i);

            for n = or+1:-1:1
                y = y + b(n) * x(n);     
            end

            alphaFIRPMFilter(i) =  y;

        end

        [c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaFIRPMFilter(data.camControl==0), 5, 'normalized');
        corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaFIRPMFilter(data.camControl==0));

        maxCorr = -1;
        maxCorrInd = 1;
        
        zeroLagCCor = c(lags==0);

        for i = 1:length(c)
            if c(i) > maxCorr
                maxCorr = c(i);
                maxCorrInd = i;
            end    
        end
        
        if zeroLagCCor + corcoefAlpha(2,1) + maxCorr > bestCor
            bestCor = zeroLagCCor + corcoefAlpha(2,1) + maxCorr;
            bestCorOr = or;
            bestCorFc = fc;            
        end
        
        if printAll
            fprintf('Max FIRPM alpha correlation for order %i, CO %iHz, is %f at lag %d. ' , or, fc, maxCorr, lags(maxCorrInd));
            fprintf('Cor Coef is %f.\n' , corcoefAlpha(2,1));
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
alphaFIRPMFilter = zeros(samples, 1);

x = zeros(1, or + 1);


for i = 1:samples
    
    y = 0;
    
    for n = or+1:-1:2
        x(n) = x(n-1);
    end

    x(1) = data.alphaCam(i);

    for n = or+1:-1:1
        y = y + b(n) * x(n);     
    end

    alphaFIRPMFilter(i) =  y;

end

corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaFIRPMFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaFIRPMFilter(data.camControl==0), 5, 'normalized');
figure(15);
stem(lags, c);

fprintf('Best FIR PM alpha has order %i cutoff %iHz with a sum of %f in relevant correlations.\n' , or, fc, bestCor);
fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlpha(2,1), c(lags==0), max(c), lags(c==max(c)));
b

figure(16);
hold on
plot(data.alphaQube);
plot(alphaFIRPMFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("Alpha Qube", "Alpha FIR PM");
axis([0 height(data) -0.03 0.03])
grid on
hold off  

%% Noise gate test

alphaEllipGateFilter = alphaEllipFilter;
noiseGate = 0.004;

for i = 1:samples
    if abs(alphaEllipGateFilter(i)) < noiseGate
        alphaEllipGateFilter(i) = 0;
    end
end

corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), alphaEllipGateFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaEllipGateFilter(data.camControl==0), 5, 'normalized');
figure(17);
stem(lags, c);

fprintf('GateEllipsoid: CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.\n' , corcoefAlpha(2,1), c(lags==0), max(c), lags(c==max(c)));

figure(18);
hold on
plot(data.alphaQube);
plot(alphaEllipGateFilter);
h = zoom;
set(h,'Motion','horizontal','Enable','on');
legend("Alpha Qube", "Alpha GatedEllipsoid");
axis([0 height(data) -0.03 0.03])
grid on
hold off 
