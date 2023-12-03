close all;

log = 'data230626doublePhase.log';
dir = strcat(pwd, '\logs\', log);

data = readtable(dir, 'Delimiter', ';');

K = [-1.000000, -1.661800, 36.745900, -1.622700, 3.242100];

%Chosen filter
fc = 25;
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

covAlpha = cov(data.alphaQube(data.camControl==0), data.alphaCam(data.camControl==0));
corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), data.alphaCam(data.camControl==0));
[c,lags] = xcorr(data.alphaQube(data.camControl==0), data.alphaCam(data.camControl==0), 15, 'normalized');
figure(1);
stem(lags, c);

covAlphaDot = cov(data.alphaDotQube(data.camControl==0), data.alphaDotCam(data.camControl==0));
corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), data.alphaDotCam(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), data.alphaDotCamButterworth(data.camControl==0), 15, 'normalized');
figure(2);
stem(lags, c);

figure(3);
hold on
plot(data.alphaCam);
plot(data.alphaQube);
legend("Alpha Cam", "AlphaQube");
axis([0 height(data) -0.03 0.03])
grid on
hold off

figure(4);
hold on
plot(data.KxCam);
plot(data.Kx);
legend("V Cam", "V Qube");
axis([0 height(data) -10 10])
grid on
hold off

figure(5);
hold on
plot(data.alphaDotCamButterworth);
plot(data.alphaDotQube);
legend("AlphaDotCamButterworth", "AlphaDotQube");
axis([0 height(data) -3 3])
grid on
hold off

figure(6);
hold on
plot(data.alphaDotCamButterworth);
plot(alphaDotDirectLowDesignFilter);
legend("AlphaDotCamButterworth", "ButterworthCalculated");
axis([0 height(data) -3 3])
grid on
hold off