function Duty = efoc_controller(omega_m, u_bus, i_N, i_abc, theta_e, omega_ref, u_bus_ref)
    %#codegen
    % Extended Field Oriented Control (EFOC) for Simulink MATLAB Function Block
    %
    % Inputs:
    % omega_m   : Mechanical speed (rad/s)
    % u_bus     : Measured DC bus voltage (V)
    % i_N       : Measured neutral point current (A)
    % i_abc     : 3-phase currents [i_a; i_b; i_c] (A)
    % theta_e   : Electrical angle (rad)
    % omega_ref : Reference mechanical speed (rad/s)
    % u_bus_ref : Reference DC bus voltage (e.g., 360 V)
    %
    % Outputs:
    % Duty      : PWM Duty cycles [D_a; D_b; D_c] (0.0 to 1.0)
    
    persistent int_id int_iq int_iN int_vbus int_spd
    if isempty(int_id)
        int_id = 0; int_iq = 0; int_iN = 0; int_vbus = 0; int_spd = 0;
    end
    
    Ts = 1e-4; % Controller sample time (10 kHz)
    
    % Hardcoded machine params (or pass via mask)
    p = 4; psi_f = 0.1; Ld = 1.5e-3; Lq = 1.5e-3; u_bat = 180;
    
    % Hardcoded PI gains (or pass via mask)
    Kp_id = 1.5; Ki_id = 810;
    Kp_iq = 1.5; Ki_iq = 810;
    Kp_iN = -0.016; Ki_iN = -0.75;
    Kp_vbus = 0.2; Ki_vbus = 5.0;
    Kp_spd = 0.1; Ki_spd = 2.0;
    
    %% 1. Park Transformation
    % Clarke
    i_alpha = (2/3) * (i_abc(1) - 0.5*i_abc(2) - 0.5*i_abc(3));
    i_beta = (2/3) * ((sqrt(3)/2)*i_abc(2) - (sqrt(3)/2)*i_abc(3));
    
    % Park
    id = i_alpha * cos(theta_e) + i_beta * sin(theta_e);
    iq = -i_alpha * sin(theta_e) + i_beta * cos(theta_e);
    
    %% 2. Speed Controller (PI)
    err_spd = omega_ref - omega_m;
    int_spd = int_spd + err_spd * Ts;
    int_spd = max(min(int_spd, 15), -15); % Anti-windup
    Te_ref = Kp_spd * err_spd + Ki_spd * int_spd;
    Te_ref = max(min(Te_ref, 15), -15);
    
    %% 3. MTPA (Surface PMSM -> id = 0)
    id_ref = 0;
    iq_ref = Te_ref / (1.5 * p * psi_f);
    
    %% 4. DC Bus Voltage Controller
    err_vbus = u_bus_ref - u_bus;
    int_vbus = int_vbus + err_vbus * Ts;
    int_vbus = max(min(int_vbus, 30), -30); % Anti-windup
    iN_ref = Kp_vbus * err_vbus + Ki_vbus * int_vbus;
    iN_ref = max(min(iN_ref, 30), -30);
    
    %% 5. Neutral Current Controller (Zero-Sequence DC/DC)
    err_iN = iN_ref - i_N;
    int_iN = int_iN + err_iN * Ts;
    
    % Feedforward term to decouple the battery voltage
    ff_D0 = u_bat / max(u_bus, 10.0); 
    D0 = ff_D0 + Kp_iN * err_iN + Ki_iN * int_iN;
    
    % Limit D0 to safe duty cycle boundaries
    if D0 > 0.9
        D0 = 0.9;
        int_iN = int_iN - err_iN * Ts; % Anti-windup
    elseif D0 < 0.1
        D0 = 0.1;
        int_iN = int_iN - err_iN * Ts;
    end
    
    %% 6. DQ Current Controllers
    err_id = id_ref - id;
    int_id = int_id + err_id * Ts;
    ud_star = Kp_id * err_id + Ki_id * int_id;
    
    err_iq = iq_ref - iq;
    int_iq = int_iq + err_iq * Ts;
    uq_star = Kp_iq * err_iq + Ki_iq * int_iq;
    
    % Cross-coupling decoupling
    omega_e = omega_m * p;
    ud_star = ud_star - omega_e * Lq * iq;
    uq_star = uq_star + omega_e * (psi_f + Ld * id);
    
    %% 7. Inverse Park Transformation
    u_alpha = ud_star * cos(theta_e) - uq_star * sin(theta_e);
    u_beta = ud_star * sin(theta_e) + uq_star * cos(theta_e);
    
    % Clarke Inverse
    u_AN_star = u_alpha;
    u_BN_star = -0.5 * u_alpha + (sqrt(3)/2) * u_beta;
    u_CN_star = -0.5 * u_alpha - (sqrt(3)/2) * u_beta;
    
    %% 8. Final Duty Cycle Generation (Eq 15)
    D_A = D0 + (u_AN_star / u_bus);
    D_B = D0 + (u_BN_star / u_bus);
    D_C = D0 + (u_CN_star / u_bus);
    
    % Saturate final duties
    Duty = [D_A; D_B; D_C];
    Duty = max(min(Duty, 1.0), 0.0);
end
