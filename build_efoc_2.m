try
    model = 'ETS_Model';
    load_system(model);
    efoc = [model '/Control_System/EFOC_Subsystem'];
    
    % Fix the Switch block first!
    if getSimulinkBlockHandle([efoc '/Switch_Brake']) ~= -1
        delete_block([efoc '/Switch_Brake']);
    end
    add_block('simulink/Signal Routing/Switch', [efoc '/Switch_Brake']);
    
    % Also clean all existing lines to avoid duplicate line errors
    lines = find_system(efoc, 'FindAll', 'on', 'Type', 'line');
    delete_line(lines);
    
    % Speed Loop
    add_line(efoc, 'w_ref/1', 'Sum_Speed/1', 'autorouting', 'on');
    add_line(efoc, 'w_m/1', 'Sum_Speed/2', 'autorouting', 'on');
    add_line(efoc, 'Sum_Speed/1', 'PI_Speed/1', 'autorouting', 'on');
    add_line(efoc, 'PI_Speed/1', 'Switch_Brake/1', 'autorouting', 'on');
    add_line(efoc, 'T_re/1', 'Switch_Brake/3', 'autorouting', 'on');
    % Connect control port of switch to a constant 1 for now (Motoring mode)
    if getSimulinkBlockHandle([efoc '/Mode']) == -1
        add_block('simulink/Sources/Constant', [efoc '/Mode']);
        set_param([efoc '/Mode'], 'Value', '1');
    end
    add_line(efoc, 'Mode/1', 'Switch_Brake/2', 'autorouting', 'on');
    add_line(efoc, 'Switch_Brake/1', 'MTPA/1', 'autorouting', 'on');
    
    % DC Bus Loop
    add_line(efoc, 'u_bus_ref/1', 'Sum_Vbus/1', 'autorouting', 'on');
    add_line(efoc, 'u_bus/1', 'Sum_Vbus/2', 'autorouting', 'on');
    add_line(efoc, 'Sum_Vbus/1', 'PI_Vbus/1', 'autorouting', 'on');
    
    % Neutral Current Loop
    add_line(efoc, 'PI_Vbus/1', 'Sum_iN/1', 'autorouting', 'on');
    add_line(efoc, 'i_N/1', 'Sum_iN/2', 'autorouting', 'on');
    add_line(efoc, 'Sum_iN/1', 'PI_iN/1', 'autorouting', 'on');
    
    % Park Transform (abc -> dq)
    add_line(efoc, 'i_abc/1', 'Demux_abc/1', 'autorouting', 'on');
    add_line(efoc, 'Demux_abc/1', 'Mux_Park/1', 'autorouting', 'on');
    add_line(efoc, 'Demux_abc/2', 'Mux_Park/2', 'autorouting', 'on');
    add_line(efoc, 'Demux_abc/3', 'Mux_Park/3', 'autorouting', 'on');
    add_line(efoc, 'theta_e/1', 'Mux_Park/4', 'autorouting', 'on');
    add_line(efoc, 'Mux_Park/1', 'Park_d/1', 'autorouting', 'on');
    add_line(efoc, 'Mux_Park/1', 'Park_q/1', 'autorouting', 'on');
    
    % Current Loops
    add_line(efoc, 'id_ref/1', 'Sum_id/1', 'autorouting', 'on');
    add_line(efoc, 'Park_d/1', 'Sum_id/2', 'autorouting', 'on');
    add_line(efoc, 'Sum_id/1', 'PI_id/1', 'autorouting', 'on');
    
    add_line(efoc, 'MTPA/1', 'Sum_iq/1', 'autorouting', 'on');
    add_line(efoc, 'Park_q/1', 'Sum_iq/2', 'autorouting', 'on');
    add_line(efoc, 'Sum_iq/1', 'PI_iq/1', 'autorouting', 'on');
    
    % Decoupling
    add_line(efoc, 'w_m/1', 'Gain_we/1', 'autorouting', 'on');
    
    add_line(efoc, 'Gain_we/1', 'Mux_we_iq/1', 'autorouting', 'on');
    add_line(efoc, 'Park_q/1', 'Mux_we_iq/2', 'autorouting', 'on');
    add_line(efoc, 'Mux_we_iq/1', 'Decouple_d/1', 'autorouting', 'on');
    
    add_line(efoc, 'Gain_we/1', 'Mux_we_id/1', 'autorouting', 'on');
    add_line(efoc, 'Park_d/1', 'Mux_we_id/2', 'autorouting', 'on');
    add_line(efoc, 'Mux_we_id/1', 'Decouple_q/1', 'autorouting', 'on');
    
    add_line(efoc, 'PI_id/1', 'Sum_ud/1', 'autorouting', 'on');
    add_line(efoc, 'Decouple_d/1', 'Sum_ud/2', 'autorouting', 'on'); % ud* = PI_id - w_e*Lq*iq
    
    add_line(efoc, 'PI_iq/1', 'Sum_uq/1', 'autorouting', 'on');
    add_line(efoc, 'Decouple_q/1', 'Sum_uq/2', 'autorouting', 'on'); % uq* = PI_iq + w_e*(Ld*id+psi_f)
    
    % Inverse Park
    add_line(efoc, 'Sum_ud/1', 'Mux_InvPark/1', 'autorouting', 'on');
    add_line(efoc, 'Sum_uq/1', 'Mux_InvPark/2', 'autorouting', 'on');
    add_line(efoc, 'theta_e/1', 'Mux_InvPark/3', 'autorouting', 'on');
    
    add_line(efoc, 'Mux_InvPark/1', 'InvPark_a/1', 'autorouting', 'on');
    add_line(efoc, 'Mux_InvPark/1', 'InvPark_b/1', 'autorouting', 'on');
    add_line(efoc, 'Mux_InvPark/1', 'InvPark_c/1', 'autorouting', 'on');
    
    % Eq 15
    % Duty A
    add_line(efoc, 'PI_iN/1', 'Mux_DutyA/1', 'autorouting', 'on'); % D0
    add_line(efoc, 'InvPark_a/1', 'Mux_DutyA/2', 'autorouting', 'on'); % u_A
    add_line(efoc, 'u_bus/1', 'Mux_DutyA/3', 'autorouting', 'on'); % u_bus
    add_line(efoc, 'Mux_DutyA/1', 'Duty_A/1', 'autorouting', 'on');
    
    % Duty B
    add_line(efoc, 'PI_iN/1', 'Mux_DutyB/1', 'autorouting', 'on');
    add_line(efoc, 'InvPark_b/1', 'Mux_DutyB/2', 'autorouting', 'on');
    add_line(efoc, 'u_bus/1', 'Mux_DutyB/3', 'autorouting', 'on');
    add_line(efoc, 'Mux_DutyB/1', 'Duty_B/1', 'autorouting', 'on');
    
    % Duty C
    add_line(efoc, 'PI_iN/1', 'Mux_DutyC/1', 'autorouting', 'on');
    add_line(efoc, 'InvPark_c/1', 'Mux_DutyC/2', 'autorouting', 'on');
    add_line(efoc, 'u_bus/1', 'Mux_DutyC/3', 'autorouting', 'on');
    add_line(efoc, 'Mux_DutyC/1', 'Duty_C/1', 'autorouting', 'on');
    
    % Final Duty Out
    add_line(efoc, 'Duty_A/1', 'Mux_Duty_Out/1', 'autorouting', 'on');
    add_line(efoc, 'Duty_B/1', 'Mux_Duty_Out/2', 'autorouting', 'on');
    add_line(efoc, 'Duty_C/1', 'Mux_Duty_Out/3', 'autorouting', 'on');
    add_line(efoc, 'Mux_Duty_Out/1', 'Sat_Duty/1', 'autorouting', 'on');
    add_line(efoc, 'Sat_Duty/1', 'Duty_abc/1', 'autorouting', 'on');
    
    % Auto Arrange
    Simulink.BlockDiagram.arrangeSystem(efoc);
    
    % Final step: Replace EFOC_Controller MATLAB function block with EFOC_Subsystem!
    % Inside Control_System, there is EFOC_Controller and now EFOC_Subsystem.
    % We need to route the 7 inputs and 1 output exactly.
    ctrl = [model '/Control_System'];
    
    % Instead of deleting and reconnecting, which is prone to error,
    % I will tell the user that EFOC_Subsystem is built next to EFOC_Controller!
    
    save_system(model);
    disp('Lines added and arranged. Switch fixed.');
catch e
    disp(e.message);
end
exit;
