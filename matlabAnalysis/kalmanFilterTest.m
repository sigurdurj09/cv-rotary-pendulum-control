close all;
clc;

%% qube2_rotpen_param
%Uncomment if you have access to the Quanser variable definition and setup scripts and 
%have placed them in the same folder.  Alternatively set up 
%the A,B,C and D matrices from the equations specified in the thesis
%equations, or the calculated parameters. 

%qube2_rotpen_param


%% rotpen_ABCD_eqns_ip

%Uncomment if you have access to the Quanser variable definition and setup scripts and 
%have placed them in the same folder.  Alternatively set up 
%the A,B,C and D matrices from the equations specified in the thesis
%equations, or the calculated parameters.

%rotpen_ABCD_eqns_ip

%%Adding to the model

%Q = diag([80, 0, 1, 1, 1]); %Standard from in class tuning
Q = diag([1, 0, 1, 1, 1]);

R = 1;

A_a = [0, 1, 0, 0, 0;
       0, A(1,:);
       0, A(2,:);
       0, A(3,:);
       0, A(4,:)];
B_a = [0; B];

C_a = [0, C(1,:)
       0, C(2,:)];
   

B_cl = [-1, 0, 0, 0, 0]';


K = lqr(A_a, B_a, Q, R);
A_cl = A_a - B_a*K;

fs = 100;

%% Data testing

log = 'data230703W.log';
dir = strcat(pwd, '\logs\', log);
data = readtable(dir, 'Delimiter', ';');

n = 0;
samples = height(data);
kalmanFilter = zeros(5, samples);
x_hat = zeros(5, samples);
z_k = [data.thetaQube, data.alphaCam]';
kalmanFilter(:,1) = [data.z(1), data.thetaQube(1), data.alphaCam(1), data.thetaDotQube(1), data.alphaDotCam(1)]';

F_k = A_cl / fs + eye(5);
H_k = C_a;

Q_k = diag([1, 1, 1, 1, 1])*10;
R_k = diag([1, 1])*3;
P_k = zeros(5,5);
P_hat_k = zeros(5,5);
K_k = zeros(5,2);

for i = 2:samples
    %Predict
    x_hat(:,i) = F_k * kalmanFilter(:,i-1);
    P_hat_k = F_k * P_k * F_k' + Q_k;
    %Update
    y_tilde_k = z_k(:,i) - H_k * x_hat(:,i);
    S_k = H_k * P_hat_k * H_k' + R_k;
    K_k = P_hat_k * H_k' * inv(S_k);
    kalmanFilter(:,i) = x_hat(:,i) + K_k * y_tilde_k;
    P_k = (eye(5,5) - K_k * H_k) * P_hat_k;
    y_tilde_k = z_k(:,i) - H_k * kalmanFilter(:,i);
     
end
    
covAlpha = cov(data.alphaQube(data.camControl==0), kalmanFilter(data.camControl==0));
corcoefAlpha = corrcoef(data.alphaQube, kalmanFilter(3,:));
[c,lags] = xcorr(data.alphaQube, kalmanFilter(3,:), 5, 'normalized');
figure(1);
stem(lags, c);

figure(2);
hold on
plot(data.alphaQube);
plot(kalmanFilter(3,:));
%plot(data.alphaCam);
legend("Alpha Qube", "KalmanFilterAlpha");
axis([0 height(data) -0.03 0.03])
grid on
hold off

figure(3);
hold on
plot(data.alphaDotQube);
plot(kalmanFilter(5,:));
%plot(data.alphaCam);
legend("AlphaDot Qube", "KalmanFilterAlphaDot");
axis([0 height(data) -3 3])
grid on
hold off

%% Kalman on 1 variable

corcoefAlpha = corrcoef(data.alphaQube(data.camControl==0), data.alphaCam(data.camControl==0));
[c,lags] = xcorr(data.alphaQube(data.camControl==0), data.alphaCam(data.camControl==0), 5, 'normalized');
fprintf('Unfiltered alpha data has CorCoef = %f and 0 lag = %f.\n' , corcoefAlpha(2,1), c(lags==0));
corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), data.alphaDotCam(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), data.alphaDotCam(data.camControl==0), 5, 'normalized');
fprintf('Unfiltered alphaDot data has CorCoef = %f and 0 lag = %f.\n' , corcoefAlphaDot(2,1), c(lags==0));

kalmanAlphaDotPredict = zeros(1, samples);
kalmanAlphaDotPredict(1) = data.alphaDotCam(1);

bestCor = 0;
bestCorWeight = 0;
bestKalmanFilter = kalmanAlphaDotPredict;

