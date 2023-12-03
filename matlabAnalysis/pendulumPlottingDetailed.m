close all;

log = 'data230626singlePhase.log';
dir = strcat(pwd, '\logs\', log);

data = readtable(dir, 'Delimiter', ';');

%Center alphaCube - it is usually biassed
K = [-1.000000, -1.661800, 36.745900, -1.622700, 3.242100];

covAlpha = cov(data.alphaQube(data.camControl==0), data.alphaCam(data.camControl==0));
corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), data.alphaCam(data.camControl==0));

covAlphaDot = cov(data.alphaDotQube(data.camControl==0), data.alphaDotCam(data.camControl==0));
corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), data.alphaDotCam(data.camControl==0));

%% LP Alpha Filters
n = 0;
samples = height(data);
alphaLowP2 = zeros(samples, 1);
average = 0.0;
xAvPoints = 2;

for i = 1:samples
    if n < xAvPoints
        n = n+1;
    end
    average = average + (data.alphaCam(i) - average) / n;
    alphaLowP2(i) =  average;
end

n = 0;
samples = height(data);
alphaLowP3 = zeros(samples, 1);
average = 0.0;
xAvPoints = 3;

for i = 1:samples
    if n < xAvPoints
        n = n+1;
    end
    average = average + (data.alphaCam(i) - average) / n;
    alphaLowP3(i) =  average;
end

covAlphaLP2 = cov(data.alphaQube(data.camControl==0), alphaLowP2(data.camControl==0));
corcoefAlphaLP2 = corrcoef(data.alphaQube(data.camControl==0), alphaLowP2(data.camControl==0));
covAlphaLP3 = cov(data.alphaQube(data.camControl==0), alphaLowP3(data.camControl==0));
corcoefAlphaLP3 = corrcoef(data.alphaQube(data.camControl==0), alphaLowP3(data.camControl==0));

alphaDotLowP2 = zeros(samples, 1);
alphaDotLowP3 = zeros(samples, 1);

frequency = 150;

alphaDotLowP2(1) = alphaLowP2(1) * frequency;
alphaDotLowP3(1) = alphaLowP3(1) * frequency;

for i = 2:samples
    alphaDotLowP2(i) = (alphaLowP2(i) - alphaLowP2(i-1)) * frequency;
    alphaDotLowP3(i) = (alphaLowP3(i) - alphaLowP3(i-1)) * frequency;  
end

covAlphaDotLP2 = cov(data.alphaDotQube(data.camControl==0), alphaDotLowP2(data.camControl==0));
corcoefAlphaDotLP2 = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotLowP2(data.camControl==0));
covAlphaDotLP3 = cov(data.alphaDotQube(data.camControl==0), alphaDotLowP3(data.camControl==0));
corcoefAlphaDotLP3 = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotLowP3(data.camControl==0));

KxLowP2 = zeros(samples, 1);
KxLowP3 = zeros(samples, 1);

for i = 1:samples
    KxLowP2(i) = data.z(i) * K(1) + data.thetaQube(i) * K(2) + alphaLowP2(i) * K(3) + data.thetaDotQube(i) * K(4) + alphaDotLowP2(i) * K(5);
    KxLowP3(i) = data.z(i) * K(1) + data.thetaQube(i) * K(2) + alphaLowP3(i) * K(3) + data.thetaDotQube(i) * K(4) + alphaDotLowP3(i) * K(5);
end

covV = cov(data.Kx(data.camControl==0), data.KxCam(data.camControl==0));
corcoefV = corrcoef(data.Kx(data.camControl==0), data.KxCam(data.camControl==0));
covVLP2 = cov(data.Kx(data.camControl==0), KxLowP2(data.camControl==0));
corcoefVLP2 = corrcoef(data.Kx(data.camControl==0), KxLowP2(data.camControl==0));
covVLP3 = cov(data.Kx(data.camControl==0), KxLowP3(data.camControl==0));
corcoefVLP3 = corrcoef(data.Kx(data.camControl==0), KxLowP3(data.camControl==0));

%Alpha Dot filters
n = 0;
samples = height(data);
alphaDotDirectLowP2 = zeros(samples, 1);
average = 0.0;
xAvPoints = 2;

