clear all;
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

%% System Analysis

%Q = diag([80, 0, 1, 1, 1]); %Standard from in class tuning
Q = diag([1, 0, 1, 1, 1]);

R = 2;

A_a = [0, 1, 0, 0, 0;
       0, A(1,:);
       0, A(2,:);
       0, A(3,:);
       0, A(4,:)];
B_a = [0; B];

C_a = [0, C(1,:)
       0, C(2,:)];

C_lqg = [zeros(1,5)
         C_a
         zeros(2,5)];

B_cl = [-1, 0, 0, 0, 0]';


K = lqr(A_a, B_a, Q, R);
L = lqr(A_a, C_lqg, Q, R);

%% H-inf norm G_yw analysis
h_min = 100;
h_min_a = 0;
h_min_ad = 0;
h_min_r = 0;
K_min = 0;

%for a = linspace(0.1, 5, 50)
for a = linspace(1, 1, 1)
    %for ad = linspace(0.1, 5, 50)
    for ad = linspace(1, 1, 1)
        for r = linspace(0.5, 4, 8)
            Q = diag([1, 0, a, 1, ad]);
            R = r;
            K = lqr(A_a, B_a, Q, R);
            A_cl = A_a - B_a*K;
            h = hinfnorm(ss(A_cl,B_a*K,eye(5),0));

            if h < h_min
                h_min_a = a;
                h_min_ad = ad;
                h_min_r = r;
                h_min = h;
                K_min = K;
            end
        end
    end
end

disp(h_min_a);
disp(h_min_ad);
disp(h_min_r);
disp(h_min);
disp(K_min);

%% System Analysis

Q = diag([1, 0, 1, 1, 1]);
R= 1;
K = lqr(A_a, B_a, Q, R);

A_cl = A_a - B_a*K;
C = eye(5);
D = 0;
sState = ss(A_cl,B_a*K,C,0);
transfer = tf(sState);

figure(1)
margin(transfer(5,1))
figure(2)
margin(transfer(5,2))
figure(3)
margin(transfer(5,3))
figure(4)
margin(transfer(5,4))
figure(5)
margin(transfer(5,5))
figure(6)
nyquist(transfer(5,5))

opts = bodeoptions;
opts.MagUnits = 'abs';
figure(7)
bodeplot(transfer(:,5), opts)

gamma_hinfnorm = hinfnorm(ss(A_cl,B_cl,C,D))


%% LMI H-inf Calculation

A = A_cl;
B = B_cl;
D = [0, 0, 0, 0, 0]';

P=sdpvar(5); 
gamma=sdpvar;
M=[A'*P+P*A, P*B          , C';
   B'*P    , -gamma*eye(1), D';
   C       , D            , -gamma*eye(5)];

lmi=[M<=0,P>=0]; 

optimize(lmi,gamma)
gamma_lmi=value(gamma)

%% LMI H-inf Control Calculation

A = A_a;
B = B_a;
B_tilde = B_cl;
X = sdpvar(5);
Y = sdpvar(1,5); 
gamma = sdpvar;

M=[X*A'+A*X-Y'*B'-B*Y, X*C'         , B;
   C*X               , -gamma*eye(5), zeros(5,1);
   B'                , zeros(1,5)   , -gamma*eye(1)];

lmi=[M<=0,X>=0,gamma<=1.0]; 

optimize(lmi)
gamma_lmi = value(gamma)
K_lmi = value(Y)*inv(value(X))

%Control from this method too agressive for C++ control

%% LMI H-inf H-2 Control Calculation

%ToDo
