try
    model = 'ETS_Model';
    load_system(model);
    efoc = [model '/Control_System/EFOC_Subsystem'];
    
    set_param([efoc '/Mux_DutyA'], 'Inputs', '3');
    set_param([efoc '/Mux_DutyB'], 'Inputs', '3');
    set_param([efoc '/Mux_DutyC'], 'Inputs', '3');
    
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
    
    save_system(model);
    disp('All EFOC lines added successfully and arranged!');
catch e
    disp(e.message);
end
exit;