for i = 1:samples
    if n < xAvPoints
        n = n+1;
    end
    average = average + (data.alphaDotCam(i) - average) / n;
    alphaDotDirectLowP2(i) =  average;
end

n = 0;
samples = height(data);
alphaDotDirectHighP2 = zeros(samples, 1);
average = 0.0;
xAvPoints = 2;

for i = 1:samples
    if n < xAvPoints
        n = n+1;
    end
    average = average + (data.alphaDotCam(i) - average) / n;
    alphaDotDirectHighP2(i) =  data.alphaDotCam(i) - average;
end

n = 0;
samples = height(data);
alphaDotDirectHighP3 = zeros(samples, 1);
average = 0.0;
xAvPoints = 3;

for i = 1:samples
    if n < xAvPoints
        n = n+1;
    end
    average = average + (data.alphaDotCam(i) - average) / n;
    alphaDotDirectHighP3(i) =  data.alphaDotCam(i) - average;
end

covAlphaDotDirectLowP2 = cov(data.alphaDotQube(data.camControl==0), alphaDotDirectLowP2(data.camControl==0));
corcoefAlphaDotDirectLowP2 = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotDirectLowP2(data.camControl==0));
covAlphaDotDirectHighP2 = cov(data.alphaDotQube(data.camControl==0), alphaDotDirectHighP2(data.camControl==0));
corcoefAlphaDotDirectHighP2 = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotDirectHighP2(data.camControl==0));
covAlphaDotDirectHighP3 = cov(data.alphaDotQube(data.camControl==0), alphaDotDirectHighP3(data.camControl==0));
corcoefAlphaDotDirectHighP3 = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotDirectHighP3(data.camControl==0));

%True 2 point MA
n = 0;
samples = height(data);
alpha2PMA = zeros(samples, 1);
xAvPoints = 2;

for i = 1:samples
    average = 0.0;
    
    if n < xAvPoints
        n = n+1;
    end
    
    for j = i-n+1:i
        average = average + data.alphaCam(j);
    end
    average = average / n;
    alpha2PMA(i) =  average;
end

covAlpha2PMA = cov(data.alphaQube(data.camControl==0), alpha2PMA(data.camControl==0));
corcoefAlpha2PMA = corrcoef(data.alphaQube(data.camControl==0), alpha2PMA(data.camControl==0));


%True 3 point MA
n = 0;
samples = height(data);
alpha3PMA = zeros(samples, 1);
xAvPoints = 3;

for i = 1:samples
    average = 0.0;
    
    if n < xAvPoints
        n = n+1;
    end
    
    for j = i-n+1:i
        average = average + data.alphaCam(j);
    end
    average = average / n;
    alpha3PMA(i) =  average;
end

covAlpha3PMA = cov(data.alphaQube(data.camControl==0), alpha3PMA(data.camControl==0));
corcoefAlpha3PMA = corrcoef(data.alphaQube(data.camControl==0), alpha3PMA(data.camControl==0));

%True -2 point MA
n = 0;
samples = height(data);
alphaDotDirect2PMAHP = zeros(samples, 1);
xAvPoints = 2;

for i = 1:samples
    average = 0.0;
    
    if n < xAvPoints
        n = n+1;
    end
    
    for j = i-n+1:i
        average = average + data.alphaDotCam(j);
    end
    average = average / n;
    alphaDotDirect2PMAHP(i) =  data.alphaDotCam(i) - average;
end

covAlphaDotDirect2PMAHP = cov(data.alphaDotQube(data.camControl==0), alphaDotDirect2PMAHP(data.camControl==0));
corcoefAlphaDotDirect2PMAHP = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotDirect2PMAHP(data.camControl==0));

%True -3 point MA
n = 0;
samples = height(data);
alphaDotDirect3PMAHP = zeros(samples, 1);
xAvPoints = 3;

for i = 1:samples
    average = 0.0;
    
    if n < xAvPoints
        n = n+1;
    end
    
    for j = i-n+1:i
        average = average + data.alphaDotCam(j);
    end
    average = average / n;
    alphaDotDirect3PMAHP(i) =  data.alphaDotCam(i) - average;
