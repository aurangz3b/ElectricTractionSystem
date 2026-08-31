% Run this script to load the parameters into the MATLAB workspace
% before running your Simulink model.

%% PMSM Parameters (from Table I of paper)
R = 0.81;       % Stator resistance (ohm)
p = 4;          % Number of pole pairs
Ld = 1.5e-3;    % d-axis inductance (H)
Lq = 1.5e-3;    % q-axis inductance (H)
L0 = 2.4e-3;    % Zero-sequence inductance (H)
psi_f = 0.1;    % Permanent magnet flux linkage (Wb)
J = 0.005;      % Inertia (kg.m^2) - estimated
B = 0.001;      % Friction factor - estimated

%% Hardware Parameters
L2 = 5e-3;      % Smoothing inductor (H)
C = 940e-6;     % DC bus capacitor (F)
Ubat = 180;     % Battery voltage (V)

%% Controller Gains
% Current PI (dq)
Kp_id = 1.5; 
Ki_id = 810;
Kp_iq = 1.5; 
Ki_iq = 810;

% Neutral Current PI (negative gains due to plant inversion)
Kp_iN = -0.016; 
Ki_iN = -0.75;

% DC Bus PI
Kp_vbus = 0.2; 
Ki_vbus = 5.0;

% Speed PI
Kp_spd = 0.1; 
Ki_spd = 2.0;

disp('ETS Parameters loaded into workspace successfully!');