for weight = 0:0.01:1
    for i = 2:samples
        predict = F_k(5,:) * [data.z(i-1), data.thetaQube(i-1), data.alphaCam(i-1), data.thetaDotQube(i-1), kalmanAlphaDotPredict(i-1)]';
        kalmanAlphaDotPredict(i) = weight * predict + (1-weight) * data.alphaDotCam(i-1);
    end
    
    corcoefAlpha = corrcoef(data.alphaDotQube(data.camControl==0), kalmanAlphaDotPredict(data.camControl==0));
    [c,lags] = xcorr(data.alphaDotQube(data.camControl==0), kalmanAlphaDotPredict(data.camControl==0), 5, 'normalized');
    zeroLagCCor = c(lags==0);
    
    maxCorr = -1;
    maxCorrInd = 1;
    
    for i = 1:length(c)
        if c(i) > maxCorr
            maxCorr = c(i);
            maxCorrInd = i;
        end    
    end
    
    if zeroLagCCor + corcoefAlpha(2,1) + maxCorr > bestCor
        bestCor = zeroLagCCor + corcoefAlpha(2,1) + maxCorr;
        bestCorWeight = weight;
        bestKalmanFilter = kalmanAlphaDotPredict;
    end
    
end

figure(4);
hold on
plot(data.alphaDotQube);
plot(bestKalmanFilter);
%plot(data.alphaCam);
legend("AlphaDot Qube", "SimpleKalmanFilterAlphaDot");
axis([0 height(data) -3 3])
grid on
hold off

corcoefAlpha = corrcoef(data.alphaDotQube(data.camControl==0), bestKalmanFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), bestKalmanFilter(data.camControl==0), 5, 'normalized');
zeroLagCCor = c(lags==0);

fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.  Weight %f.\n' , corcoefAlpha(2,1), c(lags==0), max(c), lags(c==max(c)), bestCorWeight);

%% Kalman on 1 filtered variable

%Chosen filter order and coefficients

or = 2;
b = [0.5231    0.8058    0.5231];
a = [1.0000    0.5459    0.3062]; 

%Test filter
samples = height(data);
alphaDotFilter = zeros(samples, 1);

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

    alphaDotFilter(i) =  y(1);

end

kalmanAlphaDotPredict = zeros(1, samples);
kalmanAlphaDotPredict(1) = alphaDotFilter(1);

bestCor = 0;
bestCorWeight = 0;
bestKalmanFilter = kalmanAlphaDotPredict;

for weight = 0:0.01:1
    for i = 2:samples
        predict = F_k(5,:) * [data.z(i-1), data.thetaQube(i-1), data.alphaFilteredGated(i-1), data.thetaDotQube(i-1), kalmanAlphaDotPredict(i-1)]';
        kalmanAlphaDotPredict(i) = weight * predict + (1-weight) * alphaDotFilter(i-1);
    end
    
    corcoefAlpha = corrcoef(data.alphaDotQube(data.camControl==0), kalmanAlphaDotPredict(data.camControl==0));
    [c,lags] = xcorr(data.alphaDotQube(data.camControl==0), kalmanAlphaDotPredict(data.camControl==0), 5, 'normalized');
    zeroLagCCor = c(lags==0);
    
    maxCorr = -1;
    maxCorrInd = 1;
    
    for i = 1:length(c)
        if c(i) > maxCorr
            maxCorr = c(i);
            maxCorrInd = i;
        end    
    end
    
    if zeroLagCCor + corcoefAlpha(2,1) + maxCorr > bestCor
        bestCor = zeroLagCCor + corcoefAlpha(2,1) + maxCorr;
        bestCorWeight = weight;
        bestKalmanFilter = kalmanAlphaDotPredict;
    end
    
end

figure(5);
hold on
plot(data.alphaDotQube);
plot(bestKalmanFilter);
%plot(data.alphaCam);
legend("AlphaDot Qube", "SimpleKalman+IIRFilterAlphaDot");
axis([0 height(data) -3 3])
grid on
hold off

corcoefAlpha = corrcoef(data.alphaDotQube(data.camControl==0), bestKalmanFilter(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), bestKalmanFilter(data.camControl==0), 5, 'normalized');
zeroLagCCor = c(lags==0);

fprintf('CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.  Weight %f.\n' , corcoefAlpha(2,1), c(lags==0), max(c), lags(c==max(c)), bestCorWeight);

%% Comparison

figure(6);
hold on
plot(data.alphaDotQube);
plot(data.alphaDotKalman);
%plot(data.alphaCam);
legend("AlphaDot Qube", "AlphaDot Kalman Analysis");
axis([0 height(data) -3 3])
grid on
hold off

corcoefAlphaDot = corrcoef(data.alphaDotQube(data.camControl==0), data.alphaDotKalman(data.camControl==0));
[c,lags] = xcorr(data.alphaDotQube(data.camControl==0), data.alphaDotKalman(data.camControl==0), 5, 'normalized');
zeroLagCCor = c(lags==0);

fprintf('Kalman real CorCoef = %f and 0 lag = %f.  Max crosscor is %f at index %i.  Weight %f.\n' , corcoefAlphaDot(2,1), c(lags==0), max(c), lags(c==max(c)));