end

covAlphaDotDirect3PMAHP = cov(data.alphaDotQube(data.camControl==0), alphaDotDirect3PMAHP(data.camControl==0));
corcoefAlphaDotDirect3PMAHP = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotDirect3PMAHP(data.camControl==0));

alphaDotDerivedHP = data.alphaDotCam - alphaDotLowP3;
covAlphaDotDerivedHP = cov(data.alphaDotQube(data.camControl==0), alphaDotDerivedHP(data.camControl==0));
corcoefAlphaDotDerivedHP = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotDerivedHP(data.camControl==0));

%% Further AlphaDot filters

n = 0;
samples = height(data);
alphaDotDirectLowP3 = zeros(samples, 1);
average = 0.0;
xAvPoints = 3;

for i = 1:samples
    if n < xAvPoints
        n = n+1;
    end
    average = average + (data.alphaDotCam(i) - average) / n;
    alphaDotDirectLowP3(i) =  average;
end

n = 0;
samples = height(data);
alphaDotDirectLowP4 = zeros(samples, 1);
average = 0.0;
xAvPoints = 4;

for i = 1:samples
    if n < xAvPoints
        n = n+1;
    end
    average = average + (data.alphaDotCam(i) - average) / n;
    alphaDotDirectLowP4(i) =  average;
end

n = 0;
samples = height(data);
alphaDotDirectLowP5 = zeros(samples, 1);
average = 0.0;
xAvPoints = 5;

for i = 1:samples
    if n < xAvPoints
        n = n+1;
    end
    average = average + (data.alphaDotCam(i) - average) / n;
    alphaDotDirectLowP5(i) =  average;
end

covAlphaDotDirectLowP3 = cov(data.alphaDotQube(data.camControl==0), alphaDotDirectLowP3(data.camControl==0));
corcoefAlphaDotDirectLowP3 = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotDirectLowP3(data.camControl==0));
covAlphaDotDirectLowP4 = cov(data.alphaDotQube(data.camControl==0), alphaDotDirectLowP4(data.camControl==0));
corcoefAlphaDotDirectLowP4 = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotDirectLowP4(data.camControl==0));
covAlphaDotDirectLowP5 = cov(data.alphaDotQube(data.camControl==0), alphaDotDirectLowP5(data.camControl==0));
corcoefAlphaDotDirectLowP5 = corrcoef(data.alphaDotQube(data.camControl==0), alphaDotDirectLowP5(data.camControl==0));


%% Summary
fprintf('Alpha Filters Correlation Coefficient vs. AlphaQube\n')
fprintf('AlphaCam %f\n' ,corcoefAlpha(1,2))
fprintf('AlphaCam 2PMA %f\n' ,corcoefAlpha2PMA(1,2))
fprintf('AlphaCam 3PMA %f\n' ,corcoefAlpha3PMA(1,2))
fprintf('AlphaCam LP2 %f\n' ,corcoefAlphaLP2(1,2))
fprintf('AlphaCam LP3 %f\n' ,corcoefAlphaLP3(1,2))

fprintf('\nAlpha Dot Filters Correlation Coefficient vs. AlphaQube\n')
fprintf('AlphaDotCam %f\n' , corcoefAlphaDot(1,2))
fprintf('AlphaDotCam LP2 Nested %f\n' , corcoefAlphaDotLP2(1,2))
fprintf('AlphaDotCam LP3 Nested %f\n' , corcoefAlphaDotLP3(1,2))
fprintf('AlphaDotCam Direct HP2 %f\n' , corcoefAlphaDotDirectHighP2(1,2))
fprintf('AlphaDotCam Direct HP3 %f\n' , corcoefAlphaDotDirectHighP3(1,2))
fprintf('AlphaDotCam Direct LP2 %f\n' , corcoefAlphaDotDirectLowP2(1,2))
fprintf('AlphaDotCam Direct 2PMAHP %f\n' , corcoefAlphaDotDirect2PMAHP(1,2))
fprintf('AlphaDotCam Direct 3PMAHP %f\n' , corcoefAlphaDotDirect3PMAHP(1,2))
fprintf('AlphaDotCam Direct Derived HP %f\n' , corcoefAlphaDotDerivedHP(1,2))
fprintf('AlphaDotCam Direct LP3 %f\n' , corcoefAlphaDotDirectLowP3(1,2))
fprintf('AlphaDotCam Direct LP4 %f\n' , corcoefAlphaDotDirectLowP4(1,2))
fprintf('AlphaDotCam Direct LP5 %f\n' , corcoefAlphaDotDirectLowP5(1,2))

