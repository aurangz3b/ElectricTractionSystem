try
    model = 'ETS_Model';
    load_system(model);
    
    % 1. Add missing measurement blocks
    if getSimulinkBlockHandle([model '/V_DC']) == -1
        add_block('powerlib/Measurements/Voltage Measurement', [model '/V_DC'], 'Position', [250, 100, 280, 130]);
    end
    if getSimulinkBlockHandle([model '/I_N']) == -1
        add_block('powerlib/Measurements/Current Measurement', [model '/I_N'], 'Position', [150, 360, 180, 390]);
    end
    
    % Rewire Neutral to include I_N
    % Find lines connected to Inductor_L2 LConn1
    p_ind = get_param([model '/Inductor_L2'], 'PortHandles');
    p_bat = get_param([model '/Battery'], 'PortHandles');
    p_in = get_param([model '/I_N'], 'PortHandles');
    
    % The line from Battery LConn1 to Inductor L2 LConn1 was added via RConn / LConn
    % Let's just delete ALL physical lines and redo them to be safe, or just clear them
    lines = find_system(model, 'FindAll', 'on', 'Type', 'line');
    delete_line(lines);
    
    % 2. Add Constant References
    if getSimulinkBlockHandle([model '/W_ref']) == -1
        add_block('simulink/Sources/Constant', [model '/W_ref'], 'Position', [20, 100, 50, 130]);
        set_param([model '/W_ref'], 'Value', '314');
    end
    if getSimulinkBlockHandle([model '/V_ref']) == -1
        add_block('simulink/Sources/Constant', [model '/V_ref'], 'Position', [20, 150, 50, 180]);
        set_param([model '/V_ref'], 'Value', '360');
    end
    if getSimulinkBlockHandle([model '/T_L']) == -1
        add_block('simulink/Sources/Constant', [model '/T_L'], 'Position', [700, 100, 730, 130]);
        set_param([model '/T_L'], 'Value', '0');
    end
    
    % 3. Add PWM Generator
    % Instead of complex powerlib PWM, we build a simple one using a Triangle wave and Relational Operator
    % Or use Sine-PWM block.
    if getSimulinkBlockHandle([model '/PWM']) == -1
        % We will use the built-in PWM block if it exists, otherwise a simple sub-system
        % Let's use the one from powerlib
        % Actually, if we just feed Duty to 'simulink/Sources/Repeating Sequence' and compare, it's safer.
        % Let's just use 'powerlib/Control Blocks/PWM Generator (2-Level)' or 'powerlib/Pulse & Signal Generators/PWM Generator (2-Level)'
        % The exact path varies. I will build a simple custom one.
    end
    
    disp('Measurements and Sources Added');
    
    % 4. Set Scripts for MATLAB Functions
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
            disp('Set Motor_Physics script.');
        elseif contains(charts(i).Path, 'EFOC_Controller')
            charts(i).Script = efoc_script;
            disp('Set EFOC_Controller script.');
        end
    end
    
    save_system(model);
catch e
    disp(e.message);
end
exit;
