close all;

log = 'data230621b.log';
dir = strcat(pwd, '\logs\', log);

data = readtable(dir, 'Delimiter', ';');

%Error before 14.06 in Alpha Dot calculation
%data.alphaDotCam = data.alphaDotCam * 7.25 / 9.98;

K = [-1.000000, -1.661800, 36.745900, -1.622700, 3.242100];

figure(1);
hold on
plot(data.alphaCam);
plot(data.alphaQube);
legend("Alpha Cam", "AlphaQube");
axis([0 height(data) -0.03 0.03])
grid on
hold off

%figure(2);
%hold on
%plot(data.KxCam);
%plot(data.Kx);
%legend("V Cam", "V Qube");
%axis([0 height(data) -10 10])
%grid on
%hold off

%figure(3);
%hold on
%plot(data.alphaQube, data.alphaCam, '.');
%xlabel('AlphaQube');
%ylabel('AlphaCam');
%grid on
%hold off

covAlpha = cov(data.alphaQube(data.camControl==0), data.alphaCam(data.camControl==0));
corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), data.alphaCam(data.camControl==0));

figure(4);
hold on
plot(data.alphaDotCam);
plot(data.alphaDotQube);
legend("AlphaDotCam", "AlphaDotQube");
axis([0 height(data) -3 3])
grid on
hold off

%figure(5);
%hold on
%plot(data.alphaDotQube, data.alphaDotCam, '.');
%xlabel('AlphaDotQube');
%ylabel('AlphaDotCam');
%grid on
%hold off

covAlphaDot = cov(data.alphaDotQube(data.camControl==0), data.alphaDotCam(data.camControl==0));
corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), data.alphaDotCam(data.camControl==0));

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

%figure(6);
%hold on
%plot(alphaLowP2);
%plot(data.alphaQube);
%legend("Alpha Cam LP 2", "AlphaQube");
%axis([0 height(data) -0.03 0.03])
%grid on
%hold off

figure(7);
hold on
plot(alphaLowP3);
plot(data.alphaQube);
legend("Alpha Cam LP 3", "AlphaQube");
axis([0 height(data) -0.03 0.03])
grid on
hold off

covAlphaLP2 = cov(data.alphaQube(data.camControl==0), alphaLowP2(data.camControl==0));
corcoefAlphaLP2 = corrcoef(data.alphaQube(data.camControl==0), alphaLowP2(data.camControl==0));
covAlphaLP3 = cov(data.alphaQube(data.camControl==0), alphaLowP3(data.camControl==0));
corcoefAlphaLP3 = corrcoef(data.alphaQube(data.camControl==0), alphaLowP3(data.camControl==0));

alphaDotLowP2 = zeros(samples, 1);
alphaDotLowP3 = zeros(samples, 1);

frequency = 100;

alphaDotLowP2(1) = alphaLowP2(1) * frequency;
alphaDotLowP3(1) = alphaLowP3(1) * frequency;

for i = 2:samples
    alphaDotLowP2(i) = (alphaLowP2(i) - alphaLowP2(i-1)) * frequency;
    alphaDotLowP3(i) = (alphaLowP3(i) - alphaLowP3(i-1)) * frequency;  
end

figure(8);
hold on
plot(alphaDotLowP2);
plot(data.alphaDotQube);
legend("AlphaDotCamLP2", "AlphaDotQube");
axis([0 height(data) -3 3])
grid on
hold off

figure(9);
hold on
plot(alphaDotLowP3);
plot(data.alphaDotQube);
legend("AlphaDotCamLP3", "AlphaDotQube");
axis([0 height(data) -3 3])
grid on
hold off

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

figure(10);
hold on
plot(KxLowP2);
plot(data.Kx);
legend("V LP2", "V Qube");
axis([0 height(data) -10 10])
grid on
hold off

figure(11);
hold on
plot(KxLowP3);
plot(data.Kx);
legend("V LP3", "V Qube");
axis([0 height(data) -10 10])
grid on
hold off

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

figure(12);
hold on
plot(alphaDotDirectHighP2);
plot(data.alphaDotQube);
legend("AlphaDotCamDirectHP2", "AlphaDotQube");
axis([0 height(data) -3 3])
grid on
hold off

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


%Summary
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

figure(13);
hold on
plot(alphaDotDirect3PMAHP);
plot(data.alphaDotQube);
legend("AlphaDotCamDirec3PMAHP", "AlphaDotQube");
axis([0 height(data) -3 3])
grid on
hold off

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