KxALP3ADHP2 = zeros(samples, 1);
KxALP3ADNorm = zeros(samples, 1);
KxANormADHP2 = zeros(samples, 1);
KxANormADNorm = zeros(samples, 1);
KxANormADQube = zeros(samples, 1);
KxAQubeADNorm = zeros(samples, 1);

for i = 1:samples
    KxALP3ADHP2(i) = data.z(i) * K(1) + data.thetaQube(i) * K(2) + alphaLowP3(i) * K(3) + data.thetaDotQube(i) * K(4) + alphaDotDirectHighP2(i) * K(5);
    KxALP3ADNorm(i) = data.z(i) * K(1) + data.thetaQube(i) * K(2) + alphaLowP3(i) * K(3) + data.thetaDotQube(i) * K(4) + data.alphaDotCam(i) * K(5);
    KxANormADHP2(i) = data.z(i) * K(1) + data.thetaQube(i) * K(2) + data.alphaCam(i) * K(3) + data.thetaDotQube(i) * K(4) + alphaDotDirectHighP2(i) * K(5);
    KxANormADNorm(i) = data.z(i) * K(1) + data.thetaQube(i) * K(2) + data.alphaCam(i) * K(3) + data.thetaDotQube(i) * K(4) + data.alphaDotCam(i) * K(5);
    KxANormADQube(i) = data.z(i) * K(1) + data.thetaQube(i) * K(2) + data.alphaCam(i) * K(3) + data.thetaDotQube(i) * K(4) + data.alphaDotQube(i) * K(5);
    KxAQubeADNorm(i) = data.z(i) * K(1) + data.thetaQube(i) * K(2) + data.alphaQube(i) * K(3) + data.thetaDotQube(i) * K(4) + data.alphaDotCam(i) * K(5);
end

covVALP3ADHP2 = cov(data.Kx(data.camControl==0), KxALP3ADHP2(data.camControl==0));
corcoefVALP3ADHP2 = corrcoef(data.Kx(data.camControl==0), KxALP3ADHP2(data.camControl==0));
covVALP3ADNorm = cov(data.Kx(data.camControl==0), KxALP3ADNorm(data.camControl==0));
corcoefVALP3ADNorm = corrcoef(data.Kx(data.camControl==0), KxALP3ADNorm(data.camControl==0));
covVANormADHP2 = cov(data.Kx(data.camControl==0), KxANormADHP2(data.camControl==0));
corcoefVANormADHP2 = corrcoef(data.Kx(data.camControl==0), KxANormADHP2(data.camControl==0));
covVANormADNorm = cov(data.Kx(data.camControl==0), KxANormADNorm(data.camControl==0));
corcoefVANormADNorm = corrcoef(data.Kx(data.camControl==0), KxANormADNorm(data.camControl==0));
covVANormADQube = cov(data.Kx(data.camControl==0), KxANormADQube(data.camControl==0));
corcoefVANormADQube = corrcoef(data.Kx(data.camControl==0), KxANormADQube(data.camControl==0));
covVAQubeADNorm = cov(data.Kx(data.camControl==0), KxAQubeADNorm(data.camControl==0));
corcoefVAQubeADNorm = corrcoef(data.Kx(data.camControl==0), KxAQubeADNorm(data.camControl==0));

