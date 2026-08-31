try
    model = 'ETS_Model';
    load_system(model);
    
    % Clear all lines
    lines = find_system(model, 'FindAll', 'on', 'Type', 'line');
    delete_line(lines);
    
    % 1. Physical Lines Rewire
    p_inv = get_param([model '/Inverter'], 'PortHandles');
    p_cap = get_param([model '/DC_Bus_Cap'], 'PortHandles');
    p_bat = get_param([model '/Battery'], 'PortHandles');
    p_ind = get_param([model '/Inductor_L2'], 'PortHandles');
    
    p_ia = get_param([model '/I_A'], 'PortHandles');
    p_ib = get_param([model '/I_B'], 'PortHandles');
    p_ic = get_param([model '/I_C'], 'PortHandles');
    
    p_ra = get_param([model '/RLC_A'], 'PortHandles');
    p_rb = get_param([model '/RLC_B'], 'PortHandles');
    p_rc = get_param([model '/RLC_C'], 'PortHandles');
    
    p_ea = get_param([model '/EMF_A'], 'PortHandles');
    p_eb = get_param([model '/EMF_B'], 'PortHandles');
    p_ec = get_param([model '/EMF_C'], 'PortHandles');
    
    p_vdc = get_param([model '/V_DC'], 'PortHandles');
    p_in = get_param([model '/I_N'], 'PortHandles');
    
    % AC Side (Inverter -> Current Sensors -> RLC -> EMF -> Neutral)
    add_line(model, p_inv.LConn(1), p_ia.LConn(1));
    add_line(model, p_inv.LConn(2), p_ib.LConn(1));
    add_line(model, p_inv.LConn(3), p_ic.LConn(1));
    
    add_line(model, p_ia.RConn(1), p_ra.LConn(1));
    add_line(model, p_ib.RConn(1), p_rb.LConn(1));
    add_line(model, p_ic.RConn(1), p_rc.LConn(1));
    
    add_line(model, p_ra.RConn(1), p_ea.LConn(1));
    add_line(model, p_rb.RConn(1), p_eb.LConn(1));
    add_line(model, p_rc.RConn(1), p_ec.LConn(1));
    
    add_line(model, p_ea.RConn(1), p_eb.RConn(1));
    add_line(model, p_eb.RConn(1), p_ec.RConn(1));
    
    % DC Side (Battery, Inductor, DC Bus)
    add_line(model, p_inv.RConn(1), p_cap.LConn(1));
    add_line(model, p_inv.RConn(2), p_cap.RConn(1));
    add_line(model, p_bat.RConn(1), p_inv.RConn(2));
    
    % Measure V_DC across capacitor
    add_line(model, p_vdc.LConn(1), p_cap.LConn(1));
    add_line(model, p_vdc.LConn(2), p_cap.RConn(1));
    
    % Neutral -> Inductor_L2 -> I_N -> Battery Positive
    add_line(model, p_ec.RConn(1), p_ind.RConn(1));
    add_line(model, p_ind.LConn(1), p_in.LConn(1));
    add_line(model, p_in.RConn(1), p_bat.LConn(1));
    
    % 2. Signal Lines (Mux, Controllers, PWM)
    % Inputs for Motor_Physics: ia, ib, ic, T_L
    add_line(model, 'I_A/1', 'Motor_Physics/1');
    add_line(model, 'I_B/1', 'Motor_Physics/2');
    add_line(model, 'I_C/1', 'Motor_Physics/3');
    add_line(model, 'T_L/1', 'Motor_Physics/4');
    
    % Connect Motor Outputs (ea, eb, ec) to Simulink-PS converters (Wait, Controlled Voltage Source in powerlib takes standard Simulink signal!)
    add_line(model, 'Motor_Physics/1', 'EMF_A/1');
    add_line(model, 'Motor_Physics/2', 'EMF_B/1');
    add_line(model, 'Motor_Physics/3', 'EMF_C/1');
    
    % Inputs for EFOC_Controller: omega_m, u_bus, i_N, i_abc, theta_e, omega_ref, u_bus_ref
    add_line(model, 'Motor_Physics/4', 'EFOC_Controller/1'); % omega_m
    add_line(model, 'V_DC/1', 'EFOC_Controller/2');          % u_bus
    add_line(model, 'I_N/1', 'EFOC_Controller/3');           % i_N
    
    % Mux for i_abc
    add_line(model, 'I_A/1', 'Mux_I/1');
    add_line(model, 'I_B/1', 'Mux_I/2');
    add_line(model, 'I_C/1', 'Mux_I/3');
    add_line(model, 'Mux_I/1', 'EFOC_Controller/4');         % i_abc
    
    add_line(model, 'Motor_Physics/5', 'EFOC_Controller/5'); % theta_e
    add_line(model, 'W_ref/1', 'EFOC_Controller/6');         % omega_ref
    add_line(model, 'V_ref/1', 'EFOC_Controller/7');         % u_bus_ref
    
    % PWM logic
    % Duty (3x1) compared with Carrier (1x1)
    % PWM_Compare inputs: Duty, Carrier
    add_line(model, 'EFOC_Controller/1', 'PWM_Compare/1');
    add_line(model, 'Carrier/1', 'PWM_Compare/2');
    
    % Since PWM_Compare outputs boolean, Universal Bridge expects double.
    if getSimulinkBlockHandle([model '/Data_Type_Conv']) == -1
        add_block('simulink/Signal Attributes/Data Type Conversion', [model '/Data_Type_Conv'], 'Position', [320, 50, 350, 80]);
        set_param([model '/Data_Type_Conv'], 'OutDataTypeStr', 'double');
    end
    add_line(model, 'PWM_Compare/1', 'Data_Type_Conv/1');
    
    % Generate NOT pulses for lower arms
    if getSimulinkBlockHandle([model '/Logical_NOT']) == -1
        add_block('simulink/Logic and Bit Operations/Logical Operator', [model '/Logical_NOT'], 'Position', [320, 100, 350, 130]);
        set_param([model '/Logical_NOT'], 'Operator', 'NOT');
    end
    add_line(model, 'PWM_Compare/1', 'Logical_NOT/1');
    if getSimulinkBlockHandle([model '/Data_Type_Conv_NOT']) == -1
        add_block('simulink/Signal Attributes/Data Type Conversion', [model '/Data_Type_Conv_NOT'], 'Position', [370, 100, 400, 130]);
        set_param([model '/Data_Type_Conv_NOT'], 'OutDataTypeStr', 'double');
    end
    add_line(model, 'Logical_NOT/1', 'Data_Type_Conv_NOT/1');
    
    % Mux to combine 6 pulses
    if getSimulinkBlockHandle([model '/Mux_PWM']) == -1
        add_block('simulink/Signal Routing/Mux', [model '/Mux_PWM'], 'Position', [420, 50, 430, 150]);
        set_param([model '/Mux_PWM'], 'Inputs', '6');
    end
    
    % Universal Bridge expects: P1, P2, P3, P4, P5, P6 (P1=A_upper, P2=A_lower, P3=B_upper, P4=B_lower, P5=C_upper, P6=C_lower)
    % We need to Demux the 3 phases from Data_Type_Conv, then feed to Mux_PWM.
    if getSimulinkBlockHandle([model '/Demux_UP']) == -1
        add_block('simulink/Signal Routing/Demux', [model '/Demux_UP'], 'Position', [370, 40, 380, 90]);
        set_param([model '/Demux_UP'], 'Outputs', '3');
    end
    if getSimulinkBlockHandle([model '/Demux_DOWN']) == -1
        add_block('simulink/Signal Routing/Demux', [model '/Demux_DOWN'], 'Position', [410, 110, 420, 160]);
        set_param([model '/Demux_DOWN'], 'Outputs', '3');
    end
    
    add_line(model, 'Data_Type_Conv/1', 'Demux_UP/1');
    add_line(model, 'Data_Type_Conv_NOT/1', 'Demux_DOWN/1');
    
    add_line(model, 'Demux_UP/1', 'Mux_PWM/1');   % A_up
    add_line(model, 'Demux_DOWN/1', 'Mux_PWM/2'); % A_down
    add_line(model, 'Demux_UP/2', 'Mux_PWM/3');   % B_up
    add_line(model, 'Demux_DOWN/2', 'Mux_PWM/4'); % B_down
    add_line(model, 'Demux_UP/3', 'Mux_PWM/5');   % C_up
    add_line(model, 'Demux_DOWN/3', 'Mux_PWM/6'); % C_down
    
    % Finally connect Mux_PWM to Inverter gate 'g' (which is the only input port)
    add_line(model, 'Mux_PWM/1', 'Inverter/1');
    
    save_system(model);
    disp('All physical and signal wires successfully connected!');
catch e
    disp('Error:');
    disp(e.message);
end
exit;
