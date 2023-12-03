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

%% Notation fixing
A_r_up = 1 / Jt *  [0 Jt 0 0 0;
                    0 0 0 Jt 0;
                    0 0 0 0 Jt;
                    0 0 mp^2*l^2*r*g  -Jp*(br+km^2/Rm)   -mp*l*r*bp 
                    0 0 mp*g*l*Jr    -mp*l*r*(br+km^2/Rm)  -Jr*bp];
                
A_r_down = 1 / Jt *  [0 Jt 0 0 0;
                      0 0 0 Jt 0;
                      0 0 0 0 Jt;
                      0 0 mp^2*l^2*r*g  -Jp*(br+km^2/Rm)   mp*l*r*bp 
                      0 0 -mp*g*l*Jr    mp*l*r*(br+km^2/Rm)  -Jr*bp];
                  
B_r_up = 1 / Jt * [0; 0; 0; Jp*km/Rm; mp*l*r*km/Rm];
                  
B_r_down = 1 / Jt * [0; 0; 0; Jp*km/Rm; -mp*l*r*km/Rm];

if sum(abs(A_a - A_r_up) < 10^-9, 'all') == size(A_a, 1)  * size(A_a, 2)
   disp('A_r_up matches matrix from original software - correctly defined')  
end
if sum(abs(B_a - B_r_up) < 10^-9, 'all') == size(B_a, 1)  * size(B_a, 2)
   disp('B_r_up matches matrix from original software - correctly defined')
end

%% Stability
disp('Eigs A_r_up')
eigs_up = eigs(A_r_up)
disp('Eigs A_r_down')
eigs_down = eigs(A_r_down)

%% Reachability
CM = ctrb(A_r_up, B_r_up);
OM = obsv(A, C);
rCM = rank(CM)
rOM = rank(OM)
detCM = det(CM)


%% Closed loop system
K = lqr(A_r_up, B_r_up, Q, R);
eigs(A_r_up - B_r_up * K)


%% Observer Analysis
L = [1 0 0 0 0;
     0 1 0 0 0;
     0 0 1 0 0;
     0 0 0 1 0;
     0 0 0 0 0.82
];
C = [1 0 0 0 0;
     0 1 0 0 0;
     0 0 1 0 0;
     0 0 0 1 0;
     0 0 0 0 1
];

eigs(A_r_up - B_r_up * K - L*C)