fprintf('\nVoltage Correlation Coefficient vs. VQube\n')
fprintf('V raw %f\n' ,corcoefV(1,2))
fprintf('V ALP3ADHP2 %f\n' ,covVALP3ADNorm(1,2))
fprintf('V ALP3ADCam %f\n' ,corcoefVALP3ADNorm(1,2))
fprintf('V ACamADHP2 %f\n' ,corcoefVANormADHP2(1,2))
fprintf('V ACamADCam %f\n' ,corcoefVANormADNorm(1,2))
fprintf('V ACamADQube %f\n' ,corcoefVANormADQube(1,2))
fprintf('V AQubeADCam %f\n' ,corcoefVAQubeADNorm(1,2))
fprintf('V LP3 %f\n' ,corcoefVLP3(1,2))

fprintf('\n Two dots found in %f%% of frames before cam control\n', sum(data.twoDotCheck(data.camControl==0))/length(data.twoDotCheck(data.camControl==0)))

%% Plots
%{
figure(1);
hold on
plot(data.alphaCam);
plot(data.alphaQube);
legend("Alpha Cam", "AlphaQube");
axis([0 height(data) -0.03 0.03])
grid on
hold off

figure(2);
hold on
plot(data.KxCam);
plot(data.Kx);
legend("V Cam", "V Qube");
axis([0 height(data) -10 10])
grid on
hold off

figure(3);
hold on
plot(data.alphaDotCam);
plot(data.alphaDotQube);
legend("AlphaDotCam", "AlphaDotQube");
axis([0 height(data) -3 3])
grid on
hold off

figure(4);
hold on
plot(alphaLowP3);
plot(data.alphaQube);
legend("Alpha Cam LP 3", "AlphaQube");
axis([0 height(data) -0.03 0.03])
grid on
hold off

figure(5);
hold on
plot(alphaDotLowP2);
plot(data.alphaDotQube);
legend("AlphaDotCamLP2", "AlphaDotQube");
axis([0 height(data) -3 3])
grid on
hold off

figure(6);
hold on
plot(alphaDotLowP3);
plot(data.alphaDotQube);
legend("AlphaDotCamLP3", "AlphaDotQube");
axis([0 height(data) -3 3])
grid on
hold off

figure(7);
hold on
plot(KxLowP2);
plot(data.Kx);
legend("V LP2", "V Qube");
axis([0 height(data) -10 10])
grid on
hold off

figure(8);
hold on
plot(KxLowP3);
plot(data.Kx);
legend("V LP3", "V Qube");
axis([0 height(data) -10 10])
grid on
hold off
%}
figure(9);
hold on
plot(alphaDotDirectLowP4);
plot(data.alphaDotQube);
legend("AlphaDotCamDirectLP4", "AlphaDotQube");
axis([0 height(data) -3 3])
grid on
hold off


%% Frequency analysis
alphaFreq = fft(data.alphaQube(data.camControl==0));
alphaCamFreq = fft(data.alphaCam(data.camControl==0));
Fs = 75;
T = 1/Fs;
L = length(data.alphaDotQube(data.camControl==0));

%{
f = linspace(0, Fs, length(data.alphaQube(data.camControl==0)));
figure(10)
subplot(2,1,1)
plot(f, abs(alphaFreq/L))
subplot(2,1,2)
plot(f, abs(alphaCamFreq/L))

alphaDotFreq = fft(data.alphaDotQube(data.camControl==0));
alphaDotCamFreq = fft(data.alphaDotCam(data.camControl==0));
Fs = 75;
f = linspace(0, Fs, length(data.alphaDotQube(data.camControl==0)));
figure(11)
subplot(2,1,1)
plot(f, abs(alphaDotFreq/L))
subplot(2,1,2)
plot(f, abs(alphaDotCamFreq/L))
%}


%% More IIR filters

n = 0;
samples = height(data);
alphaDotDirectLowPIRR = zeros(samples, 1);
average = 0.0;
xAvPoints = 4;

averageLast = [0,0,0];

for i = 1:samples
    if n < xAvPoints
        n = n+1;
    end
    
    averageLast(3) = averageLast(2);
    averageLast(2) = averageLast(1);    
    averageLast(1) = 1/5 * data.alphaDotCam(i) + 3/5 * averageLast(2) + 1/5 * averageLast(3);
    alphaDotDirectLowPIRR(i) =  averageLast(1);
    
end

