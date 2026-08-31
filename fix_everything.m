try
    model = 'ETS_Model';
    load_system(model);
    
    % 1. FIX THE MUX BLOCKS inside EFOC_Controller
    ctrl = [model '/Control_System/EFOC_Controller'];
    muxes = {'Mux_InvPark', 'Mux_Park', 'Mux_we_iq', 'Mux_we_id', 'Mux_DutyA', 'Mux_DutyB', 'Mux_DutyC', 'Mux_Duty_Out'};
    
    for i=1:length(muxes)
        mux_name = muxes{i};
        mux_path = [ctrl '/' mux_name];
        if getSimulinkBlockHandle(mux_path) ~= -1
            n_inputs = get_param(mux_path, 'Inputs');
            
            % Delete all lines connected to this mux first!
            lines = get_param(mux_path, 'LineHandles');
            for j=1:length(lines.Inport)
                if lines.Inport(j) ~= -1, delete_line(lines.Inport(j)); end
            end
            if lines.Outport(1) ~= -1, delete_line(lines.Outport(1)); end
            
            pos = get_param(mux_path, 'Position');
            delete_block(mux_path);
            
            % Add Vector Concatenate
            add_block('simulink/Math Operations/Matrix Concatenate', mux_path, 'Position', pos);
            set_param(mux_path, 'NumInputs', n_inputs, 'Mode', 'Vector');
        end
    end
    
    % Re-wire Mux_InvPark explicitly
    try add_line(ctrl, 'Sum_ud/1', 'Mux_InvPark/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Sum_uq/1', 'Mux_InvPark/2', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'theta_e/1', 'Mux_InvPark/3', 'autorouting', 'on'); catch; end
    
    try add_line(ctrl, 'Mux_InvPark/1', 'InvPark_a/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_InvPark/1', 'InvPark_b/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_InvPark/1', 'InvPark_c/1', 'autorouting', 'on'); catch; end
    
    % Re-wire Mux_Park
    try add_line(ctrl, 'Demux_abc/1', 'Mux_Park/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Demux_abc/2', 'Mux_Park/2', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Demux_abc/3', 'Mux_Park/3', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'theta_e/1', 'Mux_Park/4', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_Park/1', 'Park_d/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_Park/1', 'Park_q/1', 'autorouting', 'on'); catch; end
    
    % Re-wire Mux_we_iq and Mux_we_id
    try add_line(ctrl, 'Gain_we/1', 'Mux_we_iq/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Park_q/1', 'Mux_we_iq/2', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_we_iq/1', 'Decouple_d/1', 'autorouting', 'on'); catch; end
    
    try add_line(ctrl, 'Gain_we/1', 'Mux_we_id/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Park_d/1', 'Mux_we_id/2', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_we_id/1', 'Decouple_q/1', 'autorouting', 'on'); catch; end
    
    % Re-wire Duty Muxes
    try add_line(ctrl, 'PI_iN/1', 'Mux_DutyA/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'InvPark_a/1', 'Mux_DutyA/2', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'u_bus/1', 'Mux_DutyA/3', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_DutyA/1', 'Duty_A/1', 'autorouting', 'on'); catch; end
    
    try add_line(ctrl, 'PI_iN/1', 'Mux_DutyB/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'InvPark_b/1', 'Mux_DutyB/2', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'u_bus/1', 'Mux_DutyB/3', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_DutyB/1', 'Duty_B/1', 'autorouting', 'on'); catch; end
    
    try add_line(ctrl, 'PI_iN/1', 'Mux_DutyC/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'InvPark_c/1', 'Mux_DutyC/2', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'u_bus/1', 'Mux_DutyC/3', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_DutyC/1', 'Duty_C/1', 'autorouting', 'on'); catch; end
    
    try add_line(ctrl, 'Duty_A/1', 'Mux_Duty_Out/1', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Duty_B/1', 'Mux_Duty_Out/2', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Duty_C/1', 'Mux_Duty_Out/3', 'autorouting', 'on'); catch; end
    try add_line(ctrl, 'Mux_Duty_Out/1', 'Sat_Duty/1', 'autorouting', 'on'); catch; end

    % 2. WIRE THE EFOC_Controller IN Control_System
    sys = [model '/Control_System'];
    
    % Clear all lines connected to EFOC_Controller
    lh = get_param([sys '/EFOC_Controller'], 'LineHandles');
    for i=1:length(lh.Inport)
        if lh.Inport(i) ~= -1, delete_line(lh.Inport(i)); end
    end
    if lh.Outport(1) ~= -1, delete_line(lh.Outport(1)); end
    
    % The EFOC_Controller has Inports:
    % 1: w_m
    % 2: w_ref
    % 3: T_re
    % 4: u_bus
    % 5: u_bus_ref
    % 6: i_N
    % 7: i_abc
    % 8: theta_e
    
    % Control_System has Inports:
    % In1: omega_m
    % In2: V_DC
    % In3: I_N
    % In4: I_abc (Wait, I multiplexed I_A, I_B, I_C at top level, so it's a vector)
    % In5: theta_e
    % In6: W_ref
    % In7: V_ref
    
    % Let's get the names of the inports in Control_System
    sys_ports = find_system(sys, 'SearchDepth', 1, 'BlockType', 'Inport');
    for i=1:length(sys_ports)
        port_name = get_param(sys_ports{i}, 'Name');
        sys_port_num = get_param(sys_ports{i}, 'Port');
        src_port = [get_param(sys_ports{i}, 'Name') '/1'];
        
        if contains(port_name, 'Motor_Physics') % This is omega_m! (Name became Motor_Physics)
            add_line(sys, src_port, 'EFOC_Controller/1', 'autorouting', 'on'); % w_m
        elseif contains(port_name, 'W_ref')
            add_line(sys, src_port, 'EFOC_Controller/2', 'autorouting', 'on'); % w_ref
        elseif contains(port_name, 'V_DC')
            add_line(sys, src_port, 'EFOC_Controller/4', 'autorouting', 'on'); % u_bus
        elseif contains(port_name, 'V_ref')
            add_line(sys, src_port, 'EFOC_Controller/5', 'autorouting', 'on'); % u_bus_ref
        elseif contains(port_name, 'I_N')
            add_line(sys, src_port, 'EFOC_Controller/6', 'autorouting', 'on'); % i_N
        elseif contains(port_name, 'Mux_I') || contains(port_name, 'I_abc') || contains(port_name, 'In4')
            % It might be called Mux_I
            add_line(sys, src_port, 'EFOC_Controller/7', 'autorouting', 'on'); % i_abc
        elseif contains(port_name, 'theta') || contains(port_name, 'In5')
            % The 5th port is theta_e (from Motor_Physics/5)
            % Wait, port names were generated automatically
            if strcmp(port_name, 'Motor_Physics1')
                add_line(sys, src_port, 'EFOC_Controller/8', 'autorouting', 'on'); % theta_e
            end
        end
    end
    
    % We need T_re (Regen torque). Let's just add a constant block for it.
    if getSimulinkBlockHandle([sys '/T_re_Const']) == -1
        add_block('simulink/Sources/Constant', [sys '/T_re_Const']);
        set_param([sys '/T_re_Const'], 'Value', '0');
    end
    add_line(sys, 'T_re_Const/1', 'EFOC_Controller/3', 'autorouting', 'on');
    
    % Wire output
    add_line(sys, 'EFOC_Controller/1', 'PWM_Compare/1', 'autorouting', 'on');
    
    save_system(model);
    disp('Complete rewiring and dimension fix successful!');
catch e
    disp(e.message);
end
exit;
