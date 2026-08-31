try
    model = 'ETS_Model';
    load_system(model);
    
    lines = find_system(model, 'FindAll', 'on', 'Type', 'line');
    delete_line(lines);
    
    % Measurements
    if getSimulinkBlockHandle([model '/V_DC']) == -1
        add_block('powerlib/Measurements/Voltage Measurement', [model '/V_DC'], 'Position', [350, 100, 380, 130]);
    end
    if getSimulinkBlockHandle([model '/I_N']) == -1
        add_block('powerlib/Measurements/Current Measurement', [model '/I_N'], 'Position', [150, 360, 180, 390]);
    end
    
    % References
    if getSimulinkBlockHandle([model '/W_ref']) == -1
        add_block('simulink/Sources/Constant', [model '/W_ref'], 'Position', [20, 50, 50, 80]);
        set_param([model '/W_ref'], 'Value', '314');
    end
    if getSimulinkBlockHandle([model '/V_ref']) == -1
        add_block('simulink/Sources/Constant', [model '/V_ref'], 'Position', [20, 100, 50, 130]);
        set_param([model '/V_ref'], 'Value', '360');
    end
    if getSimulinkBlockHandle([model '/T_L']) == -1
        add_block('simulink/Sources/Constant', [model '/T_L'], 'Position', [750, 100, 780, 130]);
        set_param([model '/T_L'], 'Value', '0');
    end
    
    % PWM Custom
    if getSimulinkBlockHandle([model '/Carrier']) == -1
        add_block('simulink/Sources/Repeating Sequence', [model '/Carrier'], 'Position', [200, 10, 230, 40]);
        set_param([model '/Carrier'], 'rep_seq_t', '[0 5e-5 1e-4]', 'rep_seq_y', '[0 1 0]');
    end
    if getSimulinkBlockHandle([model '/PWM_Compare']) == -1
        add_block('simulink/Logic and Bit Operations/Relational Operator', [model '/PWM_Compare'], 'Position', [250, 50, 280, 80]);
        set_param([model '/PWM_Compare'], 'Operator', '>=');
    end
    % The Inverter expects 6 pulses for a 3-arm bridge!
    % If Duty >= Carrier, upper switch is ON, lower is OFF.
    % We need to generate [P1, P2, P3, P4, P5, P6] or [Pa1, Pa2, Pb1, Pb2, Pc1, Pc2] depending on Universal Bridge settings.
    % Wait! Universal Bridge expects a vector of 6 pulses.
    % P1, P2 for arm 1. P3, P4 for arm 2. P5, P6 for arm 3.
    % We can generate [Duty >= Carrier, Duty < Carrier]...
    % Or use Simulink's PWM Generator. Let's try to add the powerlib one, it's safer.
    if getSimulinkBlockHandle([model '/PWM_Gen']) == -1
        try
            add_block('powerlib/Pulse & Signal Generators/PWM Generator (2-Level)', [model '/PWM_Gen'], 'Position', [250, 50, 300, 100]);
            % Wait, PWM generator expects modulation index, not duty cycle.
            % Mod signal = 2 * Duty - 1
        catch
            disp('Could not find PWM Generator block');
        end
    end
    
    % Scripts
    rt = sfroot;
    m = rt.find('-isa', 'Stateflow.Machine', 'Name', model);
    charts = m.find('-isa', 'Stateflow.EMChart');
    
    motor_script = sprintf([ ...
        'function [ea, eb, ec, omega_m, theta_e] = fcn(ia, ib, ic, T_L)\n' ...
        '%%#codegen\n' ...
        'persistent w th\n' ...
        'if isempty(w), w = 0; th = 0; end\n' ...
        'Ts = 1e-5; p = 4; psi_f = 0.1; J = 0.005; B = 0.001; Ld = 1.5e-3; Lq = 1.5e-3;\n' ...
        'ialpha = (2/3)*(ia - 0.5*ib - 0.5*ic);\n' ...
        'ibeta = (2/3)*(sqrt(3)/2*ib - sqrt(3)/2*ic);\n' ...
        'id = ialpha*cos(th) + ibeta*sin(th);\n' ...
        'iq = -ialpha*sin(th) + ibeta*cos(th);\n' ...
        'Te = 1.5 * p * (psi_f * iq + (Ld - Lq) * id * iq);\n' ...
        'dw = (Te - T_L - B*w)/J;\n' ...
        'w = w + dw*Ts;\n' ...
        'th = th + w*p*Ts;\n' ...
        'if th > 2*pi, th = th - 2*pi; end\n' ...
        'if th < 0, th = th + 2*pi; end\n' ...
        'omega_m = w; theta_e = th;\n' ...
        'we = w*p;\n' ...
        'ea = -we * psi_f * sin(th);\n' ...
        'eb = -we * psi_f * sin(th - 2*pi/3);\n' ...
        'ec = -we * psi_f * sin(th + 2*pi/3);\n' ...
    ]);
    efoc_script = fileread('efoc_controller.m');
    for i = 1:length(charts)
        if contains(charts(i).Path, 'Motor_Physics')
            charts(i).Script = motor_script;
        elseif contains(charts(i).Path, 'EFOC_Controller')
            charts(i).Script = efoc_script;
        end
    end
    
    % Let's use SIMULINK MUX for i_abc
    if getSimulinkBlockHandle([model '/Mux_I']) == -1
        add_block('simulink/Signal Routing/Mux', [model '/Mux_I'], 'Position', [550, 150, 560, 200]);
        set_param([model '/Mux_I'], 'Inputs', '3');
    end
    
    save_system(model);
    disp('Scripts injected and blocks added.');
catch e
    disp(e.message);
end
exit;