%{
figure(21);
hold on
plot(alphaDotDirectLowPIRR);
plot(data.alphaDotQube);
legend("AlphaDotCamDirectLPIRR", "AlphaDotQube");
axis([0 height(data) -3 3])
grid on
hold off

[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotDirectLowPIRR(data.camControl==0), 15, 'normalized');
figure(22);
stem(lags, c);
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotDirectLowP4(data.camControl==0), 15, 'normalized');
figure(23);
stem(lags, c);
%}

%% Butterworth filter design
fs = 150;

orArray = [1,2,3,4,5,6];
fcArray = [10, 15, 20, 25, 30, 35, 40, 45];

for loopOr = 1:length(orArray)
    for loopFc = 1:length(fcArray)

        fc = fcArray(loopFc);
        or = orArray(loopOr);
        [b,a] = butter(or, fc/(fs/2));

        %Test filter
        n = 0;
        samples = height(data);
        alphaDotDirectLowDesignFilter = zeros(samples, 1);

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

            alphaDotDirectLowDesignFilter(i) =  y(1);

        end

        [c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotDirectLowDesignFilter(data.camControl==0), 15, 'normalized');

        maxCorr = 0;
        maxCorrInd = 0;

        for i = 1:length(c)
            if c(i) > maxCorr
                maxCorr = c(i);
                maxCorrInd = i;
            end    
        end

        fprintf('Max correlation for order %i CO %iHz is %f at lag %d\n' , or, fc, maxCorr, lags(maxCorrInd));

    end
end


%Chosen filter
fc = 15;
or = 3;
[b,a] = butter(or, fc/(fs/2));

%Test filter
n = 0;
samples = height(data);
alphaDotDirectLowDesignFilter = zeros(samples, 1);

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

    alphaDotDirectLowDesignFilter(i) =  y(1);

end

[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), alphaDotDirectLowDesignFilter(data.camControl==0), 15, 'normalized');

figure(24);
hold on
plot(alphaDotDirectLowDesignFilter);
plot(data.alphaDotQube);
legend("AlphaDotCamButterworth", "AlphaDotQube");
axis([0 height(data) -3 3])
grid on
hold off

figure(25);
stem(lags, c);

a
b


%% Alpha Filters
fs = 150;

orArray = [1,2,3,4,5,6];
fcArray = [10, 15, 20, 25, 30, 35, 40, 45];

for loopOr = 1:length(orArray)
    for loopFc = 1:length(fcArray)

        fc = fcArray(loopFc);
        or = orArray(loopOr);
        [b,a] = butter(or, fc/(fs/2));

        %Test filter
        n = 0;
        samples = height(data);
        alphaDirectLowDesignFilter = zeros(samples, 1);

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

            alphaDirectLowDesignFilter(i) =  y(1);

        end

        [c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaDirectLowDesignFilter(data.camControl==0), 15, 'normalized');

        maxCorr = -1;
        maxCorrInd = 0;

        for i = 1:length(c)
            if c(i) > maxCorr
                maxCorr = c(i);
                maxCorrInd = i;
            end    
        end

        fprintf('Max alpha correlation for order %i CO %iHz is %f at lag %d\n' , or, fc, maxCorr, lags(maxCorrInd));

    end
end


%Chosen filter
fc = 10;
or = 1;
[b,a] = butter(or, fc/(fs/2));

%Test filter
n = 0;
samples = height(data);
alphaDirectLowDesignFilter = zeros(samples, 1);

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

    alphaDirectLowDesignFilter(i) =  y(1);

end

[c,lags] = xcorr(data.alphaQube(data.camControl==0), alphaDirectLowDesignFilter(data.camControl==0), 15, 'normalized');

figure(26);
hold on
plot(alphaDirectLowDesignFilter);
plot(data.alphaQube);
legend("AlphaCamButterworth", "AlphaQube");
axis([0 height(data) -0.3 0.3])
grid on
hold off

figure(27);
stem(lags, c);

[c,lags] = xcorr(data.alphaCam(data.camControl==0), data.alphaQube(data.camControl==0), 15, 'normalized');
figure(28);
stem(lags, c);

a
b